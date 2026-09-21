import 'package:flutter/material.dart';

import '../screens/camera_live/camera_live_screen.dart' show RecordingClipSpan;
import 'camera_timeline.dart' show kRecordedBandColor;
import 'glass_card.dart';

/// One discrete zoom step for [ScrollableRecordingTimeline] — the total
/// visible time window, and the interval between labeled ticks within it.
class _ZoomLevel {
  const _ZoomLevel(this.label, this.windowSeconds, this.tickMinutes);

  final String label;
  final int windowSeconds;
  final int tickMinutes;
}

// "Day" removed 2026-09-08 per direct user request — real user reports
// traced the persistent time-sync drift to the widest zoom level in
// particular, and a full calendar day crammed into one screen width was
// unreadable anyway once the timeline started always spanning 24h.
const _zoomLevels = [
  _ZoomLevel('Hour', 3600, 15),
  _ZoomLevel('30 min', 1800, 10),
  _ZoomLevel('15 min', 900, 5),
  _ZoomLevel('5 min', 300, 1),
  _ZoomLevel('1 min', 60, 1),
];

/// The Playback tab's recording timeline (`LIVE-012`).
///
/// **Rebuilt from scratch, 2026-09-08**, after the previous
/// `ScrollController`-based design (fixed center needle, the day's tape
/// scrolled underneath via `SingleChildScrollView`) kept producing real,
/// recurring time-sync drift between the displayed time/needle and the
/// actual playing video, despite several targeted fixes — each one closed
/// one specific race (a zoom-level scale change vs. the scroll offset not
/// yet correcting to it, a fragile multi-flag "is this an external change"
/// check) without actually removing the *class* of bug: a `ScrollController`
/// keeps its own pixel-offset state, independent of the epoch it's meant to
/// represent, and every place that translates between the two (a scroll
/// listener, a `jumpTo`/`animateTo`, a notification callback) is one more
/// opportunity for them to disagree, especially across Flutter's own
/// layout-timing boundaries (a widget rebuild lands one frame before the
/// scrollable's content actually resizes to match).
///
/// This version has no `ScrollController` and no independent "scroll
/// position" at all. [_epoch] (or, while not being touched,
/// [widget.cursorEpochSeconds] directly) *is* the visible window's center —
/// every tick, recording segment, and event marker position is computed
/// directly from `epoch - halfWindowSeconds` on every `build`/`paint`, so
/// the needle (always drawn at the exact horizontal center) and the header
/// time label are, by construction, reading the same value — there is no
/// second, independently-updated value left for them to disagree with.
/// Dragging is a plain `GestureDetector.onHorizontalDragUpdate` converting
/// pixel delta directly to a time delta and moving [_epoch]; changing zoom
/// level just changes how many seconds map to the same screen width — since
/// the window is always *recomputed* from the current epoch rather than
/// carried over as a separate scroll offset, a zoom change needs no
/// corrective re-centering step at all, which structurally removes the
/// exact race the previous design kept hitting.
///
/// [onSeek] still fires continuously for live cursor-text preview only,
/// never reopening the RTSP session; [onSeekCommit] fires exactly once when
/// a drag gesture actually ends (snapping into the nearest recorded clip if
/// it ends in a gap) — same discipline the previous design had, preserved
/// because this camera's single-client RTSPS playback listener still can't
/// sanely absorb a real seek per drag-update frame.
///
/// Draws real event markers (`RecordingClipSpan.hasEvent`, the same
/// `RecordingClip.trigger` signal LIVE-013/020's Prev/Next Event buttons
/// use) as colored hatch blocks with an icon, and recorded segments in
/// `kRecordedBandColor` (`camera_timeline.dart`'s own sky-blue constant,
/// "Recorded" in Events' own legend too) — same visual language as
/// `CameraTimeline`'s own markers/band, recreated rather than reused.
class ScrollableRecordingTimeline extends StatefulWidget {
  const ScrollableRecordingTimeline({
    super.key,
    required this.spanStartEpochSeconds,
    required this.spanEndEpochSeconds,
    required this.clips,
    required this.cursorEpochSeconds,
    required this.onSeek,
    required this.onSeekCommit,
  });

  final int spanStartEpochSeconds;
  final int spanEndEpochSeconds;
  final List<RecordingClipSpan> clips;
  final int? cursorEpochSeconds;

  /// Fired continuously while dragging — moves the displayed cursor time
  /// for live preview only, never reopens the RTSP session.
  final void Function(int epochSeconds) onSeek;

  /// Fired once a drag gesture actually ends — this is what re-binds the
  /// real RTSP playback session to the new position.
  final void Function(int epochSeconds) onSeekCommit;

  @override
  State<ScrollableRecordingTimeline> createState() =>
      _ScrollableRecordingTimelineState();
}

