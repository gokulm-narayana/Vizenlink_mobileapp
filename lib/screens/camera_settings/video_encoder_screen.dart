import 'package:camera_api/camera_api.dart';
import 'package:flutter/material.dart';

import '../../app_state/homes_controller.dart';
import '../../models/camera.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/navigation_leave_guard.dart';
import '../../widgets/saving_overlay.dart';
import '../../widgets/settings_save_button.dart';

const _defaultResolution = CameraResolution.p1080;
const _defaultEncoder = CameraEncoderType.h264;
const _defaultProfile = CameraEncoderProfile.main;
const _defaultFrameRate = 15.0;
const _defaultGov = 30.0;
const _defaultQuality = 3.0;
const _defaultBitrateMode = CameraBitrateMode.cbr;
const _defaultBitrateKbps = 2048.0;

/// `CameraEncoderType` <-> ONVIF `"H264"`/`"H265"` wire values.
CameraEncoderType _encoderTypeFromWire(String wire) =>
    wire.toUpperCase() == 'H265'
    ? CameraEncoderType.h265
    : CameraEncoderType.h264;

String _encoderTypeToWire(CameraEncoderType type) => switch (type) {
  CameraEncoderType.h264 => 'H264',
  CameraEncoderType.h265 => 'H265',
};

/// `CameraEncoderProfile` <-> ONVIF `"Baseline"`/`"Main"`/`"High"` wire values.
CameraEncoderProfile? _encoderProfileFromWire(String wire) =>
    switch (wire.toLowerCase()) {
      'baseline' => CameraEncoderProfile.baseline,
      'main' => CameraEncoderProfile.main,
      'high' => CameraEncoderProfile.high,
      _ => null,
    };

String _encoderProfileToWire(CameraEncoderProfile profile) => switch (profile) {
  CameraEncoderProfile.baseline => 'Baseline',
  CameraEncoderProfile.main => 'Main',
  CameraEncoderProfile.high => 'High',
};

/// This app's fixed `CameraResolution` enum has no direct ONVIF equivalent —
/// the real wire shape is a `(width, height)` pixel pair, from whichever
/// entries the camera's own Options response reports (usually exactly one,
/// per `EncodingOptions.resolutions`'s doc). Derives the closest enum value
/// from reported pixels for display; `_save`'s own resolution-resolving
/// block does the reverse when pushing a change.
CameraResolution _resolutionFromPixels(int width, int height) {
  if (width >= 1920 && height >= 1080) return CameraResolution.p1080;
  if (width >= 1280 && height >= 720) return CameraResolution.p720;
  return CameraResolution.p480;
}

String _resolutionLabel(CameraResolution resolution) => switch (resolution) {
  CameraResolution.p1080 => '1080p',
  CameraResolution.p720 => '720p',
  CameraResolution.p480 => '480p',
};

/// Real bounds for a slider from the camera's own Options response, or a
/// fallback `(min, max)` pair when unverified. The app's own default ranges
/// (e.g. Quality 1-5) don't necessarily match the camera's real range (ONVIF
/// quality is typically 1-10) — using the real range isn't just cosmetic
/// here, a loaded value outside the fallback range would violate `Slider`'s
/// own `value` bounds assertion.
(double min, double max) _sliderBounds(
  IntRange? range,
  double fallbackMin,
  double fallbackMax,
) {
  if (range == null) return (fallbackMin, fallbackMax);
  return (range.min.toDouble(), range.max.toDouble());
}

/// Filters [fallback] (this screen's original fixed choice list) down to
/// whatever [real] actually reports — never a hardcoded fixed set once the
/// camera is verified, per `.claude/rules/mobile-app-screen-conventions.md`
/// — while always keeping [current] in the result so a dropdown/segmented
/// control's selected value is never outside its own item list. Returns
/// [fallback] unfiltered when [real] is null (camera not verified yet).
List<T> _optionsOrFallback<T>(Iterable<T>? real, T current, List<T> fallback) {
  if (real == null) return fallback;
  final supported = real.toSet()..add(current);
  return [
    for (final value in fallback)
      if (supported.contains(value)) value,
  ];
}

/// Video Encoder: resolution, encoder/profile, frame rate, GOV, quality,
/// bitrate mode, and bitrate. Backed by `OnvifVideoEncoderClient`
/// (`VideoEncoderCfg_1`, the high-res profile) when the camera has a saved
/// connection — every field is bounded/gated by the camera's own
/// `getVideoEncoderSettingsOptions()` response per encoding (H264/H265 can
/// report different bounds/profile lists/resolution choices), never a
/// hardcoded assumption. Falls back to local-only `HomesController` state
/// (`simulateCameraSave`) for a camera with no saved connection yet. LAN is
/// always tried first for both load and save; a WAN retry
/// (`WanVideoEncoderClient`) only kicks in when the LAN call itself
/// fails/times out and `connection.thingName` is known, per
/// `.claude/rules/mobile-app-screen-conventions.md`'s LAN/WAN convention.
/// Per that same convention, WAN Options are never fetched on a normal
/// load — only the current-value settings read gets a WAN fallback there.
class VideoEncoderScreen extends StatefulWidget {
  const VideoEncoderScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'video-encoder';

