import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kimppakyyti/utilities/map_utils.dart';

class MyLocations {
  Point? home;
  Point? work;
  Map<String, Point>? custom;

  List<Point> get locations {
    return [
      if (home != null) home!,
      if (work != null) work!,
      ...?custom?.entries.map((e) => NamedPoint.fromPoint(e.key, e.value)),
    ]..sort((a, b) => a.id.compareTo(b.id));
  }

  MyLocations({this.home, this.work, this.custom});

  Map<String, Object?> toJson() => {
        'home': home?.toJson(),
        'work': work?.toJson(),
        'custom': custom?.map((key, value) => MapEntry(key, value.toJson())),
      };

  factory MyLocations.fromJson(Map<Object?, Object?> json) {
    final home = json['home'] as Map<Object?, Object?>?;
    final work = json['work'] as Map<Object?, Object?>?;
    final custom = json['custom'] as Map<Object?, Object?>?;

    return MyLocations(
        home: home != null ? Point.fromJson(home) : null,
        work: work != null ? Point.fromJson(work) : null,
        custom: custom?.map((key, value) => MapEntry(
            key as String, Point.fromJson(value as Map<Object?, Object?>))));
  }
}

class NamedPoint extends Point {
  String name;
  NamedPoint(
      {required this.name,
      required super.latitude,
      required super.longitude,
      required super.area});

  @override
  String get id => name;

  factory NamedPoint.fromPoint(String name, Point point) {
    return NamedPoint(
        name: name,
        latitude: point.latitude,
        longitude: point.longitude,
        area: point.area);
  }
}

extension DoubleRounding on double {
  double toPrecision(int n) => double.parse(toStringAsFixed(n));
}

class Point {
  late final double latitude;
  late final double longitude;
  final String area;

  String get id => area;

  Point(
      {required double latitude,
      required double longitude,
      required this.area}) {
    this.latitude = latitude.toPrecision(6);
    this.longitude = longitude.toPrecision(6);
  }

  factory Point.fromJson(Map<Object?, Object?> json) {
    return Point(
        longitude: json['longitude'] as double,
        latitude: json['latitude'] as double,
        area: json['area'] as String);
  }

  Map<String, Object?> toJson() => {
        'area': area,
        'longitude': longitude,
        'latitude': latitude,
      };

  /// returns distance of two points in kilometers
  double distance(LatLng other) {
    return MapUtils.getDistance(
        latitude, longitude, other.latitude, other.longitude);
  }

  @override
  bool operator ==(covariant Point other) =>
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.area == area;

  @override
  int get hashCode => Object.hash(latitude, longitude, area);

  @override
  String toString() {
    return '$area\n[${latitude.toStringAsFixed(3)}, ${longitude.toStringAsFixed(3)}]';
  }
}

class Area {
  final String name;
  final List<Poly> polygons;

  const Area({required this.name, required this.polygons});
  factory Area.fromJson(Map<String, dynamic> json) {
    String type = json['geometry']['type'];
    switch (type) {
      case 'Polygon':
        List<Poly> items = [];
        items.add(Poly.fromJson(json['geometry']['coordinates']));
        return Area(
            name: json['properties']['Name'] as String, polygons: items);
      case 'MultiPolygon':
        List<Poly> items = List.from(List.from(json['geometry']['coordinates'])
            .map((e) => Poly.fromJson(e)));
        return Area(
            name: json['properties']['Name'] as String, polygons: items);
      default:
        throw FormatException("Invalid type: $type");
    }
  }

  bool pointInArea(final LatLng point) {
    for (var polygon in polygons) {
      if (polygon.pointInPolygon(point)) {
        return true;
      }
    }
    return false;
  }
}

class Poly {
  final List<LatLng> polygon;
  final List<List<LatLng>>? holes;
  const Poly({required this.polygon, this.holes});

  factory Poly.fromJson(List<dynamic> json) {
    List<List<LatLng>> holesList = [];
    for (var i = 1; i < json.length; i++) {
      List<dynamic> item = List.from(json[i]);
      List<LatLng> hole = List.from(item.map((e) => LatLng(e[1], e[0])));
      holesList.add(hole);
    }
    return Poly(
        polygon: List.from(List.from(json[0]).map((e) => LatLng(e[1], e[0]))),
        holes: holesList.isNotEmpty ? holesList : null);
  }

  bool pointInPolygon(final LatLng point) {
    if (MapUtils.pointInPolygon(point, polygon)) {
      if (holes != null) {
        for (var hole in holes!) {
          if (MapUtils.pointInPolygon(point, hole)) {
            return false;
          }
        }
      }
      return true;
    }
    return false;
  }
}
