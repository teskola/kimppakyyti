import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart' hide Route, DateUtils;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kimppakyyti/models/departure_time.dart';
import 'package:kimppakyyti/utilities/map_utils.dart';
import 'package:kimppakyyti/utilities/ride_utils.dart';
import 'package:kimppakyyti/widgets/loading_spinner.dart';

import '../../models/location.dart';
import '../../models/route.dart';
import '../../utilities/date_utils.dart';

class SearchResult {
  final String driverId;
  final String rideId;
  Deviations deviations;
  Route route;
  SearchResult(this.driverId, this.rideId, this.route, this.deviations);
}

class SearchResultsPage extends StatefulWidget {
  final DateTime date;
  final Point start;
  final Point destination;
  const SearchResultsPage(
      {super.key,
      required this.date,
      required this.start,
      required this.destination});

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  bool _isLoading = false;
  final List<SearchResult> _results = [];
  final List<StreamSubscription<DatabaseEvent>> _routeListeners = [];
  late StreamSubscription<DatabaseEvent> _rideAdded;

  @override
  void initState() {
    _rideAdded = FirebaseDatabase.instance
        .ref(
            'search/${widget.date.year}/${widget.date.month}/${widget.date.day}')
        .onChildAdded
        .listen((event) {
      setState(() {
        _isLoading = true;
      });
      final rideId = event.snapshot.key!;
      final driverId = event.snapshot.value as String;

      DatabaseReference routeRef =
          FirebaseDatabase.instance.ref('rides/$driverId/$rideId/route/data');
      _routeListeners.add(routeRef.onValue.listen((routeEvent) {
        final snapshot = routeEvent.snapshot.value;
        final route = Route.fromJson(snapshot as Map<Object?, Object?>);
        List<LatLng> points = [];
        for (var i = 0; i < route.legs.length; i++) {
          points.addAll(MapUtils.decodePolyline(route.legs[i].polyline));
        }
        final deviations =
            RideUtils.getDeviations(points, widget.start, widget.destination);
        if (deviations != null) {
          int index = _results.indexWhere((result) =>
              result.driverId == driverId && result.rideId == rideId);
          // New ride
          if (index < 0) {
            setState(() {
              _results.add(SearchResult(driverId, rideId, route, deviations));
              _isLoading = false;
            });
          } else {
            // Existing route has changed
            setState(() {
              _results[index].route = route;
              _results[index].deviations = deviations;
              _isLoading = false;
            });
          }
        } else {
          _results.removeWhere((result) =>
              result.driverId == driverId && result.rideId == rideId);
          setState(() {
            _isLoading = false;
          });
        }
      }));
    });

    super.initState();
  }

  @override
  void dispose() {
    for (var listener in _routeListeners) {
      listener.cancel();
    }
    _rideAdded.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).app_name)),
      body: SafeArea(child: LayoutBuilder(
        builder: (context, _) {
          if (_isLoading && _results.isEmpty) {
            return const LoadingSpinner();
          }
          if (_results.isEmpty) {
            return Center(
              child: Text(AppLocalizations.of(context).no_rides_found),
            );
          } else {
            return ListView.separated(
              itemCount: _results.length,
              itemBuilder: ((_, index) {
                return SearchListItem(_results[index], onTap: () {});
              }),
              separatorBuilder: (_, __) {
                return const Divider();
              },
            );
          }
        },
      )),
    );
  }
}

class SearchListItemTimeField extends StatelessWidget {
  final String driverId;
  final String rideId;

  const SearchListItemTimeField(
      {super.key, required this.driverId, required this.rideId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance
          .ref('/rides/$driverId/$rideId/time/data')
          .onValue,
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            final event = snapshot.data!.snapshot;
            final time =
                DepartureTime.fromJson(event.value as Map<Object?, Object?>);
            return Text(DateUtils.departureTime(time.minimum, time.maximum));
          }
          return const SizedBox.shrink();
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class SearchListItemTitle extends StatelessWidget {
  final Route route;
  final Deviations deviations;
  late final Future<String> start;
  late final Future<String> destination;
  SearchListItemTitle(
      {super.key, required this.route, required this.deviations}) {
    start = MapUtils()
        .reverseGeoCode(coordinates: deviations.startDeviation.point)
        .then((area) => area!.name);
    destination = MapUtils()
        .reverseGeoCode(coordinates: deviations.destinationDeviation.point)
        .then((area) => area!.name);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.wait([start, destination]),
      builder: (_, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Text(RideUtils.rideString(route,
              start: snapshot.data?[0], destination: snapshot.data?[1]));
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class SearchListItemStatus extends StatelessWidget {
  final String driverId;
  final String rideId;

  const SearchListItemStatus(
      {super.key, required this.driverId, required this.rideId});

  @override
  Widget build(BuildContext context) {
    return const Icon(Icons.abc);
  }
}

class SearchListItem extends StatelessWidget {
  final SearchResult data;
  final void Function() onTap;
  const SearchListItem(this.data, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title:
            SearchListItemTitle(route: data.route, deviations: data.deviations),
        subtitle:
            SearchListItemTimeField(driverId: data.driverId, rideId: data.rideId),
        trailing:
            SearchListItemStatus(driverId: data.driverId, rideId: data.rideId),
        onTap: onTap,
      ),
    );
  }
}
