import 'dart:collection';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location.dart';
import '../models/passenger.dart';
import '../models/route.dart';

class Deviations {
  final PointDistance startDeviation;
  final PointDistance destinationDeviation;

  Deviations(this.startDeviation, this.destinationDeviation);
}

class PointDistance {
  final LatLng point;
  final double distance;

  PointDistance(this.point, this.distance);
}

class RideUtils {
  static LinkedHashMap<LatLng, List<String>> getStops(
      List<LatLng> points, List<Passenger> passengers) {
    final LinkedHashMap<LatLng, List<String>> result = LinkedHashMap();
    final List<String> current = [];
    for (var point in points) {
      var changed = false;
      for (var passenger in passengers) {
        if (passenger.start == point) {
          current.add(passenger.id);
          changed = true;
        }
        if (passenger.destination == point) {
          current.remove(passenger.id);
          changed = true;
        }
      }
      if (changed) {
        result.putIfAbsent(point, () => current);
      }
    }
    return result;
  }

  /// Returns closest point of the route for start and destination.
  /// Returns null if start or destination are too far away from the route.

  static Deviations? getDeviations(
      List<LatLng> points, Point start, Point destination) {
    const double maxDeviation = 20.0;
    double? startMin;
    LatLng? startPoint;
    double? destinationMin;
    LatLng? destinationPoint;
    for (var point in points) {
      final distance = start.distance(point);
      if (distance < (startMin ?? maxDeviation)) {
        startMin = distance;
        startPoint = point;
      }
    }
    if (startPoint == null) return null;
    final destinationList = points.sublist(points.indexWhere((element) =>
        element.latitude == startPoint!.latitude &&
        element.longitude == startPoint.longitude));
    for (var point in destinationList) {
      final distance = destination.distance(point);
      if (distance < (destinationMin ?? maxDeviation)) {
        destinationMin = distance;
        destinationPoint = point;
      }
    }
    if (destinationPoint == null) return null;

    return Deviations(PointDistance(startPoint, startMin!),
        PointDistance(destinationPoint, destinationMin!));
  }

  static String rideString(Route route, {String? start, String? destination}) {
    List<String> locations = [route.start.municipality];
    if (start != null && route.start.municipality != start) {
      locations.add(start);
    }
    if (destination != null && route.destination.municipality != destination) {
      locations.add(destination);
    }
    locations.add(route.destination.municipality);
    return locations.join("—");
  }
}
