import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:kimppakyyti/providers/database.dart';

import '../models/id.dart';

class RideIdProvider extends DatabaseProvider with ChangeNotifier {
  final List<Id> data = [];
  Future<List<Id>> _fetchIds(String uid) async {
    final List<Id> result = [];
    final ref = FirebaseDatabase.instance.ref('/users/$uid/private/rides/data');
    final snapshot = await ref.get();
    if (snapshot.exists) {
      for (var driverId in snapshot.children) {
        for (var rideId in driverId.children) {
          result.add(Id(driver: driverId.key!, ride: rideId.key!));
        }
      }
    }
    return result;
  }

  void add(Id? id) {
    if (id != null && !data.contains(id)) {
      data.add(id);
    }
  }

  @override
  void start(String uid) async {
    data.addAll(await _fetchIds(uid));
    notifyListeners();
  }

  @override
  void close() {
    data.clear();
  }
}
