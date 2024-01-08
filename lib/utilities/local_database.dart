import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/id.dart';
import '../models/location.dart';
import '../models/route.dart';

class LocalDatabase {
  static final LocalDatabase _localDatabase = LocalDatabase._internal();
  Database? _db;
  LocalDatabase._internal();
  factory LocalDatabase() => _localDatabase;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initialize();
    return _db!;
  }

  Future<Database> _initialize() async {
    final String uid = FirebaseAuth.instance.currentUser!.uid;
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, "$uid.db");
    return openDatabase(path, version: 1, onConfigure: (db) async {
      await db.execute("PRAGMA foreign_keys = ON");
    }, onCreate: (db, _) async {
      await db.execute('CREATE TABLE User (id TEXT PRIMARY KEY) WITHOUT ROWID');
      await db.insert('User', {"id": uid});
      await db.execute(
          'CREATE TABLE Point (id INTEGER PRIMARY KEY, latitude REAL NOT NULL, longitude REAL NOT NULL, area TEXT NOT NULL, UNIQUE (latitude, longitude))');
      await db.execute(
          'CREATE TABLE Leg (id INTEGER PRIMARY KEY, polyline TEXT NOT NULL, start INTEGER NOT NULL, destination INTEGER NOT NULL, distance INTEGER NOT NULL, duration INTEGER NOT NULL, route INTEGER NOT NULL, count INTEGER NOT NULL, FOREIGN KEY (start) REFERENCES Point (id), FOREIGN KEY (destination) REFERENCES Point (id), FOREIGN KEY (route) REFERENCES Route (id))');
      await db.execute(
          'CREATE TABLE Route (id INTEGER PRIMARY KEY, driver TEXT DEFAULT $uid, firebase TEXT, name TEXT, FOREIGN KEY (driver, firebase) REFERENCES Ride (driver, id) ON DELETE SET DEFAULT)');
      await db.execute(
          'CREATE TABLE Ride (driver TEXT, id TEXT, route INTEGER NOT NULL, reversed INTEGER DEFAULT 0, PRIMARY KEY (driver, id), FOREIGN KEY (route) REFERENCES Route (id), FOREIGN KEY (driver) REFERENCES User (id)) WITHOUT ROWID');
    });
  }

  Future<int> _addPointTxn(Point point, Transaction txn) async {
    final search = await _searchPointTxn(point, txn);
    if (search != null) return search;
    return txn.insert("Point", point.toJson());
  }

  Future<int> _addRouteTxn(Route route, Transaction txn, String driver) async {
    final id = await txn.insert("Route", {"driver": driver});
    for (var i = 0; i < route.legs.length; i++) {
      txn.insert("Leg", {
        "start": await _addPointTxn(route.legs[i].start, txn),
        "destination": await _addPointTxn(route.legs[i].destination, txn),
        "distance": route.legs[i].distance,
        "duration": route.legs[i].duration,
        "polyline": route.legs[i].polyline,
        "route": id,
        "count": i
      });
    }
    return id;
  }

  Future<int?> _searchPointTxn(Point point, Transaction txn) async {
    final data = await txn.query("Point",
        columns: ["id"],
        where: "latitude = ? AND longitude = ?",
        whereArgs: [point.latitude, point.longitude]);
    if (data.isEmpty) return null;
    return data[0]["id"] as int;
  }

  Future<Point> _getPointTxn(int id, Transaction txn) async =>
      Point.fromJson((await txn.query("Point",
              columns: ["latitude", "longitude", "area"],
              where: "id = ?",
              whereArgs: [id]))
          .first);

  Future<int?> _routeFromPointsTxn(List<int> points, Transaction txn) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final q1 = await txn.rawQuery(
        'SELECT Route.id FROM Leg INNER JOIN Route ON Leg.route=Route.id WHERE Route.driver = ? AND Leg.start = ? AND Leg.destination = ?',
        [uid, points[0], points[1]]);
    if (q1.isEmpty) return null;
    final List<int> routeIds = q1.map((e) => e["id"] as int).toList();

    for (var i = 1; i < points.length - 1; i++) {
      var q2 = await txn.rawQuery(
          'SELECT Route.id FROM Leg INNER JOIN Route ON Leg.route=Route.id WHERE Route.driver = ? AND Leg.start = ? AND Leg.destination = ?',
          [uid, points[i], points[i + 1]]);
      if (q2.isEmpty) return null;
      List<int> l2 = q2.map((e) => e["id"] as int).toList();
      routeIds.removeWhere((element) => !l2.contains(element));
      if (routeIds.isEmpty) return null;
    }
    return routeIds[0];
  }

  /* Future<int?> routeFromPoints(List<int> points) async {
    final db = await database;
    return db.transaction((txn) async => _routeFromPointsTxn(points, txn));
  } */

  /* Future<int> _getRouteIdTxn(String firebase, Transaction txn) async {
    final query = await txn.query("Route",
        columns: ["id"], where: "firebase = ?", whereArgs: [firebase]);
  } */

  Future<List<Leg>> _getLegsTxn(int id, Transaction txn) async {
    List<Leg> result = [];
    final legs = await txn.query("Leg",
        columns: ["start", "destination", "distance", "duration", "polyline"],
        where: "route = ?",
        whereArgs: [id],
        orderBy: "count");
    for (var i = 0; i < legs.length; i++) {
      var start = await _getPointTxn(legs[i]["start"] as int, txn);
      var destination = await _getPointTxn(legs[i]["destination"] as int, txn);
      var duration = legs[i]["duration"] as int;
      var distance = legs[i]["distance"] as int;
      var polyline = legs[i]["polyline"] as String;
      result.add(Leg(start, destination, distance, duration, polyline));
    }
    return result;
  }

  Future<CustomRoute?> _getRouteTxn(int id, Transaction txn,
      {bool reversed = false}) async {
    final route = await txn.query("Route", where: "id = ?", whereArgs: [id]);
    if (route.isEmpty) return null;
    final legs = await _getLegsTxn(id, txn);
    return CustomRoute(legs, id,
        name: route[0]["name"] as String?,
        firebase: route[0]["firebase"] as String?,
        reversed: reversed);
  }

  /* Future<List<Route>> getRoutes() async {
    final List<Route> result = [];
    final db = await database;
    final list = await db.query("Route");
    for (var route in list) {
      var legs = await db.query("Leg",
          columns: ["start", "destination", "distance", "duration"],
          where: "route = ?",
          whereArgs: [route["id"] as String],
          orderBy: "count");
      List<Leg> l = [];
      for (var i = 0; i < legs.length; i++) {
        l.add(Leg(
            (await getPoint(legs[i]["start"] as int)),
            (await getPoint(legs[i]["destination"] as int)),
            legs[i]["distance"] as int,
            legs[i]["duration"] as int));
      }
      if (route["name"] != null) {
        result.add(NamedRoute(
            l, route["polyline"] as String, route["name"] as String));
      } else {
        result.add(Route(l, route["polyline"] as String));
      }
    }
    return result;
  } */

  Future<int> addRoute(Route route, String driver) async {
    final db = await database;
    return db.transaction((txn) async => _addRouteTxn(route, txn, driver));
  }

  Future<int> addRide(Id id, Object route, {bool reversed = false}) async {
    Map<String, Object> values = {"id": id.ride, "driver": id.driver};
    if (reversed) {
      values["reversed"] = 1;
    }
    if (route is int) {
      values["route"] = route;
    }
    final db = await database;
    return db.transaction((txn) async {
      await txn.insert('User', {"id": id.driver},
          conflictAlgorithm: ConflictAlgorithm.ignore);
      if (route is Route) {
        values["route"] = await _addRouteTxn(route, txn, id.driver);
      }
      int result = await txn.insert("Ride", values);
      await txn.update("Route", {"firebase": id.ride},
          where: "id = ? AND firebase IS NULL", whereArgs: [values["route"]]);
      return result;
    });
  }

  Future<CustomRoute?> getRoute(Id id) async {
    final db = await database;
    return db.transaction((txn) async {
      final query = await txn.query("Ride",
          columns: ["route", "reversed"],
          where: "id = ? AND driver = ?",
          whereArgs: [id.ride, id.driver]);
      if (query.isEmpty) return null;
      final route = query[0]["route"] as int;
      final reversed = query[0]["reversed"] as int;
      return _getRouteTxn(route, txn, reversed: reversed > 0);
    });
  }

  Future<CustomRoute?> searchRoute(
      Point start, Point destination, List<Point> waypoints) async {
    List<Point> list = [start, ...waypoints, destination];
    List<int> points = [];
    final db = await database;
    return db.transaction((txn) async {
      for (var point in list) {
        var index = await _searchPointTxn(point, txn);
        if (index == null) return null;
        points.add(index);
      }
      var route = await _routeFromPointsTxn(points, txn);
      if (route != null) {
        debugPrint("Route found from local database");
        return _getRouteTxn(route, txn);
      }
      route = await _routeFromPointsTxn(points.reversed.toList(), txn);
      if (route != null) {
        debugPrint("Route found from local database");
        return _getRouteTxn(route, txn, reversed: true);
      }
      return null;
    });
  }

  Future<void> nameRoute(String name, String id) async {
    final db = await database;
    await db.update("Route", {"name": name},
        where: "firebase = ?", whereArgs: [id]);
  }

  Future<void> reverse(int id) async {
    final db = await database;
    return db.transaction((txn) async {
      final query = await txn.query("Leg",
          columns: ["start", "destination", "id", "count"],
          where: "route = ?",
          whereArgs: [id]);
      for (var i = 0; i < query.length; i++) {
        txn.update(
            "Leg",
            {
              "start": query[i]["destination"],
              "destination": query[i]["start"],
              "count": query.length - 1 - i
        },
            where: "id = ?",
            whereArgs: [query[i]["id"]]);
      }
    });
  }
}
