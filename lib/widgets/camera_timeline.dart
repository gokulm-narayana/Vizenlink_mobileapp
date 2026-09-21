import 'package:flutter/material.dart';

import 'glass_card.dart';

/// Fallback color for the "Recorded" legend swatch / band when a screen
/// doesn't supply its own — kept distinct from any single event-marker color
/// used by either screen.
const kRecordedBandColor = Color(0xFF38BDF8);

/// Floor on how narrow a single recorded-range segment (`_buildRecordingBand`)
/// is ever allowed to render, regardless of the real clip's own proportional
/// width at the current zoom level — see that method's own doc comment.
const _minRecordedBandWidth = 6.0;

/// A contiguous span of the day (as a 0..1 fraction) for which footage
/// exists. Anything not covered by a [TimelineRange] renders as a gray dead
/// zone instead of the blue "recorded" band.
class TimelineRange {
  const TimelineRange(this.start, this.end);

  final double start;
  final double end;

  bool contains(double fraction) => fraction >= start && fraction <= end;
}

/// One discrete event marker (motion/person/alert/etc.), positioned as a
/// fraction of the 24-hour day, rendered as an icon over a hatched color
/// block.
class TimelineMarker {
  const TimelineMarker({
    this.key,
    required this.startFraction,
    required this.endFraction,
    required this.color,
    this.icon,
    this.onTap,
  });

  final Key? key;
  final double startFraction;
  final double endFraction;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;
}

class TimelineLegendEntry {
  const TimelineLegendEntry({required this.color, required this.label});

  final Color color;
  final String label;
}

/// One discrete zoom step, stepped via the zoom in/out buttons. Each level
/// relays out ticks/labels at a new density (real widget relayout, not a
/// scaled/blurry transform), matching how professional VMS apps
/// (Hikvision/Dahua/etc.) reveal progressively finer detail as you zoom.
class TimelineZoomLevel {
  const TimelineZoomLevel(this.label, this.pixelsPerHour, this.tickMinutes);

  final String label;
  final double pixelsPerHour;

  /// Interval, in minutes, between labeled ticks at this level.
  final int tickMinutes;
}

const kCameraTimelineZoomLevels = [
  TimelineZoomLevel('Day', 70, 120),
  TimelineZoomLevel('Hour', 200, 60),
  TimelineZoomLevel('30 min', 500, 30),
  TimelineZoomLevel('15 min', 1000, 15),
  TimelineZoomLevel('5 min', 2500, 5),
  TimelineZoomLevel('1 min', 6000, 1),
];

enum _ActiveHandle { start, end }

/// Shared 24-hour scrubbing timeline used by both the Events screen and the
/// Camera Live screen's Playback tab: a fixed center needle stays put while
/// the day's tape (recording-availability band, event markers, ruler ticks)
/// is scrolled underneath it, with discrete zoom levels stepped via +/-
/// buttons.
///
/// [recordedRanges] paints a solid blue band; anything outside those ranges
/// renders as a flat gray dead zone. When [enforceRecordingBounds] is true
/// (Playback, which drives real video seeking), scrolling into a dead zone
/// snaps the needle back to the nearest recorded boundary once the drag
/// ends; Events leaves dead zones purely cosmetic since browsing there
/// doesn't seek any video.
///
/// [selectionStartFraction]/[selectionEndFraction] + [onSelectionChanged]
/// opt in to two draggable clip-range handles overlaid on the timeline
/// (Playback's clip start/end markers); leave all three null to omit them
/// (Events).
class CameraTimeline extends StatefulWidget {
  const CameraTimeline({
    super.key,
    required this.markers,
    required this.recordedRanges,
    required this.legend,
    required this.needleFraction,
    required this.onNeedleFractionChanged,
    this.enforceRecordingBounds = false,
    this.showTickLabels = true,
    this.selectionStartFraction,
    this.selectionEndFraction,
    this.onSelectionChanged,
    this.selectionStartKey,
    this.selectionEndKey,
    required this.rulerKey,
    this.zoomOutKey,
    this.zoomInKey,
    required this.timeLabelKey,
    required this.legendKey,
    this.recordingBandKey,
  });

  final List<TimelineMarker> markers;
  final List<TimelineRange> recordedRanges;
  final List<TimelineLegendEntry> legend;

  /// Current needle position, as a 0..1 fraction of the day. The widget is a
  /// controlled component: it reports scroll-driven changes via
  /// [onNeedleFractionChanged], and re-centers on this value whenever it
  /// changes for a reason other than the widget's own last report (e.g. a
  /// "Next Event" button or a day-selector reset).
  final double needleFraction;
  final ValueChanged<double> onNeedleFractionChanged;

