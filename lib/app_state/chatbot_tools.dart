import 'dart:typed_data';

import 'package:camera_api/camera_api.dart';
import 'package:llamadart/llamadart.dart';

import '../models/camera.dart';
import '../models/home.dart';
import '../models/scanned_camera.dart';
import 'camera_scan.dart';
import 'homes_controller.dart';

/// A chat-renderable side effect a tool's handler produces, in addition to
/// the short text result it returns to the model. `camera_chatbot.dart`
/// appends these to the message list right after the tool's own text.
sealed class ChatToolEffect {}

/// Shows a real, freshly-captured snapshot — same image-card + full-screen
/// preview pattern as CHAT-011/CHAT-015, fed real bytes instead of a cached
/// `Camera.thumbnailUrl`.
class SnapshotEffect extends ChatToolEffect {
  SnapshotEffect({required this.bytes, required this.cameraName});

  final Uint8List bytes;
  final String cameraName;
}

/// Shows a card that deep-links to the real `CameraLiveScreen` rather than
/// an inline player — see the design discussion in this session for why.
class LiveViewEffect extends ChatToolEffect {
  LiveViewEffect(this.camera);

  final Camera camera;
}

/// Shows a card summarizing a real LAN scan (`scanForCameras()`, the same
/// WS-Discovery scan `ScannedDevicesScreen` uses) — deep-links to that real
/// screen (passing the already-fetched results so it doesn't scan again)
/// rather than reimplementing the add-camera flow inline, same pattern as
/// [LiveViewEffect].
class ScanResultsEffect extends ChatToolEffect {
  ScanResultsEffect(this.cameras);

  final List<ScannedCamera> cameras;
}

/// A destructive tool (reboot/reset/factory-reset/delete) never executes
/// from the tool call itself — the handler only stages [onConfirm] and
/// returns a "Awaiting user confirmation" text result so the model doesn't
/// treat the action as already done. The real `camera_api` call only fires
/// when the user taps the rendered Confirm chip, entirely outside the LLM
/// loop — never by the model re-parsing a free-text "yes".
class ConfirmEffect extends ChatToolEffect {
  ConfirmEffect({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
  });

  final String title;
  final String message;
  final String confirmLabel;

  /// Performs the real action and returns a short result string to post
  /// back into the chat as a follow-up assistant-style message.
  final Future<String> Function() onConfirm;
}

