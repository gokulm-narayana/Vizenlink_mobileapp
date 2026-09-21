import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/camera.dart';
import '../models/zone.dart';
import '../theme/app_colors.dart';
import 'camera_thumbnail_image.dart';

export '../models/zone.dart';

/// Renders [camera]'s thumbnail (or a placeholder) inside the given
/// [child] area, e.g. wrapped by a `Stack` that overlays zones/lines on
/// top. Extracted so preview screens that draw over the camera image don't
/// each reimplement the placeholder/loading/error states.
class CameraImage extends StatelessWidget {
  const CameraImage({super.key, required this.camera, this.overrideBytes});

  final Camera camera;

  /// See `CameraPreviewThumbnail.overrideBytes`'s doc — same
  /// never-persisted transient-frame contract.
  final Uint8List? overrideBytes;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bytes = overrideBytes;
    final thumbnailUrl = camera.thumbnailUrl;

    if (bytes != null) {
      return Image.memory(bytes, fit: BoxFit.cover, gaplessPlayback: true);
    }

    if (thumbnailUrl == null) {
      return _placeholder(colorScheme, isDark);
    }

    return CameraThumbnailImage(
      thumbnailUrl: thumbnailUrl,
      fit: BoxFit.cover,
      placeholderBuilder: () => _placeholder(colorScheme, isDark),
    );
  }

  Widget _placeholder(ColorScheme colorScheme, bool isDark) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  colorScheme.primary.withValues(alpha: 0.4),
                  AppColors.cyan.withValues(alpha: 0.18),
                ]
              : [
                  colorScheme.primary.withValues(alpha: 0.22),
                  AppColors.cyan.withValues(alpha: 0.12),
                ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.videocam_rounded,
          color: colorScheme.primary,
          size: 40,
        ),
      ),
    );
  }
}

/// A single draggable/resizable zone rectangle on a preview. [rect] is
/// fractional (0-1) bounds of the preview area; drag moves it, one of the
/// four corner handles resizes it (each corner drags freely while the
/// opposite corner stays anchored), both clamped so the rect never leaves
/// the preview and never shrinks below [minZoneWidth]/[minZoneHeight].
class ZoneOverlay extends StatelessWidget {
  const ZoneOverlay({
    super.key,
    required this.rect,
    required this.areaSize,
    required this.selected,
    required this.icon,
    required this.onTap,
    required this.onRectChanged,
  });

  final Rect rect;
  final Size areaSize;
  final bool selected;
  final IconData icon;
  final VoidCallback onTap;
  final ValueChanged<Rect> onRectChanged;

  Rect _pixelRect() {
    return Rect.fromLTWH(
      rect.left * areaSize.width,
      rect.top * areaSize.height,
      rect.width * areaSize.width,
      rect.height * areaSize.height,
    );
  }

  Rect _clampPixelRect(Rect pixelRect) {
    final minWidth = minZoneWidth * areaSize.width;
    final minHeight = minZoneHeight * areaSize.height;
    final width = pixelRect.width.clamp(minWidth, areaSize.width);
    final height = pixelRect.height.clamp(minHeight, areaSize.height);
    final left = pixelRect.left.clamp(0.0, areaSize.width - width);
    final top = pixelRect.top.clamp(0.0, areaSize.height - height);
    return Rect.fromLTWH(left, top, width, height);
  }

  void _emitPixelRect(Rect pixelRect) {
    if (areaSize.width == 0 || areaSize.height == 0) return;
    final clamped = _clampPixelRect(pixelRect);
    onRectChanged(
      Rect.fromLTWH(
        clamped.left / areaSize.width,
        clamped.top / areaSize.height,
        clamped.width / areaSize.width,
        clamped.height / areaSize.height,
      ),
    );
  }

