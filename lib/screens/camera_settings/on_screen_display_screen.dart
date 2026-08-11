import 'package:flutter/material.dart';

import '../../models/camera.dart';
import '../../widgets/camera_preview_thumbnail.dart';
import '../../widgets/color_picker_field.dart';
import '../../widgets/fixed_preview_layout.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/navigation_leave_guard.dart';
import '../../widgets/refresh_preview_button.dart';
import '../../widgets/saving_overlay.dart';
import '../../widgets/settings_save_button.dart';

enum _DateFormat { ymd, dmy, mdy }

extension on _DateFormat {
  String get label => switch (this) {
    _DateFormat.ymd => 'YYYY-MM-DD',
    _DateFormat.dmy => 'DD-MM-YYYY',
    _DateFormat.mdy => 'MM-DD-YYYY',
  };

  String format(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final mo = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return switch (this) {
      _DateFormat.ymd => '$y-$mo-$d',
      _DateFormat.dmy => '$d-$mo-$y',
      _DateFormat.mdy => '$mo-$d-$y',
    };
  }
}

enum _TimeFormat { h24, h12 }

extension on _TimeFormat {
  String get label => switch (this) {
    _TimeFormat.h24 => '24-hour',
    _TimeFormat.h12 => '12-hour',
  };

  String format(DateTime time) {
    final hour24 = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    final hour12 = (time.hour % 12 == 0 ? 12 : time.hour % 12).toString();
    final ampm = time.hour < 12 ? 'AM' : 'PM';
    return switch (this) {
      _TimeFormat.h24 => '$hour24:$minute',
      _TimeFormat.h12 => '$hour12:$minute $ampm',
    };
  }
}

/// Position choice for a draggable OSD overlay: one of the four fixed
/// preview corners, or [custom] — in which case the overlay is freely
/// draggable and its position is tracked separately as a fractional
/// offset.
enum _OverlayPosition { topLeft, topRight, bottomLeft, bottomRight, custom }

extension on _OverlayPosition {
  String get label => switch (this) {
    _OverlayPosition.topLeft => 'Top left',
    _OverlayPosition.topRight => 'Top right',
    _OverlayPosition.bottomLeft => 'Bottom left',
    _OverlayPosition.bottomRight => 'Bottom right',
    _OverlayPosition.custom => 'Custom (drag to place)',
  };

  /// Fractional (x, y) offset for a fixed corner. Not used for [custom].
  Offset get fractionalOffset => switch (this) {
    _OverlayPosition.topLeft => const Offset(0.04, 0.04),
    _OverlayPosition.topRight => const Offset(0.7, 0.04),
    _OverlayPosition.bottomLeft => const Offset(0.04, 0.78),
    _OverlayPosition.bottomRight => const Offset(0.7, 0.78),
    _OverlayPosition.custom => Offset.zero,
  };
}

const _defaultTimeOffset = Offset(0.04, 0.04);
const _defaultCustomTextOffset = Offset(0.04, 0.78);

/// On-Screen Display: a live preview showing Time and Custom Text overlays.
/// Each has a position (one of 4 fixed corners, or Custom — freely
/// draggable) and a text color. Local-only draft state — no backend/
/// protocol wired up yet (see CLAUDE.md), so Save does not persist beyond
/// this screen. Bitrate and Signal Strength (app-side, non-draggable status
/// badges that actually apply to the Camera Live page) live on the
/// separate Tags screen, since they affect the Camera Live page rather than
/// this screen's own preview. Save is disabled until a field changes.
class OnScreenDisplayScreen extends StatefulWidget {
  const OnScreenDisplayScreen({super.key, required this.camera});

  static const routeName = 'on-screen-display';

  final Camera camera;

  @override
  State<OnScreenDisplayScreen> createState() => _OnScreenDisplayScreenState();
}

class _OnScreenDisplayScreenState extends State<OnScreenDisplayScreen> {
  bool _timeEnabled = true;
  _OverlayPosition _timePosition = _OverlayPosition.custom;
  Offset _timeCustomOffset = _defaultTimeOffset;
  Color _timeColor = Colors.white;
  _DateFormat _dateFormat = _DateFormat.ymd;
  _TimeFormat _timeFormat = _TimeFormat.h24;

  bool _customTextEnabled = false;
  _OverlayPosition _customTextPosition = _OverlayPosition.custom;
  Offset _customTextCustomOffset = _defaultCustomTextOffset;
  Color _customTextColor = Colors.white;
  final _customTextController = TextEditingController();

  bool _isDirty = false;
  bool _isSaving = false;
  bool _isRefreshing = false;
  int _previewReloadKey = 0;

  @override
  void dispose() {
    _customTextController.dispose();
    super.dispose();
  }

  void _markDirty(VoidCallback update) {
    setState(() {
      update();
      _isDirty = true;
    });
  }

