import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:kimppakyyti/providers/location.dart';
import 'package:provider/provider.dart';
import '../models/location.dart';
import '../utilities/map_utils.dart';

class LocationsTextFieldListItem extends StatelessWidget {
  final Point? initialValue;
  final int stage;
  final int waypointCount;
  final bool autofocus;
  final GlobalKey<LocationsTextFieldState> textfieldKey;
  final void Function() onFocusLost;
  final void Function()? onDelete;
  final TextEditingController controller;
  final void Function(Point selected) onLocationSelected;

  const LocationsTextFieldListItem({
    super.key,
    required this.stage,
    this.waypointCount = 0,
    this.autofocus = false,
    this.onDelete,
    required this.onFocusLost,
    required this.controller,
    required this.textfieldKey,
    required this.onLocationSelected,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onFocusChange: (value) {
        // https://stackoverflow.com/questions/49153087/flutter-scrolling-to-a-widget-in-listview

        if (value) {
          Scrollable.ensureVisible(context);
        } else {
          onFocusLost();
        }
      },
      title: LocationsTextField(
        key: textfieldKey,
        initialValue: initialValue,
        stage: stage,
        controller: controller,
        onLocationSelected: onLocationSelected,
        autofocus: autofocus,
        waypointCount: waypointCount,
      ),
      trailing: stage != 2
          ? null
          : IconButton(onPressed: onDelete, icon: const Icon(Icons.delete)),
    );
  }
}

/// Textfield for searching locations.
class LocationsTextField extends StatefulWidget {
  final Point? initialValue;
  final String? label;
  final String? hint;
  final int stage;
  final int waypointCount;
  final FocusNode? focusNode;
  final TextEditingController controller;
  final void Function(Point selected) onLocationSelected;
  final bool enabled;
  final bool autofocus;

  const LocationsTextField({
    super.key,
    this.stage = 0,
    this.waypointCount = 0,
    this.enabled = true,
    this.autofocus = false,
    required this.controller,
    this.focusNode,
    required this.onLocationSelected,
    this.initialValue,
    this.label,
    this.hint,
  });

  @override
  State<LocationsTextField> createState() => LocationsTextFieldState();
}

class LocationsTextFieldState extends State<LocationsTextField> {
  Point? _selectedLocation;
  bool _editing = false;
  Point? get selectedLocation => _selectedLocation;

  void updateTextField(Point? newLocation) {
    setState(() {
      _editing = false;
      _selectedLocation = newLocation;
      widget.controller.value = TextEditingValue(
        text: newLocation != null
            ? context.read<LocationProvider>().name(context, newLocation)
            : "",
        selection: TextSelection.fromPosition(TextPosition(
            offset: newLocation != null
                ? context
                    .read<LocationProvider>()
                    .name(context, newLocation)
                    .length
                : 0)),
      );
    });
  }

  String _hint() {
    if (widget.waypointCount < MapUtils.maxWaypoints) {
      switch (widget.stage) {
        case 0:
          return AppLocalizations.of(context).from;
        case 1:
          return AppLocalizations.of(context).to;
        case 2:
          return AppLocalizations.of(context).add_waypoint;
      }
    }
    return AppLocalizations.of(context).waypoints_full;
  }

  String _label() {
    switch (widget.stage) {
      case 0:
        return AppLocalizations.of(context).start;
      case 1:
        return AppLocalizations.of(context).destination;
      default:
        return AppLocalizations.of(context).waypoint(widget.waypointCount + 1);
    }
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      updateTextField(widget.initialValue);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<LocationProvider>();
    final locations = provider.locations;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(4.0)),
          color: Colors.white),
      child: TypeAheadField<Point>(
        textFieldConfiguration: TextFieldConfiguration(
            autofocus: widget.autofocus,
            enabled: widget.enabled,
            focusNode: widget.focusNode,
            controller: widget.controller,
            onChanged: (value) {
              setState(() {
                _editing = true;
              });
            },
            onSubmitted: (value) {
              // Don't change location if user hasn't given an input.
              if (!_editing) {
                return;
              }
              try {
                Point location = locations.singleWhere((element) =>
                    provider.name(context, element).toLowerCase() ==
                    value.toLowerCase());
                updateTextField(location);
                widget.onLocationSelected(location);
              } on StateError {
                updateTextField(_selectedLocation);
              }
            },
            decoration: InputDecoration(
                prefixIcon: _selectedLocation != null && !_editing
                    ? LocationIcon(_selectedLocation!)
                    : const Icon(null),
                border: const OutlineInputBorder(),
                labelText: widget.label ?? _label(),
                floatingLabelBehavior: FloatingLabelBehavior.always,
                hintText: widget.hint ?? _hint())),
        itemBuilder: (_, itemData) => SuggestionsListItem(itemData: itemData),
        onSuggestionSelected: (suggestion) {
          updateTextField(suggestion);
          widget.onLocationSelected(suggestion);
        },
        minCharsForSuggestions: 1,
        noItemsFoundBuilder: (context) {
          return Text(AppLocalizations.of(context).location_not_found);
        },
        suggestionsCallback: (pattern) {
          return [...locations]..retainWhere((location) {
              final name = provider.name(context, location);
              return name.length >= pattern.length &&
                  name.toLowerCase().substring(0, pattern.length) ==
                      pattern.toLowerCase();
            });
        },
      ),
    );
  }
}

class LocationIcon extends StatelessWidget {
  final Point point;

  const LocationIcon(this.point, {super.key});

  @override
  Widget build(BuildContext context) {
    final locations = context.read<LocationProvider>();
    // TODO: GPS
    if (locations.home == point) return const Icon(Icons.home);
    if (locations.work == point) return const Icon(Icons.work);
    if (locations.custom?.containsValue(point) ?? false) {
      return const Icon(Icons.push_pin);
    }
    if (locations.cityCenters.contains(point)) {
      return const Icon(Icons.location_city);
    }
    return const Icon(Icons.location_on);
  }
}

/// Item in [LocationsTextField] list of suggestions.
class SuggestionsListItem extends StatelessWidget {
  final Point itemData;

  const SuggestionsListItem({super.key, required this.itemData});

  @override
  Widget build(BuildContext context) {
    return ListTile(
        dense: true,
        leading: LocationIcon(itemData),
        title: Text(context.read<LocationProvider>().name(context, itemData)));
  }
}