/// Builds this session's full tool catalog for the on-device model, resolving
/// camera names/ids against [homesController] and reporting any UI side
/// effect via [onEffect]. Every handler here mirrors the exact `camera_api`
/// call pattern its equivalent settings screen already uses elsewhere in
/// this app (LAN first, WAN retry on failure when `connection.thingName` is
/// known, local-only fallback via [HomesController] when unconnected) —
/// nothing here is a new/parallel way of talking to a camera.
///
/// Kept deliberately compact (19 tools, `set_mode`/`set_audio` consolidate
/// what would otherwise be 6 single-field setters) — small on-device models
/// measurably lose tool-selection accuracy as the schema grows, so tool
/// count is a real budget, not free.
List<ToolDefinition> buildCameraTools({
  required HomesController homesController,
  required void Function(ChatToolEffect effect) onEffect,
}) {
  /// Exact id/name match first; if that finds nothing, falls back to a
  /// case-insensitive substring match ("front" matching "Front Door
  /// Camera") but only when exactly one camera matches — an ambiguous
  /// substring returns null rather than guessing which camera the user
  /// meant.
  Camera? findCamera(String nameOrId) {
    for (final home in homesController.value.homes) {
      for (final camera in home.cameras) {
        if (camera.id == nameOrId ||
            camera.name.toLowerCase() == nameOrId.toLowerCase()) {
          return camera;
        }
      }
    }
    final query = nameOrId.toLowerCase();
    Camera? match;
    for (final home in homesController.value.homes) {
      for (final camera in home.cameras) {
        if (camera.name.toLowerCase().contains(query)) {
          if (match != null) return null; // ambiguous — more than one hit
          match = camera;
        }
      }
    }
    return match;
  }

  String notFoundError(String query) =>
      'Error: no camera matching "$query". Call list_cameras to see available cameras.';

  /// Fast-fail before a network round trip for any tool that needs the
  /// camera to actually be reachable right now — `camera.isOnline` is a
  /// cheap, already-cached signal, cheaper than waiting out a real
  /// connect/timeout for a camera the app already knows is offline.
  String? offlineError(Camera camera) {
    if (!camera.isOnline) return 'Error: ${camera.name} is currently offline.';
    if (camera.connection == null) {
      return 'Error: ${camera.name} has no saved connection.';
    }
    return null;
  }

  ToolParam cameraParam() => ToolParam.string(
    'camera',
    description:
        'Camera name, e.g. "Front Door". Call list_cameras first if unsure of the exact name.',
    required: true,
  );

  final tools = <ToolDefinition>[];

  // --- Discovery -----------------------------------------------------

  tools.add(
    ToolDefinition(
      name: 'list_cameras',
      description:
          "List every camera in the app — name, home, room, online/offline status, and whether it has a saved LAN connection. Call this whenever the user asks what cameras exist, how many there are, or which are online, rather than answering from general knowledge.",
      parameters: const [],
      handler: (params) async {
        final homes = homesController.value.homes;
        final rows = <String>[];
        for (final home in homes) {
          for (final camera in home.cameras) {
            final room = camera.room;
            rows.add(
              '${camera.name} (home: ${home.name}'
              '${room != null ? ', room: $room' : ''}) — '
              '${camera.isOnline ? 'online' : 'offline'}, '
              '${camera.connection != null ? 'connected' : 'no saved connection'}',
            );
          }
        }
        if (rows.isEmpty) return 'No cameras have been added yet.';
        return rows.join('\n');
      },
    ),
  );

  tools.add(
    ToolDefinition(
      name: 'scan_for_cameras',
      description:
          'Scan the local network for new/unconfigured cameras not yet added to the app. Call this when the user asks to scan, find, discover, or look for cameras/devices — this is a real network scan, distinct from list_cameras (which only lists cameras already added).',
      parameters: const [],
      handler: (params) async {
        final found = await scanForCameras();
        onEffect(ScanResultsEffect(found));
        if (found.isEmpty) return 'Scan finished — no cameras found.';
        final unconfigured = found.where((c) => !c.isConfigured).length;
        return 'Found ${found.length} camera(s)'
            '${unconfigured > 0 ? ' ($unconfigured not yet added)' : ''}.';
      },
    ),
  );

  tools.add(
    ToolDefinition(
      name: 'get_camera_settings',
      description:
          "Read a camera's current settings — privacy mode, video mode, anti-flicker mode, mic gain, speaker volume, audio recording, and image adjustments. Call this for any question about a camera's current configuration, e.g. \"what's the brightness on the front camera\".",
      parameters: [cameraParam()],
      handler: (params) async {
        final camera = findCamera(params.getRequiredString('camera'));
        if (camera == null) {
          return notFoundError(params.getRequiredString('camera'));
        }
        return [
          'Privacy mode: ${camera.privacyMode.name}',
          'Video mode: ${camera.videoMode.name}',
          'Anti-flicker: ${camera.antiFlickerMode.name}',
          'Mic gain: ${camera.micGain.round()}',
          'Speaker volume: ${camera.speakerVolume.round()}',
          'Audio recording: ${camera.audioRecordingEnabled ? 'on' : 'off'}',
          'Brightness: ${camera.brightness.round()}',
          'Contrast: ${camera.contrast.round()}',
          'Saturation: ${camera.saturation.round()}',
          'Sharpness: ${camera.sharpness.round()}',
        ].join(', ');
      },
    ),
  );

  // --- Live/quick actions -------------------------------------------------

  tools.add(
    ToolDefinition(
      name: 'take_snapshot',
      description: 'Capture and show a live snapshot from a camera.',
      parameters: [cameraParam()],
      handler: (params) async {
        final camera = findCamera(params.getRequiredString('camera'));
        if (camera == null) {
          return notFoundError(params.getRequiredString('camera'));
        }
        final offline = offlineError(camera);
        if (offline != null) return offline;
        final result = await SnapshotClient(camera.connection!).getSnapshot();
        return switch (result) {
          CameraSuccess(:final value) => () {
            onEffect(SnapshotEffect(bytes: value, cameraName: camera.name));
            return 'Snapshot captured from ${camera.name}.';
          }(),
          CameraFailure(:final reason) => 'Error: snapshot failed ($reason).',
          CameraTimeout() => 'Error: snapshot timed out.',
        };
      },
    ),
  );

  tools.add(
    ToolDefinition(
      name: 'open_live_view',
      description: "Open a camera's live video feed.",
      parameters: [cameraParam()],
      handler: (params) async {
        final camera = findCamera(params.getRequiredString('camera'));
        if (camera == null) {
          return notFoundError(params.getRequiredString('camera'));
        }
        onEffect(LiveViewEffect(camera));
        return 'Opened a live view card for ${camera.name}.';
      },
    ),
  );

  Future<bool> sendDeterrenceAction(
    Camera camera,
    String action, {
    required bool turningOn,
  }) async {
    final connection = camera.connection;
    if (connection == null) return false;
    final nuraeye = NuraeyeClient(connection);
    final client = DeterrenceClient(nuraeye);
    var result = turningOn
        ? await client.activateDeterrence(action)
        : await client.deactivateDeterrence(action);
    nuraeye.close();
    final thingName = connection.thingName;
    if (result is! CameraSuccess && thingName != null) {
      final wanClient = WanDeterrenceClient(thingName);
      result = turningOn
          ? await wanClient.activateDeterrence(action)
          : await wanClient.deactivateDeterrence(action);
    }
    return result is CameraSuccess;
  }

  tools.add(
    ToolDefinition(
      name: 'trigger_deterrence',
      description:
          "Turn a camera's siren, spotlight, or warning light/sound on or off. Momentary — the camera applies its own configured auto-stop duration.",
      parameters: [
        cameraParam(),
        ToolParam.enumType(
          'action',
          values: ['siren', 'spotlight', 'warning'],
          required: true,
        ),
        ToolParam.boolean('on', required: true),
      ],
      handler: (params) async {
        final camera = findCamera(params.getRequiredString('camera'));
        if (camera == null) {
          return notFoundError(params.getRequiredString('camera'));
        }
        final offline = offlineError(camera);
        if (offline != null) return offline;
        final action = params.getRequiredString('action');
        final on = params.getRequiredBool('on');
        final capable = switch (action) {
          'siren' => camera.sirenCapable,
          'spotlight' => camera.spotlightCapable,
          'warning' => camera.warningCapable,
          _ => null,
        };
        if (capable == false) {
          return 'Error: ${camera.name} does not have $action hardware.';
        }
        final succeeded = await sendDeterrenceAction(
          camera,
          action,
          turningOn: on,
        );
        return succeeded
            ? '${camera.name}\'s $action is now ${on ? 'on' : 'off'}.'
            : 'Error: failed to turn $action ${on ? 'on' : 'off'} for ${camera.name}.';
      },
    ),
  );

  // --- Modes (consolidated: privacy/video/anti-flicker share one tool) --

  Future<String> setPrivacyModeFor(Camera camera, String value) async {
    final newMode = value == 'full'
        ? CameraPrivacyMode.full
        : CameraPrivacyMode.off;
    final wireMode = newMode == CameraPrivacyMode.full
        ? PrivacyMode.full
        : PrivacyMode.none;
    final connection = camera.connection!;
    final nuraeye = NuraeyeClient(connection);
    var result = await PrivacyModeClient(nuraeye).setPrivacyMode(wireMode);
    nuraeye.close();
    final thingName = connection.thingName;
    if (result is! CameraSuccess && thingName != null) {
      result = await WanPrivacyModeClient(thingName).setPrivacyMode(wireMode);
    }
    if (result is! CameraSuccess) {
      return 'Error: failed to set privacy mode for ${camera.name}.';
    }
    homesController.updateCamera(
      camera.id,
      (current) => current.copyWith(privacyMode: newMode),
    );
    return '${camera.name}\'s privacy mode is now $value.';
  }

  Future<String> setVideoModeFor(Camera camera, String value) async {
    final newMode = switch (value) {
      'day' => CameraVideoMode.day,
      'night' => CameraVideoMode.night,
      _ => CameraVideoMode.auto,
    };
    final irCutFilter = switch (newMode) {
      CameraVideoMode.day => 'ON',
      CameraVideoMode.night => 'OFF',
      CameraVideoMode.auto => 'AUTO',
    };
    final connection = camera.connection!;
    final client = OnvifImagingClient(connection);
    var result = await client.setImagingSettings(
      ImagingSettings(irCutFilterMode: irCutFilter),
    );
    client.close();
    final thingName = connection.thingName;
    if (result is! CameraSuccess && thingName != null) {
      result = await WanImagingClient(thingName).setDayNightMode(irCutFilter);
    }
    if (result is! CameraSuccess) {
      return 'Error: failed to set video mode for ${camera.name}.';
    }
    homesController.updateCamera(
      camera.id,
      (current) => current.copyWith(videoMode: newMode),
    );
    return '${camera.name}\'s video mode is now $value.';
  }

  Future<String> setAntiFlickerFor(Camera camera, String value) async {
    final wireMode = switch (value) {
      '50hz' => AntiFlickerMode.hz50,
      '60hz' => AntiFlickerMode.hz60,
      _ => AntiFlickerMode.auto,
    };
    final appMode = switch (wireMode) {
      AntiFlickerMode.hz50 => CameraAntiFlickerMode.hz50,
      AntiFlickerMode.hz60 => CameraAntiFlickerMode.hz60,
      AntiFlickerMode.auto => CameraAntiFlickerMode.auto,
    };
    final connection = camera.connection!;
    final nuraeye = NuraeyeClient(connection);
    var result = await AntiFlickerClient(nuraeye).setAntiFlickerMode(wireMode);
    nuraeye.close();
    final thingName = connection.thingName;
    if (result is! CameraSuccess && thingName != null) {
      result = await WanAntiFlickerClient(
        thingName,
      ).setAntiFlickerMode(wireMode);
    }
    if (result is! CameraSuccess) {
      return 'Error: failed to set anti-flicker mode for ${camera.name}.';
    }
    homesController.updateCamera(
      camera.id,
      (current) => current.copyWith(antiFlickerMode: appMode),
    );
    return '${camera.name}\'s anti-flicker mode is now $value.';
  }

  tools.add(
    ToolDefinition(
      name: 'set_mode',
      description:
          "Set one of a camera's mode-style settings. mode_type=\"privacy\": value is \"off\" or \"full\" (zone masking isn't settable via chat). mode_type=\"video\": value is \"day\", \"auto\", or \"night\". mode_type=\"anti_flicker\": value is \"50hz\", \"60hz\", or \"auto\".",
      parameters: [
        cameraParam(),
        ToolParam.enumType(
          'mode_type',
          values: ['privacy', 'video', 'anti_flicker'],
          required: true,
        ),
        ToolParam.string(
          'value',
          required: true,
          description:
              'See this tool\'s own description for allowed values per mode_type.',
        ),
      ],
      handler: (params) async {
        final camera = findCamera(params.getRequiredString('camera'));
        if (camera == null) {
          return notFoundError(params.getRequiredString('camera'));
        }
        final offline = offlineError(camera);
        if (offline != null) return offline;
        final modeType = params.getRequiredString('mode_type');
        final value = params.getRequiredString('value').toLowerCase();
        return switch (modeType) {
          'privacy' => await setPrivacyModeFor(camera, value),
          'video' => await setVideoModeFor(camera, value),
          'anti_flicker' => await setAntiFlickerFor(camera, value),
          _ => 'Error: unknown mode_type "$modeType".',
        };
      },
    ),
  );

  // --- Camera identity ------------------------------------------------

  tools.add(
    ToolDefinition(
      name: 'rename_camera',
      description: "Rename a camera.",
      parameters: [cameraParam(), ToolParam.string('new_name', required: true)],
      handler: (params) async {
        final camera = findCamera(params.getRequiredString('camera'));
        if (camera == null) {
          return notFoundError(params.getRequiredString('camera'));
        }
        final newName = params.getRequiredString('new_name').trim();
        if (newName.isEmpty) return 'Error: new_name cannot be empty.';
        final home = homesController.value.homes.firstWhere(
          (h) => h.cameras.any((c) => c.id == camera.id),
        );
        final connection = camera.connection;
        // Unlike every other tool here, no saved connection isn't an error
        // for renaming — it just means the rename stays local-only below.
        // Offline *with* a saved connection is the only case worth failing
        // fast on, same reasoning as `offlineError` — otherwise this would
        // attempt a real ONVIF call and wait out a timeout before falling
        // through to the same local-only result it could've returned
        // immediately.
        if (connection != null && !camera.isOnline) {
          return 'Error: ${camera.name} is currently offline.';
        }
        if (connection != null) {
          final client = OnvifDeviceClient(connection);
          final result = await client.setDeviceName(newName);
          client.close();
          if (result is! CameraSuccess) {
            return 'Error: failed to rename ${camera.name} on the camera.';
          }
        }
        homesController.renameCamera(home.id, camera.id, newName);
        return '${camera.name} renamed to $newName.';
      },
    ),
  );

  // --- Audio (consolidated: mic gain/speaker volume/recording share one
  // tool, mirroring set_imaging's "only pass what you want to change"
  // shape) ----------------------------------------------------------

  tools.add(
    ToolDefinition(
      name: 'set_audio',
      description:
          "Adjust a camera's audio settings — mic_gain/speaker_volume (each 0-100) and/or recording_on. Only pass the fields you want to change.",
      parameters: [
        cameraParam(),
        ToolParam.integer('mic_gain'),
        ToolParam.integer('speaker_volume'),
        ToolParam.boolean('recording_on'),
      ],
      handler: (params) async {
        final camera = findCamera(params.getRequiredString('camera'));
        if (camera == null) {
          return notFoundError(params.getRequiredString('camera'));
        }
        final offline = offlineError(camera);
        if (offline != null) return offline;
        final connection = camera.connection!;
        final thingName = connection.thingName;

        final micGain = params.getInt('mic_gain');
        final speakerVolume = params.getInt('speaker_volume');
        final recordingOn = params.getBool('recording_on');
        if (micGain == null && speakerVolume == null && recordingOn == null) {
          return 'Error: no field to change was provided.';
        }

        final updates = <String>[];
        final failures = <String>[];

        if (micGain != null) {
          final gain = micGain.clamp(0, 100);
          final volumeClient = AudioVolumeClient(connection);
          var result = await volumeClient.setMicGain(gain);
          volumeClient.close();
          var ok = result is CameraSuccess;
          if (!ok && thingName != null) {
            final wanResult = await WanAudioVolumeClient(
              thingName,
            ).setMicGain(gain);
            ok = wanResult is CameraSuccess;
          }
          if (ok) {
            homesController.updateCamera(
              camera.id,
              (current) => current.copyWith(micGain: gain.toDouble()),
            );
            updates.add('mic gain to $gain');
          } else {
            failures.add('mic gain');
          }
        }

        if (speakerVolume != null) {
          final volume = speakerVolume.clamp(0, 100);
          final speakerClient = SpeakerVolumeClient(connection);
          final currentResult = await speakerClient.getSpeakerVolume();
          var ok = false;
          if (currentResult case CameraSuccess(:final value)) {
            final result = await speakerClient.setSpeakerVolume(
              value.withLevel(volume),
            );
            ok = result is CameraSuccess;
          }
          speakerClient.close();
          if (!ok && thingName != null) {
            final wanResult = await WanSpeakerVolumeClient(
              thingName,
            ).setSpeakerVolume(volume);
            ok = wanResult is CameraSuccess;
          }
          if (ok) {
            homesController.updateCamera(
              camera.id,
              (current) => current.copyWith(speakerVolume: volume.toDouble()),
            );
            updates.add('speaker volume to $volume');
          } else {
            failures.add('speaker volume');
          }
        }

        if (recordingOn != null) {
          final volumeClient = AudioVolumeClient(connection);
          var result = await volumeClient.setAudioRecordingEnabled(recordingOn);
          volumeClient.close();
          var ok = result is CameraSuccess;
          if (!ok && thingName != null) {
            final wanResult = await WanAudioVolumeClient(
              thingName,
            ).setAudioRecordingEnabled(recordingOn);
            ok = wanResult is CameraSuccess;
          }
          if (ok) {
            homesController.updateCamera(
              camera.id,
              (current) => current.copyWith(audioRecordingEnabled: recordingOn),
            );
            updates.add('audio recording ${recordingOn ? 'on' : 'off'}');
          } else {
            failures.add('audio recording');
          }
        }

        final parts = <String>[];
        if (updates.isNotEmpty) {
          parts.add('Set ${camera.name}\'s ${updates.join(', ')}.');
        }
        if (failures.isNotEmpty) {
          parts.add('Error: failed to set ${failures.join(', ')}.');
        }
        return parts.join(' ');
      },
    ),
  );

  // --- Imaging ---------------------------------------------------------

  tools.add(
    ToolDefinition(
      name: 'set_imaging',
      description:
          "Adjust a camera's brightness/contrast/saturation/sharpness (each 0-100). Only pass the fields you want to change.",
      parameters: [
        cameraParam(),
        ToolParam.integer('brightness'),
        ToolParam.integer('contrast'),
        ToolParam.integer('saturation'),
        ToolParam.integer('sharpness'),
      ],
      handler: (params) async {
        final camera = findCamera(params.getRequiredString('camera'));
        if (camera == null) {
          return notFoundError(params.getRequiredString('camera'));
        }
        final offline = offlineError(camera);
        if (offline != null) return offline;
        final connection = camera.connection!;

        final brightness =
            params.getInt('brightness')?.toDouble() ?? camera.brightness;
        final contrast =
            params.getInt('contrast')?.toDouble() ?? camera.contrast;
        final saturation =
            params.getInt('saturation')?.toDouble() ?? camera.saturation;
        final sharpness =
            params.getInt('sharpness')?.toDouble() ?? camera.sharpness;

        final client = OnvifImagingClient(connection);
        var result = await client.setImagingSettings(
          ImagingSettings(
            brightness: brightness,
            contrast: contrast,
            colorSaturation: saturation,
            sharpness: sharpness,
          ),
        );
        client.close();
        var succeeded = result is CameraSuccess;
        final thingName = connection.thingName;
        if (!succeeded && thingName != null) {
          final wanResult = await WanImageQualityClient(thingName)
              .setImageSettings({
                'brightness': brightness,
                'contrast': contrast,
                'saturation': saturation,
                'sharpness': sharpness,
              });
          succeeded = wanResult is CameraSuccess;
        }
        if (succeeded) {
          homesController.updateCamera(
            camera.id,
            (current) => current.copyWith(
              brightness: brightness,
              contrast: contrast,
              saturation: saturation,
              sharpness: sharpness,
            ),
          );
          return '${camera.name}\'s imaging settings updated.';
        }
        return 'Error: failed to update imaging settings for ${camera.name}.';
      },
    ),
  );

  // --- Network -----------------------------------------------------------

  tools.add(
    ToolDefinition(
      name: 'set_wifi',
      description: "Connect a camera to a Wi-Fi network.",
      parameters: [
        cameraParam(),
        ToolParam.string('ssid', required: true),
        ToolParam.string('password', required: true),
      ],
      handler: (params) async {
        final camera = findCamera(params.getRequiredString('camera'));
        if (camera == null) {
          return notFoundError(params.getRequiredString('camera'));
        }
        final offline = offlineError(camera);
        if (offline != null) return offline;
        final client = NetworkInfoClient(camera.connection!);
        final result = await client.setupWifi(
          ssid: params.getRequiredString('ssid'),
          psk: params.getRequiredString('password'),
        );
        client.close();
        return result is CameraSuccess
            ? '${camera.name} is connecting to ${params.getRequiredString('ssid')}.'
            : 'Error: failed to set Wi-Fi for ${camera.name}.';
      },
    ),
  );

  // --- Alerts --------------------------------------------------------

  Future<bool> sendPreferences(Camera camera, Map<String, bool> changes) async {
    final connection = camera.connection;
    if (connection == null) return false;
    final nuraeye = NuraeyeClient(connection);
    var result = await EventPreferencesClient(
      nuraeye,
    ).setEventPreferences(changes);
    nuraeye.close();
    final thingName = connection.thingName;
    if (result is! CameraSuccess && thingName != null) {
      result = await WanEventPreferencesClient(
        thingName,
      ).setEventPreferences(changes);
    }
    return result is CameraSuccess;
  }

  tools.add(
    ToolDefinition(
      name: 'set_alert_type',
      description:
          'Turn a specific alert/detection type on or off for a camera (e.g. "PersonDetected"). Use list_alert_types first to see valid type names for that camera.',
      parameters: [
        cameraParam(),
        ToolParam.string('event_type', required: true),
        ToolParam.boolean('on', required: true),
      ],
      handler: (params) async {
        final camera = findCamera(params.getRequiredString('camera'));
        if (camera == null) {
          return notFoundError(params.getRequiredString('camera'));
        }
        final offline = offlineError(camera);
        if (offline != null) return offline;
        final eventType = params.getRequiredString('event_type');
        final on = params.getRequiredBool('on');
        final succeeded = await sendPreferences(camera, {eventType: on});
        return succeeded
            ? '${camera.name}\'s $eventType alerts are now ${on ? 'on' : 'off'}.'
            : 'Error: failed to update $eventType alerts for ${camera.name}. It may not be a valid alert type for this camera — call list_alert_types to check.';
      },
    ),
  );

  tools.add(
    ToolDefinition(
      name: 'list_alert_types',
      description:
          "List the alert/detection types a camera supports and whether each is currently on.",
      parameters: [cameraParam()],
      handler: (params) async {
        final camera = findCamera(params.getRequiredString('camera'));
        if (camera == null) {
          return notFoundError(params.getRequiredString('camera'));
        }
        final offline = offlineError(camera);
        if (offline != null) return offline;
        final nuraeye = NuraeyeClient(camera.connection!);
        final capabilitiesResult = await CapabilitiesClient(
          nuraeye,
        ).getCapabilities();
        if (capabilitiesResult is! CameraSuccess<CameraCapabilities>) {
          nuraeye.close();
          return 'Error: could not read alert types for ${camera.name}.';
        }
        final preferencesResult = await EventPreferencesClient(
          nuraeye,
        ).getEventPreferences();
        nuraeye.close();
        final preferences =
            preferencesResult is CameraSuccess<Map<String, bool>>
            ? preferencesResult.value
            : const <String, bool>{};
        final types = capabilitiesResult.value.supportedEventTypes;
        if (types.isEmpty) return '${camera.name} reports no alert types.';
        return types
            .map((t) => '$t: ${preferences[t] == true ? 'on' : 'off'}')
            .join(', ');
      },
    ),
  );

  tools.add(
    ToolDefinition(
      name: 'set_all_alerts',
      description: 'Turn every alert type on or off at once for a camera.',
      parameters: [cameraParam(), ToolParam.boolean('on', required: true)],
      handler: (params) async {
        final camera = findCamera(params.getRequiredString('camera'));
        if (camera == null) {
          return notFoundError(params.getRequiredString('camera'));
        }
        final offline = offlineError(camera);
        if (offline != null) return offline;
        final on = params.getRequiredBool('on');
        final nuraeye = NuraeyeClient(camera.connection!);
        final capabilitiesResult = await CapabilitiesClient(
          nuraeye,
        ).getCapabilities();
        nuraeye.close();
        if (capabilitiesResult is! CameraSuccess<CameraCapabilities>) {
          return 'Error: could not read alert types for ${camera.name}.';
        }
        final types = capabilitiesResult.value.supportedEventTypes;
        if (types.isEmpty) return '${camera.name} reports no alert types.';
        final succeeded = await sendPreferences(camera, {
          for (final type in types) type: on,
        });
        return succeeded
            ? 'All alerts for ${camera.name} are now ${on ? 'on' : 'off'}.'
            : 'Error: failed to update alerts for ${camera.name}.';
      },
    ),
  );

  // --- Home/room management (local only) ------------------------------

  tools.add(
    ToolDefinition(
      name: 'add_home',
      description: 'Add a new home.',
      parameters: [ToolParam.string('name', required: true)],
      handler: (params) async {
        final name = params.getRequiredString('name').trim();
        if (name.isEmpty) return 'Error: name cannot be empty.';
        homesController.addHome(name);
        return 'Added home "$name".';
      },
    ),
  );

  tools.add(
    ToolDefinition(
      name: 'rename_home',
      description: 'Rename an existing home.',
      parameters: [
        ToolParam.string(
          'home',
          required: true,
          description: 'Current home name',
        ),
        ToolParam.string('new_name', required: true),
      ],
      handler: (params) async {
        final homeName = params.getRequiredString('home');
        Home? home;
        for (final candidate in homesController.value.homes) {
          if (candidate.name.toLowerCase() == homeName.toLowerCase()) {
            home = candidate;
            break;
          }
        }
        if (home == null) return 'Error: no home named "$homeName".';
        final newName = params.getRequiredString('new_name').trim();
        if (newName.isEmpty) return 'Error: new_name cannot be empty.';
        homesController.renameHome(home.id, newName);
        return 'Home "$homeName" renamed to "$newName".';
      },
    ),
  );

  // --- Danger zone (destructive — stages a confirmation, never executes
  // directly from a tool call) ------------------------------------------

  Future<bool> sendReboot(Camera camera) async {
    final connection = camera.connection;
    if (connection == null) return false;
    final client = OnvifDeviceClient(connection);
    final result = await client.reboot();
    client.close();
    var ok = result is CameraSuccess;
    final thingName = connection.thingName;
    if (!ok && thingName != null) {
      final wanResult = await WanDeviceIdentityClient(thingName).reboot();
      ok = wanResult is CameraSuccess;
    }
    return ok;
  }

  Future<bool> sendFactoryReset(Camera camera, FactoryResetMode mode) async {
    final connection = camera.connection;
    if (connection == null) return false;
    final client = OnvifDeviceClient(connection);
    final result = await client.factoryReset(mode);
    client.close();
    var ok = result is CameraSuccess;
    final thingName = connection.thingName;
    if (!ok && thingName != null) {
      final wanResult = await WanDeviceIdentityClient(
        thingName,
      ).factoryReset(mode);
      ok = wanResult is CameraSuccess;
    }
    return ok;
  }

  tools.add(
    ToolDefinition(
      name: 'reboot_camera',
      description:
          'Reboot a camera. Destructive-adjacent — asks for confirmation first.',
      parameters: [cameraParam()],
      handler: (params) async {
        final camera = findCamera(params.getRequiredString('camera'));
        if (camera == null) {
          return notFoundError(params.getRequiredString('camera'));
        }
        final offline = offlineError(camera);
        if (offline != null) return offline;
        onEffect(
          ConfirmEffect(
            title: 'Reboot camera?',
            message:
                'This reboots ${camera.name}. Settings and recordings are kept.',
            confirmLabel: 'Reboot',
            onConfirm: () async {
              final succeeded = await sendReboot(camera);
              return succeeded
                  ? '${camera.name} is rebooting.'
                  : 'Failed to reboot ${camera.name}.';
            },
          ),
        );
        return 'Awaiting user confirmation before rebooting ${camera.name}.';
      },
    ),
  );

  tools.add(
    ToolDefinition(
      name: 'reset_camera_settings',
      description:
          "Erase a camera's settings and restore factory defaults, keeping Wi-Fi. Destructive — asks for confirmation first.",
      parameters: [cameraParam()],
      handler: (params) async {
        final camera = findCamera(params.getRequiredString('camera'));
        if (camera == null) {
          return notFoundError(params.getRequiredString('camera'));
        }
        final offline = offlineError(camera);
        if (offline != null) return offline;
        onEffect(
          ConfirmEffect(
            title: 'Reset settings?',
            message:
                'This erases all settings on ${camera.name} and restores factory defaults. Wi-Fi stays connected. This cannot be undone.',
            confirmLabel: 'Erase & Reset',
            onConfirm: () async {
              final succeeded = await sendFactoryReset(
                camera,
                FactoryResetMode.soft,
              );
              return succeeded
                  ? '${camera.name}\'s settings have been reset to factory defaults.'
                  : 'Failed to reset ${camera.name}.';
            },
          ),
        );
        return 'Awaiting user confirmation before resetting ${camera.name}\'s settings.';
      },
    ),
  );

  tools.add(
    ToolDefinition(
      name: 'factory_reset_camera',
      description:
          "Fully factory reset a camera, including Wi-Fi credentials — it will need full re-onboarding. Destructive — asks for confirmation first.",
      parameters: [cameraParam()],
      handler: (params) async {
        final camera = findCamera(params.getRequiredString('camera'));
        if (camera == null) {
          return notFoundError(params.getRequiredString('camera'));
        }
        final offline = offlineError(camera);
        if (offline != null) return offline;
        onEffect(
          ConfirmEffect(
            title: 'Factory reset camera?',
            message:
                'This erases ALL settings on ${camera.name}, including Wi-Fi credentials. It will disconnect from this network and need full re-onboarding. This cannot be undone.',
            confirmLabel: 'Erase Everything',
            onConfirm: () async {
              final succeeded = await sendFactoryReset(
                camera,
                FactoryResetMode.hard,
              );
              return succeeded
                  ? '${camera.name} has been factory reset — reconnect it to the network to use it again.'
                  : 'Failed to factory reset ${camera.name}.';
            },
          ),
        );
        return 'Awaiting user confirmation before factory resetting ${camera.name}.';
      },
    ),
  );

  tools.add(
    ToolDefinition(
      name: 'delete_camera',
      description:
          'Remove a camera from the app (does not touch the physical device). Destructive — asks for confirmation first.',
      parameters: [cameraParam()],
      handler: (params) async {
        final camera = findCamera(params.getRequiredString('camera'));
        if (camera == null) {
          return notFoundError(params.getRequiredString('camera'));
        }
        final home = homesController.value.homes.firstWhere(
          (h) => h.cameras.any((c) => c.id == camera.id),
        );
        onEffect(
          ConfirmEffect(
            title: 'Delete camera?',
            message:
                '"${camera.name}" will be removed from this home. This cannot be undone.',
            confirmLabel: 'Delete',
            onConfirm: () async {
              homesController.deleteCamera(home.id, camera.id);
              return '${camera.name} has been deleted.';
            },
          ),
        );
        return 'Awaiting user confirmation before deleting ${camera.name}.';
      },
    ),
  );

  return tools;
}

