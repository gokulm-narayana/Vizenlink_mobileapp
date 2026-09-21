import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../models/camera.dart';
import '../../theme/app_colors.dart';
import '../../widgets/drawable_zone.dart';

const _presetItems = [
  'Pen',
  'Book',
  'Laptop',
  'Keys',
  'Wallet',
  'Phone',
  'Bag',
  'Other',
];

/// Fractional (0-1) size of the box a plain tap (no drag) creates, centered
/// on the tapped point.
const _tapSelectionFraction = 0.22;

/// Example questions shown in the empty state (AIMODE-023) to hint at what
/// AI Mode can be asked beyond the "lost item" preset picker.
const _suggestedPrompts = [
  'What is this object?',
  'Who is this person?',
  'When did they arrive?',
  'Track this person',
  'Is this a delivery?',
];

/// How long the "Detecting object…" beat (AIMODE-018) holds before the
/// drawn gesture snaps into an adjustable box — long enough to read as a
/// distinct step, short enough not to feel laggy.
const _detectionDelay = Duration(milliseconds: 500);

/// Navigation payload for [AiModeScreen] — the camera being viewed, the
/// frame captured the instant AI Mode was entered, and a callback to grab a
/// fresh one (AIMODE-006's Retake), reusing `CameraLiveScreen`'s own frame
/// capture rather than re-implementing it here.
class AiModeLaunchArgs {
  const AiModeLaunchArgs({
    required this.camera,
    required this.initialFrame,
    required this.captureFrame,
  });

  final Camera camera;
  final Uint8List initialFrame;
  final Future<Uint8List?> Function() captureFrame;
}

/// One turn in the AI Mode conversation: the question (with an optional
/// cropped snippet of the boxed region, cut from the frame the instant the
/// question was asked — see [_AiModeScreenState._cropFrame]), and the
/// answer once it arrives (null while still "Thinking…").
class _ChatEntry {
  const _ChatEntry({required this.question, this.croppedImage, this.answer});

  final String question;
  final Uint8List? croppedImage;
  final String? answer;

  _ChatEntry withAnswer(String answer) => _ChatEntry(
    question: question,
    croppedImage: croppedImage,
    answer: answer,
  );
}

/// AI Mode — a frozen frame from Camera Live that the user can circle
/// (Google Circle-to-Search style: draw a rough loop, or just tap, around
/// an object). The drawn gesture snaps into an adjustable bounding box —
/// reusing [ZoneOverlay], the same draggable/resizable rectangle widget the
/// Privacy Zone/motion-detection zone editors use — that the user can drag
/// or resize by its corner handles before asking. Asking crops exactly the
/// boxed pixels out of the frame and adds that crop to the chat alongside
/// the question, like an attached-image chat turn. Look-and-feel only for
/// now: no real AI backend, and no real object segmentation, is wired up
/// yet — the box is just the drawn gesture's bounding rect, and the crop is
/// real pixels but nothing analyzes them; asking always returns a canned
/// stub reply, same stubbing convention as Camera Live's Talk/Spotlight
/// tiles and the camera chatbot's mic button (`CHAT-013`).
class AiModeScreen extends StatefulWidget {
  const AiModeScreen({super.key, required this.args});

  final AiModeLaunchArgs args;

  @override
  State<AiModeScreen> createState() => _AiModeScreenState();
}

class _AiModeScreenState extends State<AiModeScreen> {
  late Uint8List _frame;
  final _dragPoints = <Offset>[];
  Size _frameAreaSize = Size.zero;

  /// Fractional (0-1) bounding box, once a gesture has finished detecting
  /// and settled into an adjustable box. Null while nothing's selected yet,
  /// or while still mid-drag/detecting.
  Rect? _selectionRect;

  bool _isDragging = false;
  bool _isDetecting = false;
  Timer? _detectionTimer;

  final _questionController = TextEditingController();
  final _customItemController = TextEditingController();
  final _scrollController = ScrollController();
  String? _selectedPreset;
  final _messages = <_ChatEntry>[];
  bool _isListening = false;
  Timer? _listeningTimer;
  bool _isRetaking = false;

  /// True once a question's been asked — the frame/box view (AIMODE-003)
  /// hides and the chat takes the full screen, same as Circle to Search's
  /// results panel taking over once you've circled something. AIMODE-022
  /// brings the frame back to select something else.
  bool _frameCollapsed = false;

  @override
  void initState() {
    super.initState();
    _frame = widget.args.initialFrame;
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _questionController.dispose();
    _customItemController.dispose();
    _scrollController.dispose();
    _listeningTimer?.cancel();
    super.dispose();
  }

