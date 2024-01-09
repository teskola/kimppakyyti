import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/location.dart';

class Geocoder {
  static final Geocoder _geocoder = Geocoder._internal();
  List<Area>? _municipalities;

  Geocoder._internal();
  factory Geocoder() => _geocoder;

  Future<List<Area>> get municipalities async {
    if (_municipalities != null) return _municipalities!;
    _municipalities = await _readLocations();
    return _municipalities!;
  }

  Future<List<Area>> _readLocations() async {
    String jsonText = await rootBundle
        .loadString('assets/json/kuntarajat.geojson', cache: false);
    final data = jsonDecode(jsonText)['features'] as List;
    return data.map((json) => Area.fromJson(json)).toList();
  }

  Future<String?> reverseGeoCode(LatLng coordinates) async {
    for (var location in await municipalities) {
      if (location.pointInArea(coordinates)) {
        return location.name;
      }
    }
    return null;
  }

  // https://gist.github.com/vlasky/d0d1d97af30af3191fc214beaf379acc

  double _cross(LatLng x, LatLng y, LatLng z) {
    return (y.latitude - x.latitude) * (z.longitude - x.longitude) -
        (z.latitude - x.latitude) * (y.longitude - x.longitude);
  }

  bool pointInPolygon(LatLng point, List<LatLng> polygon) {
    int wn = 0;
    for (var i = 0; i < polygon.length; i++) {
      final LatLng b = polygon[(i + 1) % polygon.length];
      if (polygon[i].longitude <= point.longitude) {
        if (b.longitude > point.longitude && _cross(polygon[i], b, point) > 0) {
          wn += 1;
        }
      } else if (b.longitude <= point.longitude &&
          _cross(polygon[i], b, point) < 0) {
        wn -= 1;
      }
    }
    return wn != 0;
  }
}
