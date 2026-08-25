import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../app_state/camera_sync.dart';
import '../../app_state/homes_controller.dart';
import '../../models/camera.dart';
import '../../widgets/camera_preview_thumbnail.dart';
import '../../widgets/fixed_preview_layout.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/live_status_badges.dart';
import '../../widgets/navigation_leave_guard.dart';
import '../../widgets/refresh_preview_button.dart';
import '../../widgets/saving_overlay.dart';
import '../../widgets/settings_save_button.dart';

extension on OsdCorner {
  String get label => switch (this) {
    OsdCorner.topLeft => 'Top left',
    OsdCorner.topRight => 'Top right',
    OsdCorner.bottomLeft => 'Bottom left',
    OsdCorner.bottomRight => 'Bottom right',
  };
}

/// Tags: Bitrate and Signal Strength — small status badges composited by
/// the mobile app on top of the stream (not sent to or rendered by the
/// camera), each independently toggled and positioned at a fixed preview
/// corner. Live Tag is always pinned to the top-left corner. Written
/// through [homesController] so they take effect immediately on the Camera
/// Live page. No CCTV protocol/backend is wired up yet (see CLAUDE.md).
class TagsScreen extends StatefulWidget {
  const TagsScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'tags';

  final Camera camera;
  final HomesController homesController;

  @override
  State<TagsScreen> createState() => _TagsScreenState();
}

class _TagsScreenState extends State<TagsScreen> {
  late bool _bitrateOsdEnabled = widget.camera.bitrateOsdEnabled;
  late OsdCorner _bitrateOsdPosition = widget.camera.bitrateOsdPosition;
  late bool _signalStrengthOsdEnabled = widget.camera.signalStrengthOsdEnabled;
  late OsdCorner _signalStrengthOsdPosition =
      widget.camera.signalStrengthOsdPosition;
  late bool _liveTagOsdEnabled = widget.camera.liveTagOsdEnabled;
  bool _isDirty = false;
  bool _isSaving = false;
  bool _isRefreshing = false;
  int _previewReloadKey = 0;
  Uint8List? _wanPreviewBytes;

  String get _homeId {
    return widget.homesController.value.homes
        .firstWhere((home) => home.cameras.any((c) => c.id == widget.camera.id))
        .id;
  }

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
      widget.homesController.updateCameraOsdSettings(
        _homeId,
        widget.camera.id,
        bitrateOsdEnabled: _bitrateOsdEnabled,
        bitrateOsdPosition: _bitrateOsdPosition,
        signalStrengthOsdEnabled: _signalStrengthOsdEnabled,
        signalStrengthOsdPosition: _signalStrengthOsdPosition,
        liveTagOsdEnabled: _liveTagOsdEnabled,
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
    dialogKey: const Key('TAG-013'),
    discardKey: const Key('TAG-014'),
    saveKey: const Key('TAG-015'),
  );

