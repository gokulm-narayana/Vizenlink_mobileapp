import 'dart:async';
import 'dart:typed_data';

import 'package:camera_api/camera_api.dart';
import 'package:flutter/material.dart';

import '../../app_state/camera_sync.dart';
import '../../app_state/homes_controller.dart';
import '../../models/camera.dart';
import '../../widgets/camera_preview_thumbnail.dart';
import '../../widgets/fixed_preview_layout.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/mode_tile.dart';
import '../../widgets/navigation_leave_guard.dart';
import '../../widgets/refresh_preview_button.dart';
import '../../widgets/saving_overlay.dart';
import '../../widgets/settings_save_button.dart';

/// `CameraNightMode` <-> `NightVisionType` (`grey` = Infrared, `color` = Full
/// Color, `smart` = Smart).
NightVisionType _nightModeToType(CameraNightMode mode) => switch (mode) {
  CameraNightMode.infrared => NightVisionType.grey,
  CameraNightMode.fullColor => NightVisionType.color,
  CameraNightMode.smart => NightVisionType.smart,
};

CameraNightMode _typeToNightMode(NightVisionType type) => switch (type) {
  NightVisionType.grey => CameraNightMode.infrared,
  NightVisionType.color => CameraNightMode.fullColor,
  NightVisionType.smart => CameraNightMode.smart,
};

/// Night Mode: preview thumbnail plus Infrared/Smart/Full Color selection,
/// backed by `NightVisionClient` (`GetNightVisionType`/`SetNightVisionType`)
/// when this camera has a saved connection — falls back to local-only
/// `HomesController` state (via `simulateCameraSave`) otherwise, same as
/// before. LAN is always tried first for both load and save; a WAN retry
/// (`WanNightVisionClient`) only kicks in when the LAN call itself
/// fails/times out and `connection.thingName` is known, per
/// `.claude/rules/mobile-app-screen-conventions.md`'s LAN/WAN convention.
class NightModeScreen extends StatefulWidget {
  const NightModeScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'night-mode';

  final Camera camera;
  final HomesController homesController;

  @override
  State<NightModeScreen> createState() => _NightModeScreenState();
}

class _NightModeScreenState extends State<NightModeScreen> {
  late CameraNightMode _mode = _camera.nightMode;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _isRefreshing = false;
  int _previewReloadKey = 0;

  /// A transient WAN preview fetched when [_refreshPreview]'s LAN attempt
  /// fails — never persisted (see `fetchWanPreviewSnapshot`'s doc), just
  /// held here for as long as this screen is open. Cleared once a LAN
  /// refresh succeeds again, so the persisted (and now fresher) thumbnail
  /// takes back over.
  Uint8List? _wanPreviewBytes;

  /// Hardware/firmware capability flags from the camera's own
  /// `GetNightVisionType` response — null means "camera not verified yet",
  /// in which case every tile shows (same fallback reasoning as
  /// `_dummyTimezones` in camera_info_screen). Unlike Video Mode, no
  /// separate Options call exists for this — the capability flags ride
  /// along with the current-value response itself.
  late bool? _colorCapable = _camera.nightVisionColorCapable;
  late bool? _smartCapable = _camera.nightVisionSmartCapable;

  @override
  void initState() {
    super.initState();
    _loadRealNightMode();
  }

  Future<void> _loadRealNightMode() async {
    final connection = _camera.connection;
    if (connection == null) return;
    final nuraeye = NuraeyeClient(connection);
    var result = await NightVisionClient(nuraeye).getNightVisionType();
    nuraeye.close();

    final thingName = connection.thingName;
    if (result is! CameraSuccess && thingName != null) {
      result = await WanNightVisionClient(thingName).getNightVisionType();
    }
    if (!mounted) return;
    if (result case CameraSuccess(:final value)) {
      setState(() {
        _mode = _typeToNightMode(value.type);
        _colorCapable = value.colorCapable;
        _smartCapable = value.smartCapable;
      });
      widget.homesController.updateCamera(
        widget.camera.id,
        (camera) => camera.copyWith(
          nightMode: _typeToNightMode(value.type),
          nightVisionColorCapable: value.colorCapable,
          nightVisionSmartCapable: value.smartCapable,
        ),
      );
    }
  }

