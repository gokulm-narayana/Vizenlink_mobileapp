import 'package:flutter/material.dart';

import '../../app_state/camera_sync.dart';
import '../../app_state/homes_controller.dart';
import '../../models/camera.dart';
import '../../widgets/drawable_zone.dart';
import '../../widgets/fixed_preview_layout.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/navigation_leave_guard.dart';
import '../../widgets/saving_overlay.dart';
import '../../widgets/settings_save_button.dart';

const _defaultLineStart = Offset(0.2, 0.5);
const _defaultLineEnd = Offset(0.8, 0.5);

extension on CameraCrossingDirection {
  String get label => switch (this) {
    CameraCrossingDirection.both => 'Both directions',
    CameraCrossingDirection.aToB => 'A → B only',
    CameraCrossingDirection.bToA => 'B → A only',
  };
}

/// Line Crossing: an enable toggle, sensitivity slider, a single
/// draggable line (drag either endpoint to place it) drawn over the
/// preview, and a crossing-direction selector. Persisted through
/// [HomesController] (see `updateCamera`) — see the note on `videoMode` in
/// `lib/models/camera.dart`.
class LineCrossingScreen extends StatefulWidget {
  const LineCrossingScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'line-crossing';

  final Camera camera;
  final HomesController homesController;

  @override
  State<LineCrossingScreen> createState() => _LineCrossingScreenState();
}

class _LineCrossingScreenState extends State<LineCrossingScreen> {
  late bool _enabled = widget.camera.lineCrossingEnabled;
  late double _sensitivity = widget.camera.lineCrossingSensitivity;
  late Offset _lineStart = widget.camera.lineCrossingStart;
  late Offset _lineEnd = widget.camera.lineCrossingEnd;
  late CameraCrossingDirection _direction = widget.camera.lineCrossingDirection;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _isRefreshing = false;
  int _previewReloadKey = 0;

  void _markDirty(VoidCallback update) {
    setState(() {
      update();
      _isDirty = true;
    });
  }

  /// Looked up fresh from [HomesController] on every build (not
  /// [widget.camera] directly) so a refreshed snapshot from [_refreshPreview]
  /// actually shows up without leaving and re-entering this screen.
  Camera get _camera {
    for (final home in widget.homesController.value.homes) {
      for (final camera in home.cameras) {
        if (camera.id == widget.camera.id) return camera;
      }
    }
    return widget.camera;
  }

