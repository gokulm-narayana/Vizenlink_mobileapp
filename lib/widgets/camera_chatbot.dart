import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:llamadart/llamadart.dart' show ToolDefinition;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app_state/ai_model_manager.dart';
import '../app_state/chat_controller.dart';
import '../app_state/chatbot_tools.dart';
import '../app_state/homes_controller.dart';
import '../models/camera.dart';
import '../models/scanned_camera.dart';
import '../screens/camera_live/camera_live_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/scan/scanned_devices_screen.dart';

const _quickPrompts = [
  'List my cameras',
  'Scan for cameras',
  'Take a snapshot',
  'Open live view',
];

/// Opens the camera assistant. The chat itself (CHAT-001) only opens once
/// the on-device AI model (Qwen3.5-0.8B via `AiModelManager`) is ready — the
/// user is asked for consent first (CHAT-019), and declining closes the
/// whole flow instead of falling back to a canned-reply chat, since the
/// chatbot's whole purpose is the AI. Every reply and every action the
/// chatbot takes comes from the model's own real tool-calling
/// (`chatbot_tools.dart`'s `buildCameraTools()`) — there is no keyword-
/// matched shortcut standing in for a tool call. Downloading the model is
/// strictly opt-in (see CLAUDE.md: no backend/AI dependency without
/// explicit confirmation). The conversation itself lives in [chatController]
/// (owned by the caller, instantiated once in `main.dart`) rather than this
/// sheet's own `State` — this bottom sheet's `State` is destroyed every time
/// it's closed (including an accidental back-gesture dismiss), so a
/// message list stored here alone would silently lose the whole
/// conversation on every close/reopen.
Future<void> showCameraChatbot(
  BuildContext context, {
  required HomesController homesController,
  required AiModelManager aiModelManager,
  required ChatController chatController,
}) async {
  if (aiModelManager.status != AiChatStatus.ready) {
    final ready = await _resolveAiGate(context, aiModelManager);
    if (!ready || !context.mounted) return;
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _CameraChatbotSheet(
      homesController: homesController,
      aiModelManager: aiModelManager,
      chatController: chatController,
    ),
  );
}

/// Shows the consent dialog (if not already decided) then a download-progress
/// gate. Returns true once the model is ready to chat, false if the user
/// declined or closed out before it finished.
Future<bool> _resolveAiGate(
  BuildContext context,
  AiModelManager aiModelManager,
) async {
  if (aiModelManager.status == AiChatStatus.notAccepted ||
      aiModelManager.status == AiChatStatus.declined) {
    final accepted = await _showConsentDialog(context, aiModelManager);
    if (!accepted) return false;
  }
  if (!context.mounted) return false;
  if (aiModelManager.status == AiChatStatus.ready) return true;
  final ready = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _AiDownloadGateSheet(aiModelManager: aiModelManager),
  );
  return ready ?? false;
}

Future<bool> _showConsentDialog(
  BuildContext context,
  AiModelManager aiModelManager,
) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      key: const Key('CHAT-019'),
      title: const Text('Enable AI chat?'),
      content: const Text(
        key: Key('CHAT-020'),
        'Answering with AI needs a one-time download of the Qwen3-1.7B '
        'model (about 1.1GB).',
      ),
      actions: [
        TextButton(
          key: const Key('CHAT-021'),
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Not now'),
        ),
        FilledButton(
          key: const Key('CHAT-022'),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Accept & download'),
        ),
      ],
    ),
  );
  if (result == true) {
    aiModelManager.accept();
    return true;
  }
  aiModelManager.decline();
  return false;
}

class _AiDownloadGateSheet extends StatefulWidget {
  const _AiDownloadGateSheet({required this.aiModelManager});

  final AiModelManager aiModelManager;

  @override
  State<_AiDownloadGateSheet> createState() => _AiDownloadGateSheetState();
}

