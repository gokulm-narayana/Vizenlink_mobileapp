import 'dart:async';

import 'package:camera_api/camera_api.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../app_state/camera_settings_cache.dart';
import '../../app_state/camera_sync.dart';
import '../../app_state/homes_controller.dart';
import '../../widgets/gradient_button.dart';
import 'scanned_devices_screen.dart' show GlassDialog;

/// Fallback entry point for a camera LAN discovery (`scanForCameras()`)
/// didn't find — reachable from the "No cameras found" state of the
/// scanning popup (SCAN-018/SCAN-019). The user already knows the camera's
/// real credentials (this isn't a factory-reset flow, so no default-
/// credentials prefill), so this form just needs the one field
/// `scanned_devices_screen.dart`'s setup form doesn't: the camera's LAN
/// IP/host itself. Verification, capability/identity probing, and the
/// resulting `HomesController.addCamera` call otherwise mirror that
/// screen's SCAN-010 "Connect" flow exactly.
Future<void> showAddCameraManuallyDialog(
  BuildContext context, {
  required HomesController homesController,
  http.Client? httpClient,
}) async {
  final rooms = homesController.value.selectedHome.rooms;
  final hostController = TextEditingController();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  String? selectedRoom = rooms.isNotEmpty ? rooms.first : null;
  String? errorText;
  bool verifying = false;
  DeviceInformation? verifiedInfo;
  String? verifiedMacAddress;
  String? verifiedThingName;
  String? verifiedName;
  CameraCapabilities? verifiedCapabilities;

  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setDialogState) {
          // Same reasoning as SCAN-010's identical guard — blocks the
          // system/gesture back button while a Connect attempt is in
          // flight, so a user can't back out mid-verification and leave
          // the async credential check running against a closed dialog.
          return PopScope(
            canPop: !verifying,
            child: GlassDialog(
              key: const Key('SCAN-020'),
              title: 'Add camera manually',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    key: const Key('SCAN-021'),
                    controller: hostController,
                    decoration: const InputDecoration(
                      labelText: 'Camera IP address',
                      prefixIcon: Icon(Icons.dns_outlined),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('SCAN-022'),
                    controller: usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('SCAN-023'),
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (rooms.isEmpty)
                    Text(
                      'This home has no rooms yet. The camera will be added without a room.',
                      style: Theme.of(dialogContext).textTheme.bodySmall,
                    )
                  else
                    DropdownButtonFormField<String?>(
                      key: const Key('SCAN-024'),
                      initialValue: selectedRoom,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Room',
                        prefixIcon: Icon(Icons.meeting_room_outlined),
                      ),
                      items: [
                        for (final room in rooms)
                          DropdownMenuItem<String?>(
                            value: room,
                            child: Text(room, overflow: TextOverflow.ellipsis),
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
                        key: Key('SCAN-028'),
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  GradientButton(
                    key: const Key('SCAN-026'),
                    onPressed: verifying
                        ? null
                        : () async {
                            final host = hostController.text.trim();
                            if (host.isEmpty) {
                              setDialogState(
                                () => errorText =
                                    'Enter the camera\'s IP address',
                              );
                              return;
                            }

                            setDialogState(() {
                              verifying = true;
                              errorText = null;
                            });

                            final connection = CameraConnection(
                              host: host,
                              username: usernameController.text,
                              password: passwordController.text,
                            );
                            final deviceClient = OnvifDeviceClient(
                              connection,
                              httpClient: httpClient,
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
                                'Camera did not respond. Check the IP '
                                    'address and username/password and try '
                                    'again.',
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

                            // Best-effort, same as SCAN-010's Connect flow —
                            // neither failing blocks setup.
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
                            final nuraeyeClient = NuraeyeClient(
                              connection,
                              httpClient: httpClient,
                            );
                            switch (await CapabilitiesClient(
                              nuraeyeClient,
                            ).getCapabilities()) {
                              case CameraSuccess(:final value):
                                verifiedCapabilities = value;
                              case CameraFailure() || CameraTimeout():
                                break;
                            }
                            nuraeyeClient.close();
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
                    key: const Key('SCAN-027'),
                    onPressed: verifying
                        ? null
                        : () => Navigator.of(dialogContext).pop(false),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );

  final enteredHost = hostController.text.trim();
  final enteredUsername = usernameController.text;
  final enteredPassword = passwordController.text;

  // Same 300ms grace as SCAN-010's identical dispose-timing comment — the
  // dialog's exit transition is still animating when showDialog's Future
  // resolves, and disposing these controllers immediately can crash with
  // "TextEditingController used after being disposed" once Connect takes
  // several real seconds.
  await Future<void>.delayed(const Duration(milliseconds: 300));
  hostController.dispose();
  usernameController.dispose();
  passwordController.dispose();

  if (confirmed != true) return;

  final newCamera = homesController.addCamera(
    homesController.value.selectedHome.id,
    name: verifiedName ?? 'Camera at $enteredHost',
    room: selectedRoom,
    isOnline: true,
    host: enteredHost,
    username: enteredUsername,
    password: enteredPassword,
    manufacturer: verifiedInfo?.manufacturer,
    model: verifiedInfo?.model,
    firmwareVersion: verifiedInfo?.firmwareVersion,
    serialNumber: verifiedInfo?.serialNumber,
    hardwareId: verifiedInfo?.hardwareId,
    macAddress: verifiedMacAddress,
    thingName: verifiedThingName,
    wanLiveViewCapable: verifiedCapabilities?.wanLiveViewCapable,
    wanCommandCapable: verifiedCapabilities?.wanCommandCapable,
    sirenCapable: verifiedCapabilities?.sirenCapable,
    spotlightCapable: verifiedCapabilities?.spotlightCapable,
    warningCapable: verifiedCapabilities?.warningCapable,
  );

  // Fire-and-forget, same as SCAN-010's Connect flow — enriches the camera
  // (timezone, a real snapshot, every settings screen's Options cache)
  // without making the user wait through a second multi-second round trip.
  final syncConnection = newCamera.connection;
  if (syncConnection != null) {
    unawaited(
      syncCameraFromDevice(
        homesController: homesController,
        cameraId: newCamera.id,
        connection: syncConnection,
      ),
    );
    unawaited(prefetchAndCache(syncConnection));
  }
}
