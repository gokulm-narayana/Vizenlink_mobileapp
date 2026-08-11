import 'package:flutter/material.dart';

import '../../app_state/homes_controller.dart';
import '../../models/camera.dart';
import '../../widgets/drawable_zone.dart';
import '../../widgets/fixed_preview_layout.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/mode_tile.dart';
import '../../widgets/navigation_leave_guard.dart';
import '../../widgets/saving_overlay.dart';
import '../../widgets/settings_save_button.dart';

/// Privacy Mode: Off / Full / Zone selector (PRIV-002). Full blocks the
/// entire feed; Zone reveals privacy zones — up to 8 draggable/resizable
/// mask rectangles drawn over regions of the preview. Zones can be
/// configured any time but only take effect in Zone mode, so the zones
/// section is only shown then. Persisted through [HomesController] (see
/// `updateCamera`) — see the note on `videoMode` in `lib/models/camera.dart`.
class PrivacyModeScreen extends StatefulWidget {
  const PrivacyModeScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'privacy-mode';

  final Camera camera;
  final HomesController homesController;

  @override
  State<PrivacyModeScreen> createState() => CameraPrivacyModeScreenState();
}

class CameraPrivacyModeScreenState extends State<PrivacyModeScreen> {
  late CameraPrivacyMode _mode = widget.camera.privacyMode;
  late final List<DrawableZone> _zones = [...widget.camera.privacyZones];
  int? _selectedZoneId;
  late int _nextZoneId =
      (_zones.isEmpty
          ? 0
          : _zones.map((zone) => zone.id).reduce((a, b) => a > b ? a : b)) +
      1;
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

  void _addZone() {
    if (_zones.length >= maxDrawableZones) return;
    final id = _nextZoneId++;
    final offset = 0.03 * (_zones.length % 4);
    _markDirty(() {
      _zones.add(
        DrawableZone(
          id: id,
          rect: Rect.fromLTWH(
            0.1 + offset,
            0.1 + offset,
            defaultZoneSize.dx,
            defaultZoneSize.dy,
          ),
        ),
      );
      _selectedZoneId = id;
    });
  }

  void _selectZone(int id) {
    setState(() => _selectedZoneId = id);
  }

  void _deleteZone(int id) {
    _markDirty(() {
      _zones.removeWhere((zone) => zone.id == id);
      if (_selectedZoneId == id) _selectedZoneId = null;
    });
  }

  void _deleteSelectedZone() {
    final id = _selectedZoneId;
    if (id == null) return;
    _deleteZone(id);
  }

  void _clearAllZones() {
    if (_zones.isEmpty) return;
    _markDirty(() {
      _zones.clear();
      _selectedZoneId = null;
    });
  }