/// Words too generic to discriminate between tools — every tool description
/// in this file mentions "camera", most mention "set"/"the", so leaving
/// these in would make near-every tool "match" near-every message.
const _stopwords = {
  'a',
  'an',
  'the',
  'and',
  'or',
  'of',
  'to',
  'is',
  'are',
  'on',
  'off',
  'for',
  'this',
  'that',
  'its',
  'it',
  'as',
  'in',
  'at',
  'be',
  'not',
  'if',
  'has',
  'have',
  'call',
  'tool',
  'value',
  'first',
  'via',
  'e.g',
  'camera',
  'cameras',
  'set',
  'get',
  'each',
  'only',
  'never',
  'always',
  'with',
  'from',
  'you',
  'your',
  'once',
  'one',
  'so',
  'no',
  'do',
  'does',
  'destructive',
  'asks',
};

Iterable<String> _keywordsOf(String text) => text
    .toLowerCase()
    .split(RegExp(r'[^a-z0-9]+'))
    .where((w) => w.length > 2 && !_stopwords.contains(w));

/// Narrows [allTools] to the ones actually relevant to [userText], so a
/// small on-device model only ever sees a handful of candidate tools per
/// message instead of the full catalog — see `buildCameraTools`'s doc on
/// why tool count is a real accuracy budget for this model size. Scores
/// each tool by keyword overlap between the user's message and the tool's
/// own name/description; `list_cameras` is always included since it's the
/// cheap, frequent prerequisite for resolving "which camera" (see its own
/// description). Falls back to `list_cameras` alone — not the full
/// catalog — whenever there's no keyword signal at all, whether because
/// the message has no usable keywords (a bare "hi") or because it has real
/// words that just don't match any tool (small talk, off-topic questions):
/// a message sharing no vocabulary with any tool description is very
/// unlikely to be a camera action, so there's little real capability lost,
/// and it avoids paying full-catalog prompt cost on every greeting or
/// off-topic remark.
List<ToolDefinition> selectRelevantTools(
  String userText,
  List<ToolDefinition> allTools, {
  int maxTools = 6,
}) {
  // Neither "no usable keywords at all" (a bare "hi"/"ok" — every word 2
  // characters or shorter) nor "real words that don't match any tool
  // description" (small talk like "who are you", off-topic questions) is
  // a case worth paying for the full 20-tool schema over — a message that
  // shares no vocabulary with any tool almost certainly isn't asking for
  // a camera action, so there's no real capability to lose by narrowing to
  // just the cheap discovery tool. If the model genuinely needs the full
  // catalog for an oddly-worded camera request, its own follow-up
  // question will contain real matching keywords next turn. Both
  // previously returned `allTools` — dumping all 20 tool schemas into the
  // prompt for a plain greeting or off-topic remark, which is exactly the
  // prompt bloat this filter exists to avoid.
  List<ToolDefinition> minimalFallback() => [
    for (final tool in allTools)
      if (tool.name == 'list_cameras') tool,
  ];

  final queryWords = _keywordsOf(userText).toSet();
  if (queryWords.isEmpty) return minimalFallback();

  final scored = <(ToolDefinition, int)>[];
  for (final tool in allTools) {
    final toolWords = _keywordsOf('${tool.name} ${tool.description}').toSet();
    final score = queryWords.intersection(toolWords).length;
    if (score > 0) scored.add((tool, score));
  }
  if (scored.isEmpty) return minimalFallback();

  scored.sort((a, b) => b.$2.compareTo(a.$2));
  final selected = <ToolDefinition>{
    for (final tool in allTools)
      if (tool.name == 'list_cameras') tool,
    for (final (tool, _) in scored.take(maxTools)) tool,
  };
  return selected.toList();
}
