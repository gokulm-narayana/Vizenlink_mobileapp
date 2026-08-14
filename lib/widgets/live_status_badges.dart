import 'package:flutter/material.dart';

import '../models/camera.dart';
import '../theme/app_colors.dart';

/// Horizontal space reserved per stacked badge at a shared corner — enough
/// for one badge's width plus a gap, so side-by-side badges don't overlap.
/// Approximate, since badge width varies with content (e.g. bitrate value
/// digits) — generous enough for the current fixed-text badges.
const _osdStackSpacing = 92.0;

/// Given the corners of every enabled OSD tag, in a fixed priority order
/// (earlier entries render closer to the corner), returns each entry's
/// `stackIndex` for [osdPositioned] — 0 for the first tag at a given
/// corner, 1 for the second tag at that same corner, and so on. Keeps
/// badges that land on the same corner from overlapping.
List<int> osdStackIndices(List<OsdCorner> corners) {
  final countPerCorner = <OsdCorner, int>{};
  return [
    for (final corner in corners)
      countPerCorner.update(corner, (count) => count + 1, ifAbsent: () => 1) -
          1,
  ];
}

/// Wraps [child] in a [Positioned] at the given fixed preview [corner],
/// 8px inset from both edges. Shared by every non-draggable OSD tag (Live
/// tag, Bitrate, Signal Strength) across the Tags preview and Camera Live
/// page. When more than one tag shares the same corner, pass each one's
/// [stackIndex] (0, 1, 2, ...) among tags at that corner so they line up
/// side by side — growing inward from the corner's horizontal edge —
/// instead of rendering on top of each other.
Widget osdPositioned(
  OsdCorner corner, {
  required Widget child,
  int stackIndex = 0,
}) {
  final isLeft = corner == OsdCorner.topLeft || corner == OsdCorner.bottomLeft;
  final isTop = corner == OsdCorner.topLeft || corner == OsdCorner.topRight;
  final inset = 8.0 + stackIndex * _osdStackSpacing;
  return Positioned(
    left: isLeft ? inset : null,
    right: !isLeft ? inset : null,
    top: isTop ? 8 : null,
    bottom: !isTop ? 8 : null,
    child: child,
  );
}

/// "Live"/"Needs Attention"/"Offline" indicator with a colored status dot —
/// shared between [CameraLiveScreen]'s LIVE-004 badge and the Tags screen
/// preview, so both render identically. The dot pulses continuously only
/// while fully online (a degraded-but-connected camera shouldn't read as
/// cleanly "live"). No background — plain text/dot laid directly over the
/// video.
class LiveStatusBadge extends StatelessWidget {
  const LiveStatusBadge({super.key, required this.status});

  final CameraLiveStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      CameraLiveStatus.online => (AppColors.online, 'Live'),
      CameraLiveStatus.needsAttention => (
        AppColors.attention,
        'Needs Attention',
      ),
      CameraLiveStatus.offline => (AppColors.offline, 'Offline'),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StatusDot(color: color, blinking: status == CameraLiveStatus.online),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Rough dBm -> 0-4 bar mapping, same scale [Camera.signalStrength] uses —
/// `NetworkInfoClient.getWifiSignalStrength` only reports raw RSSI, no
/// bucketed rating of its own. Shared by every screen that turns a real RSSI
/// reading into the app's bar scale (Camera Live's [SignalStrengthBadge],
/// `wifi_config_screen.dart`'s own signal icon).
int barsForRssi(int rssi) => switch (rssi) {
  >= -50 => 4,
  >= -60 => 3,
  >= -70 => 2,
  >= -80 => 1,
  _ => 0,
};

/// Formats a network-speed kbps value auto-scaled to KB/s or MB/s, matching
/// how a real bandwidth reading is usually displayed (e.g. "256 KB/s",
/// "1.2 MB/s") — used by [SignalStrengthBadge]. [BitrateBadge] shows the
/// raw kbps value instead (stream encoder bitrate is conventionally
/// reported in kbps, not KB/s).
String formatBitrate(double kbps) {
  final kilobytesPerSecond = kbps / 8;
  if (kilobytesPerSecond >= 1000) {
    return '${(kilobytesPerSecond / 1000).toStringAsFixed(1)} MB/s';
  }
  return '${kilobytesPerSecond.round()} KB/s';
}

/// Persistent "audio recording" indicator — a mic icon, shown whenever
/// `Camera.audioRecordingEnabled` is true, independent of the mute/unmute
/// control (which only affects local listening, not what's recorded). No
/// background — plain icon laid directly over the video, matching the other
/// OSD tags.
class AudioRecordingBadge extends StatelessWidget {
  const AudioRecordingBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.mic, color: Colors.white, size: 16);
  }
}

