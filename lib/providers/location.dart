import 'dart:convert';
import 'dart:io';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:kimppakyyti/providers/database.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/location.dart';

class LocationProvider extends DatabaseProvider with ChangeNotifier {
  late final List<Point> cityCenters;
  late MyLocations myLocations;
  late final SharedPreferences _prefs;
  late final String _uid;

  Point? get home => myLocations.home;
  Point? get work => myLocations.work;
  Map<String, Point>? get custom => myLocations.custom;
  int get customLength => myLocations.custom?.length ?? 0;

  set home(Point? point) {
    myLocations.home = point;
    _writeToFile();
    _writeToFirebase("home", point);
    notifyListeners();
  }

  set work(Point? point) {
    myLocations.work = point;
    _writeToFile();
    _writeToFirebase("work", point);
    notifyListeners();
  }

  List<Point> get locations {
    return [...myLocations.locations, ...cityCenters];
  }

  LocationProvider(BuildContext context) {
    _getCityCenters();
    _getMyLocationsFromLocal();
    _obtainSharedPreferences();
  }

  String? getName(int index) {
    if (myLocations.custom == null || myLocations.custom!.length < index + 1) {
      return null;
    }
    return myLocations.custom!.keys.elementAt(index);
  }

  Future<void> _obtainSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> _setTimestamp(int value) async {
    _prefs.setInt('myLocationsTimestamp', value);
  }

  Future<int?> _fetchTimestamp() async {
    final ref = FirebaseDatabase.instance
        .ref('/users/$_uid/private/locations/timestamp');
    final event = await ref.once();
    return event.snapshot.value as int?;
  }

  Future<MyLocations> _fetchLocations() async {
    final ref =
        FirebaseDatabase.instance.ref('/users/$_uid/private/locations/data/');
    final event = await ref.once();
    if (event.snapshot.value == null) return MyLocations();
    return MyLocations.fromJson(event.snapshot.value as Map<Object?, Object?>);
  }

  void _add(String name, Point point) {
    myLocations.custom ??= {};
    myLocations.custom![name] = point;
    _writeToFile();
    _writeToFirebase("custom", point, name: name);
    notifyListeners();
  }

  void update(String name, Point point) {
    if (myLocations.custom == null || myLocations.custom!.isEmpty) {
      _add(name, point);
      return;
    }
    myLocations.custom![name] = point;
    _writeToFile();
    _writeToFirebase("custom", point, name: name);
    notifyListeners();
  }

  void delete(String name) {
    myLocations.custom!.remove(name);
    _writeToFile();
    _writeToFirebase("custom", null, name: name);
    notifyListeners();
  }

  String name(BuildContext context, Point point) {
    if (home == point) return AppLocalizations.of(context).home;
    if (work == point) return AppLocalizations.of(context).work;
    if (custom != null && custom!.containsValue(point)) {
      return custom!.entries
          .firstWhere((element) => element.value == point)
          .key;
    }
    return point.municipality;
  }

  Future<void> _getMyLocationsFromLocal() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/mylocations.json";
    final file = File(path);
    if (await file.exists()) {
      final contents = await file.readAsString();
      final json = jsonDecode(contents);
      myLocations = MyLocations.fromJson(json);
      return;
    }
    myLocations = MyLocations();
  }

  Future<void> _writeToFirebase(String location, Point? point,
      {String? name}) async {
    final Map<String, dynamic> values = {};
    String path;
    if (name == null) {
      path = '/users/$_uid/private/locations/data/$location/';
    } else {
      path = '/users/$_uid/private/locations/data/$location/$name/';
    }
    values['/users/$_uid/private/locations/timestamp'] = ServerValue.timestamp;
    values[path] = point?.toJson();

    final snapshot = await FirebaseDatabase.instance.ref().update(values).then(
        (_) => FirebaseDatabase.instance
            .ref('/users/$_uid/private/locations/timestamp')
            .get());
    _setTimestamp(snapshot.value as int);
  }

  Future<void> _writeToFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory.path}/mylocations.json";
    final file = File(path);
    file.writeAsString(jsonEncode(myLocations.toJson()));
  }

  Future<void> _getCityCenters() async {
    String jsonText = await rootBundle.loadString('assets/json/locations.json');
    final jsonList = jsonDecode(jsonText)['locations'] as List;
    cityCenters = jsonList
        .map((location) => Point.fromJson(location))
        .toList(growable: false);
  }

  @override
  void close() {
    // TODO: implement close
  }

  @override
  void start(String uid) async {
    _uid = uid;
    final firebaseUpdated = await _fetchTimestamp();
    if (firebaseUpdated == null) return;
    final localUpdated = _prefs.getInt('myLocationsTimestamp');
    if (localUpdated == null || localUpdated < firebaseUpdated) {
      myLocations = await _fetchLocations();
    }
  }
}
