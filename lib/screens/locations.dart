import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:kimppakyyti/providers/location.dart';
import 'package:kimppakyyti/screens/map.dart';
import 'package:kimppakyyti/utilities/error.dart';
import 'package:provider/provider.dart';

import '../models/location.dart';

enum LocationIcon { home, work, custom }

class MyLocationsPage extends StatelessWidget {
  const MyLocationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(children: const [
      LocationTile(LocationIcon.home),
      LocationTile(LocationIcon.work),
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
          return LocationTile(LocationIcon.custom,
              name: provider.getName(index),
              key: GlobalKey<_LocationTileState>());
        });
  }
}

class LocationTitle extends StatelessWidget {
  final LocationIcon location;
  final String? name;
  final TextEditingController? controller;

  const LocationTitle(this.location, {this.name, this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    if (name != null) {
      return Text(name!);
    }
    switch (location) {
      case LocationIcon.home:
        return Text(AppLocalizations.of(context).home);
      case LocationIcon.work:
        return Text(AppLocalizations.of(context).work);
      case LocationIcon.custom:
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
  final LocationIcon location;
  final String? name;

  const LocationSubTitle(this.location, {super.key, this.name});

  @override
  Widget build(BuildContext context) {
    switch (location) {
      case LocationIcon.home:
        final home = context.watch<LocationProvider>().myLocations.home;
        return home != null ? Text(home.toString()) : const SizedBox.shrink();
      case LocationIcon.work:
        final work = context.watch<LocationProvider>().myLocations.work;
        return work != null ? Text(work.toString()) : const SizedBox.shrink();
      case LocationIcon.custom:
        final custom = context.watch<LocationProvider>().custom;
        return custom != null && custom[name] != null
            ? Text(custom[name].toString())
            : const SizedBox.shrink();
    }
  }
}

class LocationTile extends StatefulWidget {
  final LocationIcon location;
  final String? name;

  const LocationTile(this.location, {super.key, this.name});

  @override
  State<LocationTile> createState() => _LocationTileState();
}

class _LocationTileState extends State<LocationTile> {
  TextEditingController? controller;

  IconData icon() {
    switch (widget.location) {
      case LocationIcon.home:
        return Icons.home;
      case LocationIcon.work:
        return Icons.work;
      case LocationIcon.custom:
        return Icons.push_pin;
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.location == LocationIcon.custom) {
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

  Markers _marker(LocationIcon icon) {
    switch (icon) {
      case LocationIcon.home:
        return Markers.home;
      case LocationIcon.work:
        return Markers.work;
      case LocationIcon.custom:
        return Markers.custom;
    }
  }

  Future<void> _getLocationFromMap(Point? point) async {
    final Point? result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => MapPage(
                mode: MapMode.singlePoint,
                locationIcon: _marker(widget.location),
                name: controller?.text,
                initialSelection: point)));
    if (result == null) return;
    if (!context.mounted) return;

    switch (widget.location) {
      case LocationIcon.home:
        context.read<LocationProvider>().home = result;
        break;
      case LocationIcon.work:
        context.read<LocationProvider>().work = result;
        break;
      case LocationIcon.custom:
        context.read<LocationProvider>().update(controller!.text, result);
    }
  }

  Point? _getPoint(LocationProvider provider) {
    switch (widget.location) {
      case LocationIcon.home:
        return provider.home;
      case LocationIcon.work:
        return provider.work;
      case LocationIcon.custom:
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
            trailing: (widget.location == LocationIcon.custom &&
                    controller!.text.isEmpty)
                ? null
                : ActionButtons(
                    widget.location,
                    name: widget.name,
                    onEdit: () => _getLocationFromMap(point),                    
                    onAdd: () {
                      if (provider.custom != null &&
                          controller != null &&
                          provider.custom!.containsKey(controller!.text)) {
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
  final LocationIcon location;
  final String? name;
  final void Function() onEdit;
  final void Function() onAdd;
  final bool edit;
  const ActionButtons(
    this.location, {
    this.name,
    super.key,
    required this.onEdit,
    required this.edit, 
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.filledTonal(
            onPressed: edit ? onEdit : onAdd,
            icon:
                edit ? const Icon(Icons.edit_location) : const Icon(Icons.add)),
        if (edit)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: IconButton.filledTonal(
              icon: const Icon(Icons.delete),
              onPressed: () {
                switch (location) {
                  case LocationIcon.home:
                    context.read<LocationProvider>().home = null;
                    break;
                  case LocationIcon.work:
                    context.read<LocationProvider>().work = null;
                    break;
                  case LocationIcon.custom:
                    context.read<LocationProvider>().delete(name!);
                }
              },
            ),
          )
      ],
    );
  }
}
