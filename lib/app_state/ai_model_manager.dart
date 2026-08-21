import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:llamadart/llamadart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Consent/download state for the camera chatbot's on-device AI replies (see
/// lib/widgets/camera_chatbot.dart). Declining or a failed download never
/// blocks the chatbot — callers should fall back to canned replies whenever
/// [reply] returns null, per CLAUDE.md's "confirm before adding an AI/backend
/// dependency" rule: AI is strictly opt-in here, not a requirement.
enum AiChatStatus { unknown, notAccepted, declined, downloading, ready, failed }

class AiModelManager extends ChangeNotifier {
  // static const _repoId = 'bartowski/Qwen_Qwen3.5-0.8B-GGUF';  // old model ~0.6GB
  // static const _filePath = 'Qwen_Qwen3.5-0.8B-Q4_K_M.gguf';
  static const _repoId = 'bartowski/Qwen_Qwen3-1.7B-GGUF'; // new model ~1.1GB
  static const _filePath = 'Qwen_Qwen3-1.7B-Q4_K_M.gguf';
  static const _consentPrefsKey = 'ai_chat_consent';

  AiChatStatus status = AiChatStatus.unknown;
  double downloadProgress = 0;

  final _engine = LlamaEngine(LlamaBackend());
  ChatSession? _chatSession;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final consent = prefs.getString(_consentPrefsKey);
    if (consent == 'accepted') {
      unawaited(_downloadAndLoad());
    } else if (consent == 'declined') {
      status = AiChatStatus.declined;
      notifyListeners();
    } else {
      status = AiChatStatus.notAccepted;
      notifyListeners();
    }
  }

  Future<void> accept() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_consentPrefsKey, 'accepted');
    await _downloadAndLoad();
  }

  Future<void> decline() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_consentPrefsKey, 'declined');
    status = AiChatStatus.declined;
    notifyListeners();
  }

  Future<void> retry() => _downloadAndLoad();

  Future<void> _downloadAndLoad() async {
    status = AiChatStatus.downloading;
    downloadProgress = 0;
    notifyListeners();
    try {
      // Without an explicit cacheDirectory, llamadart falls back to the OS
      // temp/cache dir on Android/iOS, which the platform can wipe between
      // launches — that caused the downloaded model to disappear and
      // re-download every time the app restarted. applicationSupportDirectory
      // is app-private and durable across launches.
      final supportDir = await getApplicationSupportDirectory();
      await _engine.loadModelSource(
        ModelSource.huggingFace(repoId: _repoId, filePath: _filePath),
        options: ModelLoadOptions(cacheDirectory: supportDir.path),
        modelParams: ModelParams(
          // Default (4096) left almost no room for a prompt once the chat
          // tools' schema was attached — `ChatSession`'s own context-fit
          // check reserves half the context for the response by default,
          // so 4096 total meant only ~2048 tokens for system prompt + all
          // tool schemas + history combined, which the tool schema alone
          // could already exceed. Found via `lastRequestFitContext` going
          // false on literally the second real message in a fresh chat.
          contextSize: 8192,
          // `.auto` (llamadart's own recommended default) lets each device
          // pick its best backend — GPU/Vulkan acceleration matters a lot
          // for inference speed on capable hardware (e.g. flagship Adreno
          // GPUs), so forcing CPU-only everywhere was too broad a fix for
          // what was only confirmed as one specific test device's GPU-driver
          // anomalies (`AHardwareBuffer ... failed`, `/proc/fas/render`
          // ioctl denials in the logs). If that same device turns out to
          // need CPU-only specifically, gate it on a device check rather
          // than penalizing every device's inference speed to work around
          // one unit's driver issue.
          preferredBackend: GpuBackend.auto,
        ),
        onProgress: (progress) {
          downloadProgress = progress.fraction ?? 0;
          notifyListeners();
        },
      );
      _chatSession = ChatSession(_engine, systemPrompt: _systemPrompt);
      status = AiChatStatus.ready;
    } catch (_) {
      status = AiChatStatus.failed;
    }
    notifyListeners();
  }

  /// Streams the assistant's reply text for [userText], or null if the model
  /// isn't ready — callers should fall back to a canned reply in that case.
  ///
  /// When [tools] is non-empty, this drives the full tool-call loop itself
  /// (mirroring `llamadart`'s own `basic_app` example service): stream
  /// tokens, collect any tool-call deltas, invoke the matching
  /// [ToolDefinition]'s handler, feed the result back as a tool-role
  /// message, and let the model continue — up to [_maxToolRounds] rounds so
  /// a stuck loop can't run forever. A tool's handler is free to trigger its
  /// own side effect (e.g. showing an image card) before returning its
  /// short text result; that's the caller's concern via whatever closure
  /// state the handler already captured, not this method's.
  Stream<String>? reply(
    String userText, {
    List<ToolDefinition>? tools,
    ToolChoice? toolChoice,
    void Function(String status)? onStatus,
  }) {
    final session = _chatSession;
    if (status != AiChatStatus.ready || session == null) return null;
    return _replyStream(
      session,
      userText,
      tools: tools,
      toolChoice: toolChoice,
      onStatus: onStatus,
    );
  }

  static const _maxToolRounds = 10;

  Stream<String> _replyStream(
    ChatSession session,
    String userText, {
    List<ToolDefinition>? tools,
    ToolChoice? toolChoice,
    void Function(String status)? onStatus,
  }) async* {
    final userParts = <LlamaContentPart>[LlamaTextContent(userText)];
    var isFirstTurn = true;

    // Left at the 4096 default, `ChatSession`'s context-fit check reserves
    // `min(maxTokens, contextSize / 2)` tokens for the response alone —
    // 2048 of an (old) 4096-token context, before a single tool schema was
    // even counted. A concise chat reply doesn't need 4096 tokens; capping
    // this frees the budget for the actual prompt (system + tools +
    // history) instead.
    const generationParams = GenerationParams(maxTokens: 512);

    for (var round = 0; round < _maxToolRounds; round++) {
      final accumulators = <int, _ToolCallAccumulator>{};
      // Defensive display-layer filter: `llamadart` is expected to parse
      // `<tool_call>...</tool_call>` envelopes structurally (see
      // `_systemPrompt`'s doc on `ChatFormat.qwen3CoderXml`) rather than
      // surface them as chat text, but a streaming boundary case has been
      // observed where the raw envelope still leaks into `delta.content`
      // alongside a tool call that goes on to execute correctly. Route all
      // content through this filter so a leak like that can never reach
      // the chat bubble again, independent of whatever causes it upstream.
      final markupFilter = _ToolCallMarkupFilter();
      onStatus?.call('Thinking…');
      // Qwen3.5 always emits a <think>...</think> reasoning block by
      // default; llamadart splits that into delta.thinking separately from
      // delta.content, so disabling it keeps replies fast and free of raw
      // reasoning text in the chat bubble.
      await for (final chunk in session.create(
        isFirstTurn ? userParts : const <LlamaContentPart>[],
        params: generationParams,
        tools: tools,
        toolChoice: isFirstTurn ? toolChoice : null,
        enableThinking: false,
      )) {
        final delta = chunk.choices.first.delta;
        final content = delta.content ?? '';
        if (content.isNotEmpty) {
          final visible = markupFilter.feed(content);
          if (visible.isNotEmpty) {
            onStatus?.call('');
            yield visible;
          }
        }

        final toolCalls = delta.toolCalls;
        if (toolCalls == null) continue;
        for (final call in toolCalls) {
          final accumulator = accumulators.putIfAbsent(
            call.index,
            _ToolCallAccumulator.new,
          );
          if (call.id != null) accumulator.id = call.id;
          final function = call.function;
          if (function?.name != null) accumulator.name = function!.name;
          if (function?.arguments != null) {
            accumulator.arguments.write(function!.arguments);
          }
        }
      }
      final trailing = markupFilter.flush();
      if (trailing.isNotEmpty) yield trailing;
      isFirstTurn = false;

      // A reply with no tool calls has nothing for the fail-closed check
      // below to guard — only a pending tool call needs that gate.
      if (accumulators.isEmpty || tools == null || tools.isEmpty) return;

      // `ChatSession.lastRequestFitContext`'s own doc: "a false value means
      // even the active turn could not be compacted enough — callers that
      // execute model-proposed side effects should fail closed." A tool
      // call generated from a truncated/garbled prompt is not trustworthy
      // enough to execute, especially the destructive ones — skip
      // execution instead of running whatever came out. The plain-text
      // content already yielded this round (if any) still stands; this
      // only withholds the pending tool call(s).
      if (!session.lastRequestFitContext) {
        yield '\n\n(Skipped a requested action — this conversation has '
            'gotten too long for me to safely act on. Please start a new '
            'chat.)';
        return;
      }

      // Execute every tool call the model emitted this round — a compound
      // request ("turn on night mode and show me the snapshot") correctly
      // produces two tool calls in one round, and only running the first
      // made the second depend on the model reliably re-issuing it next
      // round from a "not executed, ask again" note, which it did
      // inconsistently (the intermittent "changed the mode but no
      // snapshot" bug). Destructive tools don't need this guard anyway —
      // reboot_camera/reset_camera_settings/factory_reset_camera/
      // delete_camera never auto-execute regardless, they always stage a
      // ConfirmEffect first (see chatbot_tools.dart), so there's no real
      // risk being traded away here for the tools that would actually
      // matter if a small model over-emitted a bad extra call.
      //
      // Previously capped to one call per round — a small model asked to
      // pick from a keyword-scored candidate list could emit multiple
      // calls in one pass when more than one tool's name/description
      // loosely matched the message, and running all of them would
      // compound a single bad guess into several side effects. Commented
      // out rather than deleted in case that tradeoff needs revisiting:
      //
      // if (index != sortedIndexes.first) {
      //   session.addMessage(
      //     LlamaChatMessage.withContent(
      //       role: LlamaChatRole.tool,
      //       content: [
      //         LlamaToolResultContent(
      //           id: call.id,
      //           name: name ?? 'unknown_tool',
      //           result:
      //               'Not executed: only one tool call is handled per '
      //               'turn. Ask again if this was actually needed.',
      //         ),
      //       ],
      //     ),
      //   );
      //   continue;
      // }
      final sortedIndexes = accumulators.keys.toList()..sort();
      for (final index in sortedIndexes) {
        final call = accumulators[index]!;
        final name = call.name;
        if (name == null || name.isEmpty) {
          session.addMessage(
            LlamaChatMessage.withContent(
              role: LlamaChatRole.tool,
              content: [
                LlamaToolResultContent(
                  id: call.id,
                  name: 'unknown_tool',
                  result: 'Error: tool call missing function name.',
                ),
              ],
            ),
          );
          continue;
        }

        ToolDefinition? tool;
        for (final candidate in tools) {
          if (candidate.name == name) {
            tool = candidate;
            break;
          }
        }
        if (tool == null) {
          session.addMessage(
            LlamaChatMessage.withContent(
              role: LlamaChatRole.tool,
              content: [
                LlamaToolResultContent(
                  id: call.id,
                  name: name,
                  result: 'Error: unknown tool "$name".',
                ),
              ],
            ),
          );
          continue;
        }

        Object? result;
        try {
          onStatus?.call('Calling ${_friendlyToolLabel(name)}…');
          final argsJson = call.arguments.toString().trim();
          final args = argsJson.isEmpty
              ? <String, dynamic>{}
              : (jsonDecode(argsJson) as Map).cast<String, dynamic>();
          result = await tool.invoke(args);
        } catch (e) {
          result = 'Error: tool execution failed for $name: $e';
        }

        session.addMessage(
          LlamaChatMessage.withContent(
            role: LlamaChatRole.tool,
            content: [
              LlamaToolResultContent(id: call.id, name: name, result: result),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    unawaited(_engine.dispose());
    super.dispose();
  }
}

/// e.g. "take_snapshot" -> "Take Snapshot", for the "Calling X…" status text.
String _friendlyToolLabel(String toolName) => toolName
    .split('_')
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');

// Kept deliberately terse — every sentence here is sent as part of the
// prompt on every single turn, tool call or not, so length is a real
// latency cost on a small on-device model, not just a style choice. Each
// instruction below exists to fix a specific observed failure (see git
// history / this session's debugging): claiming no device access despite
// having tools, contradicting a just-succeeded tool result, re-firing a
// destructive confirmation tool.
//
// Deliberately says nothing about tool-call tag syntax: this GGUF's own
// embedded chat template (`tokenizer.chat_template`) already instructs the
// model to use `<tool_call><function=name><parameter=x>value</parameter>
// </function></tool_call>`, and `llamadart` detects that same template as
// `ChatFormat.qwen3CoderXml` and parses/grammar-constrains generation to
// match it. An earlier version of this prompt told the model to use a
// different (Hermes-style JSON) tag format instead and to never use
// `<function=...>` — directly contradicting the model's own template —
// which measurably made tool calls less reliable, not more. Don't
// reintroduce tag-format guidance here without checking it agrees with
// the template above.
const _systemPrompt =
    'You are Vizen, a concise assistant in a home security camera app. '
    'Never mention Qwen/Alibaba/any model name. Use tools instead of '
    'claiming no device access — call list_cameras first for any question '
    'about which cameras or devices exist, are added, or their status '
    '("list devices"/"what cameras do I have"/"is X online" all mean the '
    'same thing here). A tool result is real, '
    'accomplished fact, never hypothetical — report it directly, never '
    'add a disclaimer like "I can\'t access the camera/devices" after a '
    'successful tool call. If a result starts with "Error", the action '
    'did NOT happen — say so plainly and never describe it as done or '
    'successful. If a result starts with "Awaiting user '
    'confirmation", say you\'ve shown a confirmation prompt and don\'t '
    'call that tool again this turn.';

/// Accumulates one streamed tool-call's `name`/`arguments` across chunks —
/// `llamadart` streams a tool call's function name and JSON arguments
/// incrementally, keyed by [LlamaCompletionChunkToolCall.index], the same
/// way OpenAI's streaming tool-call deltas work.
class _ToolCallAccumulator {
  String? id;
  String? name;
  final StringBuffer arguments = StringBuffer();
}

/// Strips `<tool_call>...</tool_call>` envelopes out of streamed assistant
/// text before it reaches the chat bubble — see the call site's doc for
/// why this exists as a defensive layer on top of `llamadart`'s own
/// structural parsing. Holds back any suffix that could be a partial match
/// of either tag across a chunk boundary (a single token can split
/// `<tool_c` + `all>`), so it never emits half a tag as visible text.
class _ToolCallMarkupFilter {
  static const _open = '<tool_call>';
  static const _close = '</tool_call>';

  bool _insideToolCall = false;
  String _carry = '';

  /// Feeds the next streamed content chunk in and returns the portion of
  /// it (plus any previously held-back text now resolved) safe to show.
  String feed(String chunk) {
    var combined = _carry + chunk;
    _carry = '';
    final out = StringBuffer();
    while (true) {
      if (!_insideToolCall) {
        final idx = combined.indexOf(_open);
        if (idx == -1) {
          final hold = _partialSuffixLength(combined, _open);
          out.write(combined.substring(0, combined.length - hold));
          _carry = combined.substring(combined.length - hold);
          break;
        }
        out.write(combined.substring(0, idx));
        combined = combined.substring(idx + _open.length);
        _insideToolCall = true;
      } else {
        final idx = combined.indexOf(_close);
        if (idx == -1) {
          _carry = combined.substring(
            combined.length - _partialSuffixLength(combined, _close),
          );
          break;
        }
        combined = combined.substring(idx + _close.length);
        _insideToolCall = false;
      }
    }
    return out.toString();
  }

  /// Flushes text held back at round end — it never completed a tag, so it
  /// was always plain content. Anything still inside an unterminated
  /// `<tool_call>` is discarded rather than shown, since a half-emitted
  /// envelope isn't meaningful chat text either way.
  String flush() {
    if (_insideToolCall) return '';
    final text = _carry;
    _carry = '';
    return text;
  }

  static int _partialSuffixLength(String text, String tag) {
    final maxLen = tag.length < text.length ? tag.length : text.length;
    for (var len = maxLen; len > 0; len--) {
      if (text.substring(text.length - len) == tag.substring(0, len)) {
        return len;
      }
    }
    return 0;
  }
}
