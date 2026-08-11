import 'package:camera_api/camera_api.dart';
import 'package:test/test.dart';

void main() {
  const containerSize = PixelSize(1000, 500);

  test('pixelRectToOnvifPolygon converts a top-left-anchored rect to normalized corners', () {
    const rect = PixelRect(left: 0, top: 0, width: 500, height: 250);

    final points = pixelRectToOnvifPolygon(rect, containerSize);

    expect(points, hasLength(4));
    // Top-left pixel corner (0,0) -> ONVIF top-left: x=-1 (left edge), y=1 (top edge, Y-flipped).
    expect(points[0].x, closeTo(-1.0, 1e-9));
    expect(points[0].y, closeTo(1.0, 1e-9));
    // Top-right pixel corner (500,0) -> ONVIF x=0 (container center), y=1.
    expect(points[1].x, closeTo(0.0, 1e-9));
    expect(points[1].y, closeTo(1.0, 1e-9));
    // Bottom-right pixel corner (500,250) -> ONVIF x=0, y=0 (vertical center).
    expect(points[2].x, closeTo(0.0, 1e-9));
    expect(points[2].y, closeTo(0.0, 1e-9));
  });

  test('onvifPolygonToPixelRect is the inverse of pixelRectToOnvifPolygon', () {
    const original = PixelRect(left: 100, top: 50, width: 300, height: 150);

    final points = pixelRectToOnvifPolygon(original, containerSize);
    final roundTripped = onvifPolygonToPixelRect(points, containerSize);

    expect(roundTripped.left, closeTo(original.left, 1e-6));
    expect(roundTripped.top, closeTo(original.top, 1e-6));
    expect(roundTripped.width, closeTo(original.width, 1e-6));
    expect(roundTripped.height, closeTo(original.height, 1e-6));
  });

  test('coordinates outside the container clamp to [-1, 1] rather than overflowing', () {
    const rect = PixelRect(left: -200, top: -100, width: 1400, height: 700);

    final points = pixelRectToOnvifPolygon(rect, containerSize);

    for (final p in points) {
      expect(p.x, inInclusiveRange(-1.0, 1.0));
      expect(p.y, inInclusiveRange(-1.0, 1.0));
    }
  });

  test('pixelPointToOnvifPos/onvifPosToPixelPoint round-trip a single position', () {
    const point = PixelPoint(800, 50);

    final pos = pixelPointToOnvifPos(point, containerSize);
    final roundTripped = onvifPosToPixelPoint(pos, containerSize);

    expect(roundTripped.dx, closeTo(point.dx, 1e-6));
    expect(roundTripped.dy, closeTo(point.dy, 1e-6));
  });
}