class _AiDownloadGateSheetState extends State<_AiDownloadGateSheet> {
  @override
  void initState() {
    super.initState();
    widget.aiModelManager.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.aiModelManager.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (!mounted) return;
    if (widget.aiModelManager.status == AiChatStatus.ready) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.aiModelManager.status;
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('CHAT-023'),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 40,
              color: colorScheme.primary,
            ),
            const SizedBox(height: 12),
            if (status == AiChatStatus.failed) ...[
              const Text(
                key: Key('CHAT-025'),
                "Couldn't download the AI model.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    key: const Key('CHAT-026'),
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: widget.aiModelManager.retry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ] else ...[
              const Text('Downloading AI model…', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: widget.aiModelManager.downloadProgress,
              ),
              const SizedBox(height: 8),
              Text(
                '${(widget.aiModelManager.downloadProgress * 100).toStringAsFixed(0)}%',
              ),
              const SizedBox(height: 16),
              TextButton(
                key: const Key('CHAT-026'),
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Close'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CameraChatbotSheet extends StatefulWidget {
  const _CameraChatbotSheet({
    required this.homesController,
    required this.aiModelManager,
    required this.chatController,
  });

  final HomesController homesController;
  final AiModelManager aiModelManager;
  final ChatController chatController;

  @override
  State<_CameraChatbotSheet> createState() => _CameraChatbotSheetState();
}

class _CameraChatbotSheetState extends State<_CameraChatbotSheet> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isListening = false;
  Timer? _listeningTimer;

  List<ChatMessage> get _messages => widget.chatController.value;

  @override
  void initState() {
    super.initState();
    // The conversation lives in `widget.chatController`, not local State —
    // rebuild whenever it changes (a new message, a streamed token, a
    // confirm card resolving) since Flutter has no other way to know.
    widget.chatController.addListener(_onChatControllerChanged);
  }

  void _onChatControllerChanged() {
    if (mounted) setState(() {});
  }

  /// True while a reply (including any tool calls it triggers) is in
  /// flight. Gates [_send] — without this, sending a second message before
  /// the first finishes let two `_streamAiReply` calls run concurrently,
  /// both sharing the single [_activeEffects]/[_activeMessageIndex]
  /// pointer below. A slow tool call from the *first* request (e.g.
  /// `take_snapshot`, which can take real seconds) could then complete
  /// after the second request had already repointed those fields at its
  /// own newer message — attaching the first request's (older) result to
  /// the second (newer) message. That's what made a fresh snapshot request
  /// appear to show a stale/previous snapshot.
  bool _isReplying = false;

  /// "Thinking…"/"Calling Take Snapshot…"-style progress text for the
  /// in-flight assistant bubble, shown while [msg.text] is still empty so
  /// the user sees the model is actually working instead of a blank bubble.
  /// Cleared as soon as real content starts streaming.
  String? _statusText;

  /// Built once — resolves camera names against the same [HomesController]
  /// this sheet already has, and routes any tool-call side effect
  /// (snapshot/live-view/confirm card) to [_handleToolEffect].
  late final List<ToolDefinition> _tools = buildCameraTools(
    homesController: widget.homesController,
    onEffect: (effect) => _handleToolEffect(effect),
  );

  /// Which in-flight assistant message/effect-list a tool-call effect
  /// should attach to — set for the duration of one [_streamAiReply] call,
  /// since a tool's handler can fire [ChatToolEffect]s while the model is
  /// still generating, not only after it finishes.
  List<ChatToolEffect>? _activeEffects;
  int? _activeMessageIndex;

  void _handleToolEffect(ChatToolEffect effect) {
    final effects = _activeEffects;
    final index = _activeMessageIndex;
    if (effects == null || index == null || !mounted) return;
    effects.add(effect);
    final msg = _messages[index];
    widget.chatController.updateAt(
      index,
      ChatMessage.assistant(msg.text, effects: List.of(effects)),
    );
    _scrollToBottom();
  }

  Future<void> _confirmEffect(ConfirmEffect effect) async {
    widget.chatController.markConfirmationInProgress(effect);
    final resultText = await effect.onConfirm();
    if (!mounted) return;
    widget.chatController.markConfirmationResolved(effect);
    widget.chatController.addAssistantMessage(resultText);
    _scrollToBottom();
  }

  void _cancelEffect(ConfirmEffect effect) {
    widget.chatController.markConfirmationResolved(effect);
    widget.chatController.addAssistantMessage('Cancelled.');
    _scrollToBottom();
  }

  void _openLiveViewEffect(Camera camera) {
    Navigator.of(context).pop();
    context.push(
      '${DashboardScreen.routeName}/${CameraLiveScreen.routeName}/${camera.id}',
      extra: camera,
    );
  }

  void _openScanResultsEffect(List<ScannedCamera> cameras) {
    Navigator.of(context).pop();
    context.push(
      '${DashboardScreen.routeName}/${ScannedDevicesScreen.routeName}',
      extra: cameras,
    );
  }

  @override
  void dispose() {
    widget.chatController.removeListener(_onChatControllerChanged);
    _inputController.dispose();
    _scrollController.dispose();
    _listeningTimer?.cancel();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _send(String rawText) {
    if (_isReplying) return;
    final text = rawText.trim();
    if (text.isEmpty) return;
    widget.chatController.addUserMessage(text);
    setState(() {
      _isReplying = true;
      _statusText = 'Thinking…';
    });
    _inputController.clear();
    _scrollToBottom();

    final aiStream = widget.aiModelManager.reply(
      text,
      tools: selectRelevantTools(text, _tools),
      onStatus: (status) {
        if (!mounted) return;
        setState(() => _statusText = status.isEmpty ? null : status);
      },
    );
    if (aiStream != null) {
      _streamAiReply(aiStream);
      return;
    }

    // Defensive fallback — shouldn't normally happen, since the chat only
    // opens once the model is ready (see _resolveAiGate).
    setState(() => _isReplying = false);
    widget.chatController.addAssistantMessage(_fallbackReplyText);
    _scrollToBottom();
  }

  static const _fallbackReplyText =
      "Sorry, I couldn't process that — please try again.";

  Future<void> _streamAiReply(Stream<String> stream) async {
    final index = _messages.length;
    final effects = <ChatToolEffect>[];
    widget.chatController.addAssistantMessage('');
    // Any tool call this reply triggers should attach its effect (snapshot/
    // live-view/scan-results/confirm card) to this same message, even
    // mid-stream — see _handleToolEffect. Cleared in `finally` below on
    // every exit path (including an early return from unmounting
    // mid-stream) — previously an early `!mounted` return skipped this
    // reset, and separately nothing stopped a second `_send()` from
    // starting a concurrent request that would repoint these fields at its
    // own message while this one's tool call (e.g. a slow `take_snapshot`)
    // was still in flight — see `_isReplying`'s doc for the exact failure
    // this caused (a stale/previous snapshot appearing on a fresh request).
    _activeEffects = effects;
    _activeMessageIndex = index;

    try {
      var buffer = '';
      try {
        await for (final delta in stream) {
          buffer += delta;
          if (!mounted) return;
          widget.chatController.updateAt(
            index,
            ChatMessage.assistant(buffer, effects: List.of(effects)),
          );
          _scrollToBottom();
        }
      } catch (e, st) {
        // Logged (not swallowed silently) — the user only ever sees the
        // generic fallback text below, so without this, a real failure
        // here (an `llamadart`/model-side exception, a version-upgrade
        // regression, etc.) leaves no trace anywhere to diagnose from.
        debugPrint('[camera_chatbot] reply stream failed: $e\n$st');
        if (!mounted) return;
        widget.chatController.updateAt(
          index,
          ChatMessage.assistant(
            buffer.isEmpty ? _fallbackReplyText : buffer,
            effects: List.of(effects),
          ),
        );
      }
      if (buffer.isEmpty && effects.isEmpty && mounted) {
        widget.chatController.updateAt(
          index,
          const ChatMessage.assistant(_fallbackReplyText),
        );
      }
      _scrollToBottom();
    } finally {
      _activeEffects = null;
      _activeMessageIndex = null;
      if (mounted) {
        setState(() {
          _isReplying = false;
          _statusText = null;
        });
      }
    }
  }

  void _toggleListening() {
    if (_isListening) return;
    setState(() => _isListening = true);
    _listeningTimer?.cancel();
    _listeningTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _isListening = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Voice input isn't available yet")),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: Container(
        key: const Key('CHAT-001'),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        key: const Key('CHAT-003'),
                        'Ask about your cameras',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      key: const Key('CHAT-002'),
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState(context)
                    : _buildMessageList(context),
              ),
              _buildInputBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          key: const Key('CHAT-004'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.smart_toy_outlined,
              size: 40,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Try asking about your cameras — list them, scan for new ones, '
              'take a snapshot, or open live view.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final prompt in _quickPrompts)
                  ActionChip(
                    label: Text(prompt),
                    onPressed: () => _send(prompt),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(BuildContext context) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) =>
          _buildMessageBubble(context, _messages[index], index),
    );
  }

  Widget _buildMessageBubble(BuildContext context, ChatMessage msg, int i) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: msg.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            key: Key(msg.isUser ? 'CHAT-006-$i' : 'CHAT-007-$i'),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: msg.isUser
                  ? colorScheme.primary
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Builder(
              builder: (context) {
                final showStatus =
                    !msg.isUser &&
                    msg.text.isEmpty &&
                    _isReplying &&
                    i == _messages.length - 1 &&
                    _statusText != null;
                return Text(
                  showStatus ? _statusText! : msg.text,
                  style: TextStyle(
                    color: msg.isUser ? colorScheme.onPrimary : null,
                    fontStyle: showStatus ? FontStyle.italic : FontStyle.normal,
                  ),
                );
              },
            ),
          ),
          for (final effect in msg.effects) _buildToolEffect(context, effect),
        ],
      ),
    );
  }

  /// Renders a real tool-call side effect — the only source of any card
  /// shown alongside a reply, from a `chatbot_tools.dart` handler that
  /// actually called `camera_api`.
  Widget _buildToolEffect(BuildContext context, ChatToolEffect effect) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: switch (effect) {
        SnapshotEffect() => _SnapshotEffectCard(
          effect: effect,
          onTap: () => _openSnapshot(effect),
        ),
        LiveViewEffect() => _LiveViewEffectCard(
          effect: effect,
          onOpen: () => _openLiveViewEffect(effect.camera),
        ),
        ScanResultsEffect() => _ScanResultsEffectCard(
          effect: effect,
          onOpen: () => _openScanResultsEffect(effect.cameras),
        ),
        ConfirmEffect() => _ConfirmEffectCard(
          effect: effect,
          resolved: widget.chatController.resolvedConfirmations.contains(
            effect,
          ),
          inProgress: widget.chatController.inProgressConfirmations.contains(
            effect,
          ),
          onConfirm: () => _confirmEffect(effect),
          onCancel: () => _cancelEffect(effect),
        ),
      },
    );
  }

  void _openSnapshot(SnapshotEffect effect) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.memory(effect.bytes, fit: BoxFit.contain),
              ),
            ),
            SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.share_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () => _shareSnapshotBytes(effect.bytes),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.download_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () => _saveSnapshotBytes(effect.bytes),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareSnapshotBytes(Uint8List bytes) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/cctv_chat_snapshot_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await file.writeAsBytes(bytes);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not share image')));
    }
  }

  Future<void> _saveSnapshotBytes(Uint8List bytes) async {
    try {
      await Gal.putImageBytes(
        bytes,
        name: 'cctv_chat_snapshot_${DateTime.now().millisecondsSinceEpoch}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Snapshot saved')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not save snapshot')));
    }
  }

  Widget _buildInputBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Row(
        children: [
          IconButton(
            key: const Key('CHAT-013'),
            icon: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              color: _isListening ? Theme.of(context).colorScheme.error : null,
            ),
            onPressed: _toggleListening,
          ),
          Expanded(
            child: TextField(
              key: const Key('CHAT-012'),
              controller: _inputController,
              enabled: !_isReplying,
              decoration: InputDecoration(
                hintText: _isReplying
                    ? 'Waiting for a reply…'
                    : 'Ask a question…',
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              onSubmitted: _send,
            ),
          ),
          IconButton(
            key: const Key('CHAT-014'),
            icon: const Icon(Icons.send),
            onPressed: _isReplying ? null : () => _send(_inputController.text),
          ),
        ],
      ),
    );
  }
}

