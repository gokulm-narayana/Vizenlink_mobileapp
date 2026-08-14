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
  });

  final PolygonZone zone;
  final Size areaSize;
  final bool selected;
  final void Function(int vertexIndex, Offset fractionalOffset) onVertexChanged;

  List<Offset> _pixelPoints() => [
    for (final p in zone.points)
      Offset(p.dx * areaSize.width, p.dy * areaSize.height),
  ];

  @override
  Widget build(BuildContext context) {
    final pixelPoints = _pixelPoints();
    final color = selected
        ? Theme.of(context).colorScheme.primary
        : Colors.amber;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        CustomPaint(
          size: areaSize,
          painter: _PolygonPainter(
            points: pixelPoints,
            color: color,
            filled: zone.isClosed,
          ),
        ),
        for (var i = 0; i < pixelPoints.length; i++)
          _PolygonVertexHandle(
            position: pixelPoints[i],
            color: color,
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
  });

  final List<Offset> points;
  final Color color;
  final bool filled;

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
          ..color = color.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _PolygonPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.color != color ||
      oldDelegate.filled != filled;
}

class _PolygonVertexHandle extends StatelessWidget {
  const _PolygonVertexHandle({
    required this.position,
    required this.color,
    required this.onPanUpdate,
  });

  final Offset position;
  final Color color;
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
            border: Border.all(color: Colors.black, width: 1.5),
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