  /// Resizes from [corner], keeping the opposite corner anchored.
  void _resizeFromCorner(Rect pixelRect, _ZoneCorner corner, Offset delta) {
    switch (corner) {
      case _ZoneCorner.topLeft:
        _emitPixelRect(
          Rect.fromLTRB(
            pixelRect.left + delta.dx,
            pixelRect.top + delta.dy,
            pixelRect.right,
            pixelRect.bottom,
          ),
        );
      case _ZoneCorner.topRight:
        _emitPixelRect(
          Rect.fromLTRB(
            pixelRect.left,
            pixelRect.top + delta.dy,
            pixelRect.right + delta.dx,
            pixelRect.bottom,
          ),
        );
      case _ZoneCorner.bottomLeft:
        _emitPixelRect(
          Rect.fromLTRB(
            pixelRect.left + delta.dx,
            pixelRect.top,
            pixelRect.right,
            pixelRect.bottom + delta.dy,
          ),
        );
      case _ZoneCorner.bottomRight:
        _emitPixelRect(
          Rect.fromLTRB(
            pixelRect.left,
            pixelRect.top,
            pixelRect.right + delta.dx,
            pixelRect.bottom + delta.dy,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pixelRect = _pixelRect();
    final colorScheme = Theme.of(context).colorScheme;
    final borderColor = selected ? colorScheme.primary : Colors.white;

    return Positioned(
      left: pixelRect.left,
      top: pixelRect.top,
      width: pixelRect.width,
      height: pixelRect.height,
      child: GestureDetector(
        onTap: onTap,
        onPanUpdate: (details) =>
            _emitPixelRect(pixelRect.shift(details.delta)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.65),
                border: Border.all(color: borderColor, width: 2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Center(child: Icon(icon, color: Colors.white70, size: 20)),
            ),
            for (final corner in _ZoneCorner.values)
              _CornerHandle(
                corner: corner,
                color: borderColor,
                onTap: onTap,
                onPanUpdate: (delta) =>
                    _resizeFromCorner(pixelRect, corner, delta),
              ),
          ],
        ),
      ),
    );
  }
}

/// Lets the user draw a new zone directly on the preview — drag a rough
/// rectangle, or tap for a default-size zone centered on the tap — as an
/// alternative to a fixed-position "Add zone" button. Reports the drawn
/// area as a fractional (0-1) [Rect] via [onZoneDrawn] once the gesture
/// ends; doesn't render or own any zone state itself. Place this
/// *underneath* existing [ZoneOverlay]s in a `Stack` (earlier in its
/// `children`) so a drag starting on an existing zone still moves/resizes
/// that zone instead of starting a new draw — Flutter hit-tests overlapping
/// `Stack` children in reverse paint order, so later (visually on-top)
/// children get first refusal.
class ZoneDrawSurface extends StatefulWidget {
  const ZoneDrawSurface({
    super.key,
    required this.areaSize,
    required this.enabled,
    required this.onZoneDrawn,
  });

  final Size areaSize;
  final bool enabled;
  final ValueChanged<Rect> onZoneDrawn;

  @override
  State<ZoneDrawSurface> createState() => _ZoneDrawSurfaceState();
}

class _ZoneDrawSurfaceState extends State<ZoneDrawSurface> {
  final _points = <Offset>[];

