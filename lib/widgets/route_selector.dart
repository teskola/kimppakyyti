import 'package:flutter/material.dart' hide Route;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/route.dart';

class RouteSelector extends StatefulWidget {
  final List<Route> routes;
  final void Function(Route? route) onSelected;

  const RouteSelector(
      {super.key, required this.routes, required this.onSelected});

  @override
  State<RouteSelector> createState() => RouteSelectorState();
}

class RouteSelectorState extends State<RouteSelector> {
  Route? selectedRoute;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: DropdownButtonHideUnderline(
          child: DropdownButton(
        // Keep other widgets able to gain autofocus.
        focusNode: FocusNode(canRequestFocus: false),
        value: selectedRoute,
        isDense: true,
        disabledHint: Text(AppLocalizations.of(context).no_saved_routes),
        hint: Text(AppLocalizations.of(context).choose_from_saved_routes),
        items: widget.routes.map((route) {
          return DropdownMenuItem(
            value: route,
            child: Text(route.toString()),
          );
        }).toList(),
        onChanged: (value) {
          widget.onSelected(value);
          setState(() {
            selectedRoute = value;
          });
        },
      )),
    );
  }
}