  bool get _hasSelection => _selectionRect != null;
  bool get _isSending => _messages.isNotEmpty && _messages.last.answer == null;

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

  void _clearSelection() {
    _detectionTimer?.cancel();
    setState(() {
      _dragPoints.clear();
      _selectionRect = null;
      _isDragging = false;
      _isDetecting = false;
    });
  }

  Future<void> _retakeFrame() async {
    setState(() => _isRetaking = true);
    final bytes = await widget.args.captureFrame();
    if (!mounted) return;
    _detectionTimer?.cancel();
    setState(() {
      _isRetaking = false;
      if (bytes != null) _frame = bytes;
      _dragPoints.clear();
      _selectionRect = null;
      _isDragging = false;
      _isDetecting = false;
    });
  }

  void _selectPreset(String preset) {
    setState(() {
      _selectedPreset = _selectedPreset == preset ? null : preset;
      if (_selectedPreset != 'Other') _customItemController.clear();
    });
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

  String? _resolveQuestionText() {
    if (_selectedPreset == 'Other') {
      final custom = _customItemController.text.trim();
      return custom.isEmpty ? null : "Have you seen my $custom?";
    }
    if (_selectedPreset != null) return 'Have you seen my $_selectedPreset?';
    final typed = _questionController.text.trim();
    if (typed.isNotEmpty) return typed;
    if (_hasSelection) return 'What is this?';
    return null;
  }

  /// Cuts exactly the pixels under [_selectionRect] out of [_frame] and
  /// returns them as a standalone PNG, so the chat turn can show what was
  /// actually circled rather than just referencing "the boxed area" in
  /// text. Maps the box's fractional (0-1) coordinates — taken relative to
  /// the displayed frame area — into the source image's own pixel space
  /// using the same scale/offset math `BoxFit.cover` itself uses, since
  /// AIMODE-003 renders the frame with `BoxFit.cover`.
  Future<Uint8List?> _cropFrame(Rect fractionalRect) async {
    final areaSize = _frameAreaSize;
    if (areaSize.width == 0 || areaSize.height == 0) return null;
    final codec = await ui.instantiateImageCodec(_frame);
    final frameInfo = await codec.getNextFrame();
    final image = frameInfo.image;
    try {
      final imgW = image.width.toDouble();
      final imgH = image.height.toDouble();
      final scale = math.max(areaSize.width / imgW, areaSize.height / imgH);
      final offsetX = (imgW * scale - areaSize.width) / 2;
      final offsetY = (imgH * scale - areaSize.height) / 2;

      Offset toImageSpace(double fracX, double fracY) => Offset(
        (fracX * areaSize.width + offsetX) / scale,
        (fracY * areaSize.height + offsetY) / scale,
      );

      final cropRect = Rect.fromPoints(
        toImageSpace(fractionalRect.left, fractionalRect.top),
        toImageSpace(fractionalRect.right, fractionalRect.bottom),
      ).intersect(Rect.fromLTWH(0, 0, imgW, imgH));
      if (cropRect.width < 1 || cropRect.height < 1) return null;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        image,
        cropRect,
        Rect.fromLTWH(0, 0, cropRect.width, cropRect.height),
        Paint(),
      );
      final cropped = await recorder.endRecording().toImage(
        cropRect.width.round().clamp(1, 4000),
        cropRect.height.round().clamp(1, 4000),
      );
      try {
        final byteData = await cropped.toByteData(
          format: ui.ImageByteFormat.png,
        );
        return byteData?.buffer.asUint8List();
      } finally {
        cropped.dispose();
      }
    } finally {
      image.dispose();
    }
  }

  /// Fills the question field with [prompt] and asks it immediately — used
  /// by the empty-state suggestion chips (AIMODE-023), same tap-to-send
  /// behavior as the camera chatbot's quick prompts.
  void _askSuggestion(String prompt) {
    _questionController.text = prompt;
    _ask();
  }

