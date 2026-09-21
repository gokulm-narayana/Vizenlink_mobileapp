import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app_state/homes_controller.dart';
import '../../models/camera.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/gradient_background.dart';
import 'video_stream_encoder_screen.dart';

String _resolutionLabel(CameraResolution resolution) => switch (resolution) {
  CameraResolution.p1080 => '1080p',
  CameraResolution.p720 => '720p',
  CameraResolution.p480 => '480p',
};

/// One-line summary of a stream's current settings, for a landing row's
/// subtitle — e.g. "1080p · H.265 · 4.0 Mbps · 15 fps".
String _streamSummary(StreamEncoderConfig c) {
  final codec = c.encoderType == CameraEncoderType.h265 ? 'H.265' : 'H.264';
  final mbps = c.bitrateKbps / 1000;
  final bitrate = mbps >= 1
      ? '${mbps.toStringAsFixed(mbps.truncateToDouble() == mbps ? 0 : 1)} Mbps'
      : '${c.bitrateKbps.round()} kbps';
  return '${_resolutionLabel(c.resolution)} · $codec · $bitrate · '
      '${c.frameRate.round()} fps';
}

/// Video Encoder landing list — one row per encoder stream (High-res /
/// Medium / Low). Tapping a row opens [VideoStreamEncoderScreen] scoped to
/// that stream. **All three streams are real** (2026-09-11) —
/// `OnvifVideoEncoderClient`/`WanVideoEncoderClient` were generalized to
/// address any video encoder config by token (`VideoEncoderCfg_1`/`_2`/`_3`),
/// not just the high-res one — see
/// `docs/screens/camera_settings/video_display/video_encoder_screen.md`.
class VideoEncoderScreen extends StatelessWidget {
  const VideoEncoderScreen({
    super.key,
    required this.camera,
    required this.homesController,
  });

  static const routeName = 'video-encoder';

  final Camera camera;
  final HomesController homesController;

  Camera get _camera {
    for (final home in homesController.value.homes) {
      for (final c in home.cameras) {
        if (c.id == camera.id) return c;
      }
    }
    return camera;
  }

  void _openStream(BuildContext context, VideoStream stream) {
    context.push(
      '${GoRouterState.of(context).matchedLocation}/'
      '${VideoStreamEncoderScreen.routeName}',
      extra: (camera: _camera, stream: stream),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          key: const Key('ENC-001'),
          title: const Text('Video Encoder'),
        ),
        body: AnimatedBuilder(
          animation: homesController,
          builder: (context, _) {
            final cam = _camera;
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StreamRow(
                  settingsKey: const Key('ENC-019'),
                  title: 'High-res stream',
                  summary: _streamSummary(
                    cam.encoderConfigFor(VideoStream.highRes),
                  ),
                  onTap: () => _openStream(context, VideoStream.highRes),
                ),
                const SizedBox(height: 12),
                _StreamRow(
                  settingsKey: const Key('ENC-020'),
                  title: 'Medium stream',
                  summary: _streamSummary(
                    cam.encoderConfigFor(VideoStream.medium),
                  ),
                  onTap: () => _openStream(context, VideoStream.medium),
                ),
                const SizedBox(height: 12),
                _StreamRow(
                  settingsKey: const Key('ENC-021'),
                  title: 'Low stream',
                  summary: _streamSummary(
                    cam.encoderConfigFor(VideoStream.low),
                  ),
                  onTap: () => _openStream(context, VideoStream.low),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StreamRow extends StatelessWidget {
  const _StreamRow({
    required this.settingsKey,
    required this.title,
    required this.summary,
    required this.onTap,
  });

  final Key settingsKey;
  final String title;
  final String summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GlassCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        key: settingsKey,
        leading: const Icon(Icons.videocam_outlined),
        title: Text(title),
        subtitle: Text(summary),
        trailing: Icon(
          Icons.chevron_right,
          color: colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }
}