  Future<void> _refreshPreview() async {
    final connection = _camera.connection;
    if (connection == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No saved connection for this camera yet'),
        ),
      );
      return;
    }
    setState(() => _isRefreshing = true);
    final succeeded = await refreshCameraSnapshot(
      homesController: widget.homesController,
      cameraId: widget.camera.id,
      connection: connection,
    );
    if (!mounted) return;
    setState(() {
      _isRefreshing = false;
      _previewReloadKey++;
    });
    if (!succeeded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to refresh preview')),
      );
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final succeeded = await simulateCameraSave();
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (succeeded) {
      widget.homesController.updateCamera(
        widget.camera.id,
        (camera) => camera.copyWith(
          lineCrossingEnabled: _enabled,
          lineCrossingSensitivity: _sensitivity,
          lineCrossingStart: _lineStart,
          lineCrossingEnd: _lineEnd,
          lineCrossingDirection: _direction,
        ),
      );
      setState(() => _isDirty = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Changes saved')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save changes. Try again.')),
      );
    }
  }

  Future<bool> _confirmLeave() => confirmDiscardOnLeave(
    context: context,
    isDirty: _isDirty,
    onSave: _save,
    isDirtyAfterSave: () => _isDirty,
    dialogKey: const Key('LINE-009'),
    discardKey: const Key('LINE-010'),
    saveKey: const Key('LINE-011'),
  );

  @override
  Widget build(BuildContext context) {
    return LeaveGuard(
      canLeave: _confirmLeave,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            key: const Key('LINE-001'),
            title: const Text('Line Crossing'),
            actions: [
              SettingsSaveButton(
                settingsKey: const Key('LINE-002'),
                isDirty: _isDirty,
                isSaving: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
          body: SavingOverlay(
            isSaving: _isSaving,
            child: FixedPreviewLayout(
              preview: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _LineCrossingPreview(
                    key: ValueKey(_previewReloadKey),
                    settingsKey: const Key('LINE-003'),
                    camera: _camera,
                    lineStart: _lineStart,
                    lineEnd: _lineEnd,
                    onLineStartChanged: (offset) =>
                        _markDirty(() => _lineStart = offset),
                    onLineEndChanged: (offset) =>
                        _markDirty(() => _lineEnd = offset),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      key: const Key('LINE-004'),
                      onPressed: _isRefreshing ? null : _refreshPreview,
                      icon: _isRefreshing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh preview'),
                    ),
                  ),
                ],
              ),
              scrollableChildren: [
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: SwitchListTile(
                    key: const Key('LINE-005'),
                    title: const Text('Line crossing detection'),
                    value: _enabled,
                    onChanged: (value) => _markDirty(() => _enabled = value),
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Sensitivity (${_sensitivity.round()})',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Slider(
                        key: const Key('LINE-006'),
                        value: _sensitivity,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        onChanged: _enabled
                            ? (value) => _markDirty(() => _sensitivity = value)
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Direction',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<CameraCrossingDirection>(
                  key: const Key('LINE-007'),
                  initialValue: _direction,
                  isExpanded: true,
                  items: [
                    for (final direction in CameraCrossingDirection.values)
                      DropdownMenuItem(
                        value: direction,
                        child: Text(direction.label),
                      ),
                  ],
                  onChanged: _enabled
                      ? (value) => _markDirty(() => _direction = value!)
                      : null,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  key: const Key('LINE-008'),
                  onPressed: () => _markDirty(() {
                    _lineStart = _defaultLineStart;
                    _lineEnd = _defaultLineEnd;
                  }),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Reset line position'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LineCrossingPreview extends StatelessWidget {
  const _LineCrossingPreview({
    super.key,
    required this.settingsKey,
    required this.camera,
    required this.lineStart,
    required this.lineEnd,
    required this.onLineStartChanged,
    required this.onLineEndChanged,
  });

  final Key settingsKey;
  final Camera camera;
  final Offset lineStart;
  final Offset lineEnd;
  final ValueChanged<Offset> onLineStartChanged;
  final ValueChanged<Offset> onLineEndChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      borderRadius: 20,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            key: settingsKey,
            children: [
              CameraImage(camera: camera),
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final areaSize = constraints.biggest;
                    return _LineOverlay(
                      areaSize: areaSize,
                      start: lineStart,
                      end: lineEnd,
                      onStartChanged: onLineStartChanged,
                      onEndChanged: onLineEndChanged,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single draggable detection line: two endpoint handles connected by a
/// line, drawn over the preview. Each handle drags independently, clamped
/// to stay within the preview bounds. [start]/[end] are fractional (0-1)
/// offsets of the preview area.
class _LineOverlay extends StatelessWidget {
  const _LineOverlay({
    required this.areaSize,
    required this.start,
    required this.end,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  final Size areaSize;
  final Offset start;
  final Offset end;
  final ValueChanged<Offset> onStartChanged;
  final ValueChanged<Offset> onEndChanged;

  Offset _toPixels(Offset fractional) =>
      Offset(fractional.dx * areaSize.width, fractional.dy * areaSize.height);

  Offset _clampPixelToFractional(Offset pixel) {
    if (areaSize.width == 0 || areaSize.height == 0) return Offset.zero;
    final clampedX = pixel.dx.clamp(0.0, areaSize.width);
    final clampedY = pixel.dy.clamp(0.0, areaSize.height);
    return Offset(clampedX / areaSize.width, clampedY / areaSize.height);
  }

  @override
  Widget build(BuildContext context) {
    final startPixel = _toPixels(start);
    final endPixel = _toPixels(end);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          size: areaSize,
          painter: _LinePainter(start: startPixel, end: endPixel),
        ),
        _LineHandle(
          position: startPixel,
          onPanUpdate: (delta) =>
              onStartChanged(_clampPixelToFractional(startPixel + delta)),
        ),
        _LineHandle(
          position: endPixel,
          onPanUpdate: (delta) =>
              onEndChanged(_clampPixelToFractional(endPixel + delta)),
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  const _LinePainter({required this.start, required this.end});

  final Offset start;
  final Offset end;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.amber
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, end, paint);
  }

  @override
  bool shouldRepaint(covariant _LinePainter oldDelegate) =>
      oldDelegate.start != start || oldDelegate.end != end;
}

class _LineHandle extends StatelessWidget {
  const _LineHandle({required this.position, required this.onPanUpdate});

  final Offset position;
  final ValueChanged<Offset> onPanUpdate;

  @override
  Widget build(BuildContext context) {
    const handleSize = 20.0;
    return Positioned(
      left: position.dx - handleSize / 2,
      top: position.dy - handleSize / 2,
      child: GestureDetector(
        onPanUpdate: (details) => onPanUpdate(details.delta),
        child: Container(
          width: handleSize,
          height: handleSize,
          decoration: BoxDecoration(
            color: Colors.amber,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1.5),
          ),
        ),
      ),
    );
  }
}
