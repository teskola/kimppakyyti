import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart' hide Route, DateUtils;
import 'package:kimppakyyti/models/departure_time.dart';
import 'package:kimppakyyti/models/id.dart';
import 'package:kimppakyyti/providers/ride_id.dart';
import 'package:kimppakyyti/providers/status.dart';
import 'package:kimppakyyti/providers/time.dart';
import 'package:kimppakyyti/utilities/database.dart';
import 'package:kimppakyyti/utilities/error.dart';
import 'package:provider/provider.dart';
import '../../models/route.dart';
import '../../utilities/date_utils.dart';
import '../map.dart';
import '../../widgets/loading_spinner.dart';

class ConfirmPage extends StatefulWidget {
  final CustomRoute route;
  final DateTime min;
  final DateTime max;
  final int capacity;
  final String? info;

  const ConfirmPage({
    super.key,
    required this.route,
    required this.min,
    required this.max,
    required this.capacity,
    this.info,
  });

  @override
  State<ConfirmPage> createState() => _ConfirmPageState();
}

class _ConfirmPageState extends State<ConfirmPage> {
  bool isLoading = false;

  void _navigateToMap(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return MapPage(
        route: widget.route,
        mode: MapMode.viewOnly,
      );
    }));
  }

  String _routeToText() {
    String result = "";
    for (var location in widget.route.locations) {
      result += "$location\n";
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? const LoadingSpinner()
        : Scaffold(
            appBar: AppBar(
              title: Text(AppLocalizations.of(context).app_name),
            ),
            body: SafeArea(
                child: Column(
              children: [
                Expanded(
                    child: SingleChildScrollView(
                        child: SizedBox(
                            width: double.infinity,
                            child: DataTable(
                                headingRowHeight: 0,
                                dataRowMaxHeight: double.infinity,
                                dividerThickness: 0,
                                columns: const [
                                  DataColumn(label: Text("")),
                                  DataColumn(label: Text("")),
                                ],
                                rows: [
                                  DataRow(
                                    cells: [
                                      DataCell(Text(
                                          AppLocalizations.of(context).route)),
                                      DataCell(Column(
                                        children: [
                                          Text(_routeToText()),
                                          ElevatedButton.icon(
                                            onPressed: () =>
                                                _navigateToMap(context),
                                            icon: const Icon(Icons.route),
                                            label: Text(
                                                AppLocalizations.of(context)
                                                    .show_on_map),
                                          )
                                        ],
                                      )),
                                    ],
                                  ),
                                  DataRow(cells: [
                                    DataCell(Text(AppLocalizations.of(context)
                                        .departure_time)),
                                    DataCell(Text(DateUtils.departureTime(
                                        widget.min, widget.max))),
                                  ]),
                                  DataRow(cells: [
                                    DataCell(Text(
                                        AppLocalizations.of(context).seats)),
                                    DataCell(Text(widget.capacity.toString()))
                                  ]),
                                  DataRow(cells: [
                                    DataCell(Text(AppLocalizations.of(context)
                                        .additional_info)),
                                    DataCell(Text(widget.info ?? ""))
                                  ])
                                ])))),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FloatingActionButton.extended(
                    onPressed: () async {
                      setState(() {
                        isLoading = true;
                      });
                      final time = DepartureTime(widget.min, widget.max);
                      final rideKey = await DatabaseUtils.addRideToDatabase(
                          widget.route, time, widget.capacity, widget.info,
                          (err) {
                        debugPrint(err.toString());
                        setState(() {
                          isLoading = false;
                          // parempi error handling
                          ErrorSnackbar.show(context, Error());
                        });
                      });
                      
                      if (!mounted) return;
                      
                      if (rideKey != null) {
                        final id = Id(
                            driver: FirebaseAuth.instance.currentUser!.uid,
                            ride: rideKey);
                        context.read<RideIdProvider>().add(id);
                        context.read<TimeProvider>().update(id, time);
                                                context.read<StatusProvider>().update(id);
                        Navigator.pop(context);
}
                    },
                    label: Text(AppLocalizations.of(context).add_ride),
                    icon: const Icon(Icons.add),
                  ),
                )
              ],
            )));
  }
}