  final bool enforceRecordingBounds;

  /// Whether each ruler tick shows its own "HH:MM" text label beneath it.
  /// **Off for Playback** (`camera_live_screen.dart`, 2026-09-07 — direct
  /// user request: "remove that line... only auto scroll the line bar") —
  /// a tick label sitting at the exact edge of the scrolled-to viewport
  /// could render as a stray clipped fragment (e.g. a bare "0" or "1"
  /// instead of a real "13:30"), read as the needle/playback position
  /// being out of sync when it never actually was. Removing the labels
  /// entirely (keeping the tick lines and the single big time-of-day
  /// readout in the header) sidesteps that whole class of bug rather than
  /// patching the clipping further. **Still on for Events** (unchanged,
  /// [events_screen.md]'s EVT-007), where hour markers along the bar are
  /// more useful than they are for Playback's own always-visible needle.
  final bool showTickLabels;

  final double? selectionStartFraction;
  final double? selectionEndFraction;
  final void Function(double start, double end)? onSelectionChanged;
  final Key? selectionStartKey;
  final Key? selectionEndKey;

  final Key rulerKey;
  final Key? zoomOutKey;
  final Key? zoomInKey;
  final Key timeLabelKey;
  final Key legendKey;
  final Key? recordingBandKey;

  bool get _hasSelectionHandles =>
      selectionStartFraction != null &&
      selectionEndFraction != null &&
      onSelectionChanged != null;

  @override
  State<CameraTimeline> createState() => _CameraTimelineState();
}

class _CameraTimelineState extends State<CameraTimeline> {
  static const _trackHeight = 90.0;
  static const _handleWidth = 20.0;
  static const _minSelectionSpan = 0.0015; // ~2 minutes of a day.

  final _controller = ScrollController();
  int _levelIndex = 0;
  late double _fraction = widget.needleFraction;
  double? _lastEmittedFraction;
  bool _didSetInitialOffset = false;
  double _viewportWidth = 0;
  _ActiveHandle? _activeHandle;

  /// True for the duration of a programmatic `_centerOn(..., animate:
  /// true)` scroll (e.g. re-centering on an externally-driven
  /// [needleFraction] change, like the Playback tab's video advancing
  /// during normal playback). [_onScroll] fires on every intermediate
  /// frame of that animation the same as a real user scroll, since
  /// `ScrollController.animateTo` posts scroll notifications throughout —
  /// without this guard, each of those intermediate frames re-emitted
  /// [onNeedleFractionChanged] with a value ahead of where the video
  /// actually was, and `_PlaybackTabState._seekToFraction` seeking on each
  /// one compounded into the video visibly playing at roughly 2x speed
  /// with stutter ("gaps") — a feedback loop between this widget centering
  /// itself on the video's position and its own centering motion being
  /// mistaken for a fresh user-driven position to seek to. Real bug, not
  /// video-encoding related — found 2026-08-28 after ruling out the
  /// bundled sample clip's frame rate.
  bool _isProgrammaticCenter = false;

  TimelineZoomLevel get _level => kCameraTimelineZoomLevels[_levelIndex];
  double get _totalWidth => _level.pixelsPerHour * 24;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  @override
  void didUpdateWidget(covariant CameraTimeline oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.needleFraction;
    final isExternalChange =
        _lastEmittedFraction == null ||
        (incoming - _lastEmittedFraction!).abs() > 0.0001;
    if (isExternalChange && (incoming - _fraction).abs() > 0.0001) {
      _fraction = incoming;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _centerOn(_fraction * 24 * 60, animate: true),
      );
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    _controller.dispose();
    super.dispose();
  }

  bool _isRecorded(double fraction) =>
      widget.recordedRanges.any((r) => r.contains(fraction));

  double _nearestRecordedFraction(double fraction) {
    if (widget.recordedRanges.isEmpty) return fraction;
    var best = fraction;
    var bestDistance = double.infinity;
    for (final range in widget.recordedRanges) {
      if (fraction < range.start) {
        final distance = range.start - fraction;
        if (distance < bestDistance) {
          bestDistance = distance;
          best = range.start;
        }
      } else if (fraction > range.end) {
        final distance = fraction - range.end;
        if (distance < bestDistance) {
          bestDistance = distance;
          best = range.end;
        }
      } else {
        return fraction;
      }
    }
    return best;
  }

