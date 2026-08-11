import 'package:flutter/material.dart';

import '../../app_state/homes_controller.dart';
import '../../models/camera.dart';
import '../../widgets/drawable_zone.dart';
import '../../widgets/fixed_preview_layout.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/navigation_leave_guard.dart';
import '../../widgets/saving_overlay.dart';
import '../../widgets/settings_save_button.dart';

/// Intrusion Detection: an enable toggle, sensitivity slider, and up to 8
/// draggable/resizable trigger zones drawn over regions of the preview —
/// detection only fires within these zones. Persisted through
/// [HomesController] (see `updateCamera`) — see the note on `videoMode` in
/// `lib/models/camera.dart`.
class IntrusionDetectionScreen extends StatefulWidget {
  const IntrusionDetectionScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'intrusion-detection';

  final Camera camera;
  final HomesController homesController;

  @override
  State<IntrusionDetectionScreen> createState() =>
      _IntrusionDetectionScreenState();
}

class _IntrusionDetectionScreenState extends State<IntrusionDetectionScreen> {
  late bool _enabled = widget.camera.intrusionDetectionEnabled;
  late double _sensitivity = widget.camera.intrusionSensitivity;
  late final List<DrawableZone> _zones = [...widget.camera.intrusionZones];
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
        (camera) => camera.copyWith(
          intrusionDetectionEnabled: _enabled,
          intrusionSensitivity: _sensitivity,
          intrusionZones: [..._zones],
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
    dialogKey: const Key('INTRUDE-011'),
    discardKey: const Key('INTRUDE-012'),
    saveKey: const Key('INTRUDE-013'),
  );

  @override
  Widget build(BuildContext context) {
    return LeaveGuard(
      canLeave: _confirmLeave,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            key: const Key('INTRUDE-001'),
            title: const Text('Intrusion Detection'),
            actions: [
              SettingsSaveButton(
                settingsKey: const Key('INTRUDE-002'),
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
                  _IntrusionPreview(
                    key: ValueKey(_previewReloadKey),
                    settingsKey: const Key('INTRUDE-003'),
                    camera: widget.camera,
                    zones: _zones,
                    selectedZoneId: _selectedZoneId,
                    onZoneSelected: _selectZone,
                    onZoneRectChanged: _updateZoneRect,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      key: const Key('INTRUDE-004'),
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
                    key: const Key('INTRUDE-005'),
                    title: const Text('Intrusion detection'),
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
                        key: const Key('INTRUDE-006'),
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
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Trigger zones (${_zones.length}/$maxDrawableZones)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton.icon(
                      key: const Key('INTRUDE-007'),
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
                      'No trigger zones yet. Tap "Add zone" to mark a region '
                      'that triggers intrusion detection.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                else
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      key: const Key('INTRUDE-008'),
                      children: [
                        for (var i = 0; i < _zones.length; i++)
                          ZoneListTile(
                            label: 'Zone ${i + 1}',
                            icon: Icons.crop_free,
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
                        key: const Key('INTRUDE-009'),
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
                        key: const Key('INTRUDE-010'),
                        onPressed: _zones.isNotEmpty ? _clearAllZones : null,
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Clear all'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IntrusionPreview extends StatelessWidget {
  const _IntrusionPreview({
    super.key,
    required this.settingsKey,
    required this.camera,
    required this.zones,
    required this.selectedZoneId,
    required this.onZoneSelected,
    required this.onZoneRectChanged,
  });

  final Key settingsKey;
  final Camera camera;
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
                            icon: Icons.crop_free,
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
