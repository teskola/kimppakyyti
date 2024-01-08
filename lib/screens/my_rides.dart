import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide Route, DateUtils;
import 'package:kimppakyyti/models/departure_time.dart';
import 'package:kimppakyyti/providers/route.dart';
import 'package:kimppakyyti/providers/status.dart';
import 'package:kimppakyyti/providers/time.dart';
import 'package:kimppakyyti/widgets/loading_spinner.dart';
import 'package:kimppakyyti/widgets/status_icon.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/id.dart';
import '../utilities/date_utils.dart';
import '../utilities/ride_utils.dart';
import 'ride.dart';

class RideListItemTitle extends StatelessWidget {
  final Id id;
  const RideListItemTitle(this.id, {super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<RouteProvider>().get(id),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }
          return Text(RideUtils.rideString(snapshot.data!));
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class RideListItemTimeField extends StatelessWidget {
  final DepartureTime time;
  const RideListItemTimeField(this.time, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(DateUtils.departureTime(time.minimum, time.maximum));
  }
}

class RideListItemStatus extends StatefulWidget {
  final Id id;
  final DepartureTime time;
  const RideListItemStatus({super.key, required this.id, required this.time});

  @override
  State<RideListItemStatus> createState() => _RideListItemStatusState();
}

class _RideListItemStatusState extends State<RideListItemStatus> {
  Timer? timer;

  @override
  void initState() {
    super.initState();
    if (widget.time.isActive &&
        widget.time.actual == null &&
        !widget.time.isLate) {
      timer = Timer(
          Duration(
              milliseconds: widget.time.maximum.millisecondsSinceEpoch -
                  DateTime.now().millisecondsSinceEpoch),
          () => setState(() {}));
    }
  }

  @override
  void dispose() {
    super.dispose();
    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: context.read<StatusProvider>().get(widget.id),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final status = snapshot.data;
          if (status == Status.active) {
            if (widget.time.isActive) {
              if (widget.time.actual != null) {
                return const StatusIcon(Status.driving);
                // TODO: GPS
              }
              if (widget.time.isLate) {
                return const StatusIcon(Status.late);
              }
              return const StatusIcon(Status.waiting);
            }
            return const StatusIcon(Status.cancelled);
          }
          return StatusIcon(status);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class RideListItem extends StatelessWidget {
  final Id id;
  final DepartureTime time;
  final void Function() onTap;
  const RideListItem(
      {super.key, required this.id, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: RideListItemTitle(id),
      subtitle: RideListItemTimeField(time),
      trailing:
          SizedBox(width: 60, child: RideListItemStatus(id: id, time: time)),
      onTap: onTap,
    );
  }
}

class ActiveDriversList extends StatelessWidget {
  final driver = FirebaseAuth.instance.currentUser!.uid;
  ActiveDriversList({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<TimeProvider>().activeDriver;
    if (data.isEmpty) return const SizedBox.shrink();
    return Column(children: [
      ListTile(
          leading: const Icon(Icons.directions_car),
          title: Text(AppLocalizations.of(context).as_driver),
          dense: true),
      const Divider(),
      ListView.separated(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemBuilder: (_, index) {
            final key = data.keys.elementAt(index);
            final id = Id(driver: driver, ride: key);
            return RideListItem(
                id: id,
                time: data.values.elementAt(index),
                onTap: () => {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (_) {
                          return RidePage(id);
                        },
                      ))
                    });
          },
          separatorBuilder: (_, __) => const Divider(),
          itemCount: data.length),
      const Divider()
    ]);
  }
}

class HistoryList extends StatelessWidget {
  const HistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    final data = context.read<TimeProvider>().history;
    if (data.isEmpty) return const SizedBox.shrink();
    return Column(children: [
      ListTile(
          leading: const Icon(Icons.history),
          title: Text(AppLocalizations.of(context).history),
          dense: true),
      const Divider(),
      ListView.separated(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemBuilder: (_, index) {
            return RideListItem(
                id: data.keys.elementAt(index),
                time: data.values.elementAt(index),
                onTap: () {});
          },
          separatorBuilder: (_, __) => const Divider(),
          itemCount: data.length),
    ]);
  }
}

class MyRidesPage extends StatelessWidget {
  const MyRidesPage({super.key});

  /* Widget _activePassengerList(
    BuildContext context,
    DepractedDatabaseProvider provider,
  ) {
    final activePassenger = provider.activePassenger;
    if (activePassenger.isEmpty) return const SizedBox.shrink();
    return Column(children: [
      ListTile(
          leading: const Icon(Icons.hail),
          title: Text(AppLocalizations.of(context).as_passenger),
          dense: true),
      const Divider(),
      ListView.separated(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemBuilder: (_, index) {
            String key = activePassenger[index];
            return RideListItem(
                type: Type.passenger,
                info: provider.rideInfos[key],
                route: provider.routes[key],
                passenger: provider.passengers[key]
                    ?.singleWhere(
                        (element) => element.passenger.id == provider.user?.id)
                    .passenger,
                changed: provider.changedRides.contains(key),
                onTap: () => {});
          },
          separatorBuilder: (_, __) => const Divider(),
          itemCount: activePassenger.length),
    ]);
  }

  Widget _activeRequestList(
      BuildContext context, DepractedDatabaseProvider provider) {
    final activeRequest = provider.activeRequest;
    if (activeRequest.isEmpty) return const SizedBox.shrink();
    return Column(children: [
      ListTile(
          title: Text(AppLocalizations.of(context).requests), dense: true),
      ListView.separated(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemBuilder: (_, index) {
            final key = activeRequest[index];
            return RideListItem(
                type: Type.request,
                info: provider.rideInfos[key],
                route: provider.routes[key],
                request: provider.requests[key]?.firstWhere(
                    (element) => element.passenger == provider.user?.id),
                changed: provider.changedRides.contains(key),
                onTap: () => {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) {
                          return RidePage(id: key);
                        },
                      ))
                    });
          },
          separatorBuilder: (_, __) => const Divider(),
          itemCount: activeRequest.length),
    ]);
  } */
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TimeProvider>();
    if (provider.isLoading) {
      return const LoadingSpinner();
    }
    if (provider.data.isEmpty) {
      return Center(
        child: Text(AppLocalizations.of(context).no_rides_found),
      );
    }
    return ListView(
      children: [
/*               _activeRequestList(context, provider),
 */
        ActiveDriversList(),
/*               _activePassengerList(context, provider),
 */
        HistoryList(),
      ],
    );
  }
}
