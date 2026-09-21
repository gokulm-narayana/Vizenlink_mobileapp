import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app_state/camera_sync.dart';
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

/// Parking Monitoring: zone-based occupancy tracking, distinct from
/// `vehicle_detection_screen.dart`'s plain "did a vehicle appear at all"
/// toggle. Lets the user draw up to [maxParkingZones] free-form polygon
/// zones on the preview, each one of three types:
///
/// - **Parking Slot**: a real, countable bay — contributes to the
///   occupied/free tally, can be flagged "wrong bay" if a vehicle overlaps
///   a neighboring slot.
/// - **Open Area**: an unmarked lot/section with no painted lines (the
///   common case outside organized/mall parking) — counts vehicles inside
///   the boundary against a user-entered estimated capacity rather than
///   judging position against a grid.
/// - **Restricted / No-Parking**: never counts as a space; a vehicle inside
///   fires a violation after a dwell-time threshold (fire lanes, loading
///   zones).
///
/// **Entirely local-only for now** — no `camera_api` capability exists yet
/// for per-zone vehicle occupancy classification (only a plain
/// `VehicleDetected` boolean exists, confirmed via `ui-api-gap-audit`), so
/// every zone's outline color is a static per-type color, not a live status,
/// and the summary card deliberately shows configured counts only — never a
/// fabricated occupied/free number. This repo removed all dummy/fake
/// media/data (2026-09-08/09); this screen must not reintroduce it. Wiring
/// real occupancy requires a new capability from the senior engineer first.
class ParkingMonitoringScreen extends StatefulWidget {
  const ParkingMonitoringScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'parking-monitoring';

  final Camera camera;
  final HomesController homesController;

  @override
  State<ParkingMonitoringScreen> createState() =>
      _ParkingMonitoringScreenState();
}

class _ParkingMonitoringScreenState extends State<ParkingMonitoringScreen> {
  late bool _enabled = widget.camera.parkingMonitoringEnabled;
  late final List<ParkingZone> _zones = [...widget.camera.parkingZones];
  ParkingZoneType _newZoneType = ParkingZoneType.slot;
  int? _selectedZoneId;
  late int _nextZoneId =
      (_zones.isEmpty
          ? 0
          : _zones.map((zone) => zone.id).reduce((a, b) => a > b ? a : b)) +
      1;
  late int _restrictedDwellSeconds =
      widget.camera.parkingRestrictedDwellSeconds;
  late int _wrongBayDwellSeconds = widget.camera.parkingWrongBayDwellSeconds;
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

  /// Real bug fix: every new zone used to start its first point at the same
  /// fixed [polygonPointBaseOffset] regardless of how many zones already
  /// existed, so a second zone's points landed stacked directly on top of
  /// the first one's — looking like nothing happened, or grabbing the
  /// wrong zone's vertex handle instead of starting a new shape. Cascades
  /// through a 3x3 grid of center positions keyed off how many zones exist
  /// already (wrapping after 9) — same idea Intrusion/Privacy Mode's
  /// rectangle zones already use (`0.03 * (zones.length % 4)`), just
  /// spread across two axes since a polygon needs more separation room
  /// than a small nudge gives.
  Offset _nextZoneCenter() {
    final column = _zones.length % 3;
    final row = (_zones.length ~/ 3) % 3;
    return Offset(0.2 + column * 0.25, 0.2 + row * 0.25);
  }

  /// Radius (fractional, of the preview) of the regular pentagon
  /// [_addDefaultZone] places — sized similarly to [defaultZoneSize]'s area.
  static const _defaultZoneRadius = 0.1;

  /// A regular pentagon's 5 vertices around [center], point-up — same
  /// "instantly a complete, draggable shape" convention Privacy/Intrusion's
  /// rectangle zones already use (`_addZone`'s `defaultZoneSize` rect),
  /// adapted to a polygon instead of point-by-point placement (which this
  /// screen used to require via a since-removed Add-point/Finish-zone
  /// flow) — a real, if minor, usability gap this fixes: every other
  /// zone-editing screen in this app creates a complete shape in one tap.
  List<Offset> _defaultPentagon(Offset center) {
    return [
      for (var i = 0; i < 5; i++)
        Offset(
          (center.dx +
                  _defaultZoneRadius *
                      math.cos(-math.pi / 2 + i * 2 * math.pi / 5))
              .clamp(0.0, 1.0),
          (center.dy +
                  _defaultZoneRadius *
                      math.sin(-math.pi / 2 + i * 2 * math.pi / 5))
              .clamp(0.0, 1.0),
        ),
    ];
  }

