import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/location.dart';
import '../models/route.dart';
import '../utilities/error.dart';

class Request {
  final Point origin;
  final Point destination;
  final List<Point>? intermediates;
  final bool computeAlternativeRoutes = false;

  String get body => jsonEncode(toJson());

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> result = {};
    result["origin"] = {
      "location": {
        "latLng": {"latitude": origin.latitude, "longitude": origin.longitude}
      }
    };
    result["destination"] = {
      "location": {
        "latLng": {
          "latitude": destination.latitude,
          "longitude": destination.longitude
        }
      }
    };
    result["computeAlternativeRoutes"] = computeAlternativeRoutes;

    if (intermediates != null && intermediates!.isNotEmpty) {
      final List<Map<String, dynamic>> list = [];
      for (var intermediate in intermediates!) {
        list.add({
          "location": {
            "latLng": {
              "latitude": intermediate.latitude,
              "longitude": intermediate.longitude
            }
          }
        });
      }
      result["intermediates"] = list;
    }
    return result;
  }

  Request(this.origin, this.destination, {this.intermediates});
}

class DirectionsProvider {
  static const Map<String, String> headers = {
    "Content-Type": "application/json",
    "X-Goog-Api-Key": String.fromEnvironment('API_KEY'),
    "X-Goog-FieldMask":
        "routes.legs.duration,routes.legs.distanceMeters,routes.legs.polyline.encodedPolyline"
  };
  static Future<Route> fetchRoute({
    required Point start,
    required Point destination,
    required List<Point> waypoints,
  }) async {
    Uri uri = Uri.https("routes.googleapis.com", "directions/v2:computeRoutes");
    try {
      final body = Request(start, destination, intermediates: waypoints).body;
      final response = await http.post(uri, headers: headers, body: body);
      if (response.statusCode == 429) {
        throw RouteException(
            type: RouteError.quoataExceeded, message: response.body);
      }
      if (response.statusCode != 200) {
        debugPrint(response.body);
        throw RouteException(
            type: RouteError.unknownError, message: response.body);
      }
      if (response.body.isEmpty) {
        throw RouteException(type: RouteError.notFound);
      }
      final json = jsonDecode(response.body);
      return parseJsonToRoute(json, start, destination, waypoints);
    } on SocketException {
      throw RouteException(error: Errors.networkError);
    }
  }

  static int durationToInt(String string) {
    return int.parse(string.substring(0, string.length - 1));
  }

  static Route parseJsonToRoute(final Map<String, dynamic> json,
      final Point start, final Point destination, final List<Point> waypoints) {
    List<dynamic> parsedLegs = json["routes"][0]["legs"];
    final distances = parsedLegs.map((e) => e["distanceMeters"] as int);
    final durations = parsedLegs.map((e) => e["duration"] as String);
    final polyline =
        parsedLegs.map((e) => e["polyline"]["encodedPolyline"] as String);

    final List<Leg> legs = [];
    if (parsedLegs.length < 2) {
      legs.add(Leg(start, destination, distances.elementAt(0),
          durationToInt(durations.elementAt(0)), polyline.elementAt(0)));
    } else {
      legs.add(Leg(start, waypoints[0], distances.elementAt(0),
          durationToInt(durations.elementAt(0)), polyline.elementAt(0)));
      for (var i = 0; i < waypoints.length - 1; i++) {
        legs.add(Leg(
            waypoints[i],
            waypoints[i + 1],
            distances.elementAt(i + 1),
            durationToInt(durations.elementAt(i + 1)),
            polyline.elementAt(i + 1)));
      }
      legs.add(Leg(
          waypoints[waypoints.length - 1],
          destination,
          distances.elementAt(waypoints.length),
          durationToInt(durations.elementAt(waypoints.length)),
          polyline.elementAt(waypoints.length)));
    }
    return Route(legs);
  }
}
