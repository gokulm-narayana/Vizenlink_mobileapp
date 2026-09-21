/// A single ONVIF polygon point — `x`/`y` each in `[-1, 1]`, origin at the frame's center,
/// Y increasing upward (ONVIF's normalized coordinate convention, not screen/pixel convention).
class OnvifPoint {
  const OnvifPoint(this.x, this.y);
  final double x;
  final double y;
}

/// A pixel-space rectangle (top-left origin, Y increasing downward — plain screen convention).
/// This package has no `package:flutter` dependency (pure-Dart by design, `camera_api`'s
/// `pubspec.yaml`), so this stands in for `dart:ui`'s `Rect`, which isn't available here.
class PixelRect {
  const PixelRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
  final double left;
  final double top;
  final double width;
  final double height;

  @override
  bool operator ==(Object other) =>
      other is PixelRect &&
      left == other.left &&
      top == other.top &&
      width == other.width &&
      height == other.height;

  @override
  int get hashCode => Object.hash(left, top, width, height);
}

/// A pixel-space container size — stand-in for `dart:ui`'s `Size`, same reason as [PixelRect].
class PixelSize {
  const PixelSize(this.width, this.height);
  final double width;
  final double height;
}

/// A single pixel-space point — stand-in for `dart:ui`'s `Offset`, same reason as [PixelRect].
class PixelPoint {
  const PixelPoint(this.dx, this.dy);
  final double dx;
  final double dy;
}

/// Pixel ↔ ONVIF-normalized-polygon conversion for a rectangular region — ports
/// `android_app/app/src/main/assets/lib.js`'s `convertHtmlStyleAttributesToOnvifPolygon` (pixel
/// → ONVIF) and `bsp_camera_ameba.c`'s `prvConvertOnvifMaskPolygon` (ONVIF → pixel bounding box,
/// the inverse the firmware itself uses) exactly, rather than re-deriving the math — both the
/// mask editor and the OSD position drag (`DESIGN.md` §10.10) share this.
///
/// Points are always ordered top-left, top-right, bottom-right, bottom-left — matching what the
/// legacy app sends and what `bsp_camera_ameba.c`'s bounding-box conversion expects (it only
/// reads min/max across all 4 points, so exact order doesn't matter to the camera, but keeping
/// it consistent avoids surprises against any client that does care, e.g. VMS's ONVIF viewer).
List<OnvifPoint> pixelRectToOnvifPolygon(PixelRect pixelRect, PixelSize containerSize) {
  final l = pixelRect.left;
  final t = pixelRect.top;
  final w = pixelRect.width;
  final h = pixelRect.height;
  final containerW = containerSize.width;
  final containerH = containerSize.height;

  double x(double px) => ((px / containerW) * 2) - 1;
  double y(double py) => (((containerH - py) / containerH) * 2) - 1;

  final points = [
    OnvifPoint(x(l), y(t)), // top-left
    OnvifPoint(x(l + w), y(t)), // top-right
    OnvifPoint(x(l + w), y(t + h)), // bottom-right
    OnvifPoint(x(l), y(t + h)), // bottom-left
  ];

  return points
      .map((p) => OnvifPoint(p.x.clamp(-1.0, 1.0), p.y.clamp(-1.0, 1.0)))
      .toList(growable: false);
}

/// Inverse of [pixelRectToOnvifPolygon] — the bounding box of an arbitrary point set (matching
/// `prvConvertOnvifMaskPolygon`'s own bounding-box reduction, since this firmware's masks are
/// hardware rectangles regardless of how many polygon points ONVIF allows in principle).
PixelRect onvifPolygonToPixelRect(List<OnvifPoint> points, PixelSize containerSize) {
  var minX = 1.0, maxX = -1.0, minY = 1.0, maxY = -1.0;
  for (final p in points) {
    if (p.x < minX) minX = p.x;
    if (p.x > maxX) maxX = p.x;
    if (p.y < minY) minY = p.y;
    if (p.y > maxY) maxY = p.y;
  }

  final left = minX;
  final top = maxY;
  final width = maxX - minX;
  final height = maxY - minY;
  final containerW = containerSize.width;
  final containerH = containerSize.height;

  final x = ((left + 1) / 2) * containerW;
  final y = ((1 - top) / 2) * containerH;
  final w = (width / 2) * containerW;
  final h = (height / 2) * containerH;

  return PixelRect(left: x, top: y, width: w, height: h);
}

/// A single-point ONVIF position (OSD placement, not a mask region) — pixel top-left corner of
/// the overlay's rendered bounds converted to ONVIF's `Pos x/y`, reusing the same convention
/// [pixelRectToOnvifPolygon] uses for a rect's top-left corner (`lib.js`'s `for_osd` branch is
/// the same transform with an in-bounds clamp, not a different one).
OnvifPoint pixelPointToOnvifPos(PixelPoint pixelTopLeft, PixelSize containerSize) {
  final containerW = containerSize.width;
  final containerH = containerSize.height;
  final x = ((pixelTopLeft.dx / containerW) * 2) - 1;
  final y = (((containerH - pixelTopLeft.dy) / containerH) * 2) - 1;
  return OnvifPoint(x.clamp(-1.0, 1.0), y.clamp(-1.0, 1.0));
}

/// Inverse of [pixelPointToOnvifPos].
PixelPoint onvifPosToPixelPoint(OnvifPoint pos, PixelSize containerSize) {
  final containerW = containerSize.width;
  final containerH = containerSize.height;
  final x = ((pos.x + 1) / 2) * containerW;
  final y = ((1 - pos.y) / 2) * containerH;
  return PixelPoint(x, y);
}
