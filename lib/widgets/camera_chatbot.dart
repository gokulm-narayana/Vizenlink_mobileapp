import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../app_state/ai_model_manager.dart';
import '../app_state/events_controller.dart';
import '../app_state/homes_controller.dart';
import '../models/event.dart';
import '../models/event_type_display.dart';
import '../screens/events/event_detail_screen.dart';
import '../screens/events/events_screen.dart';

const _quickPrompts = [
  "Today's events",
  'Any motion alerts?',
  'Show recent snapshots',
  'Show me videos',
];

/// Opens the camera assistant. The chat itself (CHAT-001) only opens once
/// the on-device AI model (Qwen3.5-0.8B via `AiModelManager`) is ready — the
/// user is asked for consent first (CHAT-019), and declining closes the
/// whole flow instead of falling back to a canned-reply chat, since the
/// chatbot's whole purpose is the AI. Event/video/image result cards are
/// still built from existing local data (`EventsController`,
/// `HomesController`) via keyword matching once chatting. Downloading the
/// model is strictly opt-in (see CLAUDE.md: no backend/AI dependency without
/// explicit confirmation).
Future<void> showCameraChatbot(
  BuildContext context, {
  required HomesController homesController,
  required EventsController eventsController,
  required AiModelManager aiModelManager,
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
      eventsController: eventsController,
      aiModelManager: aiModelManager,
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
        'Answering with AI needs a one-time download of the Qwen3.5-0.8B '
        'model (about 0.6GB).',
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

typedef _ResultData = ({
  List<RecordedEvent> events,
  List<RecordedEvent> videos,
  List<String> images,
});

class _ChatMessage {
  const _ChatMessage.user(this.text)
    : isUser = true,
      events = const [],
      videos = const [],
      images = const [];

  const _ChatMessage.assistant(
    this.text, {
    this.events = const [],
    this.videos = const [],
    this.images = const [],
  }) : isUser = false;

  final bool isUser;
  final String text;
  final List<RecordedEvent> events;
  final List<RecordedEvent> videos;
  final List<String> images;
}

class _CameraChatbotSheet extends StatefulWidget {
  const _CameraChatbotSheet({
    required this.homesController,
    required this.eventsController,
    required this.aiModelManager,
  });

  final HomesController homesController;
  final EventsController eventsController;
  final AiModelManager aiModelManager;

  @override
  State<_CameraChatbotSheet> createState() => _CameraChatbotSheetState();
}

class _CameraChatbotSheetState extends State<_CameraChatbotSheet> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <_ChatMessage>[];
  bool _isListening = false;
  Timer? _listeningTimer;

  @override
  void dispose() {
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
    final text = rawText.trim();
    if (text.isEmpty) return;
    setState(() => _messages.add(_ChatMessage.user(text)));
    _inputController.clear();
    _scrollToBottom();

    final data = _computeResultData(text);
    final aiStream = widget.aiModelManager.reply(text);
    if (aiStream != null) {
      _streamAiReply(
        aiStream,
        data,
        fallbackText: () => _cannedReplyText(text, data),
      );
      return;
    }

    // Defensive fallback — shouldn't normally happen, since the chat only
    // opens once the model is ready (see _resolveAiGate).
    setState(() {
      _messages.add(
        _ChatMessage.assistant(
          _cannedReplyText(text, data),
          events: data.events,
          videos: data.videos,
          images: data.images,
        ),
      );
    });
    _scrollToBottom();
  }

  Future<void> _streamAiReply(
    Stream<String> stream,
    _ResultData data, {
    required String Function() fallbackText,
  }) async {
    final index = _messages.length;
    setState(() {
      _messages.add(
        _ChatMessage.assistant(
          '',
          events: data.events,
          videos: data.videos,
          images: data.images,
        ),
      );
    });
    var buffer = '';
    try {
      await for (final delta in stream) {
        buffer += delta;
        if (!mounted) return;
        setState(() {
          _messages[index] = _ChatMessage.assistant(
            buffer,
            events: data.events,
            videos: data.videos,
            images: data.images,
          );
        });
        _scrollToBottom();
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages[index] = _ChatMessage.assistant(
          buffer.isEmpty ? fallbackText() : buffer,
          events: data.events,
          videos: data.videos,
          images: data.images,
        );
      });
    }
    if (buffer.isEmpty && mounted) {
      setState(() {
        _messages[index] = _ChatMessage.assistant(
          fallbackText(),
          events: data.events,
          videos: data.videos,
          images: data.images,
        );
      });
    }
    _scrollToBottom();
  }

  _ResultData _computeResultData(String text) {
    final query = text.toLowerCase();
    final events = [...widget.eventsController.value]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (query.contains('video') ||
        query.contains('clip') ||
        query.contains('record')) {
      return (
        events: const [],
        videos: events.take(2).toList(),
        images: const [],
      );
    }
    if (query.contains('image') ||
        query.contains('photo') ||
        query.contains('snapshot') ||
        query.contains('picture')) {
      final images = widget.homesController.value.selectedHome.cameras
          .map((camera) => camera.thumbnailUrl)
          .whereType<String>()
          .take(3)
          .toList();
      return (events: const [], videos: const [], images: images);
    }
    if (events.isNotEmpty &&
        (query.contains('event') ||
            query.contains('motion') ||
            query.contains('alert') ||
            query.contains('today') ||
            events.any((e) => query.contains(e.cameraName.toLowerCase())))) {
      final matchingCamera = events
          .where((e) => query.contains(e.cameraName.toLowerCase()))
          .toList();
      final results = (matchingCamera.isNotEmpty ? matchingCamera : events)
          .take(3)
          .toList();
      return (events: results, videos: const [], images: const []);
    }
    return (events: const [], videos: const [], images: const []);
  }

  String _cannedReplyText(String text, _ResultData data) {
    if (data.videos.isNotEmpty) return 'Here are some recent clips:';
    if (data.images.isNotEmpty) return 'Here are some recent snapshots:';
    if (data.events.isNotEmpty) return "Here's what I found:";
    final query = text.toLowerCase();
    if (query.contains('image') ||
        query.contains('photo') ||
        query.contains('snapshot') ||
        query.contains('picture')) {
      return "I don't have any camera snapshots to show yet.";
    }
    return 'I can help you check recent events, video clips, and snapshots '
        'from your cameras. Try asking things like "today\'s events" or '
        '"show me snapshots".';
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

  void _openEvent(RecordedEvent event) {
    Navigator.of(context).pop();
    context.push(
      '${EventsScreen.routeName}/${EventDetailScreen.routeName}',
      extra: event,
    );
  }

  Future<Uint8List> _fetchImageBytes(String url) async {
    final request = await HttpClient().getUrl(Uri.parse(url));
    final response = await request.close();
    return Uint8List.fromList(
      await response.fold<List<int>>(
        <int>[],
        (previous, chunk) => previous..addAll(chunk),
      ),
    );
  }

  Future<void> _shareImage(String url) async {
    try {
      final bytes = await _fetchImageBytes(url);
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/cctv_chat_share_${DateTime.now().millisecondsSinceEpoch}.jpg',
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

  Future<void> _saveImage(String url) async {
    try {
      final bytes = await _fetchImageBytes(url);
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

  void _openImage(String url) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) => Dialog.fullscreen(
        key: const Key('CHAT-015'),
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    key: const Key('CHAT-016'),
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                  Row(
                    children: [
                      IconButton(
                        key: const Key('CHAT-017'),
                        icon: const Icon(
                          Icons.share_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () => _shareImage(url),
                      ),
                      IconButton(
                        key: const Key('CHAT-018'),
                        icon: const Icon(
                          Icons.download_outlined,
                          color: Colors.white,
                        ),
                        onPressed: () => _saveImage(url),
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

  void _openVideoStub() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Playback preview not available yet')),
    );
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
              'Try asking about your cameras\' events, videos, or snapshots.',
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

  Widget _buildMessageBubble(BuildContext context, _ChatMessage msg, int i) {
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
            child: Text(
              msg.text,
              style: TextStyle(
                color: msg.isUser ? colorScheme.onPrimary : null,
              ),
            ),
          ),
          if (msg.events.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildResultRow(
              height: 100,
              count: msg.events.length,
              itemBuilder: (context, j) {
                final event = msg.events[j];
                return _EventResultCard(
                  key: Key('CHAT-009-$i-$j'),
                  event: event,
                  onTap: () => _openEvent(event),
                );
              },
            ),
          ],
          if (msg.videos.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildResultRow(
              height: 90,
              count: msg.videos.length,
              itemBuilder: (context, j) {
                final video = msg.videos[j];
                return _VideoResultCard(
                  key: Key('CHAT-010-$i-$j'),
                  video: video,
                  onTap: _openVideoStub,
                );
              },
            ),
          ],
          if (msg.images.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildResultRow(
              height: 90,
              count: msg.images.length,
              itemBuilder: (context, j) {
                final url = msg.images[j];
                return _ImageResultCard(
                  key: Key('CHAT-011-$i-$j'),
                  url: url,
                  onTap: () => _openImage(url),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultRow({
    required double height,
    required int count,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: count,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: itemBuilder,
      ),
    );
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
              decoration: const InputDecoration(
                hintText: 'Ask a question…',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(24)),
                ),
                contentPadding: EdgeInsets.symmetric(
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
            onPressed: () => _send(_inputController.text),
          ),
        ],
      ),
    );
  }
}

class _EventResultCard extends StatelessWidget {
  const _EventResultCard({super.key, required this.event, required this.onTap});

  final RecordedEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  event.type.icon,
                  size: 16,
                  color: event.type.timelineColor,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    event.type.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              event.cameraName,
              style: Theme.of(context).textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _VideoResultCard extends StatelessWidget {
  const _VideoResultCard({super.key, required this.video, required this.onTap});

  final RecordedEvent video;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 140,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (video.thumbnailUrl != null)
                Image.network(video.thumbnailUrl!, fit: BoxFit.cover)
              else
                Container(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                ),
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${video.duration.inSeconds}s',
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageResultCard extends StatelessWidget {
  const _ImageResultCard({super.key, required this.url, required this.onTap});

  final String url;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 90,
          child: Image.network(url, fit: BoxFit.cover),
        ),
      ),
    );
  }
}