  void _addDefaultZone() {
    if (_zones.length >= maxParkingZones) return;
    _markDirty(() {
      final zone = ParkingZone(
        id: _nextZoneId++,
        type: _newZoneType,
        points: _defaultPentagon(_nextZoneCenter()),
      );
      _zones.add(zone);
      _selectedZoneId = zone.id;
    });
  }

  /// Completes a zone from a single freehand trace on the preview
  /// ([PolygonDrawSurface]) — the traced outline already satisfies
  /// [minPolygonPoints] (the surface itself discards anything shorter), so
  /// it becomes a real, selected zone immediately, same as
  /// [_addDefaultZone]'s result.
  void _addTracedZone(List<Offset> points) {
    _markDirty(() {
      final zone = ParkingZone(
        id: _nextZoneId++,
        type: _newZoneType,
        points: points,
      );
      _zones.add(zone);
      _selectedZoneId = zone.id;
    });
  }

  void _updateVertex(int vertexIndex, Offset offset) {
    _markDirty(() {
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
    if (_zones.isEmpty) return;
    _markDirty(() {
      _zones.clear();
      _selectedZoneId = null;
    });
  }

  void _renameZone(int id, String label) {
    _markDirty(() {
      final index = _zones.indexWhere((zone) => zone.id == id);
      if (index == -1) return;
      _zones[index] = _zones[index].copyWith(
        label: label.trim().isEmpty ? null : label.trim(),
      );
    });
  }

  void _setEstimatedCapacity(int id, int? capacity) {
    _markDirty(() {
      final index = _zones.indexWhere((zone) => zone.id == id);
      if (index == -1) return;
      // `copyWith`'s `?? this.field` semantics can't express "clear this
      // back to null", so rebuild the zone directly when the field's
      // cleared (empty capacity input) instead of going through copyWith.
      _zones[index] = ParkingZone(
        id: _zones[index].id,
        type: _zones[index].type,
        points: _zones[index].points,
        label: _zones[index].label,
        estimatedCapacity: capacity,
      );
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
    // No camera_api capability exists yet for this screen's fields — see
    // this file's own doc comment — so every camera always takes the
    // local-only save path, unlike Person Detection's real-field save.
    final succeeded = await simulateCameraSave();

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (succeeded) {
      widget.homesController.updateCamera(
        widget.camera.id,
        (camera) => camera.copyWith(
          parkingMonitoringEnabled: _enabled,
          parkingZones: [..._zones],
          parkingRestrictedDwellSeconds: _restrictedDwellSeconds,
          parkingWrongBayDwellSeconds: _wrongBayDwellSeconds,
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
    dialogKey: const Key('PARK-017'),
    discardKey: const Key('PARK-019'),
    saveKey: const Key('PARK-020'),
  );

  bool get _hasRestrictedZone =>
      _zones.any((zone) => zone.type == ParkingZoneType.restricted);
  bool get _hasSlotZone =>
      _zones.any((zone) => zone.type == ParkingZoneType.slot);

  String _defaultLabel(ParkingZone zone) {
    final sameType = _zones.where((z) => z.type == zone.type).toList();
    final index = sameType.indexWhere((z) => z.id == zone.id);
    final ordinal = index == -1 ? sameType.length : index + 1;
    return switch (zone.type) {
      ParkingZoneType.slot => 'Slot $ordinal',
      ParkingZoneType.openArea => 'Open Area $ordinal',
      ParkingZoneType.restricted => 'Restricted $ordinal',
    };
  }

  @override
  Widget build(BuildContext context) {
    final slotZones = _zones.where((z) => z.type == ParkingZoneType.slot);
    final openAreaZones = _zones.where(
      (z) => z.type == ParkingZoneType.openArea,
    );
    final restrictedZones = _zones.where(
      (z) => z.type == ParkingZoneType.restricted,
    );
    final configuredCapacity = openAreaZones
        .map((z) => z.estimatedCapacity)
        .whereType<int>()
        .fold<int>(0, (sum, value) => sum + value);

    return LeaveGuard(
      canLeave: _confirmLeave,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            key: const Key('PARK-001'),
            title: const Text('Parking Monitoring'),
            actions: [
              SettingsSaveButton(
                settingsKey: const Key('PARK-002'),
                isDirty: _isDirty,
                isSaving: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
          body: SavingOverlay(
            isSaving: _isSaving,
            label: 'Saving…',
            child: FixedPreviewLayout(
              preview: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ParkingPreview(
                    key: ValueKey(_previewReloadKey),
                    settingsKey: const Key('PARK-003'),
                    camera: _camera,
                    zones: _zones,
                    selectedZoneId: _selectedZoneId,
                    onVertexChanged: _updateVertex,
                    overrideBytes: _wanPreviewBytes,
                    labelFor: _defaultLabel,
                    drawEnabled: _zones.length < maxParkingZones,
                    onZoneTraced: _addTracedZone,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      key: const Key('PARK-004'),
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
                    key: const Key('PARK-005'),
                    title: const Text('Parking monitoring'),
                    subtitle: const Text(
                      'Zones can still be configured while this is off',
                    ),
                    value: _enabled,
                    onChanged: (value) => _markDirty(() => _enabled = value),
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  key: const Key('PARK-016'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Configured zones',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Slots: ${slotZones.length} configured',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'Open areas: ${openAreaZones.length} configured'
                        '${configuredCapacity > 0 ? ' · capacity $configuredCapacity' : ''}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'Restricted: ${restrictedZones.length} zones',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Live occupancy needs camera support — not '
                        'available yet',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_hasRestrictedZone) ...[
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Alert after ${_restrictedDwellSeconds}s in a '
                          'restricted zone',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'Avoids flagging a vehicle briefly cutting across '
                          'the area — only a vehicle that stays this long '
                          'is a violation',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Slider(
                          key: const Key('PARK-012'),
                          value: _restrictedDwellSeconds.toDouble(),
                          min: 0,
                          max: 600,
                          divisions: 60,
                          onChanged: (value) => _markDirty(
                            () => _restrictedDwellSeconds = value.round(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_hasSlotZone) ...[
                  const SizedBox(height: 12),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Flag wrong bay after ${_wrongBayDwellSeconds}s',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          'A vehicle briefly straddling a neighboring '
                          'slot\'s line while parking isn\'t a violation — '
                          'still straddling after this long is',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Slider(
                          key: const Key('PARK-013'),
                          value: _wrongBayDwellSeconds.toDouble(),
                          min: 0,
                          max: 600,
                          divisions: 60,
                          onChanged: (value) => _markDirty(
                            () => _wrongBayDwellSeconds = value.round(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  key: const Key('PARK-006'),
                  children: [
                    Expanded(
                      child: ModeTile(
                        icon: Icons.directions_car_filled,
                        label: 'Parking Slot',
                        selected: _newZoneType == ParkingZoneType.slot,
                        onTap: () =>
                            setState(() => _newZoneType = ParkingZoneType.slot),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ModeTile(
                        icon: Icons.crop_free,
                        label: 'Open Area',
                        selected: _newZoneType == ParkingZoneType.openArea,
                        onTap: () => setState(
                          () => _newZoneType = ParkingZoneType.openArea,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ModeTile(
                        icon: Icons.block,
                        label: 'Restricted',
                        selected: _newZoneType == ParkingZoneType.restricted,
                        onTap: () => setState(
                          () => _newZoneType = ParkingZoneType.restricted,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Zones (${_zones.length}/$maxParkingZones)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    TextButton.icon(
                      key: const Key('PARK-007'),
                      onPressed: _zones.length < maxParkingZones
                          ? _addDefaultZone
                          : null,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add zone'),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '"Add zone" drops a ready-to-adjust 5-point shape you '
                    'can drag into place, or drag a finger directly on the '
                    'preview above to trace a custom outline in one go.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 8),
                if (_zones.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'No zones yet. Pick a type above, then "Add zone" for '
                      'a ready-made shape, or trace your own on the preview.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
                else
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      key: const Key('PARK-009'),
                      children: [
                        for (var i = 0; i < _zones.length; i++)
                          _ParkingZoneTile(
                            zone: _zones[i],
                            label: _zones[i].label ?? _defaultLabel(_zones[i]),
                            selected: _zones[i].id == _selectedZoneId,
                            isLast: i == _zones.length - 1,
                            onTap: () => _selectZone(_zones[i].id),
                            onDelete: () => _deleteZone(_zones[i].id),
                            onRename: (label) =>
                                _renameZone(_zones[i].id, label),
                            onCapacityChanged: (capacity) =>
                                _setEstimatedCapacity(_zones[i].id, capacity),
                            labelFieldKey: const Key('PARK-014'),
                            capacityFieldKey: const Key('PARK-015'),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('PARK-010'),
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
                        key: const Key('PARK-011'),
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

Color _zoneColor(ParkingZoneType type) => switch (type) {
  ParkingZoneType.slot => Colors.lightBlueAccent,
  ParkingZoneType.openArea => Colors.tealAccent,
  ParkingZoneType.restricted => Colors.redAccent,
};

IconData _zoneIcon(ParkingZoneType type) => switch (type) {
  ParkingZoneType.slot => Icons.directions_car_filled,
  ParkingZoneType.openArea => Icons.crop_free,
  ParkingZoneType.restricted => Icons.block,
};

class _ParkingPreview extends StatelessWidget {
  const _ParkingPreview({
    super.key,
    required this.settingsKey,
    required this.camera,
    required this.zones,
    required this.selectedZoneId,
    required this.onVertexChanged,
    required this.labelFor,
    required this.drawEnabled,
    required this.onZoneTraced,
    this.overrideBytes,
  });

  final Key settingsKey;
  final Camera camera;
  final List<ParkingZone> zones;
  final int? selectedZoneId;
  final void Function(int vertexIndex, Offset offset) onVertexChanged;
  final String Function(ParkingZone zone) labelFor;
  final bool drawEnabled;
  final ValueChanged<List<Offset>> onZoneTraced;
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
                        PolygonDrawSurface(
                          key: const Key('PARK-018'),
                          areaSize: areaSize,
                          enabled: drawEnabled,
                          onZoneDrawn: onZoneTraced,
                        ),
                        for (final zone in zones) ...[
                          PolygonOverlay(
                            key: ValueKey(zone.id),
                            zone: PolygonZone(id: zone.id, points: zone.points),
                            areaSize: areaSize,
                            selected: zone.id == selectedZoneId,
                            unselectedColor: _zoneColor(zone.type),
                            onVertexChanged: onVertexChanged,
                          ),
                          if (zone.points.isNotEmpty)
                            _ZoneLabelChip(
                              position: Offset(
                                zone.points.first.dx * areaSize.width,
                                zone.points.first.dy * areaSize.height,
                              ),
                              label: labelFor(zone),
                              color: _zoneColor(zone.type),
                              icon: _zoneIcon(zone.type),
                            ),
                        ],
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

class _ZoneLabelChip extends StatelessWidget {
  const _ZoneLabelChip({
    required this.position,
    required this.label,
    required this.color,
    required this.icon,
  });

  final Offset position;
  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position.dx,
      top: position.dy - 28,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A zone row in [ParkingMonitoringScreen]'s zone list — extends the shared
/// `PolygonZoneListTile` pattern with an inline expand-on-select editor for
/// PARK-014 (label) and, for Open Area zones only, PARK-015 (capacity).
class _ParkingZoneTile extends StatefulWidget {
  const _ParkingZoneTile({
    required this.zone,
    required this.label,
    required this.selected,
    required this.isLast,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
    required this.onCapacityChanged,
    required this.labelFieldKey,
    required this.capacityFieldKey,
  });

  final ParkingZone zone;
  final String label;
  final bool selected;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final ValueChanged<String> onRename;
  final ValueChanged<int?> onCapacityChanged;
  final Key labelFieldKey;
  final Key capacityFieldKey;

  @override
  State<_ParkingZoneTile> createState() => _ParkingZoneTileState();
}

class _ParkingZoneTileState extends State<_ParkingZoneTile> {
  late final _labelController = TextEditingController(
    text: widget.zone.label ?? '',
  );
  late final _capacityController = TextEditingController(
    text: widget.zone.estimatedCapacity?.toString() ?? '',
  );

  @override
  void dispose() {
    _labelController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: widget.isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
      child: Column(
        children: [
          Material(
            color: widget.selected
                ? colorScheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
            child: InkWell(
              onTap: widget.onTap,
              child: ListTile(
                leading: Icon(
                  _zoneIcon(widget.zone.type),
                  color: _zoneColor(widget.zone.type),
                ),
                title: Text(widget.label),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete zone',
                  onPressed: widget.onDelete,
                ),
              ),
            ),
          ),
          if (widget.selected)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: widget.labelFieldKey,
                    controller: _labelController,
                    decoration: const InputDecoration(
                      labelText: 'Zone label',
                      isDense: true,
                    ),
                    onSubmitted: widget.onRename,
                    onEditingComplete: () =>
                        widget.onRename(_labelController.text),
                  ),
                  if (widget.zone.type == ParkingZoneType.openArea) ...[
                    const SizedBox(height: 8),
                    TextField(
                      key: widget.capacityFieldKey,
                      controller: _capacityController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Estimated capacity',
                        isDense: true,
                        helperText:
                            'How many vehicles this area roughly fits — '
                            'there are no painted lines to count',
                      ),
                      onSubmitted: (value) =>
                          widget.onCapacityChanged(int.tryParse(value)),
                      onEditingComplete: () => widget.onCapacityChanged(
                        int.tryParse(_capacityController.text),
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}
