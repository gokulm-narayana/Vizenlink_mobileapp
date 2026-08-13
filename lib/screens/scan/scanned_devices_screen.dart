import 'dart:async';

import 'package:camera_api/camera_api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../app_state/camera_scan.dart';
import '../../app_state/camera_sync.dart';
import '../../app_state/homes_controller.dart';
import '../../models/scanned_camera.dart';
import '../../theme/app_colors.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/gradient_button.dart';
import 'scanning_popup.dart';

class ScannedDevicesScreen extends StatefulWidget {
  const ScannedDevicesScreen({
    super.key,
    required this.homesController,
    this.initialResults,
    this.scan = scanForCameras,
    this.httpClient,
  });

  static const routeName = 'scan';

  final HomesController homesController;

  /// Results from a scan the caller already ran (the Dashboard's scanning
  /// popup — see `dashboard_screen.dart`'s `_startAddCameraFlow`) — when
  /// present, skips this screen's own initial scan entirely rather than
  /// running `scanForCameras()` a second time back-to-back.
  final List<ScannedCamera>? initialResults;

  /// Defaults to the real [scanForCameras] (LAN WS-Discovery over UDP
  /// sockets) — overridable so tests can supply canned results instead of
  /// hitting real network hardware, which isn't available in a sandboxed
  /// test environment (see `scan_cameras_screen.md`'s Notes).
  final Future<List<ScannedCamera>> Function() scan;

  /// Threaded into every `OnvifDeviceClient` this screen constructs for the
  /// setup form's real credential verification (`OnvifDeviceClient.
  /// getDeviceInformation` and friends) — `null` means the real HTTP
  /// client. Overridable for the same reason as [scan]: tests can supply a
  /// `MockClient` instead of calling a real camera.
  final http.Client? httpClient;

  @override
  State<ScannedDevicesScreen> createState() => _ScannedDevicesScreenState();
}

class _ScannedDevicesScreenState extends State<ScannedDevicesScreen> {
  late List<ScannedCamera> _found = widget.initialResults ?? const [];
  late bool _loading = widget.initialResults == null;

  @override
  void initState() {
    super.initState();
    if (widget.initialResults == null) _loadInitial();
  }

  Future<void> _loadInitial() async {
    final results = await widget.scan();
    if (!mounted) return;
    setState(() {
      _found = results;
      _loading = false;
    });
  }

  Future<void> _rescan() async {
    final scanFuture = widget.scan();
    await showScanningPopup(context);
    final results = await scanFuture;
    if (!mounted) return;
    setState(() => _found = results);
  }