/// A real, freshly-captured snapshot from `take_snapshot`.
class _SnapshotEffectCard extends StatelessWidget {
  const _SnapshotEffectCard({required this.effect, required this.onTap});

  final SnapshotEffect effect;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: const Key('CHAT-027'),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 90,
          width: 120,
          child: Image.memory(effect.bytes, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

/// A card for `open_live_view`, deep-linking to the real `CameraLiveScreen`
/// rather than embedding a player in the chat bubble.
class _LiveViewEffectCard extends StatelessWidget {
  const _LiveViewEffectCard({required this.effect, required this.onOpen});

  final LiveViewEffect effect;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      key: const Key('CHAT-028'),
      onPressed: onOpen,
      icon: const Icon(Icons.videocam_outlined),
      label: Text('Open ${effect.camera.name} Live View'),
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        alignment: Alignment.centerLeft,
      ),
    );
  }
}

/// A card for `scan_for_cameras` — summarizes a real LAN scan and
/// deep-links to the real `ScannedDevicesScreen` (passing the already-
/// fetched results) rather than reimplementing the add-camera flow inline.
class _ScanResultsEffectCard extends StatelessWidget {
  const _ScanResultsEffectCard({required this.effect, required this.onOpen});

  final ScanResultsEffect effect;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cameras = effect.cameras;
    return Card(
      key: const Key('CHAT-032'),
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              cameras.isEmpty
                  ? 'No cameras found on the network.'
                  : 'Found ${cameras.length} camera(s):',
              style: theme.textTheme.titleSmall,
            ),
            for (final camera in cameras.take(5))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    Icon(
                      camera.isConfigured
                          ? Icons.check_circle_outline
                          : Icons.videocam_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('${camera.name} (${camera.ipAddress})'),
                    ),
                    if (!camera.isConfigured)
                      Text(
                        'New',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
            if (cameras.isNotEmpty) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                key: const Key('CHAT-033'),
                onPressed: onOpen,
                icon: const Icon(Icons.add_to_queue_outlined),
                label: const Text('Add cameras'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Confirm/Cancel card for a destructive tool (reboot/reset/factory-reset/
/// delete) — the real `camera_api` call only fires from [onConfirm]'s tap,
/// never from the model's own tool call, per this session's design
/// discussion on destructive-action safety.
class _ConfirmEffectCard extends StatelessWidget {
  const _ConfirmEffectCard({
    required this.effect,
    required this.resolved,
    required this.inProgress,
    required this.onConfirm,
    required this.onCancel,
  });

  final ConfirmEffect effect;
  final bool resolved;

  /// True from the moment Confirm is tapped until [effect]'s real
  /// `camera_api` call actually finishes — distinct from [resolved], so the
  /// card can't claim "Handled" while the reboot/reset/delete is still in
  /// flight.
  final bool inProgress;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      key: const Key('CHAT-029'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            effect.title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(effect.message, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 8),
          if (inProgress)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  'Working…',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            )
          else if (resolved)
            Text('Handled', style: Theme.of(context).textTheme.labelMedium)
          else
            Row(
              children: [
                TextButton(
                  key: const Key('CHAT-030'),
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  key: const Key('CHAT-031'),
                  onPressed: onConfirm,
                  style: FilledButton.styleFrom(
                    backgroundColor: colorScheme.error,
                  ),
                  child: Text(effect.confirmLabel),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
