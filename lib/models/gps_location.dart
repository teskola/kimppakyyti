import 'package:google_maps_flutter/google_maps_flutter.dart';

class GpsLocation {
  final LatLng coordinates;
  final int timestamp;

  GpsLocation(this.coordinates, this.timestamp);
}
