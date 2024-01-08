import 'package:google_maps_flutter/google_maps_flutter.dart';

class Passenger {
  final String id;
  final LatLng start;
  final LatLng destination;
  final bool removed;
  final bool cancelled;

  Passenger(
      this.id, this.start, this.destination, this.removed, this.cancelled);
}

class PassengerInfo {
  final Passenger passenger;
  final int timestamp;

  PassengerInfo(this.passenger, this.timestamp);
}