  Future<void> _refreshPreview() async {
    setState(() => _isRefreshing = true);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    setState(() {
      _isRefreshing = false;
      _previewReloadKey++;
    });
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final succeeded = await simulateCameraSave();
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (succeeded) {
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
    dialogKey: const Key('OSD-019'),
    discardKey: const Key('OSD-020'),
    saveKey: const Key('OSD-021'),
  );

  @override
  Widget build(BuildContext context) {
    return LeaveGuard(
      canLeave: _confirmLeave,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            key: const Key('OSD-001'),
            title: const Text('On-Screen Display'),
            actions: [
              SettingsSaveButton(
                settingsKey: const Key('OSD-004'),
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
                  _OsdPreview(
                    key: ValueKey(_previewReloadKey),
                    settingsKey: const Key('OSD-005'),
                    camera: widget.camera,
                    timeEnabled: _timeEnabled,
                    timeText:
                        '${_dateFormat.format(DateTime.now())} '
                        '${_timeFormat.format(DateTime.now())}',
                    timeColor: _timeColor,
                    timePosition: _timePosition,
                    timeCustomOffset: _timeCustomOffset,
                    onTimeCustomOffsetChanged: (offset) =>
                        _markDirty(() => _timeCustomOffset = offset),
                    customText: _customTextController.text,
                    customTextEnabled: _customTextEnabled,
                    customTextColor: _customTextColor,
                    customTextPosition: _customTextPosition,
                    customTextCustomOffset: _customTextCustomOffset,
                    onCustomTextCustomOffsetChanged: (offset) =>
                        _markDirty(() => _customTextCustomOffset = offset),
                  ),
                  const SizedBox(height: 8),
                  RefreshPreviewButton(
                    settingsKey: const Key('OSD-018'),
                    isRefreshing: _isRefreshing,
                    onPressed: _refreshPreview,
                  ),
                ],
              ),
              scrollableChildren: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SwitchListTile(
                        key: const Key('OSD-006'),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Time'),
                        value: _timeEnabled,
                        onChanged: (value) =>
                            _markDirty(() => _timeEnabled = value),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<_DateFormat>(
                        key: const Key('OSD-016'),
                        initialValue: _dateFormat,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Date format',
                        ),
                        items: [
                          for (final format in _DateFormat.values)
                            DropdownMenuItem(
                              value: format,
                              child: Text(
                                format.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: _timeEnabled
                            ? (value) => _markDirty(() => _dateFormat = value!)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<_TimeFormat>(
                        key: const Key('OSD-017'),
                        initialValue: _timeFormat,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Time format',
                        ),
                        items: [
                          for (final format in _TimeFormat.values)
                            DropdownMenuItem(
                              value: format,
                              child: Text(
                                format.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: _timeEnabled
                            ? (value) => _markDirty(() => _timeFormat = value!)
                            : null,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<_OverlayPosition>(
                        key: const Key('OSD-012'),
                        initialValue: _timePosition,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Position',
                        ),
                        items: [
                          for (final position in _OverlayPosition.values)
                            DropdownMenuItem(
                              value: position,
                              child: Text(
                                position.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: _timeEnabled
                            ? (value) =>
                                  _markDirty(() => _timePosition = value!)
                            : null,
                      ),
                      if (_timePosition == _OverlayPosition.custom) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Drag on the preview to reposition',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'Color',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      ColorPickerField(
                        settingsKey: const Key('OSD-013'),
                        color: _timeColor,
                        enabled: _timeEnabled,
                        onChanged: (color) =>
                            _markDirty(() => _timeColor = color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SwitchListTile(
                        key: const Key('OSD-007'),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Custom text'),
                        value: _customTextEnabled,
                        onChanged: (value) =>
                            _markDirty(() => _customTextEnabled = value),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        key: const Key('OSD-008'),
                        controller: _customTextController,
                        enabled: _customTextEnabled,
                        decoration: const InputDecoration(labelText: 'Text'),
                        onChanged: (_) => _markDirty(() {}),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<_OverlayPosition>(
                        key: const Key('OSD-014'),
                        initialValue: _customTextPosition,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Position',
                        ),
                        items: [
                          for (final position in _OverlayPosition.values)
                            DropdownMenuItem(
                              value: position,
                              child: Text(
                                position.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                        onChanged: _customTextEnabled
                            ? (value) =>
                                  _markDirty(() => _customTextPosition = value!)
                            : null,
                      ),
                      if (_customTextPosition == _OverlayPosition.custom) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Drag on the preview to reposition',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text(
                        'Color',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      ColorPickerField(
                        settingsKey: const Key('OSD-015'),
                        color: _customTextColor,
                        enabled: _customTextEnabled,
                        onChanged: (color) =>
                            _markDirty(() => _customTextColor = color),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OsdPreview extends StatelessWidget {
  const _OsdPreview({
    super.key,
    required this.settingsKey,
    required this.camera,
    required this.timeEnabled,
    required this.timeText,
    required this.timeColor,
    required this.timePosition,
    required this.timeCustomOffset,
    required this.onTimeCustomOffsetChanged,
    required this.customText,
    required this.customTextEnabled,
    required this.customTextColor,
    required this.customTextPosition,
    required this.customTextCustomOffset,
    required this.onCustomTextCustomOffsetChanged,
  });

  final Key settingsKey;
  final Camera camera;
  final bool timeEnabled;
  final String timeText;
  final Color timeColor;
  final _OverlayPosition timePosition;
  final Offset timeCustomOffset;
  final ValueChanged<Offset> onTimeCustomOffsetChanged;
  final String customText;
  final bool customTextEnabled;
  final Color customTextColor;
  final _OverlayPosition customTextPosition;
  final Offset customTextCustomOffset;
  final ValueChanged<Offset> onCustomTextCustomOffsetChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: settingsKey,
      children: [
        CameraPreviewThumbnail(
          settingsKey: const Key('OSD-005-image'),
          camera: camera,
        ),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final areaSize = constraints.biggest;
              return Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  if (timeEnabled)
                    _OverlayChip(
                      position: timePosition,
                      areaSize: areaSize,
                      customOffset: timeCustomOffset,
                      onCustomOffsetChanged: onTimeCustomOffsetChanged,
                      child: Text(
                        timeText,
                        style: TextStyle(
                          color: timeColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (customTextEnabled && customText.isNotEmpty)
                    _OverlayChip(
                      position: customTextPosition,
                      areaSize: areaSize,
                      customOffset: customTextCustomOffset,
                      onCustomOffsetChanged: onCustomTextCustomOffsetChanged,
                      child: Text(
                        customText,
                        style: TextStyle(
                          color: customTextColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Renders [child] at [position]: a fixed corner (non-draggable), or, when
/// [position] is [_OverlayPosition.custom], at [customOffset] and freely
/// draggable — measuring its own rendered size after layout (via a
/// `GlobalKey`/`RenderBox`, since text width varies with content) and
/// clamping against that actual footprint rather than a guessed constant,
/// so it can't be dragged or resized-into partway off the preview edges.
class _OverlayChip extends StatefulWidget {
  const _OverlayChip({
    required this.position,
    required this.areaSize,
    required this.customOffset,
    required this.onCustomOffsetChanged,
    required this.child,
  });

  final _OverlayPosition position;
  final Size areaSize;
  final Offset customOffset;
  final ValueChanged<Offset> onCustomOffsetChanged;
  final Widget child;

  @override
  State<_OverlayChip> createState() => _OverlayChipState();
}

class _OverlayChipState extends State<_OverlayChip> {
  final _chipKey = GlobalKey();
  Size _chipSize = Size.zero;

  bool get _isCustom => widget.position == _OverlayPosition.custom;

  Offset get _fractionalOffset =>
      _isCustom ? widget.customOffset : widget.position.fractionalOffset;

  double get _maxLeft =>
      (widget.areaSize.width - _chipSize.width).clamp(0.0, double.infinity);
  double get _maxTop =>
      (widget.areaSize.height - _chipSize.height).clamp(0.0, double.infinity);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndClamp());
  }

  @override
  void didUpdateWidget(covariant _OverlayChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureAndClamp());
  }

  void _measureAndClamp() {
    if (!mounted) return;
    final renderBox = _chipKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;
    final newSize = renderBox.size;
    if (newSize != _chipSize) setState(() => _chipSize = newSize);

    if (!_isCustom) return;
    if (widget.areaSize.width == 0 || widget.areaSize.height == 0) return;
    final left = (_fractionalOffset.dx * widget.areaSize.width).clamp(
      0.0,
      (widget.areaSize.width - newSize.width).clamp(0.0, double.infinity),
    );
    final top = (_fractionalOffset.dy * widget.areaSize.height).clamp(
      0.0,
      (widget.areaSize.height - newSize.height).clamp(0.0, double.infinity),
    );
    final clamped = Offset(
      left / widget.areaSize.width,
      top / widget.areaSize.height,
    );
    if ((clamped - _fractionalOffset).distanceSquared > 0.0000001) {
      widget.onCustomOffsetChanged(clamped);
    }
  }

  @override
  Widget build(BuildContext context) {
    final left = (_fractionalOffset.dx * widget.areaSize.width).clamp(
      0.0,
      _maxLeft,
    );
    final top = (_fractionalOffset.dy * widget.areaSize.height).clamp(
      0.0,
      _maxTop,
    );

    final content = Container(key: _chipKey, child: widget.child);

    if (!_isCustom) {
      return Positioned(left: left, top: top, child: content);
    }

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onPanUpdate: (details) {
          if (widget.areaSize.width == 0 || widget.areaSize.height == 0) {
            return;
          }
          final newLeft = (left + details.delta.dx).clamp(0.0, _maxLeft);
          final newTop = (top + details.delta.dy).clamp(0.0, _maxTop);
          widget.onCustomOffsetChanged(
            Offset(
              newLeft / widget.areaSize.width,
              newTop / widget.areaSize.height,
            ),
          );
        },
        child: content,
      ),
    );
  }
}