  void _onScroll() {
    if (!_controller.hasClients || _activeHandle != null) return;
    final viewport = _controller.position.viewportDimension;
    final centerX = _controller.offset + viewport / 2;
    final fraction = (centerX / _totalWidth).clamp(0.0, 1.0);
    setState(() => _fraction = fraction);
    // Don't echo this frame back as a "new" position while we're the ones
    // driving the scroll (see [_isProgrammaticCenter]'s doc) — otherwise
    // every intermediate animation frame re-triggers a seek ahead of where
    // the video/needle actually is.
    if (_isProgrammaticCenter) return;
    _lastEmittedFraction = fraction;
    widget.onNeedleFractionChanged(fraction);
  }

  /// Real bug, found 2026-09-07 via a stack-overflow crash with real
  /// (sparse, short-clip) recording data: `ScrollController.animateTo`
  /// short-circuits to a synchronous `jumpTo` whenever the target is
  /// already at/near the current offset (Flutter's own "nearEqual" check),
  /// and `jumpTo` *unconditionally* fires a new `ScrollEndNotification`
  /// before returning — which re-enters this exact method. If the computed
  /// snap target lands back on the same not-recorded fraction (e.g. we're
  /// already sitting at whichever timeline edge is nearest to a gap with
  /// nothing recorded on either side), every call recomputes the identical
  /// target, `animateTo` takes the identical `jumpTo` shortcut, and the
  /// notification fires again — infinite synchronous recursion until the
  /// call stack overflows. The old mocked ranges (always wide, tens-of-
  /// minutes blocks) essentially never left the scrubber sitting exactly at
  /// an unrecorded edge with no closer target to converge to; real clip
  /// data does. This guard makes a re-entrant call while already handling
  /// one a no-op instead of recursing.
  bool _isHandlingScrollEnd = false;

  void _onScrollEnd() {
    if (_isHandlingScrollEnd) return;
    if (!widget.enforceRecordingBounds) return;
    if (_isRecorded(_fraction)) return;
    _isHandlingScrollEnd = true;
    try {
      final snapped = _nearestRecordedFraction(_fraction);
      _centerOn(snapped * 24 * 60, animate: true);
      _lastEmittedFraction = snapped;
      widget.onNeedleFractionChanged(snapped);
    } finally {
      _isHandlingScrollEnd = false;
    }
  }

  void _centerOn(double minutes, {bool animate = false}) {
    if (!_controller.hasClients || _viewportWidth == 0) return;
    final sidePadding = _viewportWidth / 2;
    final offset = (minutes / (24 * 60)) * _totalWidth - sidePadding;
    final clamped = offset.clamp(0.0, _totalWidth);
    if (animate) {
      _isProgrammaticCenter = true;
      _controller
          .animateTo(
            clamped,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          )
          .whenComplete(() => _isProgrammaticCenter = false);
    } else {
      _controller.jumpTo(clamped);
    }
  }