  Rect? _boundingPixelRect() {
    if (_points.isEmpty) return null;
    var minX = _points.first.dx;
    var maxX = minX;
    var minY = _points.first.dy;
    var maxY = minY;
    for (final point in _points) {
      if (point.dx < minX) minX = point.dx;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dy > maxY) maxY = point.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Converts a pixel-space rect (within [widget.areaSize]) into the
  /// fractional (0-1) rect a [DrawableZone] expects, floored to the same
  /// [minZoneWidth]/[minZoneHeight] `ZoneOverlay` itself enforces on resize,
  /// and kept fully within bounds.
  Rect _toFractional(Rect pixelRect) {
    final areaSize = widget.areaSize;
    if (areaSize.width == 0 || areaSize.height == 0) {
      return Rect.fromLTWH(0.1, 0.1, defaultZoneSize.dx, defaultZoneSize.dy);
    }
    final minWidth = minZoneWidth * areaSize.width;
    final minHeight = minZoneHeight * areaSize.height;
    final width = (pixelRect.width < minWidth ? minWidth : pixelRect.width)
        .clamp(0.0, areaSize.width);
    final height = (pixelRect.height < minHeight ? minHeight : pixelRect.height)
        .clamp(0.0, areaSize.height);
    final center = pixelRect.center;
    final left = (center.dx - width / 2).clamp(0.0, areaSize.width - width);
    final top = (center.dy - height / 2).clamp(0.0, areaSize.height - height);
    return Rect.fromLTWH(
      left / areaSize.width,
      top / areaSize.height,
      width / areaSize.width,
      height / areaSize.height,
    );
  }

  void _finishDrag() {
    final rect = _boundingPixelRect();
    setState(() => _points.clear());
    if (rect == null || rect.width < 4 || rect.height < 4) return;
    widget.onZoneDrawn(_toFractional(rect));
  }

  void _placeTapZone(Offset center) {
    final areaSize = widget.areaSize;
    widget.onZoneDrawn(
      _toFractional(
        Rect.fromCenter(
          center: center,
          width: defaultZoneSize.dx * areaSize.width,
          height: defaultZoneSize.dy * areaSize.height,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) => setState(
        () => _points
          ..clear()
          ..add(details.localPosition),
      ),
      onPanUpdate: (details) =>
          setState(() => _points.add(details.localPosition)),
      onPanEnd: (_) => _finishDrag(),
      onTapUp: (details) => _placeTapZone(details.localPosition),
      child: CustomPaint(
        painter: _points.length > 1
            ? _ZoneDrawPreviewPainter(points: _points)
            : null,
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Thin live-preview line while the user is mid-drag on a [ZoneDrawSurface]
/// — purely transient feedback, replaced by the real [ZoneOverlay] once the
/// gesture ends and [ZoneDrawSurface.onZoneDrawn] fires.
class _ZoneDrawPreviewPainter extends CustomPainter {
  const _ZoneDrawPreviewPainter({required this.points});

  final List<Offset> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ZoneDrawPreviewPainter oldDelegate) =>
      oldDelegate.points != points;
}

/// Lets the user trace a free-form polygon zone directly on the preview in
/// one continuous drag, as an alternative to placing vertices one at a time
/// (the `Add point`/`Finish zone` flow most polygon-zone screens use).
/// Reports the traced outline as fractional (0-1) points via [onZoneDrawn]
/// once the gesture ends (only if it closes into [minPolygonPoints]+ real
/// vertices — a tap or a too-short drag is discarded, same "must actually
/// mean it" threshold [ZoneDrawSurface] applies to its own tap-for-a-zone
/// shortcut).
///
/// A raw finger drag samples a new point on nearly every frame — capturing
/// all of them and handing them straight to the caller produces a "wall of
/// dots" polygon (one drag handle per sample) instead of a clean shape with
/// only its real corners, like [ZoneOverlay]'s 4-handle rectangle. Fixed by
/// running the finished trace through [_simplifyPolygon] (Ramer–Douglas–
/// Peucker) once the gesture ends — it keeps only the points a straight
/// line between neighbors can't already stand in for, collapsing a mostly-
/// straight edge traced as 40 wobbly samples down to the 2 points that
/// actually define it. A rough rectangle-ish trace comes out as ~4-6
/// vertices, the same ballpark a careful point-by-point trace would
/// produce; a genuinely curved boundary keeps more points, proportionally.
///
/// Same [Stack] placement rule as [ZoneDrawSurface]: put this *underneath*
/// existing [PolygonOverlay]s so a drag starting on an existing zone still
/// moves that zone's vertex instead of starting a new trace.
class PolygonDrawSurface extends StatefulWidget {
  const PolygonDrawSurface({
    super.key,
    required this.areaSize,
    required this.enabled,
    required this.onZoneDrawn,
  });

  final Size areaSize;
  final bool enabled;
  final ValueChanged<List<Offset>> onZoneDrawn;

  @override
  State<PolygonDrawSurface> createState() => _PolygonDrawSurfaceState();
}

class _PolygonDrawSurfaceState extends State<PolygonDrawSurface> {
  /// Minimum raw-sample spacing during the drag itself, before
  /// simplification — just enough to avoid recording literally every pixel
  /// of jitter. The real vertex-count control is [_simplifyPolygon] below,
  /// run once the gesture ends.
  static const _minSampleDistance = 0.01;

  /// Starting point (fractional, of the preview's shorter side) for how far
  /// a point may deviate from the straight line between its neighbors
  /// before [_simplifyPolygon] keeps it as a real corner — [_finishTrace]
  /// grows this until the result is reasonably clean (see
  /// [_maxTracedVertices]) rather than using one fixed pass.
  static const _simplifyTolerance = 0.02;

  /// Real bug fix: a single fixed [_simplifyTolerance] pass left a
  /// traced shape's vertex count entirely at the mercy of how steady the
  /// user's hand was — normal small wobble on a phone screen easily
  /// produced 9-10 vertices for what was intended as a simple 4-5 sided
  /// shape. Matches PARK-007's fixed 5-point default pentagon exactly —
  /// an 8-vertex cap tried first still looked noticeably busier than the
  /// one-tap default, so both creation methods now converge on the same
  /// vertex count. [_finishTrace] keeps re-simplifying at a growing
  /// tolerance until the result is at or under this count (or gives up
  /// after enough attempts) so a rough trace ends up exactly as clean as
  /// the default shape; a trace that genuinely needs more corners still
  /// keeps them if repeated widening can't get under the cap.
  static const _maxTracedVertices = 5;

  final _points = <Offset>[];

  double get _minSamplePixels =>
      _minSampleDistance *
      (widget.areaSize.shortestSide == 0 ? 1 : widget.areaSize.shortestSide);

  void _addSample(Offset point) {
    if (_points.isEmpty ||
        (point - _points.last).distance >= _minSamplePixels) {
      setState(() => _points.add(point));
    }
  }

  void _finishTrace() {
    final areaSize = widget.areaSize;
    final traced = List<Offset>.of(_points);
    setState(() => _points.clear());
    if (traced.length < minPolygonPoints ||
        areaSize.width == 0 ||
        areaSize.height == 0) {
      return;
    }
    var tolerance = _simplifyTolerance * areaSize.shortestSide;
    var best = _simplifyPolygon(traced, tolerance);
    if (best.length < minPolygonPoints) {
      // Real bug fix: a trace close enough to a straight line has no real
      // corners, so RDP correctly collapses it to just its 2 endpoints —
      // below what a polygon needs. The previous fallback here used the
      // full raw, unsimplified `traced` list instead, which for a
      // mostly-straight drag meant every single touch sample along the
      // line (often dozens) rendered as its own vertex handle — a dense
      // trail of dots, not a usable shape. A straight line isn't a valid
      // enclosed zone at all, so discard the trace outright instead, the
      // same as a too-short drag already does just above.
      return;
    }
    var attempts = 0;
    // Keeps the last simplification that still has enough points to be a
    // valid polygon, rather than only checking the final attempt — a fixed
    // growth factor can overshoot past `minPolygonPoints` before reaching
    // `_maxTracedVertices` on some shapes, and naively using whatever the
    // loop lands on would then fall all the way back to the raw, messy
    // `traced` points instead of the best clean-but-still-valid result
    // found along the way.
    while (best.length > _maxTracedVertices && attempts < 8) {
      tolerance *= 1.5;
      final candidate = _simplifyPolygon(traced, tolerance);
      if (candidate.length < minPolygonPoints) break;
      best = candidate;
      attempts++;
    }
    final result = best;
    widget.onZoneDrawn([
      for (final point in result)
        Offset(
          (point.dx / areaSize.width).clamp(0.0, 1.0),
          (point.dy / areaSize.height).clamp(0.0, 1.0),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) => setState(
        () => _points
          ..clear()
          ..add(details.localPosition),
      ),
      onPanUpdate: (details) => _addSample(details.localPosition),
      onPanEnd: (_) => _finishTrace(),
      child: CustomPaint(
        painter: _points.length > 1
            ? _ZoneDrawPreviewPainter(points: _points)
            : null,
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Ramer–Douglas–Peucker polyline simplification — recursively keeps only
/// the point farthest from the straight line between the current segment's
/// endpoints, as long as that distance exceeds [tolerance]; drops everything
/// closer than that, since a straight line through the endpoints already
/// represents it well enough. Always keeps [points]' first and last point.
List<Offset> _simplifyPolygon(List<Offset> points, double tolerance) {
  if (points.length <= 2 || tolerance <= 0) return points;

  var maxDistance = 0.0;
  var maxIndex = 0;
  final first = points.first;
  final last = points.last;
  for (var i = 1; i < points.length - 1; i++) {
    final distance = _perpendicularDistance(points[i], first, last);
    if (distance > maxDistance) {
      maxDistance = distance;
      maxIndex = i;
    }
  }

  if (maxDistance <= tolerance) return [first, last];

  final left = _simplifyPolygon(points.sublist(0, maxIndex + 1), tolerance);
  final right = _simplifyPolygon(points.sublist(maxIndex), tolerance);
  // `left`'s last point and `right`'s first point are both `points[maxIndex]`
  // — drop one copy where they join.
  return [...left.sublist(0, left.length - 1), ...right];
}

double _perpendicularDistance(Offset point, Offset lineStart, Offset lineEnd) {
  final dx = lineEnd.dx - lineStart.dx;
  final dy = lineEnd.dy - lineStart.dy;
  final lengthSquared = dx * dx + dy * dy;
  if (lengthSquared == 0) return (point - lineStart).distance;
  final t =
      ((point.dx - lineStart.dx) * dx + (point.dy - lineStart.dy) * dy) /
      lengthSquared;
  final closest = Offset(lineStart.dx + t * dx, lineStart.dy + t * dy);
  return (point - closest).distance;
}

enum _ZoneCorner { topLeft, topRight, bottomLeft, bottomRight }

class _CornerHandle extends StatelessWidget {
  const _CornerHandle({
    required this.corner,
    required this.color,
    required this.onTap,
    required this.onPanUpdate,
  });

  final _ZoneCorner corner;
  final Color color;
  final VoidCallback onTap;
  final ValueChanged<Offset> onPanUpdate;

  @override
  Widget build(BuildContext context) {
    const handleSize = 20.0;
    const inset = -8.0;
    return Positioned(
      left: corner == _ZoneCorner.topLeft || corner == _ZoneCorner.bottomLeft
          ? inset
          : null,
      right: corner == _ZoneCorner.topRight || corner == _ZoneCorner.bottomRight
          ? inset
          : null,
      top: corner == _ZoneCorner.topLeft || corner == _ZoneCorner.topRight
          ? inset
          : null,
      bottom:
          corner == _ZoneCorner.bottomLeft || corner == _ZoneCorner.bottomRight
          ? inset
          : null,
      child: GestureDetector(
        onTap: onTap,
        onPanUpdate: (details) => onPanUpdate(details.delta),
        child: Container(
          width: handleSize,
          height: handleSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1.5),
          ),
          child: const Icon(Icons.open_in_full, size: 12, color: Colors.black),
        ),
      ),
    );
  }
}

/// Renders a single [PolygonZone]'s outline (filled once closed) plus a
/// draggable handle per vertex. While the zone has fewer than
/// [minPolygonPoints] vertices it's still being built (open polyline, no
/// fill) — [onFinish] isn't callable yet at that point; the caller is
/// expected to gate the "Finish zone" action on `zone.isClosed` itself.
class PolygonOverlay extends StatelessWidget {
  const PolygonOverlay({
    super.key,
    required this.zone,
    required this.areaSize,
    required this.selected,
    required this.onVertexChanged,
    this.unselectedColor,
  });

  final PolygonZone zone;
  final Size areaSize;
  final bool selected;
  final void Function(int vertexIndex, Offset fractionalOffset) onVertexChanged;

  /// Overrides the default amber/selected-primary outline with a fixed
  /// per-zone color — used by screens with more than one zone type (e.g.
  /// Parking Monitoring's Slot/Open Area/Restricted) so each type stays
  /// identifiable by color at a glance.
  ///
  /// Real bug fix: this used to still lose to [selected]'s
  /// `colorScheme.primary` override, so a zone's very first moments — it's
  /// always auto-selected the instant it's finished drawing — showed the
  /// generic selection color instead of its own type color, which is
  /// exactly when a user is looking to confirm "did this draw as the type
  /// I picked?". Now, when [unselectedColor] is given, it wins regardless
  /// of [selected]; selection shows instead as a thicker outline/brighter
  /// fill and a highlighted vertex-handle ring (see [_PolygonPainter],
  /// [_PolygonVertexHandle]) rather than a hue swap. Screens with only one
  /// zone kind (e.g. Person Detection's exclusion zones, which pass no
  /// [unselectedColor]) keep their original selected-is-primary behavior
  /// unchanged — there's no per-type color to protect there.
  final Color? unselectedColor;

  List<Offset> _pixelPoints() => [
    for (final p in zone.points)
      Offset(p.dx * areaSize.width, p.dy * areaSize.height),
  ];

  @override
  Widget build(BuildContext context) {
    final pixelPoints = _pixelPoints();
    final color =
        unselectedColor ??
        (selected ? Theme.of(context).colorScheme.primary : Colors.amber);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Real bug fix: `CustomPaint`'s `size` here is the *whole preview
        // area* (so the outline/fill paint the full canvas coordinate
        // space it needs), not just this polygon's own small bounding box
        // — and by default a `CustomPaint` claims hit-testing across its
        // entire declared size, not just the pixels it actually painted.
        // Left un-ignored, the very first finished zone's `CustomPaint`
        // silently covered the *entire* preview with an invisible hit
        // box, swallowing every touch anywhere on it from then on —
        // including a brand-new `PolygonDrawSurface` trace attempted
        // nowhere near this zone. This layer is purely decorative (only
        // the vertex handles below need to be interactive), so it must
        // never intercept a touch at all.
        IgnorePointer(
          child: CustomPaint(
            size: areaSize,
            painter: _PolygonPainter(
              points: pixelPoints,
              color: color,
              filled: zone.isClosed,
              selected: selected,
            ),
          ),
        ),
        for (var i = 0; i < pixelPoints.length; i++)
          _PolygonVertexHandle(
            position: pixelPoints[i],
            color: color,
            selected: selected,
            onPanUpdate: (delta) {
              if (areaSize.width == 0 || areaSize.height == 0) return;
              final newPixel = pixelPoints[i] + delta;
              final clampedX = newPixel.dx.clamp(0.0, areaSize.width);
              final clampedY = newPixel.dy.clamp(0.0, areaSize.height);
              onVertexChanged(
                i,
                Offset(clampedX / areaSize.width, clampedY / areaSize.height),
              );
            },
          ),
      ],
    );
  }
}

class _PolygonPainter extends CustomPainter {
  const _PolygonPainter({
    required this.points,
    required this.color,
    required this.filled,
    required this.selected,
  });

  final List<Offset> points;
  final Color color;
  final bool filled;

  /// Shown as a thicker outline + brighter fill rather than a color swap —
  /// see [PolygonOverlay.unselectedColor]'s doc for why: a hue swap would
  /// hide which zone type this is at exactly the moment (just after
  /// drawing it) a user most wants to confirm that.
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    if (filled) {
      path.close();
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: selected ? 0.45 : 0.3)
          ..style = PaintingStyle.fill,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = selected ? 3 : 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _PolygonPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.color != color ||
      oldDelegate.filled != filled ||
      oldDelegate.selected != selected;
}

class _PolygonVertexHandle extends StatelessWidget {
  const _PolygonVertexHandle({
    required this.position,
    required this.color,
    required this.selected,
    required this.onPanUpdate,
  });

  final Offset position;
  final Color color;

  /// A brighter, thicker ring instead of a color swap — see
  /// [PolygonOverlay.unselectedColor]'s doc for why the zone's own color
  /// must survive selection.
  final bool selected;
  final ValueChanged<Offset> onPanUpdate;

  @override
  Widget build(BuildContext context) {
    const handleSize = 18.0;
    return Positioned(
      left: position.dx - handleSize / 2,
      top: position.dy - handleSize / 2,
      child: GestureDetector(
        onPanUpdate: (details) => onPanUpdate(details.delta),
        child: Container(
          width: handleSize,
          height: handleSize,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? Colors.white : Colors.black,
              width: selected ? 2.5 : 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

/// Row for a polygon zone in a zone-management list: tap to select,
/// trailing delete icon to remove just that zone.
class PolygonZoneListTile extends StatelessWidget {
  const PolygonZoneListTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.onDelete,
    required this.isLast,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
      child: Material(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ListTile(
            leading: Icon(
              Icons.pentagon_outlined,
              color: selected ? colorScheme.primary : AppColors.offline,
            ),
            title: Text(label),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete zone',
              onPressed: onDelete,
            ),
          ),
        ),
      ),
    );
  }
}

/// Row for a zone in a zone-management list: tap to select, trailing
/// delete icon to remove just that zone.
class ZoneListTile extends StatelessWidget {
  const ZoneListTile({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    required this.onDelete,
    required this.isLast,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: isLast
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
            ),
      child: Material(
        color: selected
            ? colorScheme.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: ListTile(
            leading: Icon(
              icon,
              color: selected ? colorScheme.primary : AppColors.offline,
            ),
            title: Text(label),
            trailing: IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete zone',
              onPressed: onDelete,
            ),
          ),
        ),
      ),
    );
  }
}
