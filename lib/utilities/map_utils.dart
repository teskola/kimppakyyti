import 'dart:convert';
import 'dart:math';
import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum MarkerIcon {
  start,
  destination,
  waypoint,
  gpsLocation,
  car,
  home,
  work,
  custom
}

class MapUtils {
  static const int maxWaypoints = 2;

  static Future<BitmapDescriptor> getIcon(MarkerIcon marker, ImageConfiguration config) async {
    switch (marker) {
      case MarkerIcon.home:
        return await BitmapDescriptor.fromAssetImage(
            config, 'assets/icons/home.png');
      case MarkerIcon.custom:
        return await BitmapDescriptor.fromAssetImage(
            config, 'assets/icons/custom.png');
      case MarkerIcon.work:
        return await BitmapDescriptor.fromAssetImage(
            config, 'assets/icons/work.png');
      case MarkerIcon.start:
        return await BitmapDescriptor.fromAssetImage(
            config, 'assets/icons/start.png');
      case MarkerIcon.destination:
        return await BitmapDescriptor.fromAssetImage(
            config, 'assets/icons/checkered.png');
      case MarkerIcon.waypoint:
        return await BitmapDescriptor.fromAssetImage(
            config, 'assets/icons/waypoint.png');
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }    

  // https://stackoverflow.com/questions/27928/calculate-distance-between-two-latitude-longitude-points-haversine-formula

  static double getDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Radius of the earth in km
    final dLat = _deg2rad(lat2 - lat1); // deg2rad below
    final dLon = _deg2rad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_deg2rad(lat1)) *
            cos(_deg2rad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final d = R * c; // Distance in km
    return d;
  }

  static double _deg2rad(deg) {
    return deg * (pi / 180);
  }
  
  // https://github.com/Dammyololade/flutter_polyline_points/blob/master/lib/src/network_util.dart

  static List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;
    BigInt big0 = BigInt.from(0);
    BigInt big0x1f = BigInt.from(0x1f);
    BigInt big0x20 = BigInt.from(0x20);

    while (index < len) {
      int shift = 0;
      BigInt b, result;
      result = big0;
      do {
        b = BigInt.from(encoded.codeUnitAt(index++) - 63);
        result |= (b & big0x1f) << shift;
        shift += 5;
      } while (b >= big0x20);
      BigInt rShifted = result >> 1;
      int dLat;
      if (result.isOdd) {
        dLat = (~rShifted).toInt();
      } else {
        dLat = rShifted.toInt();
      }
      lat += dLat;

      shift = 0;
      result = big0;
      do {
        b = BigInt.from(encoded.codeUnitAt(index++) - 63);
        result |= (b & big0x1f) << shift;
        shift += 5;
      } while (b >= big0x20);
      rShifted = result >> 1;
      int dLng;
      if (result.isOdd) {
        dLng = (~rShifted).toInt();
      } else {
        dLng = rShifted.toInt();
      }
      lng += dLng;

      points.add(LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble()));
    }
    return points;
  }

  // https://github.com/everton-e26/polyline_codec

  static num _py2Round(num value) {
    return (value.abs() + 0.5).floor() * (value >= 0 ? 1 : -1);
  }

  static String _encode(num current, num previous, num factor) {
    current = _py2Round(current * factor);
    previous = _py2Round(previous * factor);
    Int32 coordinate = Int32(current as int) - Int32(previous as int) as Int32;
    coordinate <<= 1;
    if (current - previous < 0) {
      coordinate = ~coordinate;
    }
    var output = "";
    while (coordinate >= Int32(0x20)) {
      try {
        Int32 v = (Int32(0x20) | (coordinate & Int32(0x1f))) + 63 as Int32;
        output += String.fromCharCodes([v.toInt()]);
      } catch (err) {
        debugPrint(err.toString());
      }
      coordinate >>= 5;
    }
    output += ascii.decode([coordinate.toInt() + 63]);
    return output;
  }

  static String encodePolyline(List<LatLng> coordinates, {int precision = 5}) {
    if (coordinates.isEmpty) {
      return "";
    }

    final factor = pow(10, precision);
    var output = _encode(coordinates[0].latitude, 0, factor) +
        _encode(coordinates[0].longitude, 0, factor);

    for (var i = 1; i < coordinates.length; i++) {
      var a = coordinates[i], b = coordinates[i - 1];
      output += _encode(a.latitude, b.latitude, factor);
      output += _encode(a.longitude, b.longitude, factor);
    }
    return output;
  }

  // https://gist.github.com/vlasky/d0d1d97af30af3191fc214beaf379acc

  static double _cross(final LatLng x, final LatLng y, final LatLng z) {
    return (y.latitude - x.latitude) * (z.longitude - x.longitude) -
        (z.latitude - x.latitude) * (y.longitude - x.longitude);
  }

  static bool pointInPolygon(final LatLng point, final List<LatLng> polygon) {
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
