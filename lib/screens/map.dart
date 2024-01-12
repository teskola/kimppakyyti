import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart' hide Route;
import 'package:flutter/scheduler.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:kimppakyyti/providers/geocoder.dart';
import 'package:kimppakyyti/utilities/error.dart';
import 'package:kimppakyyti/utilities/local_database.dart';
import '../models/location.dart';
import '../models/route.dart';
import '../utilities/map_controller.dart';
import '../utilities/map_utils.dart';
import '../providers/directions.dart';
import '../widgets/locations_textfield.dart';

enum MapMode { selectRoute, endPointsOnly, singlePoint, viewOnly }

enum Markers {
  start,
  destination,
  waypoint,
  gpsLocation,
  car,
  home,
  work,
  custom
}

class MapPage extends StatefulWidget {
  final Point? start;
  final Point? destination;
  final Point? initialSelection;
  final String? name;
  final List<Point>? waypoints;
  final Route? route;
  final Markers? locationIcon;
  final MapMode mode;
  final int maxWaypoints;

  const MapPage(
      {super.key,
      this.start,
      this.destination,
      this.waypoints,
      this.route,
      this.maxWaypoints = MapUtils.maxWaypoints,
      this.mode = MapMode.selectRoute,
      this.locationIcon,
      this.initialSelection,
      this.name});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  static const List<MarkerId> _markerIds = [
    MarkerId('start'),
    MarkerId('destination'),
  ];

  final GlobalKey<LocationsTextFieldState> _textfield = GlobalKey();
  ImageConfiguration? _config;
  late final FocusNode _focusNode;
  late final GoogleMapController _controller;
  final List<Route> _routes = [];
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  Point? _start;
  Point? _destination;
  Point? _selected;
  final List<Point> _wayPoints = [];
  final TextEditingController _textEditingController = TextEditingController();
  bool _isLoading = false;  

  /// ### Current selection stage
  ///
  /// 0 = Select start location.<br>
  /// 1 = Select destination.<br>
  /// 2 = Select waypoint
  int get stage {
    if (_start == null) {
      return 0;
    }
    if (_destination == null) {
      return 1;
    } else {
      return 2;
    }
  }

  String _asset(Markers marker) => 'assets/icons/${marker.name}.png';

  Future<BitmapDescriptor> getIcon(Markers marker) async =>
      BitmapDescriptor.fromAssetImage(
          _config ?? (_config = createLocalImageConfiguration(context)), _asset(marker));

  Offset anchor(Markers icon) {
    switch (icon) {
      case Markers.custom:
        return const Offset(0.5, 0.875);
      case Markers.destination:
        return const Offset(0.24, 0.83);
      default:
        return const Offset(0.5, 0.5);
    }
  }

  void _addPoint(Point newPoint) {
    switch (stage) {
      case 0:
        _start = newPoint;
        break;
      case 1:
        _destination = newPoint;
        break;
      case 2:
        _wayPoints.add(newPoint);
        break;
      default:
        throw UnimplementedError();
    }
  }

  Future<void> _setMarkerIcons() async {
    if (widget.initialSelection != null && widget.locationIcon != null) {
      _markers.add(Marker(
          markerId: MarkerId(widget.locationIcon!.name),
          anchor: anchor(widget.locationIcon!),
          icon: await getIcon(widget.locationIcon!),
          position: LatLng(widget.initialSelection!.latitude,
              widget.initialSelection!.longitude),
          draggable: true,
          onDragEnd: (coordinates) => _onLocationSelectedFromMap(coordinates)));
      return;
    }

    if (_start != null) {
      _markers.add(Marker(
          markerId: _markerIds[0],
          anchor: anchor(Markers.start),
          icon: await getIcon(Markers.start),
          position: LatLng(_start!.latitude, _start!.longitude)));
    }
    if (_destination != null) {
      _markers.add(Marker(
          markerId: _markerIds[1],
          anchor: anchor(Markers.destination),
          icon: await getIcon(Markers.destination),
          position: LatLng(_destination!.latitude, _destination!.longitude)));
    }

    for (var i = 0; i < _wayPoints.length; i++) {
      _markers.add(Marker(
          markerId: MarkerId('waypoint$i'),
          anchor: anchor(Markers.waypoint),
          icon: await getIcon(Markers.waypoint),
          position: LatLng(_wayPoints[i].latitude, _wayPoints[i].longitude)));
    }
  }

