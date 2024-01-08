import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:kimppakyyti/providers/location.dart';
import 'package:kimppakyyti/screens/map.dart';
import 'package:kimppakyyti/utilities/error.dart';
import 'package:kimppakyyti/utilities/map_utils.dart';
import 'package:provider/provider.dart';

import '../models/location.dart';

enum Location { home, work, custom }

class MyLocationsPage extends StatelessWidget {
  const MyLocationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(children: const [
      LocationTile(Location.home),
      LocationTile(Location.work),
      CustomList()
    ]);
  }
}

class CustomList extends StatelessWidget {
  const CustomList({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocationProvider>();
    final count = provider.customLength;
    return ListView.builder(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: count == 5 ? 5 : count + 1,
        itemBuilder: (_, index) {
          return LocationTile(Location.custom,
              name: provider.getName(index),
              key: GlobalKey<_LocationTileState>());
        });
  }
}

class LocationTitle extends StatelessWidget {
  final Location location;
  final String? name;
  final TextEditingController? controller;

  const LocationTitle(this.location, {this.name, this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    if (name != null) {
      return Text(name!);
    }
    switch (location) {
      case Location.home:
        return Text(AppLocalizations.of(context).home);
      case Location.work:
        return Text(AppLocalizations.of(context).work);
      case Location.custom:
        return TextField(
          inputFormatters: [LengthLimitingTextInputFormatter(18)],
          decoration: InputDecoration.collapsed(
              border: InputBorder.none,
              hintText: AppLocalizations.of(context).add_location),
          controller: controller,
        );
    }
  }
}

class LocationSubTitle extends StatelessWidget {
  final Location location;
  final String? name;

  const LocationSubTitle(this.location, {super.key, this.name});

  @override
  Widget build(BuildContext context) {
    switch (location) {
      case Location.home:
        final home = context.watch<LocationProvider>().myLocations.home;
        return home != null ? Text(home.toString()) : const SizedBox.shrink();
      case Location.work:
        final work = context.watch<LocationProvider>().myLocations.work;
        return work != null ? Text(work.toString()) : const SizedBox.shrink();
      case Location.custom:
        final custom = context.watch<LocationProvider>().custom;
        return custom != null && custom[name] != null
            ? Text(custom[name].toString())
            : const SizedBox.shrink();
    }
  }
}

class LocationTile extends StatefulWidget {
  final Location location;
  final String? name;

  const LocationTile(this.location, {super.key, this.name});

  @override
  State<LocationTile> createState() => _LocationTileState();
}

class _LocationTileState extends State<LocationTile> {
  TextEditingController? controller;

  IconData icon() {
    switch (widget.location) {
      case Location.home:
        return Icons.home;
      case Location.work:
        return Icons.work;
      case Location.custom:
        return Icons.push_pin;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.location == Location.custom) {
      controller = TextEditingController()
        ..addListener(() {
          setState(() {});
        });
      if (widget.name != null) {
        controller?.text = widget.name!;
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    controller?.dispose();
  }

  Future<void> _getLocationFromMap(Point? point) async {
    final Point? result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => MapPage(
                mode: MapMode.singlePoint,
                marker: _marker(),
                name: controller?.text,
                initialSelection: point)));
    if (result == null) return;
    if (!context.mounted) return;

    switch (widget.location) {
      case Location.home:
        context.read<LocationProvider>().home = result;
        break;
      case Location.work:
        context.read<LocationProvider>().work = result;
        break;
      case Location.custom:
        context.read<LocationProvider>().update(controller!.text, result);
    }
  }

  MarkerIcon _marker() {
    switch (widget.location) {
      case Location.home:
        return MarkerIcon.home;
      case Location.work:
        return MarkerIcon.work;
      case Location.custom:
        return MarkerIcon.custom;
    }
  }

  Point? _getPoint(LocationProvider provider) {
    switch (widget.location) {
      case Location.home:
        return provider.home;
      case Location.work:
        return provider.work;
      case Location.custom:
        return provider.custom != null ? provider.custom![widget.name] : null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LocationProvider>();
    final point = _getPoint(provider);
    return Column(
      children: [
        Card(
          child: ListTile(
            leading: Icon(icon(), size: 32.0),
            title: LocationTitle(widget.location,
                name: widget.name, controller: controller),
            subtitle: LocationSubTitle(widget.location, name: widget.name),
            trailing: (widget.location == Location.custom &&
                    controller!.text.isEmpty)
                ? null
                : ActionButtons(
                    widget.location,
                    name: widget.name,
                    onEdit: () {
                      if (provider.custom != null &&
                          controller != null &&
                          provider.custom!.containsKey(controller!.text)) {
                        // TODO: parempi error objecti
                        ErrorSnackbar.show(
                            context,
                            Error(
                                message: AppLocalizations.of(context)
                                    .location_already_added(controller!.text)));
                        return;
                      }
                      _getLocationFromMap(point);
                    },
                    edit: point != null,
                  ),
          ),
        ),
      ],
    );
  }
}

class ActionButtons extends StatelessWidget {
  final Location location;
  final String? name;
  final void Function() onEdit;
  final bool edit;
  const ActionButtons(
    this.location, {
    this.name,
    super.key,
    required this.onEdit,
    required this.edit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
            onPressed: onEdit,
            icon:
                edit ? const Icon(Icons.edit_location) : const Icon(Icons.add)),
        if (edit)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton.filledTonal(
              icon: const Icon(Icons.delete),
              onPressed: () {
                switch (location) {
                  case Location.home:
                    context.read<LocationProvider>().home = null;
                    break;
                  case Location.work:
                    context.read<LocationProvider>().work = null;
                    break;
                  case Location.custom:
                    context.read<LocationProvider>().delete(name!);
                }
              },
            ),
          )
      ],
    );
  }
}