  void _zoomIn() {
    if (_levelIndex >= kCameraTimelineZoomLevels.length - 1) return;
    final center = _fraction * 24 * 60;
    setState(() => _levelIndex++);
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOn(center));
  }

  void _zoomOut() {
    if (_levelIndex <= 0) return;
    final center = _fraction * 24 * 60;
    setState(() => _levelIndex--);
    WidgetsBinding.instance.addPostFrameCallback((_) => _centerOn(center));
  }

  String get _timeLabel {
    final totalMinutes = (_fraction * 24 * 60).round().clamp(0, 24 * 60 - 1);
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    final period = hours >= 12 ? 'PM' : 'AM';
    final displayHour = hours % 12 == 0 ? 12 : hours % 12;
    return '$displayHour:${minutes.toString().padLeft(2, '0')} $period';
  }

  static String _tickLabel(int minuteOfDay, int tickMinutes) {
    final hour = (minuteOfDay ~/ 60) % 24;
    final minute = minuteOfDay % 60;
    if (tickMinutes >= 60) return '${hour.toString().padLeft(2, '0')}:00';
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  void _onHandleDragStart(_ActiveHandle handle) {
    setState(() => _activeHandle = handle);
  }

  void _onHandleDragUpdate(_ActiveHandle handle, DragUpdateDetails details) {
    final start = widget.selectionStartFraction;
    final end = widget.selectionEndFraction;
    if (start == null || end == null) return;
    final deltaFraction = details.delta.dx / _totalWidth;
    if (handle == _ActiveHandle.start) {
      final next = (start + deltaFraction).clamp(0.0, end - _minSelectionSpan);
      widget.onSelectionChanged?.call(next, end);
    } else {
      final next = (end + deltaFraction).clamp(start + _minSelectionSpan, 1.0);
      widget.onSelectionChanged?.call(start, next);
    }
  }

  void _onHandleDragEnd() {
    setState(() => _activeHandle = null);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                    key: widget.timeLabelKey,
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
                    key: widget.zoomOutKey,
                    tooltip: 'Zoom out',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.remove_circle_outline_rounded),
                    onPressed: _levelIndex > 0 ? _zoomOut : null,
                  ),
                  IconButton(
                    key: widget.zoomInKey,
                    tooltip: 'Zoom in',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    onPressed:
                        _levelIndex < kCameraTimelineZoomLevels.length - 1
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
              key: widget.legendKey,
              spacing: 10,
              runSpacing: 4,
              children: [
                for (final entry in widget.legend)
                  _LegendDot(color: entry.color, label: entry.label),
              ],
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            key: widget.rulerKey,
            builder: (context, constraints) {
              final viewportWidth = constraints.maxWidth;
              final sidePadding = viewportWidth / 2;
              _viewportWidth = viewportWidth;

              if (!_didSetInitialOffset) {
                _didSetInitialOffset = true;
                final initialOffset = _fraction * _totalWidth - sidePadding;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_controller.hasClients) {
                    _controller.jumpTo(initialOffset.clamp(0.0, _totalWidth));
                  }
                });
              }

              return SizedBox(
                height: _trackHeight + 20,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollEndNotification) {
                          _onScrollEnd();
                        }
                        return false;
                      },
                      child: SingleChildScrollView(
                        controller: _controller,
                        scrollDirection: Axis.horizontal,
                        physics: _activeHandle != null
                            ? const NeverScrollableScrollPhysics()
                            : null,
                        padding: EdgeInsets.symmetric(horizontal: sidePadding),
                        child: SizedBox(
                          width: _totalWidth,
                          height: _trackHeight,
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
                              _buildRecordingBand(),
                              ..._buildTicks(context),
                              for (final marker in widget.markers)
                                _buildMarkerBlock(marker),
                              if (widget._hasSelectionHandles)
                                ..._buildSelectionOverlay(colorScheme),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: viewportWidth / 2 - 1.5,
                      top: 0,
                      bottom: 22,
                      child: IgnorePointer(
                        child: Container(width: 3, color: colorScheme.error),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecordingBand() {
    return Positioned(
      key: widget.recordingBandKey,
      top: 30,
      bottom: 22,
      left: 0,
      right: 0,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final range in widget.recordedRanges)
            if (range.end > range.start)
              Positioned(
                // A short real clip (event-triggered recordings are often
                // just seconds long) can compute to well under a pixel wide
                // at a zoomed-out level like Day (70px/hour here) —
                // clamping to a minimum width keeps every real recording
                // visibly represented as at least a thin tick, instead of
                // silently disappearing. The old mocked ranges never
                // exposed this since they were always tens of minutes wide.
                left: (range.start * _totalWidth).clamp(
                  0.0,
                  _totalWidth - _minRecordedBandWidth,
                ),
                width: ((range.end - range.start) * _totalWidth).clamp(
                  _minRecordedBandWidth,
                  _totalWidth,
                ),
                top: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: kRecordedBandColor.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  List<Widget> _buildTicks(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final pixelsPerMinute = _level.pixelsPerHour / 60;
    final widgets = <Widget>[];
    final subdivide = _level.tickMinutes >= 5;

    // Real bug, found 2026-09-07 from a direct user report ("scroll time
    // and line is not sync") — a tick label sitting right at the edge of
    // the currently-scrolled-to viewport rendered as just a stray
    // fragment (e.g. "0", later "1" at the opposite edge, instead of a
    // real "13:30"), read as the needle and playback position being out
    // of sync when they weren't (the video's own burned-in timestamp
    // matched the needle's real time exactly). The label box itself was
    // never actually wrong — only *partially* visible, clipped by the
    // scroll viewport's own edge, the same way any horizontally-scrolling
    // ruler clips content mid-scroll. Skipping a label entirely (keeping
    // its tick line) whenever its own 48px box wouldn't render fully
    // on-screen avoids ever showing that confusing fragment.
    //
    // First attempt at this fix (same day) compared a tick's content-local
    // `left` directly against `_controller.offset` — still visibly broken
    // (confirmed via a follow-up screenshot showing a bare "1" at the
    // *right* edge this time) because `_controller.offset` is measured in
    // the scroll view's own coordinate space, which is `sidePadding`
    // (`_viewportWidth / 2`) ahead of a tick's content-local `left` — the
    // `SingleChildScrollView`'s own `padding: EdgeInsets.symmetric(
    // horizontal: sidePadding)` shifts everything inside it right by that
    // amount relative to scroll offset 0. Converting the visible window
    // into that same content-local space (`offset - sidePadding` ..
    // `offset + sidePadding`) before comparing is what actually fixes it.
    final sidePadding = _viewportWidth / 2;
    final offset = _controller.hasClients ? _controller.offset : sidePadding;
    final visibleLeft = offset - sidePadding;
    final visibleRight = offset + sidePadding;

    for (var m = 0; m <= 24 * 60; m += _level.tickMinutes) {
      final left = m * pixelsPerMinute;
      widgets.add(
        Positioned(
          left: left - 0.5,
          top: 30,
          bottom: 22,
          child: Container(
            width: 1,
            color: colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
      );
      widgets.add(
        Positioned(
          left: left - 0.5,
          top: 30,
          height: 12,
          child: Container(
            width: 1.5,
            color: colorScheme.onSurface.withValues(alpha: 0.4),
          ),
        ),
      );
      final labelLeft = left - 24;
      final labelFullyVisible =
          _viewportWidth <= 0 ||
          (labelLeft >= visibleLeft && labelLeft + 48 <= visibleRight);
      if (widget.showTickLabels && labelFullyVisible) {
        widgets.add(
          Positioned(
            left: labelLeft,
            bottom: 0,
            width: 48,
            child: Text(
              _tickLabel(m, _level.tickMinutes),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        );
      }
      if (subdivide && m < 24 * 60) {
        final subLeft = left + (_level.tickMinutes / 2) * pixelsPerMinute;
        widgets.add(
          Positioned(
            left: subLeft - 0.5,
            top: 30,
            bottom: 22,
            child: Container(
              width: 1,
              color: colorScheme.onSurface.withValues(alpha: 0.04),
            ),
          ),
        );
      }
    }
    return widgets;
  }

  Widget _buildMarkerBlock(TimelineMarker marker) {
    final left = marker.startFraction * _totalWidth;
    final width = ((marker.endFraction - marker.startFraction) * _totalWidth)
        .clamp(6.0, double.infinity);
    return Positioned(
      key: marker.key,
      left: left,
      top: 0,
      bottom: 22,
      width: width,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: marker.onTap,
        child: Column(
          children: [
            if (marker.icon != null)
              Icon(marker.icon, size: 16, color: marker.color),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: CustomPaint(
                  painter: _EventBlockPainter(marker.color),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildSelectionOverlay(ColorScheme colorScheme) {
    final start = widget.selectionStartFraction!;
    final end = widget.selectionEndFraction!;
    return [
      Positioned(
        left: start * _totalWidth,
        width: (end - start) * _totalWidth,
        top: 30,
        bottom: 22,
        child: IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.18),
            ),
          ),
        ),
      ),
      _buildHandle(
        _ActiveHandle.start,
        start,
        widget.selectionStartKey,
        _kClipStartColor,
      ),
      _buildHandle(
        _ActiveHandle.end,
        end,
        widget.selectionEndKey,
        _kClipEndColor,
      ),
    ];
  }

  Widget _buildHandle(
    _ActiveHandle handle,
    double fraction,
    Key? key,
    Color color,
  ) {
    return Positioned(
      key: key,
      left: fraction * _totalWidth - _handleWidth / 2,
      top: 8,
      bottom: 12,
      width: _handleWidth,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => _onHandleDragStart(handle),
        onHorizontalDragUpdate: (details) =>
            _onHandleDragUpdate(handle, details),
        onHorizontalDragEnd: (_) => _onHandleDragEnd(),
        onHorizontalDragCancel: _onHandleDragEnd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: _handleWidth,
              height: _handleWidth,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black45, blurRadius: 3),
                ],
              ),
              child: Icon(
                handle == _ActiveHandle.start
                    ? Icons.chevron_right
                    : Icons.chevron_left,
                size: 14,
                color: Colors.white,
              ),
            ),
            Expanded(
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Distinct, high-contrast colors for the clip start/end handles so they're
/// unmistakably two separate draggable bars rather than blending into the
/// timeline background.
const _kClipStartColor = Color(0xFF22C55E);
const _kClipEndColor = Color(0xFFF97316);

/// Paints an event block's solid color plus a fixed-pixel-spacing vertical
/// hatch/grid texture on top — spacing stays constant in logical pixels
/// (not proportional to the block's width), so wider blocks at higher zoom
/// show visibly more grid lines rather than a couple of stretched stripes.
class _EventBlockPainter extends CustomPainter {
  const _EventBlockPainter(this.color);

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
  bool shouldRepaint(covariant _EventBlockPainter oldDelegate) =>
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