  Future<void> _changeMarkerIcon(Point selected) async {
    _removeMarker();
    switch (stage) {
      case 0:
        _markers.add(Marker(
            markerId: _markerIds[stage],
            anchor: anchor(Markers.start),
            icon: await getIcon(Markers.start),
            position: LatLng(selected.latitude, selected.longitude)));
        break;
      case 1:
        _markers.add(Marker(
            markerId: _markerIds[stage],
            anchor: anchor(Markers.destination),
            icon: await getIcon(Markers.destination),
            position: LatLng(selected.latitude, selected.longitude)));
        break;
      case 2:
        _markers.add(Marker(
            markerId: MarkerId('waypoint${_wayPoints.length}'),
            anchor: anchor(Markers.waypoint),
            icon: await getIcon(Markers.waypoint),
            position: LatLng(selected.latitude, selected.longitude)));
        break;
      default:
        throw UnimplementedError();
    }
  }

  void _removeMarker() {
    if (widget.mode == MapMode.singlePoint) {
      _markers.clear();
      return;
    }
    _markers.removeWhere((marker) => stage < 2
        ? marker.markerId == _markerIds[stage]
        : marker.markerId == MarkerId('waypoint${_wayPoints.length}'));
  }

  Future<void> _changeMarkerPosition(LatLng newPosition) async {
    final currentStage = stage;
    final currentWaypointCount = _wayPoints.length;
    _removeMarker();
    if (widget.mode == MapMode.singlePoint) {
      _markers.add(Marker(
          markerId: MarkerId(widget.locationIcon!.name),
          anchor: anchor(widget.locationIcon!),
          icon: await getIcon(widget.locationIcon!),
          position: newPosition,
          draggable: true,
          onDragEnd: (coordinates) => _onLocationSelectedFromMap(coordinates)));
    } else {
      _markers.add(Marker(
        markerId: stage < 2
            ? _markerIds[stage]
            : MarkerId('waypoint${_wayPoints.length}'),
        position: newPosition,
        draggable:
            currentStage == stage && currentWaypointCount == _wayPoints.length,
        onDragEnd: (coordinates) => _onLocationSelectedFromMap(coordinates),
      ));
    }
  }

  void _addRoute(Route route) {
    setState(() {
      _routes.add(route);
      _polylines.clear();
      _polylines.addAll(_routeToPolyline(route));
    });
  }