class _ScrollableRecordingTimelineState
    extends State<ScrollableRecordingTimeline> {
  static const _trackHeight = 90.0;
  static const _minRecordedBandWidth = 6.0;

  int _levelIndex = 0;
  late int _epoch = widget.cursorEpochSeconds ?? widget.spanStartEpochSeconds;
  bool _isDragging = false;

  _ZoomLevel get _level => _zoomLevels[_levelIndex];
  int get _windowSeconds => _level.windowSeconds;

  /// The value actually shown in the header/needle, and the center of the
  /// window every other visual element is computed from — see this class's
  /// own doc for why a single value drives everything, rather than a
  /// separately-tracked scroll position.
  int get _displayEpoch =>
      _isDragging ? _epoch : (widget.cursorEpochSeconds ?? _epoch);

  bool _isRecorded(int epoch) =>
      widget.clips.any((c) => epoch >= c.start && epoch < c.end);

  int _clampToSpan(int epoch) =>
      epoch.clamp(widget.spanStartEpochSeconds, widget.spanEndEpochSeconds);

  int _nearestRecordedEpoch(int epoch) {
    if (widget.clips.isEmpty) return epoch;
    var best = epoch;
    var bestDistance = 1 << 62;
    for (final clip in widget.clips) {
      if (epoch < clip.start) {
        final distance = clip.start - epoch;
        if (distance < bestDistance) {
          bestDistance = distance;
          best = clip.start;
        }
      } else if (epoch >= clip.end) {
        final distance = epoch - (clip.end - 1);
        if (distance < bestDistance) {
          bestDistance = distance;
          best = clip.end - 1;
        }
      } else {
        return epoch;
      }
    }
    return best;
  }

  void _onDragStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
      _epoch = _displayEpoch;
    });
  }

  void _onDragUpdate(DragUpdateDetails details, double pixelsPerSecond) {
    final deltaSeconds = -(details.delta.dx / pixelsPerSecond).round();
    if (deltaSeconds == 0) return;
    setState(() => _epoch = _clampToSpan(_epoch + deltaSeconds));
    widget.onSeek(_epoch);
  }

  void _onDragEnd(DragEndDetails details) {
    final target = _isRecorded(_epoch) ? _epoch : _nearestRecordedEpoch(_epoch);
    setState(() {
      _epoch = target;
      _isDragging = false;
    });
    widget.onSeekCommit(target);
  }

  void _onTapUp(TapUpDetails details, double pixelsPerSecond, double width) {
    final tapEpoch = _clampToSpan(
      _displayEpoch +
          ((details.localPosition.dx - width / 2) / pixelsPerSecond).round(),
    );
    final target = _isRecorded(tapEpoch)
        ? tapEpoch
        : _nearestRecordedEpoch(tapEpoch);
    setState(() => _epoch = target);
    widget.onSeek(target);
    widget.onSeekCommit(target);
  }

  void _zoomIn() {
    if (_levelIndex >= _zoomLevels.length - 1) return;
    setState(() => _levelIndex++);
  }

  void _zoomOut() {
    if (_levelIndex <= 0) return;
    setState(() => _levelIndex--);
  }

  String get _timeLabel {
    final t = DateTime.fromMillisecondsSinceEpoch(
      _displayEpoch * 1000,
    ).toLocal();
    final hour12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final period = t.hour < 12 ? 'AM' : 'PM';
    return '$hour12:${t.minute.toString().padLeft(2, '0')} $period';
  }

  String _tickLabel(int epochSeconds) {
    final t = DateTime.fromMillisecondsSinceEpoch(
      epochSeconds * 1000,
    ).toLocal();
    return '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayEpoch = _displayEpoch;

    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      borderRadius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _timeLabel,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  Text(
                    '${_level.label} view',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const Key('LIVE-056'),
                    tooltip: 'Zoom out',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    onPressed: _levelIndex > 0 ? _zoomOut : null,
                  ),
                  IconButton(
                    key: const Key('LIVE-057'),
                    tooltip: 'Zoom in',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    onPressed: _levelIndex < _zoomLevels.length - 1
                        ? _zoomIn
                        : null,
                  ),
                ],
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                _LegendDot(color: colorScheme.tertiary, label: 'Event'),
                const _LegendDot(color: kRecordedBandColor, label: 'Recorded'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final pixelsPerSecond = width / _windowSeconds;
              final windowStart = displayEpoch - _windowSeconds ~/ 2;

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onHorizontalDragStart: _onDragStart,
                onHorizontalDragUpdate: (d) =>
                    _onDragUpdate(d, pixelsPerSecond),
                onHorizontalDragEnd: _onDragEnd,
                onTapUp: (d) => _onTapUp(d, pixelsPerSecond, width),
                child: SizedBox(
                  height: _trackHeight + 20,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 30,
                        bottom: 22,
                        left: 0,
                        right: 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.08,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      ..._buildRecordingBand(
                        windowStart,
                        pixelsPerSecond,
                        width,
                      ),
                      ..._buildTicks(
                        context,
                        windowStart,
                        pixelsPerSecond,
                        width,
                      ),
                      ..._buildEventMarkers(
                        windowStart,
                        pixelsPerSecond,
                        width,
                      ),
                      Positioned(
                        left: width / 2 - 1.5,
                        top: 0,
                        bottom: 22,
                        child: IgnorePointer(
                          child: Container(width: 3, color: colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  double _xFor(int epoch, int windowStart, double pixelsPerSecond) =>
      (epoch - windowStart) * pixelsPerSecond;

  List<Widget> _buildRecordingBand(
    int windowStart,
    double pixelsPerSecond,
    double width,
  ) {
    final widgets = <Widget>[];
    for (final clip in widget.clips) {
      if (clip.end <= clip.start) continue;
      final left = _xFor(clip.start, windowStart, pixelsPerSecond);
      final right = _xFor(clip.end, windowStart, pixelsPerSecond);
      // Only clips that actually fall (at least partly) within the visible
      // window — `widget.clips` covers the whole day, and most of them sit
      // far outside whatever's currently on screen at any real zoom level.
      if (right < 0 || left > width) continue;
      final clampedWidth = (right - left).clamp(
        _minRecordedBandWidth,
        double.infinity,
      );
      widgets.add(
        Positioned(
          left: left,
          width: clampedWidth,
          top: 30,
          bottom: 22,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: kRecordedBandColor.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  List<Widget> _buildTicks(
    BuildContext context,
    int windowStart,
    double pixelsPerSecond,
    double width,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final widgets = <Widget>[];
    final tickIntervalSeconds = _level.tickMinutes * 60;
    final firstTick =
        ((windowStart + tickIntervalSeconds - 1) ~/ tickIntervalSeconds) *
        tickIntervalSeconds;
    final windowEnd = windowStart + _windowSeconds;

    for (var t = firstTick; t <= windowEnd; t += tickIntervalSeconds) {
      final x = _xFor(t, windowStart, pixelsPerSecond);
      widgets.add(
        Positioned(
          left: x - 0.5,
          top: 30,
          bottom: 22,
          child: Container(
            width: 1.5,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      );
      // Only a label that fits fully within the visible width — this
      // widget's canvas *is* the viewport (no separate scrollable content
      // wider than it), so a label near either edge could otherwise render
      // half-cut instead of being skipped cleanly.
      final labelLeft = x - 24;
      if (labelLeft >= 0 && labelLeft + 48 <= width) {
        widgets.add(
          Positioned(
            left: labelLeft,
            bottom: 0,
            width: 48,
            child: Text(
              _tickLabel(t),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );
      }
    }
    return widgets;
  }

  /// Event markers — a colored hatch block + icon over every event-triggered
  /// clip's own span, same visual language `CameraTimeline._buildMarkerBlock`
  /// uses for Events' motion/person/alert markers, driven here by
  /// `RecordingClipSpan.hasEvent` (the same `RecordingClip.trigger` signal
  /// LIVE-013/020's Prev/Next Event buttons already use).
  List<Widget> _buildEventMarkers(
    int windowStart,
    double pixelsPerSecond,
    double width,
  ) {
    final widgets = <Widget>[];
    for (final clip in widget.clips) {
      if (!clip.hasEvent) continue;
      final left = _xFor(clip.start, windowStart, pixelsPerSecond);
      final right = _xFor(clip.end, windowStart, pixelsPerSecond);
      if (right < 0 || left > width) continue;
      final markerWidth = (right - left).clamp(6.0, double.infinity);
      widgets.add(
        Positioned(
          left: left,
          top: 0,
          bottom: 22,
          width: markerWidth,
          child: Builder(
            builder: (context) {
              final color = Theme.of(context).colorScheme.tertiary;
              return Column(
                children: [
                  Icon(Icons.bolt_rounded, size: 16, color: color),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: CustomPaint(
                        painter: _EventHatchPainter(color),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
    }
    return widgets;
  }
}

/// Paints a solid color plus a fixed-pixel-spacing vertical hatch/grid
/// texture on top — spacing stays constant in logical pixels (not
/// proportional to the block's width), same as
/// `CameraTimeline`'s own `_EventBlockPainter`, recreated here rather than
/// imported/reused per this widget's own doc.
class _EventHatchPainter extends CustomPainter {
  const _EventHatchPainter(this.color);

  final Color color;
  static const _spacing = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1;
    for (var x = _spacing; x < size.width; x += _spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EventHatchPainter oldDelegate) =>
      oldDelegate.color != color;
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