  Future<void> _handleTap(ScannedCamera camera) async {
    if (camera.isConfigured) {
      await _showSetupForm(
        camera,
        prefillUsername: null,
        prefillPassword: null,
        requireConfirm: false,
      );
      return;
    }

    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return _GlassDialog(
          key: const Key('SCAN-007'),
          title: camera.name,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'This camera is factory-reset. How would you like to set it up?',
                style: Theme.of(dialogContext).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () => Navigator.of(dialogContext).pop('default'),
                child: const Text('Connect with default credentials'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => Navigator.of(dialogContext).pop('change'),
                child: const Text('Change credentials'),
              ),
            ],
          ),
        );
      },
    );

    if (action == null) return;

    if (action == 'default') {
      await _showSetupForm(
        camera,
        prefillUsername: kScanDefaultUsername,
        prefillPassword: kScanDefaultPassword,
        requireConfirm: false,
      );
    } else {
      await _showSetupForm(
        camera,
        prefillUsername: kScanDefaultUsername,
        prefillPassword: '',
        requireConfirm: true,
      );
    }
  }

  Future<void> _showSetupForm(
    ScannedCamera camera, {
    required String? prefillUsername,
    required String? prefillPassword,
    required bool requireConfirm,
  }) async {
    final rooms = widget.homesController.value.selectedHome.rooms;
    final usernameController = TextEditingController(
      text: prefillUsername ?? '',
    );
    final passwordController = TextEditingController(
      text: prefillPassword ?? '',
    );
    final confirmPasswordController = TextEditingController(
      text: prefillPassword ?? '',
    );
    String? selectedRoom = rooms.isNotEmpty ? rooms.first : null;
    String? errorText;
    bool verifying = false;
    DeviceInformation? verifiedInfo;
    String? verifiedMacAddress;
    String? verifiedThingName;
    String? verifiedName;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return _GlassDialog(
              key: const Key('SCAN-010'),
              title: camera.name,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: requireConfirm ? 'New password' : 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                    ),
                  ),
                  if (requireConfirm) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Confirm password',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (rooms.isEmpty)
                    Text(
                      'This home has no rooms yet. The camera will be added without a room.',
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    )
                  else
                    DropdownButtonFormField<String?>(
                      initialValue: selectedRoom,
                      decoration: const InputDecoration(
                        labelText: 'Room',
                        prefixIcon: Icon(Icons.meeting_room_outlined),
                      ),
                      items: [
                        for (final room in rooms)
                          DropdownMenuItem<String?>(
                            value: room,
                            child: Text(room),
                          ),
                      ],
                      onChanged: (value) =>
                          setDialogState(() => selectedRoom = value),
                    ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      errorText!,
                      style: TextStyle(
                        color: Theme.of(dialogContext).colorScheme.error,
                      ),
                    ),
                  ],
                  if (verifying) ...[
                    const SizedBox(height: 16),
                    const Center(
                      child: SizedBox(
                        key: Key('SCAN-012'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  GradientButton(
                    onPressed: verifying
                        ? null
                        : () async {
                            if (requireConfirm &&
                                passwordController.text !=
                                    confirmPasswordController.text) {
                              setDialogState(
                                () => errorText = 'Passwords do not match',
                              );
                              return;
                            }

                            setDialogState(() {
                              verifying = true;
                              errorText = null;
                            });

                            final connection = CameraConnection(
                              host: camera.ipAddress,
                              username: usernameController.text,
                              password: passwordController.text,
                            );
                            final deviceClient = OnvifDeviceClient(
                              connection,
                              httpClient: widget.httpClient,
                            );
                            final infoResult = await deviceClient
                                .getDeviceInformation();

                            final failureMessage = switch (infoResult) {
                              CameraSuccess(:final value) => () {
                                verifiedInfo = value;
                                return null;
                              }(),
                              CameraFailure(:final reason) => reason,
                              CameraTimeout() =>
                                'Camera did not respond. Check the '
                                    'username/password and try again.',
                            };

                            if (failureMessage != null) {
                              deviceClient.close();
                              if (!dialogContext.mounted) return;
                              setDialogState(() {
                                verifying = false;
                                errorText = failureMessage;
                              });
                              return;
                            }

                            // Best-effort — a WAN thing name or MAC address
                            // isn't required for the camera to be usable over
                            // LAN, so a failure here doesn't block setup.
                            switch (await deviceClient.getSerialNumber()) {
                              case CameraSuccess(:final value):
                                verifiedThingName = value;
                              case CameraFailure() || CameraTimeout():
                                break;
                            }
                            switch (await deviceClient
                                .getNetworkInterfaceInfo()) {
                              case CameraSuccess(:final value):
                                verifiedMacAddress = value.macAddress;
                              case CameraFailure() || CameraTimeout():
                                break;
                            }
                            // The camera's actually-configured display name
                            // (ONVIF GetScopes) — falls back to whatever name
                            // was already showing (the scan-list entry, or
                            // this dialog's title) if the camera has none set
                            // yet (empty scope) or this call fails.
                            switch (await deviceClient.getDeviceIdentity()) {
                              case CameraSuccess(:final value)
                                  when value.name.isNotEmpty:
                                verifiedName = value.name;
                              case CameraSuccess() ||
                                  CameraFailure() ||
                                  CameraTimeout():
                                break;
                            }
                            deviceClient.close();

                            if (!dialogContext.mounted) return;
                            Navigator.of(dialogContext).pop(true);
                          },
                    child: const Text('Connect'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: verifying
                        ? null
                        : () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    final enteredUsername = usernameController.text;
    final enteredPassword = passwordController.text;

    // showDialog's Future resolves as soon as Navigator.pop() is called, not
    // after the dialog's exit transition actually finishes — its TextFields
    // (and their bound controllers) are still mounted and animating out for
    // a short time after this point. Disposing immediately intermittently
    // crashed with "TextEditingController used after being disposed" once
    // Connect started taking several real seconds (credential verification)
    // instead of closing instantly. 300ms comfortably clears Material's
    // ~150ms default dialog transition.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    if (confirmed != true) return;

    final newCamera = widget.homesController.addCamera(
      widget.homesController.value.selectedHome.id,
      name: verifiedName ?? camera.name,
      room: selectedRoom,
      isOnline: true,
      host: camera.ipAddress,
      username: enteredUsername,
      password: enteredPassword,
      manufacturer: verifiedInfo?.manufacturer,
      model: verifiedInfo?.model,
      firmwareVersion: verifiedInfo?.firmwareVersion,
      serialNumber: verifiedInfo?.serialNumber,
      hardwareId: verifiedInfo?.hardwareId,
      macAddress: verifiedMacAddress,
      thingName: verifiedThingName,
    );

    // Fire-and-forget: enriches the camera with fields the Connect-time
    // check above doesn't fetch (timezone, a real snapshot) without making
    // the user wait through a second multi-second round trip before
    // returning to the Dashboard. Safe to leave running after this screen
    // pops — it only touches homesController, no BuildContext.
    final syncConnection = newCamera.connection;
    if (syncConnection != null) {
      unawaited(
        syncCameraFromDevice(
          homesController: widget.homesController,
          cameraId: newCamera.id,
          connection: syncConnection,
        ),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          key: const Key('SCAN-003'),
          title: const Text('Scanned devices'),
          actions: [
            IconButton(
              key: const Key('SCAN-006'),
              tooltip: 'Rescan',
              icon: const Icon(Icons.refresh),
              onPressed: _rescan,
            ),
          ],
        ),
        body: _buildResults(context),
      ),
    );
  }

  Widget _buildResults(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(key: Key('SCAN-011')),
      );
    }

    if (_found.isEmpty) {
      return Center(
        child: Text(
          key: const Key('SCAN-005'),
          'No cameras found on the network.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    return ListView.builder(
      key: const Key('SCAN-004'),
      padding: const EdgeInsets.all(16),
      itemCount: _found.length,
      itemBuilder: (context, index) {
        final camera = _found[index];
        final statusColor = camera.isConfigured
            ? AppColors.online
            : Colors.amber;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: EdgeInsets.zero,
            borderRadius: 16,
            child: Material(
              type: MaterialType.transparency,
              child: ListTile(
                onTap: () => _handleTap(camera),
                leading: Container(
                  width: 44,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(
                      alpha: isDark ? 0.25 : 0.12,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.videocam_rounded,
                    color: colorScheme.primary,
                  ),
                ),
                title: Text(camera.name),
                subtitle: Text(camera.ipAddress),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    camera.isConfigured ? 'Configured' : 'Unconfigured',
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Glass-styled dialog shell shared by the scan setup dialogs, matching the
/// app's Login/Signup visual language instead of a default AlertDialog.
class _GlassDialog extends StatelessWidget {
  const _GlassDialog({super.key, required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: GlassCard(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