  final Camera camera;
  final HomesController homesController;

  @override
  State<VideoEncoderScreen> createState() => _VideoEncoderScreenState();
}

class _VideoEncoderScreenState extends State<VideoEncoderScreen> {
  late CameraResolution _resolution = _camera.videoResolution;
  late CameraEncoderType _encoder = _camera.encoderType;
  late CameraEncoderProfile _profile = _camera.encoderProfile;
  late double _frameRate = _camera.frameRate;
  late double _gov = _camera.govLength;
  late double _quality = _camera.encoderQuality;
  late CameraBitrateMode _bitrateMode = _camera.bitrateMode;
  late double _bitrateKbps = _camera.bitrateKbps;
  bool _isDirty = false;
  bool _isSaving = false;

  /// Native pixel size backing [_resolution] — loaded from the camera,
  /// needed on Save since the wire format is `(width, height)`, not an
  /// enum. Defaults are placeholders only used for a camera with no saved
  /// connection (local-only save path never reads these).
  int _width = 1920;
  int _height = 1080;

  /// Per-encoding bounds/choice lists from the camera's own
  /// `getVideoEncoderSettingsOptions()` — null means "camera not verified
  /// yet", in which case every control falls back to a fixed set (same
  /// reasoning as `_dummyTimezones` in camera_info_screen).
  VideoEncoderSettingsOptions? _encoderOptions;

  EncodingOptions? get _currentEncodingOptions =>
      _encoderOptions?.forEncoding(_encoderTypeToWire(_encoder));

  /// Looked up fresh from [HomesController] on every build (not
  /// [widget.camera] directly), matching every other camera-settings screen.
  Camera get _camera {
    for (final home in widget.homesController.value.homes) {
      for (final camera in home.cameras) {
        if (camera.id == widget.camera.id) return camera;
      }
    }
    return widget.camera;
  }

  @override
  void initState() {
    super.initState();
    _loadRealVideoEncoder();
  }

  Future<void> _loadRealVideoEncoder() async {
    final connection = _camera.connection;
    if (connection == null) return;
    final client = OnvifVideoEncoderClient(connection);
    final results = await Future.wait([
      client.getVideoEncoderSettings(),
      client.getVideoEncoderSettingsOptions(),
    ]);
    client.close();

    var settingsResult = results[0] as CameraResult<VideoEncoderSettings>;
    final optionsResult =
        results[1] as CameraResult<VideoEncoderSettingsOptions>;

    // Options are LAN-only on a normal load (see this class's doc comment)
    // — only the current-value settings read falls back to WAN here.
    final thingName = connection.thingName;
    if (settingsResult is! CameraSuccess && thingName != null) {
      settingsResult = await WanVideoEncoderClient(
        thingName,
      ).getVideoEncoderSettings();
    }
    if (!mounted) return;

    setState(() {
      if (settingsResult case CameraSuccess(:final value)) {
        _encoder = _encoderTypeFromWire(value.encoding);
        final profile = _encoderProfileFromWire(value.encoderProfile);
        if (profile != null) _profile = profile;
        _frameRate = value.frameRate.toDouble();
        _gov = value.govLength.toDouble();
        _quality = value.quality.toDouble();
        _bitrateMode = value.cbr
            ? CameraBitrateMode.cbr
            : CameraBitrateMode.vbr;
        _bitrateKbps = value.bitrate.toDouble();
        _width = value.width;
        _height = value.height;
        _resolution = _resolutionFromPixels(value.width, value.height);
      }
      if (optionsResult case CameraSuccess(:final value)) {
        _encoderOptions = value;
      }
    });

    if (settingsResult case CameraSuccess(:final value)) {
      widget.homesController.updateCamera(
        widget.camera.id,
        (camera) => camera.copyWith(
          videoResolution: _resolutionFromPixels(value.width, value.height),
          encoderType: _encoderTypeFromWire(value.encoding),
          encoderProfile:
              _encoderProfileFromWire(value.encoderProfile) ??
              camera.encoderProfile,
          frameRate: value.frameRate.toDouble(),
          govLength: value.govLength.toDouble(),
          encoderQuality: value.quality.toDouble(),
          bitrateMode: value.cbr
              ? CameraBitrateMode.cbr
              : CameraBitrateMode.vbr,
          bitrateKbps: value.bitrate.toDouble(),
        ),
      );
    }
  }

