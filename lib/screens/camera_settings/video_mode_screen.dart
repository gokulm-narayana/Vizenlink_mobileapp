import 'dart:async';

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

/// `CameraVideoMode` <-> ONVIF `IrCutFilter` wire values (`ON` = day, `OFF` =
/// night, `AUTO` = auto) — see `OnvifImagingClient.ImagingSettings
/// .irCutFilterMode`'s doc.
String _videoModeToIrCutFilter(CameraVideoMode mode) => switch (mode) {
  CameraVideoMode.day => 'ON',
  CameraVideoMode.night => 'OFF',
  CameraVideoMode.auto => 'AUTO',
};

CameraVideoMode? _irCutFilterToVideoMode(String? wireValue) =>
    switch (wireValue?.toUpperCase()) {
      'ON' => CameraVideoMode.day,
      'OFF' => CameraVideoMode.night,
      'AUTO' => CameraVideoMode.auto,
      _ => null,
    };

/// Video Mode: preview thumbnail plus Day/Auto/Night selection, backed by
/// ONVIF's `IrCutFilter` setting (`OnvifImagingClient`) when this camera has
/// a saved connection — falls back to local-only `HomesController` state
/// (via `simulateCameraSave`) otherwise, same as before. WAN fallback
/// (`WanImagingClient.getDayNightMode`/`setDayNightMode`) isn't wired up yet.
class VideoModeScreen extends StatefulWidget {
  const VideoModeScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'video-mode';

  final Camera camera;
  final HomesController homesController;

  @override
  State<VideoModeScreen> createState() => _VideoModeScreenState();
}

class _VideoModeScreenState extends State<VideoModeScreen> {
  late CameraVideoMode _mode = _camera.videoMode;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _isRefreshing = false;
  int _previewReloadKey = 0;

  /// The camera's own supported `IrCutFilter` values (`OnvifImagingClient
  /// .getImagingOptions`), fetched once a connection is available. Null
  /// means "camera not verified yet" — show every tile rather than none,
  /// same reasoning as `_dummyTimezones`'s fallback in camera_info_screen.
  List<String>? _irCutFilterModes;

  @override
  void initState() {
    super.initState();
    _loadRealVideoMode();
  }

  Future<void> _loadRealVideoMode() async {
    final connection = _camera.connection;
    if (connection == null) return;
    final client = OnvifImagingClient(connection);
    final results = await Future.wait([
      client.getImagingSettings(),
      client.getImagingOptions(),
    ]);
    client.close();
    if (!mounted) return;

    final settingsResult = results[0] as CameraResult<ImagingSettings>;
    final optionsResult = results[1] as CameraResult<ImagingOptions>;

    setState(() {
      if (settingsResult case CameraSuccess(:final value)) {
        final mode = _irCutFilterToVideoMode(value.irCutFilterMode);
        if (mode != null) _mode = mode;
      }
      if (optionsResult case CameraSuccess(:final value)) {
        _irCutFilterModes = value.irCutFilterModes;
      }
    });

    if (settingsResult case CameraSuccess()) {
      widget.homesController.updateCamera(
        widget.camera.id,
        (camera) => camera.copyWith(videoMode: _mode),
      );
    }
  }

  void _onModeChanged(CameraVideoMode? value) {
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
    final connection = _camera.connection;
    setState(() => _isSaving = true);

    final bool succeeded;
    if (connection != null) {
      final client = OnvifImagingClient(connection);
      final result = await client.setImagingSettings(
        ImagingSettings(irCutFilterMode: _videoModeToIrCutFilter(_mode)),
      );
      client.close();
      succeeded = result is CameraSuccess;
    } else {
      succeeded = await simulateCameraSave();
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (succeeded) {
      widget.homesController.updateCamera(
        widget.camera.id,
        (camera) => camera.copyWith(videoMode: _mode),
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
    dialogKey: const Key('VIDMODE-008'),
    discardKey: const Key('VIDMODE-009'),
    saveKey: const Key('VIDMODE-010'),
  );

  @override
  Widget build(BuildContext context) {
    return LeaveGuard(
      canLeave: _confirmLeave,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            key: const Key('VIDMODE-001'),
            title: const Text('Video Mode'),
            actions: [
              SettingsSaveButton(
                settingsKey: const Key('VIDMODE-005'),
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
                    settingsKey: const Key('VIDMODE-003'),
                    camera: _camera,
                  ),
                  const SizedBox(height: 8),
                  RefreshPreviewButton(
                    settingsKey: const Key('VIDMODE-007'),
                    isRefreshing: _isRefreshing,
                    onPressed: _refreshPreview,
                  ),
                ],
              ),
              scrollableChildren: [
                Row(
                  key: const Key('VIDMODE-004'),
                  children: [
                    for (final entry in [
                      (CameraVideoMode.day, Icons.wb_sunny, 'Day'),
                      (CameraVideoMode.auto, Icons.brightness_auto, 'Auto'),
                      (CameraVideoMode.night, Icons.nightlight_round, 'Night'),
                    ])
                      // Only render a mode this camera's own Options response
                      // actually reports — never a hardcoded fixed set, per
                      // .claude/rules/mobile-app-screen-conventions.md. Shows
                      // all three when unverified (no connection yet).
                      if (_irCutFilterModes == null ||
                          _irCutFilterModes!.contains(
                            _videoModeToIrCutFilter(entry.$1),
                          )) ...[
                        Expanded(
                          child: ModeTile(
                            icon: entry.$2,
                            label: entry.$3,
                            selected: _mode == entry.$1,
                            onTap: () => _onModeChanged(entry.$1),
                          ),
                        ),
                        if (entry.$1 != CameraVideoMode.night)
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