  void _onModeChanged(CameraNightMode? value) {
    if (value == null) return;
    setState(() {
      _mode = value;
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
    // LAN/WAN convention. The last-shown preview (whether the persisted
    // thumbnail or a previous WAN frame) stays on screen until this
    // resolves, not blanked out mid-refresh.
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
    final connection = _camera.connection;
    setState(() => _isSaving = true);

    final bool succeeded;
    if (connection != null) {
      final nuraeye = NuraeyeClient(connection);
      var result = await NightVisionClient(
        nuraeye,
      ).setNightVisionType(_nightModeToType(_mode));
      nuraeye.close();

      // A failed LAN Apply/Set retries over WAN before surfacing an error,
      // per mobile-app-screen-conventions.md's LAN/WAN convention.
      final thingName = connection.thingName;
      if (result is! CameraSuccess && thingName != null) {
        result = await WanNightVisionClient(
          thingName,
        ).setNightVisionType(_nightModeToType(_mode));
      }
      succeeded = result is CameraSuccess;
    } else {
      succeeded = await simulateCameraSave();
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (succeeded) {
      widget.homesController.updateCamera(
        widget.camera.id,
        (camera) => camera.copyWith(nightMode: _mode),
      );
      setState(() => _isDirty = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Changes saved')));
      if (connection != null) unawaited(_refreshPreview());
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
    dialogKey: const Key('NIGHT-008'),
    discardKey: const Key('NIGHT-009'),
    saveKey: const Key('NIGHT-010'),
  );

  @override
  Widget build(BuildContext context) {
    return LeaveGuard(
      canLeave: _confirmLeave,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            key: const Key('NIGHT-001'),
            title: const Text('Night Mode'),
            actions: [
              SettingsSaveButton(
                settingsKey: const Key('NIGHT-004'),
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
                  CameraPreviewThumbnail(
                    key: ValueKey(_previewReloadKey),
                    settingsKey: const Key('NIGHT-005'),
                    camera: _camera,
                    overrideBytes: _wanPreviewBytes,
                  ),
                  const SizedBox(height: 8),
                  RefreshPreviewButton(
                    settingsKey: const Key('NIGHT-007'),
                    isRefreshing: _isRefreshing,
                    onPressed: _refreshPreview,
                  ),
                ],
              ),
              scrollableChildren: [
                Row(
                  key: const Key('NIGHT-006'),
                  children: [
                    // Infrared (grey) is the baseline capability, always
                    // shown. Smart/Full Color are gated on the camera's own
                    // reported capability flags — never hardcoded — per
                    // .claude/rules/mobile-app-screen-conventions.md. Shows
                    // both when unverified (no connection yet, `null`).
                    for (final entry in [
                      (
                        CameraNightMode.infrared,
                        Icons.nightlight,
                        'Infrared',
                        true,
                      ),
                      (
                        CameraNightMode.smart,
                        Icons.auto_awesome,
                        'Smart',
                        _smartCapable != false,
                      ),
                      (
                        CameraNightMode.fullColor,
                        Icons.palette,
                        'Full Color',
                        _colorCapable != false,
                      ),
                    ])
                      if (entry.$4) ...[
                        Expanded(
                          child: ModeTile(
                            icon: entry.$2,
                            label: entry.$3,
                            selected: _mode == entry.$1,
                            onTap: () => _onModeChanged(entry.$1),
                          ),
                        ),
                        if (entry.$1 != CameraNightMode.fullColor)
                          const SizedBox(width: 12),
                      ],
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
