import 'dart:typed_data';

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

/// Person Detection: an enable toggle, confidence-threshold slider, and up
/// to 8 free-form polygon exclusion zones drawn over regions of the
/// preview — person detection ignores movement inside these zones (e.g. a
/// street or a neighbor's yard visible in frame) and still detects
/// normally everywhere else. Persisted through [HomesController] (see
/// `updateCamera`) — see the note on `videoMode` in `lib/models/camera.dart`.
class PersonDetectionScreen extends StatefulWidget {
  const PersonDetectionScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'person-detection';

  final Camera camera;
  final HomesController homesController;

  @override
  State<PersonDetectionScreen> createState() => _PersonDetectionScreenState();
}

class _PersonDetectionScreenState extends State<PersonDetectionScreen> {
  late bool _enabled = widget.camera.personDetectionEnabled;
  late double _confidence = widget.camera.personDetectionConfidence;
  late final List<PolygonZone> _zones = [...widget.camera.personDetectionZones];
  PolygonZone? _draftZone;
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
  Uint8List? _wanPreviewBytes;

  void _markDirty(VoidCallback update) {
    setState(() {
      update();
      _isDirty = true;
    });
  }

  void _addPoint() {
    if (_zones.length + (_draftZone == null ? 0 : 1) >= maxDrawableZones &&
        _draftZone == null) {
      return;
    }
    _markDirty(() {
      final draft = _draftZone ?? PolygonZone(id: _nextZoneId++, points: []);
      final stagger = polygonPointStagger * draft.points.length;
      final point = Offset(
        (polygonPointBaseOffset.dx + stagger).clamp(0.0, 1.0),
        (polygonPointBaseOffset.dy + stagger).clamp(0.0, 1.0),
      );
      _draftZone = draft.copyWith(points: [...draft.points, point]);
      _selectedZoneId = draft.id;
    });
  }

  void _finishZone() {
    final draft = _draftZone;
    if (draft == null || !draft.isClosed) return;
    _markDirty(() {
      _zones.add(draft);
      _draftZone = null;
    });
  }

  void _cancelDraftZone() {
    _markDirty(() {
      _draftZone = null;
      _selectedZoneId = null;
    });
  }

  void _updateVertex(int vertexIndex, Offset offset) {
    _markDirty(() {
      if (_draftZone != null) {
        final points = [..._draftZone!.points];
        points[vertexIndex] = offset;
        _draftZone = _draftZone!.copyWith(points: points);
        return;
      }
      final index = _zones.indexWhere((zone) => zone.id == _selectedZoneId);
      if (index == -1) return;
      final points = [..._zones[index].points];
      points[vertexIndex] = offset;
      _zones[index] = _zones[index].copyWith(points: points);
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
    if (_zones.isEmpty && _draftZone == null) return;
    _markDirty(() {
      _zones.clear();
      _draftZone = null;
      _selectedZoneId = null;
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
    if (succeeded) {
      setState(() {
        _isRefreshing = false;
        _previewReloadKey++;
        _wanPreviewBytes = null;
      });
      return;
    }

    // LAN failed — fall back to a transient WAN preview rather than
    // surfacing an error outright, per mobile-app-screen-conventions.md's
    // LAN/WAN convention.
    final wanBytes = await fetchWanPreviewSnapshot(connection: connection);
    if (!mounted) return;
    setState(() {
      _isRefreshing = false;
      if (wanBytes != null) _wanPreviewBytes = wanBytes;
    });
    if (wanBytes == null) {
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
          personDetectionEnabled: _enabled,
          personDetectionConfidence: _confidence,
          personDetectionZones: [..._zones],
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
    dialogKey: const Key('PERSON-013'),
    discardKey: const Key('PERSON-014'),
    saveKey: const Key('PERSON-015'),
  );

  @override
  Widget build(BuildContext context) {
    final totalZones = _zones.length + (_draftZone == null ? 0 : 1);

    return LeaveGuard(
      canLeave: _confirmLeave,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            key: const Key('PERSON-001'),
            title: const Text('Person Detection'),
            actions: [
              SettingsSaveButton(
                settingsKey: const Key('PERSON-002'),
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
                  _PersonPreview(
                    key: ValueKey(_previewReloadKey),
                    settingsKey: const Key('PERSON-006'),
                    camera: _camera,
                    zones: _zones,
                    draftZone: _draftZone,
                    selectedZoneId: _selectedZoneId,
                    onVertexChanged: _updateVertex,
                    overrideBytes: _wanPreviewBytes,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      key: const Key('PERSON-007'),
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
                    key: const Key('PERSON-003'),
                    title: const Text('Person detection'),
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
                        'Confidence threshold (${_confidence.round()})',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Slider(
                        key: const Key('PERSON-004'),
                        value: _confidence,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        onChanged: _enabled
                            ? (value) => _markDirty(() => _confidence = value)
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
                        'Exclusion zones ($totalZones/$maxDrawableZones)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton.icon(
                      key: const Key('PERSON-008'),
                      onPressed: totalZones < maxDrawableZones
                          ? _addPoint
                          : null,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add point'),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Excludes person detection inside these areas (e.g. a '
                    'street or neighbor\'s yard) — detection still runs '
                    'normally everywhere else.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                if (_draftZone != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          key: const Key('PERSON-009'),
                          onPressed: _draftZone!.isClosed ? _finishZone : null,
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(
                            _draftZone!.isClosed
                                ? 'Finish zone'
                                : 'Add ${minPolygonPoints - _draftZone!.points.length} more point(s)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: _cancelDraftZone,
                        child: const Text('Cancel'),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                if (_zones.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No exclusion zones yet. Tap "Add point" to start '
                      'outlining a region to ignore (3+ points, then Finish '
                      'zone).',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                else
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      key: const Key('PERSON-010'),
                      children: [
                        for (var i = 0; i < _zones.length; i++)
                          PolygonZoneListTile(
                            label: 'Zone ${i + 1}',
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
                        key: const Key('PERSON-011'),
                        onPressed: _selectedZoneId != null && _draftZone == null
                            ? _deleteSelectedZone
                            : null,
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete selected'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('PERSON-012'),
                        onPressed: totalZones > 0 ? _clearAllZones : null,
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

class _PersonPreview extends StatelessWidget {
  const _PersonPreview({
    super.key,
    required this.settingsKey,
    required this.camera,
    required this.zones,
    required this.draftZone,
    required this.selectedZoneId,
    required this.onVertexChanged,
    this.overrideBytes,
  });

  final Key settingsKey;
  final Camera camera;
  final List<PolygonZone> zones;
  final PolygonZone? draftZone;
  final int? selectedZoneId;
  final void Function(int vertexIndex, Offset offset) onVertexChanged;
  final Uint8List? overrideBytes;

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
              CameraImage(camera: camera, overrideBytes: overrideBytes),
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final areaSize = constraints.biggest;
                    return Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        for (final zone in zones)
                          PolygonOverlay(
                            key: ValueKey(zone.id),
                            zone: zone,
                            areaSize: areaSize,
                            selected: zone.id == selectedZoneId,
                            onVertexChanged: (index, offset) =>
                                onVertexChanged(index, offset),
                          ),
                        if (draftZone != null)
                          PolygonOverlay(
                            key: ValueKey(draftZone!.id),
                            zone: draftZone!,
                            areaSize: areaSize,
                            selected: true,
                            onVertexChanged: onVertexChanged,
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
