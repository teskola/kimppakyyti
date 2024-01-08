import 'package:kimppakyyti/models/departure_time.dart';
import 'package:kimppakyyti/models/route.dart';
import 'gps_location.dart';
import 'passenger.dart';

class Ride {
  final String id;
  final Route route;
  final DepartureTime departureTime;
  final String driverId;
  final String? info;
  final List<Passenger> passengers;
  final int capacity;
  final bool cancelled;
  GpsLocation? location;

  Ride(this.id, this.route, this.departureTime, this.driverId, this.passengers,
      this.capacity, this.info,
      {this.cancelled = false, this.location});
}

class RideInfo {
  final int capacity;
  final String driver;
  final DepartureTime departureTime;
  final int timestamp;
  final bool cancelled;
  final bool finished;
  final String? info;

  bool get isActive {
    if (cancelled) return false;
    if (finished) return false;
    return departureTime.isActive;
  }

  RideInfo(this.capacity, this.driver, this.departureTime, this.timestamp,
      this.cancelled, this.finished, this.info);
}
