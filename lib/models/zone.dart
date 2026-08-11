import 'dart:ui';

const maxDrawableZones = 8;
const minZoneWidth = 0.08;
const minZoneHeight = 0.08;
const defaultZoneSize = Offset(0.22, 0.16);

/// Minimum vertices for a polygon zone to be closeable into a valid shape.
const minPolygonPoints = 3;

/// Default spot (fractional, 0-1) a freshly-added polygon vertex appears
/// at before being dragged into place — offset slightly per point so
/// successive points don't stack exactly on top of each other.
const polygonPointBaseOffset = Offset(0.3, 0.3);
const polygonPointStagger = 0.04;

/// A mask/detection-zone rectangle, stored as fractional bounds (0-1) of
/// the preview so it scales with preview size. [id] is stable across edits
/// so a zone list and the preview overlay can reference the same zone.
/// Shared by Privacy Mode's mask zones and Intrusion Detection's trigger
/// zones — same drag/resize/delete mechanics, different icon/labeling.
class DrawableZone {
  const DrawableZone({required this.id, required this.rect});

  final int id;
  final Rect rect;

  DrawableZone copyWith({Rect? rect}) =>
      DrawableZone(id: id, rect: rect ?? this.rect);
}

/// A free-form polygon zone — an ordered list of vertices, each stored as a
/// fractional (0-1) offset of the preview so it scales with preview size.
/// [id] is stable across edits so a zone list and the preview overlay can
/// reference the same polygon. Used for exclusion/inclusion areas that
/// aren't well represented by a rectangle (e.g. a diagonal sidewalk).
class PolygonZone {
  const PolygonZone({required this.id, required this.points});

  final int id;
  final List<Offset> points;

  bool get isClosed => points.length >= minPolygonPoints;

  PolygonZone copyWith({List<Offset>? points}) =>
      PolygonZone(id: id, points: points ?? this.points);
}
