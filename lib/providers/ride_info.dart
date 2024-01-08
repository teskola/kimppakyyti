import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:kimppakyyti/models/departure_time.dart';
import 'package:kimppakyyti/providers/database.dart';

import '../models/ride.dart';
import '../models/route.dart';

class RideInfoProvider extends DatabaseProvider with ChangeNotifier  {
  final Map<String, RideInfo> data = {};
  final Map<String, StreamSubscription<DatabaseEvent>> _listeners = {};
  String? uid;

  List<String> get history {
    return data.entries
        .where((element) => !element.value.isActive)
        .map((e) => e.key)
        .toList(growable: false)
      ..sort((k1, k2) =>
          data[k2]!.departureTime.compareTo(data[k1]!.departureTime));
  }

  List<String> get activeDriver {
    return data.entries
        .where(
            (element) => element.value.isActive && element.value.driver == uid)
        .map((e) => e.key)
        .toList(growable: false)
      ..sort((k1, k2) =>
          data[k1]!.departureTime.compareTo(data[k2]!.departureTime));
  }

  List<String> get historyDriver {
    return data.entries
        .where((element) =>
            !element.value.isActive && element.value.driver == uid)
        .map((e) => e.key)
        .toList(growable: false);
  }

  RideInfo _parseInfo(DataSnapshot snapshot) {
    String driver = snapshot.child('driver').value as String;
    final capacity = snapshot.child('capacity').value as int;
    final min = snapshot.child('time').child('min').value as int;
    final max = snapshot.child('time').child('max').value as int;
    final actual = snapshot.child('time').child('actual').value as int?;
    final timestamp = snapshot.child('time').child('timestamp').value as int;
    final cancelled = snapshot.child('cancelled').value as bool?;
    final finished = snapshot.child('finished').value as bool?;
    final info = snapshot.child('info').value as String?;
    return RideInfo(
        capacity,
        driver,
        DepartureTime(DateTime.fromMillisecondsSinceEpoch(min),
            DateTime.fromMillisecondsSinceEpoch(max),
            actual: actual != null
                ? DateTime.fromMillisecondsSinceEpoch(actual)
                : null),
        timestamp,
        cancelled ?? false,
        finished ?? false,
        info);
  }

  void add(String? id) {
    if (id == null) return;
    final ref = FirebaseDatabase.instance.ref('/rides/$id/');
    _listeners.putIfAbsent(
        id,
        () => ref.onValue.listen((event) {
              final info = _parseInfo(event.snapshot);
              data.update(id, (_) => info, ifAbsent: () => info);
              if (!info.isActive) {
                _listeners[id]?.cancel();
                _listeners.remove(id);
              }
              notifyListeners();
            }));
  }

  Future<String?> addRideToDatabase(Route route, DepartureTime time,
      int capacity, String? info, Function onError) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final Map<String, dynamic> values = {};
    final rideData = {
      'capacity': capacity,
      'info': {'value': info, 'timestamp': ServerValue.timestamp},
      'time': {'data': time.toJson(), 'timestamp': ServerValue.timestamp},
      'route': {'data': route.toJson(), 'timestamp': ServerValue.timestamp}
    };
    final rideKey =
        FirebaseDatabase.instance.ref().child('/rides/$uid/').push().key;
    values['/rides/$uid/$rideKey/'] = rideData;
    for (var day in time.dates!) {
      values['/search/${day.year}/${day.month}/${day.day}/$rideKey/'] = uid;
    }
    values['/users/$uid/private/rides/$uid/$rideKey/'] =
        ServerValue.timestamp;
    String? result;
    await FirebaseDatabase.instance.ref().update(values).then((_) {
      result = rideKey;
    }).catchError((err) {
      onError(err);
      result = null;
    });
    return result;
  }

  void remove(String id) {
    data.remove(id);
    _listeners[id]?.cancel();
    _listeners.remove(id);
  }

  @override
  void start(String uid) {
    uid = uid;
  }

  @override
  void close() {
    for (var key in _listeners.keys) {
      _listeners[key]?.cancel();
    }
    _listeners.clear();
    data.clear();
  }
}