  @override
  Widget build(BuildContext context) {
    return LeaveGuard(
      canLeave: _confirmLeave,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            key: const Key('TAG-001'),
            title: const Text('Tags'),
            actions: [
              SettingsSaveButton(
                settingsKey: const Key('TAG-002'),
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
                  _TagsPreview(
                    key: ValueKey(_previewReloadKey),
                    settingsKey: const Key('TAG-003'),
                    camera: _camera,
                    bitrateOsdEnabled: _bitrateOsdEnabled,
                    bitrateOsdPosition: _bitrateOsdPosition,
                    signalStrengthOsdEnabled: _signalStrengthOsdEnabled,
                    signalStrengthOsdPosition: _signalStrengthOsdPosition,
                    liveTagOsdEnabled: _liveTagOsdEnabled,
                    overrideBytes: _wanPreviewBytes,
                  ),
                  const SizedBox(height: 8),
                  RefreshPreviewButton(
                    settingsKey: const Key('TAG-012'),
                    isRefreshing: _isRefreshing,
                    onPressed: _refreshPreview,
                  ),
                ],
              ),
              scrollableChildren: [
                GlassCard(
                  padding: EdgeInsets.zero,
                  child: SwitchListTile(
                    key: const Key('TAG-005'),
                    title: const Text('Live tag'),
                    subtitle: const Text(
                      'Shown on the Camera Live page by the app, not sent to '
                      'the camera. Always pinned to the top-left corner.',
                    ),
                    value: _liveTagOsdEnabled,
                    onChanged: (value) =>
                        _markDirty(() => _liveTagOsdEnabled = value),
                  ),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SwitchListTile(
                        key: const Key('TAG-004'),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Bitrate'),
                        subtitle: const Text(
                          'Shown on the Camera Live page by the app, not '
                          'sent to the camera',
                        ),
                        value: _bitrateOsdEnabled,
                        onChanged: (value) =>
                            _markDirty(() => _bitrateOsdEnabled = value),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<OsdCorner>(
                        key: const Key('TAG-006'),
                        initialValue: _bitrateOsdPosition,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Position',
                        ),
                        items: [
                          for (final corner in OsdCorner.values)
                            DropdownMenuItem(
                              value: corner,
                              child: Text(corner.label),
                            ),
                        ],
                        onChanged: _bitrateOsdEnabled
                            ? (value) =>
                                  _markDirty(() => _bitrateOsdPosition = value!)
                            : null,
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
                        key: const Key('TAG-007'),
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Signal strength'),
                        subtitle: const Text(
                          'Shown on the Camera Live page by the app, not '
                          'sent to the camera',
                        ),
                        value: _signalStrengthOsdEnabled,
                        onChanged: (value) =>
                            _markDirty(() => _signalStrengthOsdEnabled = value),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<OsdCorner>(
                        key: const Key('TAG-008'),
                        initialValue: _signalStrengthOsdPosition,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Position',
                        ),
                        items: [
                          for (final corner in OsdCorner.values)
                            DropdownMenuItem(
                              value: corner,
                              child: Text(corner.label),
                            ),
                        ],
                        onChanged: _signalStrengthOsdEnabled
                            ? (value) => _markDirty(
                                () => _signalStrengthOsdPosition = value!,
                              )
                            : null,
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

class _TagsPreview extends StatelessWidget {
  const _TagsPreview({
    super.key,
    required this.settingsKey,
    required this.camera,
    required this.bitrateOsdEnabled,
    required this.bitrateOsdPosition,
    required this.signalStrengthOsdEnabled,
    required this.signalStrengthOsdPosition,
    required this.liveTagOsdEnabled,
    this.overrideBytes,
  });

  final Key settingsKey;
  final Camera camera;
  final bool bitrateOsdEnabled;
  final OsdCorner bitrateOsdPosition;
  final bool signalStrengthOsdEnabled;
  final OsdCorner signalStrengthOsdPosition;
  final bool liveTagOsdEnabled;
  final Uint8List? overrideBytes;

  @override
  Widget build(BuildContext context) {
    // Live tag is always top-left; Bitrate/Signal Strength are
    // user-positioned. Compute stack indices across all enabled tags so any
    // that land on the same corner stack instead of overlapping.
    final entries = [
      if (liveTagOsdEnabled) OsdCorner.topLeft,
      if (bitrateOsdEnabled) bitrateOsdPosition,
      if (signalStrengthOsdEnabled) signalStrengthOsdPosition,
    ];
    final stackIndices = osdStackIndices(entries);
    var i = 0;

    return Stack(
      key: settingsKey,
      children: [
        CameraPreviewThumbnail(
          settingsKey: const Key('TAG-003-image'),
          camera: camera,
          overrideBytes: overrideBytes,
        ),
        if (liveTagOsdEnabled)
          osdPositioned(
            OsdCorner.topLeft,
            stackIndex: stackIndices[i++],
            child: const LiveStatusBadge(status: CameraLiveStatus.online),
          ),
        if (bitrateOsdEnabled)
          osdPositioned(
            bitrateOsdPosition,
            stackIndex: stackIndices[i++],
            child: BitrateBadge(configuredKbps: camera.bitrateKbps),
          ),
        if (signalStrengthOsdEnabled)
          osdPositioned(
            signalStrengthOsdPosition,
            stackIndex: stackIndices[i++],
            child: SignalStrengthBadge(
              signalStrength: camera.signalStrength,
              networkSpeedKbps: camera.networkSpeedKbps,
            ),
          ),
      ],
    );
  }
}
