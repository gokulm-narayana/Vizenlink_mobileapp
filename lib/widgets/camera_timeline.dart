import 'package:flutter/material.dart';

import 'glass_card.dart';

/// Fallback color for the "Recorded" legend swatch / band when a screen
/// doesn't supply its own — kept distinct from any single event-marker color
/// used by either screen.
const kRecordedBandColor = Color(0xFF38BDF8);

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
    _lastEmittedFraction = fraction;
    widget.onNeedleFractionChanged(fraction);
  }

  void _onScrollEnd() {
    if (!widget.enforceRecordingBounds) return;
    if (_isRecorded(_fraction)) return;
    final snapped = _nearestRecordedFraction(_fraction);
    _centerOn(snapped * 24 * 60, animate: true);
    _lastEmittedFraction = snapped;
    widget.onNeedleFractionChanged(snapped);
  }

  void _centerOn(double minutes, {bool animate = false}) {
    if (!_controller.hasClients || _viewportWidth == 0) return;
    final sidePadding = _viewportWidth / 2;
    final offset = (minutes / (24 * 60)) * _totalWidth - sidePadding;
    final clamped = offset.clamp(0.0, _totalWidth);
    if (animate) {
      _controller.animateTo(
        clamped,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
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
            Positioned(
              left: range.start * _totalWidth,
              width: (range.end - range.start) * _totalWidth,
              top: 0,
              bottom: 0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: kRecordedBandColor.withValues(alpha: 0.55),
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
      widgets.add(
        Positioned(
          left: left - 24,
          bottom: 0,
          width: 48,
          child: Text(
            _tickLabel(m, _level.tickMinutes),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
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
