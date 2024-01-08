import 'package:google_maps_flutter/google_maps_flutter.dart';

class Request {
  final String passenger;
  final LatLng start;
  final LatLng destination;
  final bool declined;
  final int timestamp;

  Request(this.passenger, this.start, this.destination, this.declined,
      this.timestamp);
}