  Future<void> _ask() async {
    final questionText = _resolveQuestionText();
    if (questionText == null || _isSending) return;
    setState(() => _frameCollapsed = true);
    final selectionRect = _selectionRect;
    final cropped = selectionRect != null
        ? await _cropFrame(selectionRect)
        : null;
    if (!mounted) return;

    final index = _messages.length;
    setState(() {
      _messages.add(_ChatEntry(question: questionText, croppedImage: cropped));
      _questionController.clear();
    });
    _scrollToBottom();

    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _messages[index] = _messages[index].withAnswer(
        cropped != null
            ? 'AI object recognition isn\'t connected yet — once wired up, '
                  'I\'ll look at the cropped snippet above and answer: '
                  '"$questionText"'
            : 'AI search isn\'t connected yet — once wired up, I\'ll check '
                  'this camera\'s footage and answer: "$questionText"',
      );
    });
    _scrollToBottom();
  }

  Rect _pixelToFractional(Rect pixelRect) {
    final areaSize = _frameAreaSize;
    if (areaSize.width == 0 || areaSize.height == 0) {
      return const Rect.fromLTWH(0.3, 0.3, 0.4, 0.4);
    }
    return Rect.fromLTRB(
      (pixelRect.left / areaSize.width).clamp(0.0, 1.0),
      (pixelRect.top / areaSize.height).clamp(0.0, 1.0),
      (pixelRect.right / areaSize.width).clamp(0.0, 1.0),
      (pixelRect.bottom / areaSize.height).clamp(0.0, 1.0),
    );
  }

  Rect _boundingPixelRect(List<Offset> points) {
    var minX = points.first.dx;
    var maxX = minX;
    var minY = points.first.dy;
    var maxY = minY;
    for (final point in points) {
      if (point.dx < minX) minX = point.dx;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dy > maxY) maxY = point.dy;
    }
    const pad = 18.0;
    return Rect.fromLTRB(minX - pad, minY - pad, maxX + pad, maxY + pad);
  }

  /// Runs the "Detecting object…" beat (AIMODE-018) then reveals [pixelRect]
  /// as an adjustable box — shared by both the drag-release and tap paths.
  void _beginDetection(Rect pixelRect) {
    setState(() {
      _isDragging = false;
      _isDetecting = true;
    });
    _detectionTimer?.cancel();
    _detectionTimer = Timer(_detectionDelay, () {
      if (!mounted) return;
      setState(() {
        _isDetecting = false;
        _selectionRect = _pixelToFractional(pixelRect);
      });
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (_hasSelection) return;
    setState(() {
      _dragPoints
        ..clear()
        ..add(details.localPosition);
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging) return;
    setState(() => _dragPoints.add(details.localPosition));
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging || _dragPoints.length < 2) {
      setState(() => _isDragging = false);
      return;
    }
    _beginDetection(_boundingPixelRect(_dragPoints));
  }

  void _onTapUp(TapUpDetails details) {
    if (_hasSelection) return;
    final center = details.localPosition;
    final w = _frameAreaSize.width * _tapSelectionFraction;
    final h = _frameAreaSize.height * _tapSelectionFraction;
    _beginDetection(Rect.fromCenter(center: center, width: w, height: h));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        key: const Key('AIMODE-001'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('AI Mode'),
        leading: IconButton(
          key: const Key('AIMODE-002'),
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_frameCollapsed)
            IconButton(
              key: const Key('AIMODE-022'),
              tooltip: 'Select another object',
              icon: const Icon(Icons.center_focus_weak),
              onPressed: () => setState(() {
                _frameCollapsed = false;
                _selectionRect = null;
                _dragPoints.clear();
              }),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!_frameCollapsed)
              Expanded(
                flex: 3,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: _buildFrameArea(context),
                  ),
                ),
              ),
            Expanded(
              flex: 5,
              child: Container(
                color: colorScheme.surface,
                child: _buildAskPanel(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrameArea(BuildContext context) {
    return LayoutBuilder(
      key: const Key('AIMODE-003'),
      builder: (context, constraints) {
        _frameAreaSize = Size(constraints.maxWidth, constraints.maxHeight);
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.memory(_frame, fit: BoxFit.cover),
            AnimatedOpacity(
              key: const Key('AIMODE-017'),
              opacity: (_isDragging || _isDetecting) ? 0.35 : 0,
              duration: const Duration(milliseconds: 150),
              child: const ColoredBox(color: Colors.black),
            ),
            if (!_hasSelection)
              GestureDetector(
                key: const Key('AIMODE-004'),
                behavior: HitTestBehavior.opaque,
                onTapUp: _onTapUp,
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                onPanEnd: _onPanEnd,
                child: CustomPaint(
                  painter: _DragPathPainter(
                    points: _dragPoints,
                    color: AppColors.cyan,
                  ),
                ),
              ),
            if (_isDetecting)
              const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              ),
            if (_selectionRect != null)
              ZoneOverlay(
                rect: _selectionRect!,
                areaSize: _frameAreaSize,
                selected: true,
                icon: Icons.center_focus_strong,
                onTap: () {},
                onRectChanged: (rect) => setState(() => _selectionRect = rect),
              ),
            if (_isRetaking)
              const ColoredBox(
                color: Colors.black45,
                child: Center(child: CircularProgressIndicator()),
              ),
            Positioned(
              top: 8,
              right: 8,
              child: Row(
                children: [
                  if (_hasSelection || _dragPoints.isNotEmpty)
                    _FrameIconButton(
                      key: const Key('AIMODE-005'),
                      icon: Icons.layers_clear_outlined,
                      tooltip: 'Clear selection',
                      onPressed: _clearSelection,
                    ),
                  const SizedBox(width: 8),
                  _FrameIconButton(
                    key: const Key('AIMODE-006'),
                    icon: Icons.refresh,
                    tooltip: 'Retake frame',
                    onPressed: _isRetaking ? null : _retakeFrame,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAskPanel(BuildContext context) {
    final canAsk = _resolveQuestionText() != null && !_isSending;
    return Column(
      key: const Key('AIMODE-007'),
      children: [
        Expanded(
          child: _messages.isEmpty
              ? _buildEmptyState(context)
              : _buildChatList(context),
        ),
        if (_isDetecting)
          const Padding(
            key: Key('AIMODE-018'),
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _DetectingSkeleton(),
          ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 36,
                  child: Row(
                    children: [
                      Text(
                        key: const Key('AIMODE-010'),
                        'Lost item:',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ListView(
                          key: const Key('AIMODE-011'),
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (final item in _presetItems)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(item),
                                  selected: _selectedPreset == item,
                                  onSelected: (_) => _selectPreset(item),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_selectedPreset == 'Other')
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: TextField(
                      key: const Key('AIMODE-012'),
                      controller: _customItemController,
                      decoration: const InputDecoration(
                        hintText: 'What did you lose?',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    IconButton(
                      key: const Key('AIMODE-016'),
                      icon: Icon(
                        _isListening ? Icons.mic : Icons.mic_none,
                        color: _isListening
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                      onPressed: _toggleListening,
                    ),
                    Expanded(
                      child: TextField(
                        key: const Key('AIMODE-008'),
                        controller: _questionController,
                        decoration: InputDecoration(
                          hintText: _hasSelection
                              ? 'Ask about the boxed area…'
                              : 'Ask a question…',
                          border: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(24)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                        onSubmitted: (_) => _ask(),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      key: const Key('AIMODE-009'),
                      icon: const Icon(Icons.send),
                      onPressed: canAsk ? _ask : null,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          key: const Key('AIMODE-015'),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Circle or tap something on the frame above, or pick an item '
              'below, then ask.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              key: const Key('AIMODE-023'),
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final prompt in _suggestedPrompts)
                  ActionChip(
                    label: Text(prompt),
                    onPressed: () => _askSuggestion(prompt),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList(BuildContext context) {
    return ListView.builder(
      key: const Key('AIMODE-013'),
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: _messages.length,
      itemBuilder: (context, i) => _buildChatTurn(context, _messages[i], i),
    );
  }

  Widget _buildChatTurn(BuildContext context, _ChatEntry entry, int i) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (entry.croppedImage != null)
            ClipRRect(
              key: Key('AIMODE-019-$i'),
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                entry.croppedImage!,
                width: 96,
                height: 96,
                fit: BoxFit.cover,
              ),
            ),
          const SizedBox(height: 6),
          Container(
            key: Key('AIMODE-020-$i'),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              entry.question,
              style: TextStyle(color: colorScheme.onPrimary),
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: entry.answer == null
                ? const Padding(
                    key: Key('AIMODE-014'),
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 10),
                        Text('Thinking…'),
                      ],
                    ),
                  )
                : Container(
                    key: Key('AIMODE-021-$i'),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(entry.answer!),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Live "still figuring out what you selected" state shown while
/// [_AiModeScreenState._isDetecting] holds after a gesture ends, before it
/// snaps into an adjustable box (AIMODE-018) — a distinct beat from the
/// per-turn "Thinking…" row, matching Circle to Search's own two-stage feel
/// (instant detect, then answer).
class _DetectingSkeleton extends StatelessWidget {
  const _DetectingSkeleton();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        ),
        const SizedBox(width: 12),
        Text('Detecting object…', style: TextStyle(color: color)),
      ],
    );
  }
}

class _FrameIconButton extends StatelessWidget {
  const _FrameIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          tooltip: tooltip,
          icon: Icon(icon, color: Colors.white, size: 20),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

/// Thin live-preview line while the user is still dragging (AIMODE-004),
/// before the gesture snaps into the adjustable box — purely transient
/// feedback, not the final selection shape.
class _DragPathPainter extends CustomPainter {
  const _DragPathPainter({required this.points, required this.color});

  final List<Offset> points;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _DragPathPainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
