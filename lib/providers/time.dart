import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:kimppakyyti/models/departure_time.dart';
import 'package:kimppakyyti/models/id.dart';
import 'package:kimppakyyti/providers/database.dart';

class TimeProvider extends DatabaseProvider with ChangeNotifier {
  Map<Id, DepartureTime> data = {};
  String? _uid;
  bool isLoading = true;

  Map<String, DepartureTime> get activeDriver {
    return Map.fromEntries(data.entries
        .where(
            (element) => element.value.isActive && element.key.driver == _uid)
        .map((e) => MapEntry(e.key.ride, e.value))
        .toList(growable: false)
      ..sort((e1, e2) => e1.value.compareTo(e2.value)));
  }

  Map<Id, DepartureTime> get history {
    return Map.fromEntries(
        data.entries.where((element) => !element.value.isActive));
  }

  Future<DepartureTime> _fetchTime(Id id) async {
    final driver = id.driver;
    final ride = id.ride;
    final ref = FirebaseDatabase.instance.ref('/rides/$driver/$ride/time/data');
    final event = await ref.once();
    return DepartureTime.fromJson(
        event.snapshot.value as Map<Object?, Object?>);
  }

  Future<void> fetchAll(List<Id> ids) async {
    for (var id in ids) {
      if (!data.containsKey(id)) {
        final time = await _fetchTime(id);
        data.putIfAbsent(id, () => time);
      }
    }
    isLoading = false;
    notifyListeners();
  }

  void update(Id id, DepartureTime departureTime) {
    data.update(id, (_) => departureTime, ifAbsent: () => departureTime);
    notifyListeners();
  }

  @override
  void close() {
    data.clear();
  }

  @override
  void start(String uid) {
    _uid = uid;
  }
}
