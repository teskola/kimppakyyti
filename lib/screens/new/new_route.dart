import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:kimppakyyti/utilities/error.dart';
import 'package:kimppakyyti/utilities/local_database.dart';
import '../../models/location.dart';
import '../../models/route.dart';
import '../../providers/directions.dart';
import '../map.dart';
import 'select_time.dart';
import '../../utilities/map_utils.dart';
import '../../widgets/locations_textfield.dart';
import '../../widgets/route_selector.dart';

class TextFieldItem {
  final GlobalKey<LocationsTextFieldState> key = GlobalKey();
  final TextEditingController controller = TextEditingController();
  Point? value;

  TextFieldItem({this.value});
}

class NewRoutePage extends StatefulWidget {
  final void Function(String id) onRouteAdded;
  const NewRoutePage({super.key, required this.onRouteAdded});
  @override
  State<NewRoutePage> createState() => _NewRoutePageState();
}

class _NewRoutePageState extends State<NewRoutePage> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<RouteSelectorState> _routeSelector = GlobalKey();
  final GlobalKey _listWidget = GlobalKey();
    final TextFieldItem _startTextField = TextFieldItem();
  final TextFieldItem _destinationTextField = TextFieldItem();
  List<TextFieldItem> _waypointTextFields = [];
  double? _textfieldHeight;
  bool _isLoading = false;
  CustomRoute? _route;

  Point? get start {
    return _startTextField.value;
  }

  set start(Point? point) {
    _startTextField.value = point;
    if (_startTextField.key.currentState != null) {
      _startTextField.key.currentState!.updateTextField(point);
    }
  }

  Point? get destination {
    return _destinationTextField.value;
  }

  set destination(Point? point) {
    if (_destinationTextField.key.currentState != null) {
      _destinationTextField.key.currentState!.updateTextField(point);
    }
    _destinationTextField.value = point;
  }

  List<Point> get waypoints {
    return _waypointTextFields
        .where((element) => element.value != null)
        .map((e) => e.value!)
        .toList();
  }

  void _onRouteSelected(CustomRoute selectedRoute) {
    for (var waypoint in _waypointTextFields) {
      waypoint.controller.dispose();
    }
    _waypointTextFields.clear();
    start = selectedRoute.start;
    destination = selectedRoute.destination;

    for (var point in selectedRoute.waypoints) {
      _waypointTextFields.add(TextFieldItem(value: point));
    }
    setState(() {
      _route = selectedRoute;
    });
  }

  bool _selectionEqualsRoute() {
        _route = null;
    _routeSelector.currentState!.selectedRoute = null;
    return false;
  }

  double _getTextFieldHeight() {
    final RenderBox renderBox =
        _listWidget.currentContext?.findRenderObject() as RenderBox;
    return renderBox.size.height;
  }

  Future<void> _navigateToMapAndGetRoute(BuildContext context) async {
    if (start != null &&
        destination != null &&
        start!.area == destination!.area) {
      ErrorSnackbar.show(context,
          Error(message: AppLocalizations.of(context).destination_error));
      return;
    }
    final CustomRoute? result =
        await Navigator.push(context, MaterialPageRoute(builder: (context) {
      if (_route != null) {
        return MapPage(
          route: _route,
        );
      } else {
        return MapPage(
          start: start,
          destination: destination,
          waypoints: waypoints,
        );
      }
    }));

    if (!mounted) return;

    if (result == null) return;

    _onRouteSelected(result);

    /*  const int index = 0;

    if (index < 0) {
      _routeSelector.currentState!.selectedRoute = null;
      _onRouteSelected(result);
    } else {
      _routeSelector.currentState!.selectedRoute = _savedRoutes[index];
      _onRouteSelected(_savedRoutes[index]);
    } */
  }

  Future<CustomRoute> _getRoute() async {
    final local =
        await LocalDatabase().searchRoute(start!, destination!, waypoints);
    if (local != null) return local;
    final result = await DirectionsProvider.fetchRoute(
      start: start!, destination: destination!, waypoints: waypoints);
final id = await LocalDatabase().addRoute(result, FirebaseAuth.instance.currentUser!.uid);
    return CustomRoute(result.legs, id);
  }

  Future<void> _navigateToDateSelection(BuildContext context) async {
    if (start != null &&
        destination != null &&
        start!.area == destination!.area) {
      ErrorSnackbar.show(context,
          Error(message: AppLocalizations.of(context).destination_error));
      return;
    }
    if (_route == null) {
      setState(() {
        _isLoading = true;
      });
      try {
        final fetchedRoute = await _getRoute();
        setState(() {
          _route = fetchedRoute;
        });
      } on RouteException catch (error) {
        if (!mounted) return;
        ErrorSnackbar.show(context, error);
        return;
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }

    if (!mounted) return;

    final String? result =
        await Navigator.push(context, MaterialPageRoute(builder: (context) {
      return SelectTimePage(route: _route!);
    }));

    if (result == null) {
      return;
    } else {
      widget.onRouteAdded(result);
    }
  }

  @override
  initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _textfieldHeight = _getTextFieldHeight();
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _startTextField.controller.dispose();
    _destinationTextField.controller.dispose();
    for (var waypoint in _waypointTextFields) {
      waypoint.controller.dispose();
    }
    super.dispose();
  }

  List<Widget> _children() {
    return [
      RouteSelector(
        key: _routeSelector,
        routes: const [],
        onSelected: (_) => {},
      ),
      LocationsTextFieldListItem(
        stage: 0,
        initialValue: start,
        onFocusLost: () => _scrollController.jumpTo(0),
        controller: _startTextField.controller,
        textfieldKey: _startTextField.key,
        onLocationSelected: (selected) {
          setState(() {
            _startTextField.value = selected;
          });
          _selectionEqualsRoute();
        },
      ),
      for (var i = 0; i < _waypointTextFields.length; i++)
        LocationsTextFieldListItem(
          autofocus: (i == _waypointTextFields.length - 1) &&
              _waypointTextFields[i].value == null,
          stage: 2,
          waypointCount: i,
          initialValue: _waypointTextFields[i].value,
          onFocusLost: () => _scrollController.jumpTo(0),
          controller: _waypointTextFields[i].controller,
          textfieldKey: _waypointTextFields[i].key,
          onLocationSelected: ((selected) {
            _waypointTextFields[i].value = selected;
            _selectionEqualsRoute();
            setState(() {});
          }),
          onDelete: () {
            _waypointTextFields[i].controller.dispose();
            _waypointTextFields.removeAt(i);
            _scrollController.jumpTo(0);
            _selectionEqualsRoute();
            setState(() {});
          },
        ),
      if (start != null &&
          destination != null &&
          _waypointTextFields.every((element) => element.value != null) &&
          _waypointTextFields.length < MapUtils.maxWaypoints)
        ListTile(
          dense: true,
          leading: const Icon(Icons.add_circle),
          title: Text(AppLocalizations.of(context).add_waypoint),
          onTap: () {
            setState(() {
              _waypointTextFields.add(TextFieldItem());
            });
          },
        ),
      LocationsTextFieldListItem(
          key: _listWidget,
          stage: 1,
          initialValue: destination,
          onFocusLost: () => _scrollController.jumpTo(0),
          controller: _destinationTextField.controller,
          textfieldKey: _destinationTextField.key,
          onLocationSelected: (selected) {
            setState(() {
              _destinationTextField.value = selected;
            });
            _selectionEqualsRoute();
          }),
      if (start != null && destination != null)
        ListTile(
          dense: true,
          leading: const Icon(Icons.cached),
          title: Text(AppLocalizations.of(context).reverse),
          onTap: () {
            setState(() {
              final temp = start;
              start = destination;
              destination = temp;
              _waypointTextFields = _waypointTextFields.reversed.toList();
              if (_route != null) {
                _route = _route!.reverse();
}
            });
          },
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(child: LayoutBuilder(builder: (context, constraints) {
          return SizedBox(
            height: constraints.maxHeight,
            width: _isLoading ? constraints.maxWidth : null,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : SingleChildScrollView(
                    controller: _scrollController,
                    // Padding to keep last widget on top of screen, when scrolled down.
                    padding: EdgeInsets.only(
                        top: 8.0,
                        bottom: (_textfieldHeight != null &&
                                constraints.maxHeight > _textfieldHeight!)
                            ? constraints.maxHeight - _textfieldHeight!
                            : 0),
                    child: Column(
                      children: _children(),
                    ),
                  ),
          );
        })),
        Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                    onPressed: _isLoading
                        ? null
                        : () => _navigateToMapAndGetRoute(context),
                    icon: const Icon(Icons.location_on),
                    label: Text(AppLocalizations.of(context).choose_from_map)),
                Visibility(
                    visible: start != null && destination != null,
                    child: FloatingActionButton(
                      onPressed: _isLoading
                          ? null
                          : () => _navigateToDateSelection(context),
                      child: const Icon(Icons.arrow_forward),
                    ))
              ],
            )),
      ],
    );
  }
}
