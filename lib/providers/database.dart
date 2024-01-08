import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/widgets.dart' hide Route;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kimppakyyti/models/departure_time.dart';
import '../models/gps_location.dart';
import '../models/message.dart';
import '../models/passenger.dart';
import '../models/request.dart';
import '../models/ride.dart';
import '../models/route.dart';
import '../models/user.dart';

abstract class DatabaseProvider {
  void start(String uid);
  void close();
  DatabaseProvider() {
    firebase.FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        close();
        return;
      }
      start(user.uid);
    });
  }
}

class DepractedDatabaseProvider extends ChangeNotifier {
  User? _user;
  StreamSubscription<DatabaseEvent>? _rideAddedListener;
  StreamSubscription<DatabaseEvent>? _timestampUpdateListener;
  final Map<String, StreamSubscription<DatabaseEvent>> _infoListeners = {};
  final Map<String, StreamSubscription<DatabaseEvent>> _routeListeners = {};
  final Map<String, List<StreamSubscription<DatabaseEvent>>>
      _passengerListeners = {};
  final Map<String, StreamSubscription<DatabaseEvent>> _locationListeners = {};
  final Map<String, List<StreamSubscription<DatabaseEvent>>> _requestListeners =
      {};
  final Map<String, Map<String, StreamSubscription<DatabaseEvent>>>
      _requestMessageListeners = {};
  final Map<String, StreamSubscription<DatabaseEvent>> _rideMessageListeners =
      {};

  final Map<String, int> _rides =
      {}; // key: ride id, value: last seen timestamp
  final Map<String, RideInfo> rideInfos = {};
  final Map<String, RouteInfo> routeInfos = {};
  final Map<String, List<PassengerInfo>> passengers = {};
  final Map<String, GpsLocation> locations = {};
  final Map<String, List<Request>> requests = {};
  final Map<String, Map<String, List<Message>>> requestMessages = {};
  final Map<String, List<Message>> rideMessages = {};

  List<String> get history {
    return rideInfos.entries
        .where((element) => !element.value.isActive)
        .map((e) => e.key)
        .toList(growable: false)
      ..sort((k1, k2) =>
          rideInfos[k2]!.departureTime.compareTo(rideInfos[k1]!.departureTime));
  }

  List<String> get activeDriver {
    return rideInfos.entries
        .where((element) =>
            element.value.isActive && element.value.driver == user?.id)
        .map((e) => e.key)
        .toList(growable: false)
      ..sort((k1, k2) =>
          rideInfos[k1]!.departureTime.compareTo(rideInfos[k2]!.departureTime));
  }

  List<String> get historyDriver {
    return rideInfos.entries
        .where((element) =>
            !element.value.isActive && element.value.driver == user?.id)
        .map((e) => e.key)
        .toList(growable: false);
  }

  List<String> get activePassenger {
    return passengers.entries
        .where((e1) => e1.value.any((e2) {
              return e2.passenger.id == user?.id && rideInfos[e1.key]!.isActive;
            }))
        .map((e) => e.key)
        .toList(growable: false)
      ..sort((k1, k2) =>
          rideInfos[k1]!.departureTime.compareTo(rideInfos[k2]!.departureTime));
  }

  List<String> get historyPassenger {
    return passengers.entries
        .where((e1) => e1.value.any((e2) {
              return e2.passenger.id == user?.id &&
                  !rideInfos[e1.key]!.isActive;
            }))
        .map((e) => e.key)
        .toList(growable: false);
  }

  List<String> get activeRequest {
    return requests.entries
        .where((e1) => e1.value.any((e2) {
              return e2.passenger == user?.id && rideInfos[e1.key]!.isActive;
            }))
        .map((e) => e.key)
        .toList(growable: false)
      ..sort((k1, k2) =>
          rideInfos[k1]!.departureTime.compareTo(rideInfos[k2]!.departureTime));
  }

  List<String> get historyRequest {
    return requests.entries
        .where((e1) => e1.value.any((e2) {
              return e2.passenger == user?.id && !rideInfos[e1.key]!.isActive;
            }))
        .map((e) => e.key)
        .toList(growable: false);
  }