  void _markDirty(VoidCallback update) {
    setState(() {
      update();
      _isDirty = true;
    });
  }

  void _resetToDefault() {
    _markDirty(() {
      _resolution = _defaultResolution;
      _encoder = _defaultEncoder;
      _profile = _defaultProfile;
      _frameRate = _defaultFrameRate;
      _gov = _defaultGov;
      _quality = _defaultQuality;
      _bitrateMode = _defaultBitrateMode;
      _bitrateKbps = _defaultBitrateKbps;
    });
  }

  Future<void> _save() async {
    final connection = _camera.connection;
    setState(() => _isSaving = true);

    final bool succeeded;
    if (connection != null) {
      final client = OnvifVideoEncoderClient(connection);
      // Resolution has no direct enum on the wire — resolve the selected
      // enum to one of the camera's own reported (width, height) choices
      // for the current encoding; keep the camera's current pixel size
      // unchanged if the enum doesn't match any of them (e.g. this
      // firmware's typical single-resolution report).
      var width = _width;
      var height = _height;
      final resolutions = _currentEncodingOptions?.resolutions;
      if (resolutions != null && resolutions.isNotEmpty) {
        for (final candidate in resolutions) {
          if (_resolutionFromPixels(candidate.width, candidate.height) ==
              _resolution) {
            width = candidate.width;
            height = candidate.height;
            break;
          }
        }
      }
      final settings = VideoEncoderSettings(
        bitrate: _bitrateKbps.round(),
        frameRate: _frameRate.round(),
        govLength: _gov.round(),
        quality: _quality.round(),
        encoderProfile: _encoderProfileToWire(_profile),
        width: width,
        height: height,
        encoding: _encoderTypeToWire(_encoder),
        cbr: _bitrateMode == CameraBitrateMode.cbr,
      );
      final result = await client.setVideoEncoderSettings(settings);
      client.close();

      // A failed LAN Apply/Set retries over WAN before surfacing an error,
      // per mobile-app-screen-conventions.md's LAN/WAN convention. WAN's
      // setVideoEncoderSettings returns the applied VideoEncoderSettings
      // rather than void, unlike the LAN client — only its success/failure
      // matters here, not the returned value.
      final thingName = connection.thingName;
      if (result is CameraSuccess) {
        succeeded = true;
      } else if (thingName != null) {
        final wanResult = await WanVideoEncoderClient(
          thingName,
        ).setVideoEncoderSettings(settings);
        succeeded = wanResult is CameraSuccess;
      } else {
        succeeded = false;
      }
    } else {
      succeeded = await simulateCameraSave();
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    if (succeeded) {
      widget.homesController.updateCamera(
        widget.camera.id,
        (camera) => camera.copyWith(
          videoResolution: _resolution,
          encoderType: _encoder,
          encoderProfile: _profile,
          frameRate: _frameRate,
          govLength: _gov,
          encoderQuality: _quality,
          bitrateMode: _bitrateMode,
          bitrateKbps: _bitrateKbps,
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
    dialogKey: const Key('ENC-015'),
    discardKey: const Key('ENC-016'),
    saveKey: const Key('ENC-017'),
  );

  @override
  Widget build(BuildContext context) {
    return LeaveGuard(
      canLeave: _confirmLeave,
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            key: const Key('ENC-001'),
            title: const Text('Video Encoder'),
            actions: [
              SettingsSaveButton(
                settingsKey: const Key('ENC-002'),
                isDirty: _isDirty,
                isSaving: _isSaving,
                onPressed: _save,
              ),
            ],
          ),
          body: SavingOverlay(
            isSaving: _isSaving,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton(
                    key: const Key('ENC-014'),
                    onPressed: _resetToDefault,
                    child: const Text('Reset to Default'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Resolution',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final resolutions = _currentEncodingOptions?.resolutions;
                    // Read-only when the camera reports one (or zero) valid
                    // resolution for this encoding — a picker with a single
                    // option isn't a real choice. Per
                    // EncodingOptions.resolutions's doc, this is the common
                    // case on this firmware today.
                    if (resolutions != null && resolutions.length <= 1) {
                      return Text(
                        key: const Key('ENC-003'),
                        _resolutionLabel(_resolution),
                        style: Theme.of(context).textTheme.bodyLarge,
                      );
                    }
                    final available = _optionsOrFallback(
                      resolutions?.map(
                        (r) => _resolutionFromPixels(r.width, r.height),
                      ),
                      _resolution,
                      CameraResolution.values,
                    );
                    return DropdownButtonFormField<CameraResolution>(
                      key: const Key('ENC-003'),
                      initialValue: _resolution,
                      items: [
                        for (final res in available)
                          DropdownMenuItem(
                            value: res,
                            child: Text(_resolutionLabel(res)),
                          ),
                      ],
                      onChanged: (value) =>
                          _markDirty(() => _resolution = value!),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Video encoder',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<CameraEncoderType>(
                  key: const Key('ENC-007'),
                  initialValue: _encoder,
                  items: [
                    for (final type in _optionsOrFallback(
                      _encoderOptions?.availableEncodings.map(
                        _encoderTypeFromWire,
                      ),
                      _encoder,
                      CameraEncoderType.values,
                    ))
                      DropdownMenuItem(
                        value: type,
                        child: Text(
                          type == CameraEncoderType.h265 ? 'H.265' : 'H.264',
                        ),
                      ),
                  ],
                  onChanged: (value) => _markDirty(() {
                    _encoder = value!;
                    // Each encoding has its own supportsCbr — if the new
                    // one doesn't allow CBR, force VBR so ENC-012's
                    // dropdown (which hides CBR entirely when unsupported)
                    // never ends up with a selected value outside its own
                    // item list.
                    if (!(_currentEncodingOptions?.supportsCbr ?? true)) {
                      _bitrateMode = CameraBitrateMode.vbr;
                    }
                  }),
                ),
                const SizedBox(height: 16),
                Text(
                  'Encoder profile',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<CameraEncoderProfile>(
                  key: const Key('ENC-008'),
                  initialValue: _profile,
                  items: [
                    for (final profile in _optionsOrFallback(
                      _currentEncodingOptions?.encoderProfiles
                          .map(_encoderProfileFromWire)
                          .whereType<CameraEncoderProfile>(),
                      _profile,
                      CameraEncoderProfile.values,
                    ))
                      DropdownMenuItem(
                        value: profile,
                        child: Text(switch (profile) {
                          CameraEncoderProfile.baseline => 'Baseline',
                          CameraEncoderProfile.main => 'Main',
                          CameraEncoderProfile.high => 'High',
                        }),
                      ),
                  ],
                  onChanged: (value) => _markDirty(() => _profile = value!),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Frame rate (${_frameRate.round()} fps)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Builder(
                        builder: (context) {
                          final (min, max) = _sliderBounds(
                            _currentEncodingOptions?.frameRateRange,
                            1,
                            25,
                          );
                          return Slider(
                            key: const Key('ENC-009'),
                            value: _frameRate.clamp(min, max),
                            min: min,
                            max: max,
                            divisions: (max - min).round(),
                            onChanged: (value) =>
                                _markDirty(() => _frameRate = value),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'GOV (${_gov.round()})',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Builder(
                        builder: (context) {
                          final (min, max) = _sliderBounds(
                            _currentEncodingOptions?.govLengthRange,
                            10,
                            50,
                          );
                          return Slider(
                            key: const Key('ENC-010'),
                            value: _gov.clamp(min, max),
                            min: min,
                            max: max,
                            divisions: (max - min).round(),
                            onChanged: (value) =>
                                _markDirty(() => _gov = value),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Quality (${_quality.round()})',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Builder(
                        builder: (context) {
                          final (min, max) = _sliderBounds(
                            _currentEncodingOptions?.qualityRange,
                            1,
                            5,
                          );
                          return Slider(
                            key: const Key('ENC-011'),
                            value: _quality.clamp(min, max),
                            min: min,
                            max: max,
                            divisions: (max - min).round(),
                            onChanged: (value) =>
                                _markDirty(() => _quality = value),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bitrate mode',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<CameraBitrateMode>(
                  key: const Key('ENC-012'),
                  initialValue: _bitrateMode,
                  items: [
                    const DropdownMenuItem(
                      value: CameraBitrateMode.vbr,
                      child: Text('VBR (Variable)'),
                    ),
                    // Hidden, not just disabled, when the camera's own
                    // Options response says this encoding doesn't support
                    // CBR — per EncodingOptions.supportsCbr's doc.
                    if (_currentEncodingOptions?.supportsCbr ?? true)
                      const DropdownMenuItem(
                        value: CameraBitrateMode.cbr,
                        child: Text('CBR (Constant)'),
                      ),
                  ],
                  onChanged: (value) => _markDirty(() => _bitrateMode = value!),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Bitrate (${_bitrateKbps.round()} kbps)',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Builder(
                        builder: (context) {
                          final (min, max) = _sliderBounds(
                            _currentEncodingOptions?.bitrateRange,
                            32,
                            8192,
                          );
                          return Slider(
                            key: const Key('ENC-013'),
                            value: _bitrateKbps.clamp(min, max),
                            min: min,
                            max: max,
                            divisions: (max - min).round(),
                            onChanged: (value) =>
                                _markDirty(() => _bitrateKbps = value),
                          );
                        },
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