/// Small app-side "bitrate" badge — a stream-rate icon plus the raw kbps
/// value — composited by the app rather than sent to or rendered by the
/// camera. Shows [configuredKbps] (`Camera.bitrateKbps`, the camera's
/// actual configured target encoder bitrate from Video Encoder settings) —
/// a stable configuration fact, not the live per-second measured throughput
/// (`LiveViewController.measuredBitrateKbps`, shown separately on LIVE-038's
/// connection indicator instead), which naturally jitters with scene
/// motion/compression and isn't what "what's this camera's bitrate set to"
/// is asking.
class BitrateBadge extends StatelessWidget {
  const BitrateBadge({super.key, required this.configuredKbps});

  final double configuredKbps;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.speed, color: Colors.white, size: 14),
        const SizedBox(width: 4),
        Text(
          '${configuredKbps.round()} kbps',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Small app-side "signal strength" badge — colored bars icon (red at 0-1
/// bars, amber at 2, green at 3-4) scaled to [signalStrength], a 0–4 bar
/// rating matching `Camera.signalStrength`, plus the current network speed
/// auto-scaled to KB/s or MB/s (no numeric bar count shown) — composited by
/// the app rather than sent to or rendered by the camera.
class SignalStrengthBadge extends StatelessWidget {
  const SignalStrengthBadge({
    super.key,
    required this.signalStrength,
    required this.networkSpeedKbps,
  });

  final int signalStrength;
  final double networkSpeedKbps;

  IconData get _icon => switch (signalStrength.clamp(0, 4)) {
    0 => Icons.signal_cellular_0_bar,
    1 => Icons.signal_cellular_alt_1_bar,
    2 => Icons.signal_cellular_alt_2_bar,
    _ => Icons.signal_cellular_alt,
  };

  Color get _color => switch (signalStrength.clamp(0, 4)) {
    0 || 1 => AppColors.offline,
    2 => AppColors.attention,
    _ => AppColors.online,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(_icon, color: _color, size: 14),
        const SizedBox(width: 4),
        Text(
          formatBitrate(networkSpeedKbps),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Small colored dot, e.g. for a live/offline badge. When [blinking] is
/// true it pulses opacity in a continuous loop.
class StatusDot extends StatefulWidget {
  const StatusDot({super.key, required this.color, this.blinking = false});

  final Color color;
  final bool blinking;

  @override
  State<StatusDot> createState() => _StatusDotState();
}

class _StatusDotState extends State<StatusDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Created unconditionally (not as a lazy `late final` initializer) so it
    // always runs here, while the element is still mounted. A non-blinking
    // StatusDot never otherwise touches `_controller` in build(), so a lazy
    // initializer would only fire on first access — which turned out to be
    // inside dispose(), where creating a ticker is unsafe (the element is
    // already deactivated by then).
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.blinking) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant StatusDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.blinking && !oldWidget.blinking) {
      _controller.repeat(reverse: true);
    } else if (!widget.blinking && oldWidget.blinking) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color,
        boxShadow: [
          BoxShadow(color: widget.color.withValues(alpha: 0.7), blurRadius: 6),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.blinking) return _buildDot();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          Opacity(opacity: 0.35 + (_controller.value * 0.65), child: child),
      child: _buildDot(),
    );
  }
}
