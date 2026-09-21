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

/// Higher than [maxDrawableZones]/[maxPersonDetectionZones]-style caps — a
/// real parking lot easily has more than 8 bays, unlike an exclusion zone
/// count.
const maxParkingZones = 20;

/// What a [ParkingZone] represents and how it counts toward occupancy:
/// - [slot]: a real, countable bay — contributes to the occupied/free tally
///   and can be flagged if a vehicle overlaps a neighboring slot's line.
/// - [openArea]: an unmarked lot/section with no painted lines — counts
///   vehicles inside the boundary against [ParkingZone.estimatedCapacity]
///   rather than judging position against a grid.
/// - [restricted]: never counts as a space; a vehicle inside fires a
///   violation after a dwell-time threshold (fire lanes, loading zones).
enum ParkingZoneType { slot, openArea, restricted }

/// A free-form polygon parking zone — see `parking_monitoring_screen.dart`'s
/// own doc comment for the product reasoning behind the three [type]s.
/// Distinct from [PolygonZone] since neither that nor [DrawableZone] carries
/// a type/label/capacity.
class ParkingZone {
  const ParkingZone({
    required this.id,
    required this.type,
    required this.points,
    this.label,
    this.estimatedCapacity,
  });

  final int id;
  final ParkingZoneType type;
  final List<Offset> points;

  /// User-entered display name, e.g. "Reserved — Manager". Null means show
  /// the auto-generated default ("Slot 3", "Open Area 1", "Restricted 2").
  final String? label;

  /// Only meaningful for [ParkingZoneType.openArea] — the user's own
  /// estimate of how many vehicles the area fits, since there are no
  /// painted slots to count. Null excludes this zone from the capacity
  /// total shown on the summary card.
  final int? estimatedCapacity;

  bool get isClosed => points.length >= minPolygonPoints;

  ParkingZone copyWith({
    List<Offset>? points,
    String? label,
    int? estimatedCapacity,
  }) => ParkingZone(
    id: id,
    type: type,
    points: points ?? this.points,
    label: label ?? this.label,
    estimatedCapacity: estimatedCapacity ?? this.estimatedCapacity,
  );
}
