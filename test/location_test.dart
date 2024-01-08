import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kimppakyyti/models/location.dart';

void main() {
  const List<LatLng> polygon = [
    LatLng(60, -120),
    LatLng(60, 120),
    LatLng(-60, 120),
    LatLng(-60, -120),
    LatLng(60, -120)
  ];
  const List<List<LatLng>> holes = [
    [
      LatLng(30, -60),
      LatLng(30, 60),
      LatLng(-30, 60),
      LatLng(-30, -60),
      LatLng(30, -60)
    ]
  ];
  const poly = Poly(polygon: polygon, holes: holes);

  
  group('Point in polygon', () {
    test('Point inside polygon.', () {
      const point = LatLng(45, 90);
      expect(poly.pointInPolygon(point), true);
    });
    test('Point outside polygon', () {
      const point = LatLng(65, 90);
      expect(poly.pointInPolygon(point), false);
    });
    test('Point inside a hole', () {
      const point = LatLng(15, 0);
      expect(poly.pointInPolygon(point), false);
    });
    test('Point on the edge of polygon', () {
      const point = LatLng(60, -120);
      expect(poly.pointInPolygon(point), false);
    });
    test('Point on the edge of a hole', () {
      const point = LatLng(30, -60);
      expect(poly.pointInPolygon(point), true);
    });
  });
}
