/* import 'package:flutter/material.dart' hide Route, DateUtils;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kimppakyyti/models/passenger.dart';
import 'package:kimppakyyti/utilities/map_utils.dart';
import 'package:kimppakyyti/utilities/ride_utils.dart';
import '../models/request.dart';
import '../models/ride.dart';
import '../models/route.dart';
import '../providers/status.dart';
import '../screens/ride.dart';
import '../utilities/date_utils.dart';
import 'status_icon.dart';

enum Type { driver, passenger, request, search }

class RideListItem extends StatelessWidget {
  final BuildContext context;
  final String id;
  final Type type;
  final RideInfo? info;
  final Route? route;
  final Passenger? passenger;
  final Request? request;
  final bool changed;

  const RideListItem(
      {super.key,
      required this.context,
      required this.id,
      required this.type,
      this.info,
      this.route,
      this.passenger,
      this.changed = false,
      this.request});

  Status? _getStatus() {
    if (info == null) return null;
    if (info!.cancelled) return Status.cancelled;
    if (type == Type.passenger) {
      if (passenger == null) return null;
      if (passenger!.removed || passenger!.cancelled) {
        return Status.cancelled;
      }
    }
    if (info!.finished) return Status.finished;
    if (!info!.departureTime.isActive) return Status.cancelled;
    if (type == Type.request) {
      if (request == null) return null;
      if (request!.declined) return Status.declined;
      return Status.waiting;
    }
    if (info!.departureTime.actual == null) return Status.waiting;
    if (type == Type.search) {
      // TODO: full check
      return Status.full;
    }
    return Status.driving;
  }

  Future<Widget?> _getTitle() async {
    switch (type) {
      case Type.driver:
        return Text(
            route!.name ?? "${route!.start.name}—${route!.destination.name}");
      case Type.passenger:
        if (passenger == null) return null;
        final start = await MapUtils().reverseGeoCode(
            coordinates:
                LatLng(passenger!.start.latitude, passenger!.start.longitude));
        final destination = await MapUtils().reverseGeoCode(
            coordinates: LatLng(passenger!.destination.latitude,
                passenger!.destination.longitude));
        return Text(
            RideUtils.rideString(route!, start: start?.name, destination: destination?.name));
      case Type.request:
        if (request == null) return null;
        final start = await MapUtils().reverseGeoCode(
            coordinates:
                LatLng(request!.start.latitude, request!.start.longitude));
        final destination = await MapUtils().reverseGeoCode(
            coordinates: LatLng(
                request!.destination.latitude, request!.destination.longitude));
        return Text(
            RideUtils.rideString(route!, start: start?.name, destination: destination?.name));
      default:
        throw UnimplementedError();
    }
  }

  @override
  Widget build(BuildContext context) {
    return info == null ||
            route == null ||
            (type == Type.passenger && passenger == null) ||
            (type == Type.request && request == null)
        ? const SizedBox.shrink()
        : FutureBuilder(
            future: _getTitle(),
            builder: (context, snapshot) {
              return Stack(
                children: [
                  Positioned(
                      right: 2,
                      child: Container(
                        decoration: changed
                            ? BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(6))
                            : null,
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                      )),
                  ListTile(
                    title: snapshot.data,
                    subtitle: Text(DateUtils.departureTime(
                        info!.departureTime.minimum,
                        info!.departureTime.maximum)),
                    trailing: StatusIcon(_getStatus()),
                    onTap:() {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) {
                          return RidePage(id);
                        },
                      ));
                    },
                  )
                ],
              );
            },
          );
  }
}
 */