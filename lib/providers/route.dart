import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart' hide Route;
import 'package:kimppakyyti/models/id.dart';
import 'package:kimppakyyti/models/route.dart';
import 'package:kimppakyyti/utilities/local_database.dart';

class RouteProvider extends ChangeNotifier {
  
  Future<dynamic> _fetchRoute(Id id) async {
    final ref = FirebaseDatabase.instance
        .ref('/rides/${id.driver}/${id.ride}/route/data');
    final snapshot = await ref.get();
final result = snapshot.value as Map<Object?, Object?>;
    final pointer = result["pointer"] as String?;
    final reversed = result["reversed"] as bool?;
    if (pointer != null) {
      return {"pointer": pointer, "reversed": reversed};
    }
    final route = Route.fromJson(snapshot.value as Map<Object?, Object?>);
    return route;
  }

  Future<CustomRoute?> _getRouteFromLocalDatabase(Id id) async {
    final local = await LocalDatabase().getRoute(id);
    if (local == null) return null;
    if (local.reversed) {
      return local.reverse();
    }
    return local;
  }

  Future<Route> get(Id id) async {
    final local = await _getRouteFromLocalDatabase(id);
    if (local != null) return local;
    final fetch1 = await _fetchRoute(id);
    if (fetch1 is Route) {
      await LocalDatabase().addRide(id, fetch1);
      return fetch1;
    }
    final pointer = fetch1["pointer"] as String;
    final reversed = fetch1["reversed"] as bool;
    final pointerId = Id(driver: id.driver, ride: pointer);
    final local2 = await _getRouteFromLocalDatabase(pointerId);
    if (local2 != null) {
      await LocalDatabase().addRide(id, local2.local, reversed: reversed);
      if (reversed) return local2.reverse();
      return local2;
    }
    final fetch2 = await _fetchRoute(pointerId);
    final rideId = await LocalDatabase().addRide(pointerId, fetch2 as Route);
    await LocalDatabase().addRide(id, rideId, reversed: reversed);
    if (reversed) return fetch2.reverse();
    return fetch2;
  }
}
