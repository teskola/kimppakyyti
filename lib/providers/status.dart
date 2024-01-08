import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart';

import '../models/id.dart';

enum Status {
  cancelled,
  driving,
  waiting,
  finished,
  declined,
  accepted,
  full,
  active,
  late,
  gpsOn,
  close,
  past
}

class StatusProvider extends ChangeNotifier {
  final Map<Id, Status> data = {};

  void update(Id id, {Status status = Status.active}) {
    data.update(id, (_) => status, ifAbsent: () => Status.active);
  }

  Future<Status> _fetchStatus(Id id) async {
    final driver = id.driver;
    final ride = id.ride;
    final ref = FirebaseDatabase.instance.ref('/rides/$driver/$ride/status/');
    final event = await ref.once();
    final snapshot = event.snapshot;
    if (!snapshot.exists) {
      return data.putIfAbsent(id, () => Status.active);
    }
    if (snapshot.hasChild('cancelled')) {
      return data.putIfAbsent(id, () => Status.cancelled);
    }
    if (snapshot.hasChild('finished')) {
      return data.putIfAbsent(id, () => Status.finished);
    }
    throw Exception('Couldn\'t determine ride status');
  }

  Future<Status?> get(Id id) async {
    if (data.containsKey(id)) {
      return data[id];
    }
    return _fetchStatus(id);
  }
}
