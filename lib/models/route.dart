import 'package:flutter/foundation.dart';
import 'package:kimppakyyti/models/location.dart';
import 'package:kimppakyyti/utilities/map_utils.dart';

class Leg {
  final Point start;
  final Point destination;
  final int distance;
  final int duration;
  final String polyline;

  const Leg(this.start, this.destination, this.distance, this.duration,
      this.polyline);

  Map<String, Object?> toJson() => {
        'start': start.toJson(),
        'destination': destination.toJson(),
        'distance': distance,
        'duration': duration,
        'polyline': polyline
      };

  factory Leg.fromJson(Map<Object?, Object?> json) => Leg(
      Point.fromJson(json['start'] as Map<Object?, Object?>),
      Point.fromJson(json['destination'] as Map<Object?, Object?>),
      json["distance"] as int,
      json["duration"] as int,
      json["polyline"] as String);

  Leg reverse() => Leg(
      destination,
      start,
      distance,
      duration,
      MapUtils.encodePolyline(
          MapUtils.decodePolyline(polyline).reversed.toList(growable: false)));

  @override
  bool operator ==(covariant Leg other) =>
      other.start == start &&
      other.destination == destination &&
      other.distance == distance &&
      other.duration == duration &&
      other.polyline == polyline;

  @override
  int get hashCode =>
      Object.hash(start, destination, distance, duration, polyline);
}

/// Route created by authenticated user
class CustomRoute extends Route {
  final int local;
  String? name;
  String? firebase;
  final bool reversed;
  CustomRoute(super.legs, this.local,
      {this.name, this.firebase, this.reversed = false});

  @override
  CustomRoute reverse() => CustomRoute(reversedLegs(), local,
      name: name, firebase: firebase, reversed: !reversed);
}

class Route {
  final List<Leg> legs;

  Point get start {
    return legs.first.start;
  }

  Point get destination {
    return legs.last.destination;
  }

  int get distance {
    final values = legs.map((e) => e.distance);
    return values.fold(0, (previousValue, element) => previousValue + element);
  }

  int get duration {
    final values = legs.map((e) => e.duration);
    return values.fold(0, (previousValue, element) => previousValue + element);
  }

  List<String> get locations => [
        start.municipality,
        ...waypoints.map((e) => e.municipality),
        destination.municipality
      ];

  List<Point> get waypoints {
    if (legs.length < 2) {
      return [];
    }
    final lastRemoved = [...legs]..removeLast();
    return lastRemoved.map((e) => e.destination).toList(growable: false);
  }

  Route reverse() => Route(reversedLegs());

  List<Leg> reversedLegs() {
    return [...legs]
        .map((e) => e.reverse())
        .toList(growable: false)
        .reversed
        .toList(growable: false);
  }

  @override
  bool operator ==(covariant Route other) => listEquals(legs, other.legs);

  @override
  int get hashCode => legs.hashCode;

  Route(this.legs);
  // TODO: let provider handle this
  bool equals(
      Point? otherStart, Point? otherDestination, List<Point> otherWaypoints) {
    if (otherStart == null || otherDestination == null) {
      return false;
    }
    if (start == otherStart &&
        destination == otherDestination &&
        waypoints.length == otherWaypoints.length) {
      for (var i = 0; i < waypoints.length; i++) {
        if (waypoints[i] != otherWaypoints[i]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  @override
  String toString() {
    return locations.join("—");
  }

  Map<String, dynamic> toJson() => {
        'legs': legs.map((e) => e.toJson()).toList(),
      };

  factory Route.fromJson(Map<Object?, Object?> json) {
    return Route(
      (json['legs'] as List<Object?>)
          .map((e) => (Leg.fromJson(e as Map<Object?, Object?>)))
          .toList(),
    );
  }
}

class RouteInfo {
  final Route route;
  final int timestamp;

  RouteInfo(this.route, this.timestamp);
}