  void _updateZoneRect(int id, Rect rect) {
    _markDirty(() {
      final index = _zones.indexWhere((zone) => zone.id == id);
      if (index == -1) return;
      _zones[index] = _zones[index].copyWith(rect: rect);
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
      widget.homesController.updateCamera(
        widget.camera.id,
        (camera) =>
            camera.copyWith(privacyMode: _mode, privacyZones: [..._zones]),
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
    dialogKey: const Key('PRIV-011'),
    discardKey: const Key('PRIV-012'),
    saveKey: const Key('PRIV-013'),
  );

  @override
  Widget build(BuildContext context) {
    return LeaveGuard(
      canLeave: _confirmLeave,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            key: const Key('PRIV-001'),
            title: const Text('Privacy Mode'),
            actions: [
              SettingsSaveButton(
                settingsKey: const Key('PRIV-010'),
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
                  _PrivacyPreview(
                    key: ValueKey(_previewReloadKey),
                    settingsKey: const Key('PRIV-004'),
                    camera: widget.camera,
                    mode: _mode,
                    zones: _zones,
                    selectedZoneId: _selectedZoneId,
                    onZoneSelected: _selectZone,
                    onZoneRectChanged: _updateZoneRect,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      key: const Key('PRIV-005'),
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
                Row(
                  key: const Key('PRIV-002'),
                  children: [
                    Expanded(
                      child: ModeTile(
                        icon: Icons.visibility_outlined,
                        label: 'Off',
                        selected: _mode == CameraPrivacyMode.off,
                        onTap: () =>
                            _markDirty(() => _mode = CameraPrivacyMode.off),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ModeTile(
                        icon: Icons.visibility_off,
                        label: 'Full',
                        selected: _mode == CameraPrivacyMode.full,
                        onTap: () =>
                            _markDirty(() => _mode = CameraPrivacyMode.full),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ModeTile(
                        icon: Icons.crop_square,
                        label: 'Zone',
                        selected: _mode == CameraPrivacyMode.zone,
                        onTap: () =>
                            _markDirty(() => _mode = CameraPrivacyMode.zone),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    key: const Key('PRIV-003'),
                    switch (_mode) {
                      CameraPrivacyMode.off =>
                        'Privacy mode is off — the camera streams and '
                            'records normally.',
                      CameraPrivacyMode.full =>
                        'This camera stops streaming and recording video '
                            'and audio entirely until a different mode is '
                            'selected.',
                      CameraPrivacyMode.zone =>
                        'Only the privacy zones below are masked — the rest '
                            'of the feed streams and records normally.',
                    },
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (_mode == CameraPrivacyMode.zone) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Privacy zones (${_zones.length}/$maxDrawableZones)',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      TextButton.icon(
                        key: const Key('PRIV-006'),
                        onPressed: _zones.length < maxDrawableZones
                            ? _addZone
                            : null,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add zone'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_zones.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No privacy zones yet. Tap "Add zone" to mask a '
                        'region of the preview.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  else
                    GlassCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        key: const Key('PRIV-007'),
                        children: [
                          for (var i = 0; i < _zones.length; i++)
                            ZoneListTile(
                              label: 'Zone ${i + 1}',
                              icon: Icons.crop_square,
                              selected: _zones[i].id == _selectedZoneId,
                              onTap: () => _selectZone(_zones[i].id),
                              onDelete: () => _deleteZone(_zones[i].id),
                              isLast: i == _zones.length - 1,
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('PRIV-008'),
                          onPressed: _selectedZoneId != null
                              ? _deleteSelectedZone
                              : null,
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: const Text('Delete selected'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: const Key('PRIV-009'),
                          onPressed: _zones.isNotEmpty ? _clearAllZones : null,
                          icon: const Icon(Icons.clear_all, size: 18),
                          label: const Text('Clear all'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyPreview extends StatelessWidget {
  const _PrivacyPreview({
    super.key,
    required this.settingsKey,
    required this.camera,
    required this.mode,
    required this.zones,
    required this.selectedZoneId,
    required this.onZoneSelected,
    required this.onZoneRectChanged,
  });

  final Key settingsKey;
  final Camera camera;
  final CameraPrivacyMode mode;
  final List<DrawableZone> zones;
  final int? selectedZoneId;
  final ValueChanged<int> onZoneSelected;
  final void Function(int id, Rect rect) onZoneRectChanged;

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
              if (mode == CameraPrivacyMode.full)
                const Positioned.fill(child: _FullBlackoutOverlay())
              else
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final areaSize = constraints.biggest;
                      return Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          for (final zone in zones)
                            ZoneOverlay(
                              key: ValueKey(zone.id),
                              rect: zone.rect,
                              areaSize: areaSize,
                              selected: zone.id == selectedZoneId,
                              icon: Icons.visibility_off,
                              onTap: () => onZoneSelected(zone.id),
                              onRectChanged: (rect) =>
                                  onZoneRectChanged(zone.id, rect),
                            ),
                        ],
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

/// Full opaque blackout shown over the preview when Privacy Mode is set to
/// Full — the entire feed is blocked, so the preview reflects that instead
/// of still showing the camera image underneath.
class _FullBlackoutOverlay extends StatelessWidget {
  const _FullBlackoutOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.visibility_off,
              color: Colors.white.withValues(alpha: 0.6),
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              'Privacy Mode: Full',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