  Map<String, Route> get routes {
    return routeInfos.map((key, value) => MapEntry(key, value.route));
  }

  List<String> get changedRides {
    final map = Map.of(_rides)
      ..removeWhere((key, value) => !rideChanged(key, lastSeen: value));
    return map.keys.toList();
  }

  bool rideChanged(String id, {int? lastSeen}) {
    if ((lastSeen ??= _rides[id]) == null) return false;
    if (rideInfos[id] != null && rideInfos[id]!.timestamp > lastSeen!) {
      return true;
    }
    if (routeInfos[id] != null && routeInfos[id]!.timestamp > lastSeen!) {
      return true;
    }
    if (requests[id] != null &&
        requests[id]!.any((element) => element.timestamp > lastSeen!)) {
      return true;
    }
    if (requestMessages[id] != null &&
        requestMessages[id]!.values.any((element) =>
            element.any((element) => element.timestamp > lastSeen!))) {
      return true;
    }
    if (passengers[id] != null &&
        passengers[id]!.any((element) =>
            element.passenger.id == user?.id &&
            element.timestamp > lastSeen!)) {
      return true;
    }
    if (rideMessages[id] != null &&
        rideMessages[id]!.any((element) => element.timestamp > lastSeen!)) {
      return true;
    }
    return false;
  }

  void removeListeners(String id) {
    _infoListeners[id]?.cancel();
    _infoListeners.remove(id);
    _routeListeners[id]?.cancel();
    _routeListeners.remove(id);
    _passengerListeners[id]?.forEach((element) {
      element.cancel();
    });
    _passengerListeners.remove(id);
    _locationListeners[id]?.cancel();
    _locationListeners.remove(id);
    _requestListeners[id]?.forEach((element) {
      element.cancel();
    });
    _requestListeners.remove(id);
    _requestMessageListeners[id]?.forEach((key, value) {
      value.cancel();
    });
    _requestMessageListeners.remove(id);
    _rideMessageListeners[id]?.cancel();
    _rideMessageListeners.remove(id);
  }

