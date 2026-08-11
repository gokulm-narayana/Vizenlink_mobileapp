import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:llamadart/llamadart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The iOS Simulator's Metal implementation (`MTLSimDevice`, a software
/// compatibility shim rather than a real GPU) crashes with SIGTRAP inside
/// `ggml_metal_buffer_get_tensor`/`_xpc_shmem_create_with_prot` the moment
/// llama.cpp tries to run inference on it — confirmed via a real crash
/// report from `~/Library/Logs/DiagnosticReports/`. Real iOS devices have
/// genuine Metal GPUs and aren't affected, so this only forces CPU-only
/// inference when actually running under the Simulator.
bool _isIosSimulator() =>
    Platform.isIOS && Platform.environment.containsKey('SIMULATOR_DEVICE_NAME');

/// Consent/download state for the camera chatbot's on-device AI replies (see
/// lib/widgets/camera_chatbot.dart). Declining or a failed download never
/// blocks the chatbot — callers should fall back to canned replies whenever
/// [reply] returns null, per CLAUDE.md's "confirm before adding an AI/backend
/// dependency" rule: AI is strictly opt-in here, not a requirement.
enum AiChatStatus { unknown, notAccepted, declined, downloading, ready, failed }

class AiModelManager extends ChangeNotifier {
  static const _repoId = 'bartowski/Qwen_Qwen3.5-0.8B-GGUF';
  static const _filePath = 'Qwen_Qwen3.5-0.8B-Q4_K_M.gguf';
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
          preferredBackend: _isIosSimulator()
              ? GpuBackend.cpu
              : GpuBackend.auto,
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
  Stream<String>? reply(String userText) {
    final session = _chatSession;
    if (status != AiChatStatus.ready || session == null) return null;
    // Qwen3.5 always emits a <think>...</think> reasoning block by default;
    // llamadart splits that into delta.thinking separately from
    // delta.content, so disabling it keeps replies fast and free of raw
    // reasoning text in the chat bubble.
    return session
        .create([LlamaTextContent(userText)], enableThinking: false)
        .map((chunk) => chunk.choices.first.delta.content ?? '');
  }

  @override
  void dispose() {
    unawaited(_engine.dispose());
    super.dispose();
  }
}

const _systemPrompt =
    'Your name is Vizen, a concise assistant embedded in a home security '
    'camera app. If asked your name, say you are Vizen — never mention '
    'Qwen, Alibaba, or any underlying model/vendor name. Answer briefly '
    'and helpfully about the user\'s cameras, events, and footage.';
