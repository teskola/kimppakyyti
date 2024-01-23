import 'package:flutter_test/flutter_test.dart';
import 'package:kimppakyyti/models/location.dart';
import 'package:kimppakyyti/models/route.dart';
import 'package:kimppakyyti/providers/directions.dart';
import 'package:kimppakyyti/utilities/error.dart';

void main() {
  final Point tampere =
      Point(latitude: 61.497815, longitude: 23.762265, municipality: "Tampere");
  final Point helsinki =
      Point(latitude: 60.17116, longitude: 24.93258, municipality: "Helsinki");
  final Point forssa =
      Point(latitude: 60.824104, longitude: 23.587275, municipality: "Forssa");
  final Point vantaa =
      Point(latitude: 60.289348, longitude: 25.029676, municipality: "Vantaa");
  final Point ocean =
      Point(municipality: "Unknown", latitude: 72.88435, longitude: 20.284394);

  /* group("Encoding/Decoding", () {
    Route original = DirectionsProvider.parseJsonToRoute(
        tampereHelsinki, tampere, helsinki, []);
    Route reversed = original.reverse();
    test("Reversed start, destination, distance should remain unchanged", () {
      expect(reversed.start, helsinki);
      expect(reversed.destination, tampere);
      expect(reversed.distance, original.distance);
    });
    test("Double reversed should return same polyline", () {
      Route doubleReversed = reversed.reverse();
      expect(doubleReversed == original, true);
    });
  });
  group("Parse Route from json", () {
    test("No waypoints", () {
      Route route = DirectionsProvider.parseJsonToRoute(
          tampereHelsinki, tampere, helsinki, []);
      expect(route.start, tampere);
      expect(route.destination, helsinki);
      expect(route.waypoints, []);
      expect(route.distance, 179458);
      expect(route.duration, 7568);
    });
    test("One waypoint", () {
      Route route = DirectionsProvider.parseJsonToRoute(
          tampereForssaHelsinki, tampere, helsinki, [forssa]);
      expect(route.start, tampere);
      expect(route.destination, helsinki);
      expect(route.waypoints, [forssa]);
      expect(route.distance, 218972);
      expect(route.duration, 9866);
    });
    test("Two waypoints", () {
      Route route = DirectionsProvider.parseJsonToRoute(
          tampereForssaVantaaHelsinki, tampere, helsinki, [forssa, vantaa]);
      expect(route.waypoints, [forssa, vantaa]);
      expect(route.legs[0].destination, forssa);
      expect(route.legs[1].start, forssa);
    });
  }); */
}
