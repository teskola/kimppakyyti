import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:kimppakyyti/models/departure_time.dart';
import 'package:kimppakyyti/models/id.dart';
import 'package:kimppakyyti/utilities/local_database.dart';

import '../models/route.dart';

class DatabaseUtils {
  static Future<String?> addRideToDatabase(
      final CustomRoute route,
      final DepartureTime time,
      final int capacity,
      final String? info,
      final Function onError) async {
var reversed = route.reversed;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final Map<String, dynamic> values = {};
    Map<String, dynamic> routeData = {'timestamp': ServerValue.timestamp};
    Map<String, dynamic> rideData = {
      'capacity': capacity,
      'info': {'value': info, 'timestamp': ServerValue.timestamp},
      'time': {'data': time.toJson(), 'timestamp': ServerValue.timestamp},
      };
    if (route.firebase != null) {
      routeData["data"] = {
        "pointer": route.firebase,
        "reversed": route.reversed
      };
    } else {
      if (route.reversed) {
        LocalDatabase().reverse(route.local);
        reversed = false;
        routeData["data"] = route.reverse().toJson();
      } else {
        routeData["data"] = route.toJson();
      }
    }
    rideData['route'] = routeData;
    final rideKey =
        FirebaseDatabase.instance.ref().child('/rides/$uid/').push().key;
    values['/rides/$uid/$rideKey/'] = rideData;
    for (var day in time.dates!) {
      values['/search/${day.year}/${day.month}/${day.day}/$rideKey/'] = uid;
    }
    values['/users/$uid/private/rides/data/$uid/$rideKey/'] =
        ServerValue.timestamp;
    values['/users/$uid/private/rides/timestamp'] = ServerValue.timestamp;
    String? result;
    await FirebaseDatabase.instance.ref().update(values).then((_) {
      LocalDatabase().addRide(Id(driver: uid, ride: rideKey!), route.local, reversed: reversed);
result = rideKey;
    }).catchError((err) {
      onError(err);
result = null;
    });
return result;
  }
}