  Future<void> _addRouteAndDrawLine(
      Point? start, Point? destination, List<Point>? waypoints) async {
    if (start == null || destination == null) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    final local =
        await LocalDatabase().searchRoute(start, destination, waypoints ?? []);
    if (local != null) {
      _addRoute(local);
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final result = await DirectionsProvider.fetchRoute(
          start: start, destination: destination, waypoints: waypoints ?? []);
      final id = await LocalDatabase()
          .addRoute(result, FirebaseAuth.instance.currentUser!.uid);
      _addRoute(CustomRoute(result.legs, id));
    } on RouteException catch (error) {
      if (_wayPoints.isEmpty) {
        _onPointRemoved();
      } else {
        _wayPoints.removeLast();
        _removeMarker();
      }
      if (!mounted) return;
      ErrorSnackbar.show(context, error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Set<Polyline> _routeToPolyline(Route route) {
    final Set<Polyline> result = {};
    for (int i = 0; i < route.legs.length; i++) {
      result.add(Polyline(
          polylineId: PolylineId('route: ${_routes.length} leg: $i'),
          points: MapUtils.decodePolyline(route.legs[i].polyline),
          width: 4,
          color: Colors.red));
    }
    return result;
  }

  Future<void> _onMapCreated(GoogleMapController controller) async {
    _controller = controller;
    await _setMarkerIcons();
    if (widget.route != null) {
      setState(() {
        _polylines.addAll(_routeToPolyline(widget.route!));
      });
    } else if (widget.mode == MapMode.selectRoute ||
        widget.mode == MapMode.viewOnly) {
      _addRouteAndDrawLine(widget.start, widget.destination, widget.waypoints);
    }
  }

  void _onConfirm() async {
    if (widget.mode == MapMode.singlePoint) {
      Navigator.pop(context, _selected);
      return;
    }

    switch (stage) {
      case 0:
        _controller.updateCamera(_start, _selected);
        break;
      case 1:
        if (widget.mode == MapMode.selectRoute ||
            widget.mode == MapMode.viewOnly) {
          if (_selected?.area != _start?.area) {
            _addRouteAndDrawLine(_start, _selected, _wayPoints);
          } else {
            ErrorSnackbar.show(context,
                Error(message: AppLocalizations.of(context).destination_error));
            return;
          }
        }
        _controller.updateCamera(_start, _selected);
        break;
      case 2:
        if (widget.mode == MapMode.selectRoute ||
            widget.mode == MapMode.viewOnly) {
          Navigator.pop(context, _routes.last);
        } else {
          Navigator.pop(context, [_start, _destination]);
        }
        return;
      default:
        throw UnimplementedError();
    }
    await _changeMarkerIcon(_selected!);
    _textfield.currentState!.updateTextField(null);
    setState(() {
      _addPoint(_selected!);
      _selected = null;
    });
  }

  void _onWaypointConfirmed() async {
    _addRouteAndDrawLine(_start, _destination, [..._wayPoints, _selected!]);
    await _changeMarkerIcon(_selected!);
    setState(() {
      _addPoint(_selected!);
      _selected = null;
    });
    _controller.updateCamera(_start, _destination);
    _textfield.currentState!.updateTextField(null);
  }

  void _onPointRemoved() {
    if (_selected != null) {
      setState(() {
        _selected = null;
        _removeMarker();
      });
      _textfield.currentState!.updateTextField(null);
      _controller.updateCamera(_start, _destination);
      return;
    }
    if (stage == 1) {
      setState(() {
        _start = null;
        _removeMarker();
      });
    } else if (_wayPoints.isEmpty) {
      setState(() {
        _destination = null;
        _removeMarker();
      });
      if (_routes.isNotEmpty) {
        setState(() {
          _routes.removeLast();
          _polylines.clear();
        });
      }
    } else {
      setState(() {
        _wayPoints.removeLast();
        _removeMarker();
        if (_routes.isNotEmpty) {
          _routes.removeLast();
        }
        _polylines.clear();
        if (_routes.isNotEmpty) {
          _polylines.addAll(_routeToPolyline(_routes.last));
        } else {
          _addRouteAndDrawLine(_start, _destination, _wayPoints);
        }
      });
    }
    _controller.updateCamera(_start, _destination);
  }

  Future<void> _onLocationSelectedFromMap(LatLng coordinates) async {
    _focusNode.unfocus();
    _controller.centerToLocation(coordinates);

    setState(() {
      _isLoading = true;
      _changeMarkerPosition(coordinates);
    });

    String? location = await Geocoder().reverseGeoCode(coordinates);
    setState(() {
      _isLoading = false;
    });
    if (location != null) {
      setState(() {
        _selected = Point(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude,
            area: location);
      });
      _textfield.currentState!.updateTextField(_selected);
    } else {
      setState(() {
        _selected = null;
        _removeMarker();
      });
      _textfield.currentState!.updateTextField(null);
    }
  }

  void _onLocationSelectedFromTextField(Point selected) {
    final coordinates = LatLng(selected.latitude, selected.longitude);
    if (widget.mode != MapMode.singlePoint) {
      setState(() {
        _changeMarkerPosition(coordinates);
        _selected = selected;
      });
    }
    _controller.centerToLocation(coordinates);
  }

  bool _textfieldEnabled() {
    switch (widget.mode) {
      case MapMode.selectRoute:
        return _wayPoints.length < widget.maxWaypoints;
      case MapMode.endPointsOnly:
        return _destination == null;
      default:
        return true;
    }
  }

  bool _showConfirmButton() {
    switch (widget.mode) {
      case MapMode.selectRoute:
        return _polylines.isNotEmpty;
      case MapMode.endPointsOnly:
        return _destination != null;
      case MapMode.singlePoint:
        return _selected != null;
      default:
        return false;
    }
  }

  String? _label() {
    switch (widget.locationIcon) {
      case Markers.home:
        return AppLocalizations.of(context).home;
      case Markers.work:
        return AppLocalizations.of(context).work;
      default:
        return widget.name;
    }
  }

  @override
  initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() {
        setState(() {});
      });
    if (widget.initialSelection != null) {
      _selected = widget.initialSelection;
      return;
    }
    if (widget.route != null) {
      _start = widget.route!.start;
      _destination = widget.route!.destination;
      _wayPoints.addAll(widget.route!.waypoints);
      _routes.add(widget.route!);
    } else if (widget.start != null) {
      _start = widget.start;
      if (widget.destination != null) {
        _destination = widget.destination;
        if (widget.waypoints != null) {
          _wayPoints.addAll(widget.waypoints!);
        }
      }
    }    
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(AppLocalizations.of(context).app_name),
          Visibility(
              visible: _isLoading, child: const CircularProgressIndicator())
        ],
      )),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
          child: Stack(
        alignment: Alignment.center,
        children: [
          GoogleMap(
            minMaxZoomPreference:
                const MinMaxZoomPreference(4.85, double.infinity),
            initialCameraPosition: const CameraPosition(
              target: MapController.centerOfFinland,
              zoom: 4.85,
            ),
            onMapCreated: (mapCon) async {
              await _onMapCreated(mapCon);
              final initial = widget.initialSelection;
              if (initial != null) {
                _controller.centerToLocation(
                    LatLng(initial.latitude, initial.longitude));
                _textfield.currentState?.updateTextField(initial);
              } else {
                _controller.updateCamera(_start, _destination);
              }
              setState(() {});
            },
            cameraTargetBounds: CameraTargetBounds(LatLngBounds(
                southwest: MapController.southwest,
                northeast: MapController.northeast)),
            mapToolbarEnabled: false,
            rotateGesturesEnabled: false,
            compassEnabled: false,
            myLocationButtonEnabled: false,
            buildingsEnabled: false,
            markers: _markers,
            polylines: _polylines,
            onTap: widget.mode == MapMode.viewOnly ||
                    (widget.mode == MapMode.endPointsOnly &&
                        _destination != null)
                ? null
                : (coordinates) => _onLocationSelectedFromMap(coordinates),
          ),
          Positioned(
              bottom: 1.0,
              right: 1.0,
              child: Text('Powered by Google, ©${DateTime.now().year} Google')),
          Positioned(
              bottom: 20.0,
              child: Visibility(
                  visible: _showConfirmButton(),
                  child: FloatingActionButton.extended(
                    onPressed: _onConfirm,
                    label: Text(widget.mode == MapMode.endPointsOnly ||
                            widget.mode == MapMode.singlePoint
                        ? AppLocalizations.of(context).confirm
                        : AppLocalizations.of(context).confirm_route),
                    icon: const Icon(Icons.check),
                  ))),
          Positioned(
              top: 10.0,
              right: 10.0,
              left: 10.0,
              child: Row(
                children: widget.mode == MapMode.viewOnly
                    ? []
                    : [
                        Visibility(
                          visible: widget.mode != MapMode.singlePoint &&
                              !_focusNode.hasFocus &&
                              stage > 0,
                          maintainState: true,
                          maintainSize: true,
                          maintainAnimation: true,
                          child: IconButton.filledTonal(
                              onPressed: _onPointRemoved,
                              icon: Icon(
                                _wayPoints.isEmpty
                                    ? Icons.arrow_back
                                    : Icons.remove,
                              )),
                        ),
                        Expanded(
                            child: LocationsTextField(
                          key: _textfield,
                          label: _label(),
                          hint: widget.mode == MapMode.singlePoint
                              ? AppLocalizations.of(context).add_location
                              : null,
                          controller: _textEditingController,
                          enabled: _textfieldEnabled(),
                          onLocationSelected: _onLocationSelectedFromTextField,
                          stage:
                              widget.mode == MapMode.endPointsOnly && stage > 1
                                  ? 1
                                  : stage,
                          waypointCount: _wayPoints.length,
                          focusNode: _focusNode,
                        )),
                        Visibility(
                            visible: widget.mode != MapMode.singlePoint &&
                                !_focusNode.hasFocus &&
                                _selected != null,
                            maintainState: true,
                            maintainSize: true,
                            maintainAnimation: true,
                            child: IconButton.filledTonal(
                                onPressed: stage < 2 &&
                                        widget.mode != MapMode.endPointsOnly
                                    ? _onConfirm
                                    : _onWaypointConfirmed,
                                icon: Icon(
                                  stage < 2 ? Icons.arrow_forward : Icons.add,
                                )))
                      ],
              ))
        ],
      )),
    );
  }
}