  void removeAllListeners() {
    _infoListeners.forEach((key, value) {
      value.cancel();
    });
    _infoListeners.clear();
    _routeListeners.forEach((key, value) {
      value.cancel();
    });
    _routeListeners.clear();
    _passengerListeners.forEach((key, value) {
      for (var sub in value) {
        sub.cancel();
      }
    });
    _passengerListeners.clear();
    _locationListeners.forEach((key, value) {
      value.cancel();
    });
    _locationListeners.clear();
    _requestListeners.forEach((key, value) {
      for (var sub in value) {
        sub.cancel();
      }
    });
    _requestListeners.clear();
    _requestMessageListeners.forEach((key, val) {
      val.forEach((key, value) {
        value.cancel();
      });
    });
    _requestMessageListeners.clear();
    _rideMessageListeners.forEach((key, value) {
      value.cancel();
    });
    _rideMessageListeners.clear();
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

  Message? _parseMessage(DataSnapshot snapshot) {
    final id = snapshot.key;
    if (id == null) return null;
    final sender = snapshot.child('sender').value as String;
    final value = snapshot.child('value').value as String;
    final timestamp = snapshot.child('timestamp').value as int;
    return Message(timestamp, sender, value);
  }

  Request? _parseRequest(DataSnapshot snapshot) {
    final id = snapshot.key;
    if (id == null) return null;
    final startLat = snapshot.child('start/latitude').value as double;
    final startLon = snapshot.child('start/longitude').value as double;
    final destLat = snapshot.child('destination/latitude').value as double;
    final destLon = snapshot.child('destination/longitude').value as double;
    final declined = snapshot.child('declined').value as bool?;
    final timestamp = snapshot.child('timestamp').value as int;
    return Request(id, LatLng(startLat, startLon), LatLng(destLat, destLon),
        declined ?? false, timestamp);
  }

  Future<Request> fetchRequest(String rideId) async {
    final ref = FirebaseDatabase.instance.ref('requests/$rideId/${user?.id}/');
    final event = await ref.once();
    final snapshot = event.snapshot;
    return requests.putIfAbsent(rideId, () => [_parseRequest(snapshot)!]).first;
  }

  void _listenRideMessages(String rideId) {
    final messagesRef = FirebaseDatabase.instance.ref('/ride_messages/$rideId');
    _rideMessageListeners.putIfAbsent(
        rideId,
        () => messagesRef.onChildAdded.listen((event) {
              final message = _parseMessage(event.snapshot);
              if (message == null) return;
              rideMessages.update(rideId, (value) => [...value, message],
                  ifAbsent: () => [message]);
            }));
  }

  void _requestAdded(String rideId, DataSnapshot snapshot) {
    final request = _parseRequest(snapshot);
    if (request == null) return;
    requests.update(rideId, (list) => [...list, request],
        ifAbsent: () => [request]);
    final messagesRef = FirebaseDatabase.instance
        .ref('/request_messages/$rideId/${request.passenger}/');
    final listener = messagesRef.onChildAdded.listen((event) {
      final message = _parseMessage(event.snapshot);
      if (message == null) return;
      requestMessages.update(
          rideId,
          (value) => value
            ..update(
              request.passenger,
              (list) => [...list, message],
              ifAbsent: () => [message],
            ),
          ifAbsent: () => {
                request.passenger: [message]
              });
    });
    if (!request.declined) {
      _requestMessageListeners.update(rideId,
          (value) => value..putIfAbsent(request.passenger, () => listener),
          ifAbsent: () => {request.passenger: listener});
    }

    notifyListeners();
  }

  void _requestChanged(String rideId, DataSnapshot snapshot) {
    final request = _parseRequest(snapshot);
    if (request == null) return;
    requests.update(rideId, (list) {
      final index =
          list.indexWhere((element) => element.passenger == request.passenger);
      list[index] = request;
      return list;
    }, ifAbsent: () => [request]);
    if (request.declined) {
      _requestMessageListeners[rideId]?[request.passenger]?.cancel();
      _requestMessageListeners[rideId]?.remove(request.passenger);
    } else {
      final messagesRef = FirebaseDatabase.instance
          .ref('/request_messages/$rideId/${request.passenger}/');
      final listener = messagesRef.onChildAdded.listen((event) {
        final message = _parseMessage(event.snapshot);
        if (message == null) return;
        requestMessages.update(
            rideId,
            (value) => value
              ..update(
                request.passenger,
                (list) => [...list, message],
                ifAbsent: () => [message],
              ),
            ifAbsent: () => {
                  request.passenger: [message]
                });
      });
      _requestMessageListeners.update(rideId,
          (value) => value..putIfAbsent(request.passenger, () => listener),
          ifAbsent: () => {request.passenger: listener});
    }
    notifyListeners();
  }

  void _requestRemoved(String rideId, DataSnapshot snapshot) {
    final request = _parseRequest(snapshot);
    if (request == null) return;
    requests.update(
        rideId,
        (list) => list
          ..removeWhere((element) => element.passenger == request.passenger));
    _requestMessageListeners[rideId]?[request.passenger]?.cancel();
    _requestMessageListeners[rideId]?.remove(request.passenger);
    notifyListeners();
  }

  PassengerInfo? _parsePassenger(DataSnapshot snapshot) {
    final id = snapshot.key;
    if (id == null) return null;
    final startLat = snapshot.child('start/latitude').value as double;
    final startLon = snapshot.child('start/longitude').value as double;
    final destLat = snapshot.child('destination/latitude').value as double;
    final destLon = snapshot.child('destination/longitude').value as double;
    final deleted = snapshot.child('deleted').value as bool?;
    final cancelled = snapshot.child('cancelled').value as bool?;
    final timestamp = snapshot.child('timestamp').value as int;
    final passenger = Passenger(id, LatLng(startLat, startLon),
        LatLng(destLat, destLon), deleted ?? false, cancelled ?? false);
    return PassengerInfo(passenger, timestamp);
  }

  Future<Passenger> fetchPassenger(String rideId) async {
    final ref = FirebaseDatabase.instance.ref('passengers/$rideId/');
    final event = await ref.once();
    final snapshot = event.snapshot;
    return passengers
        .putIfAbsent(rideId,
            () => snapshot.children.map((e) => _parsePassenger(e)!).toList())
        .singleWhere((element) => element.passenger.id == user?.id)
        .passenger;
  }

  Future<Route> fetchRoute(String id) async {
    final ref = FirebaseDatabase.instance.ref('/routes/$id');
    final event = await ref.once();
    final json = jsonDecode(jsonEncode(event.snapshot.value));
    final route = Route.fromJson(json);
    final timestamp = event.snapshot.child('timestamp').value as int;
    return routeInfos.putIfAbsent(id, () => RouteInfo(route, timestamp)).route;
  }

  void _passengerAdded(String rideId, DataSnapshot snapshot) {
    final data = _parsePassenger(snapshot);
    if (data == null) return;
    passengers.update(rideId, (list) => [...list, data],
        ifAbsent: () => [data]);
    if (!data.passenger.cancelled &&
        !data.passenger.removed &&
        data.passenger.id == user?.id) {
      _requestListeners[rideId]?.first.cancel();
      _requestListeners.remove(rideId);
      _requestMessageListeners[rideId]?[user?.id]?.cancel();
      _requestMessageListeners.remove(rideId);
      _listenRideMessages(rideId);
      final locationRef = FirebaseDatabase.instance.ref('/location/$rideId');
      _locationListeners.putIfAbsent(
          rideId,
          () => locationRef.onValue
              .listen((event) => _locationChanged(event.snapshot)));
    }
    notifyListeners();
  }

  void _passengerChanged(String rideId, DataSnapshot snapshot) {
    final id = snapshot.key;
    if (id == null) return;
    final data = _parsePassenger(snapshot);
    if (data == null) return;
    passengers.update(rideId, (list) {
      final index = list.indexWhere((element) => element.passenger.id == id);
      list[index] = data;
      return list;
    });
    if ((data.passenger.cancelled || data.passenger.removed) &&
        data.passenger.id == user?.id) {
      _locationListeners[rideId]?.cancel();
      _locationListeners.remove(rideId);
      _rideMessageListeners[rideId]?.cancel();
      _rideMessageListeners.remove(rideId);
    }
    notifyListeners();
  }

  void _passengerRemoved(String rideId, DataSnapshot snapshot) {
    final id = snapshot.key;
    if (id == null) return;
    passengers.update(
        rideId, (list) => list..removeWhere((data) => data.passenger.id == id));
    notifyListeners();
  }

  void _routeChanged(DataSnapshot snapshot) {
    final key = snapshot.key;
    if (key == null) return;
    final route = Route.fromJson(snapshot.value as Map<Object?, Object?>);
    final timestamp = snapshot.child('timestamp').value as int;
    final info = RouteInfo(route, timestamp);
    routeInfos.update(key, (_) => info, ifAbsent: () => info);
    notifyListeners();
  }

  void _locationChanged(DataSnapshot snapshot) {
    final key = snapshot.key;
    if (key == null) return;
    if (!snapshot.exists) return;
    final timestamp = snapshot.child('timestamp').value as int;
    final latitude = snapshot.child('latitude').value as double;
    final longitude = snapshot.child('longitude').value as double;
    final location = GpsLocation(LatLng(latitude, longitude), timestamp);
    locations.update(key, (_) => location, ifAbsent: () => location);
    notifyListeners();
  }

  void addInfoListener(String rideId) {
    _infoListeners.putIfAbsent(rideId, () => _addInfoListener(rideId));
  }

  StreamSubscription<DatabaseEvent> _addInfoListener(String rideId) {
    final rideInfo = FirebaseDatabase.instance.ref('/rides/$rideId/');
    return rideInfo.onValue.listen((event) {
      final info = _parseInfo(event.snapshot);
      if (info.isActive) {
        final routeInfo = FirebaseDatabase.instance.ref('/routes/$rideId');
        _routeListeners.putIfAbsent(
            rideId,
            () => routeInfo.onValue.listen((event) {
                  _routeChanged(event.snapshot);
                }));
        if (info.driver == user?.id) {
          _listenRideMessages(rideId);
          final requestRef = FirebaseDatabase.instance.ref('/requests/$rideId');
          _requestListeners.putIfAbsent(
              rideId,
              () => [
                    requestRef.onChildAdded.listen((event) {
                      _requestAdded(rideId, event.snapshot);
                    }),
                    requestRef.onChildChanged.listen((event) {
                      _requestChanged(rideId, event.snapshot);
                    }),
                    requestRef.onChildRemoved.listen((event) {
                      _requestRemoved(rideId, event.snapshot);
                    })
                  ]);
        } else {
          final requestRef =
              FirebaseDatabase.instance.ref('/requests/$rideId/${user?.id}/');
          _requestListeners.putIfAbsent(
              rideId,
              () => [
                    requestRef.onValue.listen((event) {
                      _requestChanged(rideId, event.snapshot);
                    })
                  ]);
        }

        final passengerRef =
            FirebaseDatabase.instance.ref('/passengers/$rideId');
        _passengerListeners.putIfAbsent(
            rideId,
            () => [
                  passengerRef.onChildAdded.listen(
                      (event) => _passengerAdded(rideId, event.snapshot)),
                  passengerRef.onChildChanged.listen(
                      (event) => _passengerChanged(rideId, event.snapshot)),
                ]);
      } else {
        removeListeners(rideId);
      }
      rideInfos.update(rideId, (_) => info, ifAbsent: () => info);
      notifyListeners();
    });
  }

  void _addListeners() {
    final ridesList =
        FirebaseDatabase.instance.ref('/users/${_user?.id}/rides');
    _timestampUpdateListener = ridesList.onChildChanged.listen((event) {
      final rideId = event.snapshot.key!;
      _rides.update(rideId, (value) => event.snapshot.value as int);
    });
    _rideAddedListener = ridesList.onChildAdded.listen((event) {
      final rideId = event.snapshot.key!;
      _rides.putIfAbsent(rideId, () => event.snapshot.value as int);
      _infoListeners.putIfAbsent(rideId, () => _addInfoListener(rideId));
    });
  }

  User? get user {
    return _user;
  }

  set user(User? newuser) {
    _timestampUpdateListener?.cancel();
    _rideAddedListener?.cancel();
    _rides.clear();
    removeAllListeners();
    _user = newuser;
    if (_user == null) return;
    _addListeners();
  }

  Future<String?> addRide(Route route, DepartureTime time, int capacity,
      String driver, String? info, Function onError) async {
    final Map<String, dynamic> values = {};
    final timeData = {
      'timestamp': ServerValue.timestamp,
      'min': max(time.min!.millisecondsSinceEpoch,
          DateTime.now().millisecondsSinceEpoch),
      'max': max(time.max!.millisecondsSinceEpoch,
          DateTime.now().millisecondsSinceEpoch),
    };
    final rideData = {
      'capacity': capacity,
      'driver': driver,
      'info': info,
      'time': timeData
    };
    final rideKey = FirebaseDatabase.instance.ref().child('/rides/').push().key;
    values['/rides/$rideKey/'] = rideData;
    for (var day in time.dates!) {
      values['/search/${day.year}/${day.month}/${day.day}/$rideKey/'] = true;
    }
    values['/users/${_user?.id}/rides/$rideKey/'] = ServerValue.timestamp;
    values['/routes/$rideKey/'] = route.toJson()
      ..putIfAbsent('timestamp', () => ServerValue.timestamp);
    String? result;
    await FirebaseDatabase.instance.ref().update(values).then((_) {
      result = rideKey;
    }).catchError((err) {
      onError(err);
      result = null;
    });
    return result;
  }
}
