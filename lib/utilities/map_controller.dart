import 'dart:math';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/location.dart';

extension MapController on GoogleMapController {
  static const LatLng centerOfFinland = LatLng(64.950133, 25.43435);
  static const LatLng south = LatLng(59.807983, 22.913117);
  static const LatLng north = LatLng(70.092283, 27.955583);
  static const LatLng southwest = LatLng(59.807983, 19.131067);
  static const LatLng northeast = LatLng(70.092283, 31.5867);

  Future<void> centerToLocation(LatLng location) async {
    final zoomLevel = await getZoomLevel();
    return animateCamera(CameraUpdate.newCameraPosition(CameraPosition(
        target: location, zoom: max(11.0, zoomLevel))));
  }

  // https://stackoverflow.com/questions/55989773/how-to-zoom-between-two-google-map-markers-in-flutter

  Future<void> _updateCameraLocation(
      {LatLng source = south,
      LatLng destination = north,
      double padding = 0}) async {
    LatLngBounds bounds;

    if (source.latitude > destination.latitude &&
        source.longitude > destination.longitude) {
      bounds = LatLngBounds(southwest: destination, northeast: source);
    } else if (source.longitude > destination.longitude) {
      bounds = LatLngBounds(
          southwest: LatLng(source.latitude, destination.longitude),
          northeast: LatLng(destination.latitude, source.longitude));
    } else if (source.latitude > destination.latitude) {
      bounds = LatLngBounds(
          southwest: LatLng(destination.latitude, source.longitude),
          northeast: LatLng(source.latitude, destination.longitude));
    } else {
      bounds = LatLngBounds(southwest: source, northeast: destination);
    }

    CameraUpdate cameraUpdate = CameraUpdate.newLatLngBounds(bounds, padding);

    return _checkCameraLocation(cameraUpdate);
  }

  Future<void> _checkCameraLocation(CameraUpdate cameraUpdate) async {
    animateCamera(cameraUpdate);
    LatLngBounds l1 = await getVisibleRegion();
    LatLngBounds l2 = await getVisibleRegion();

    if (l1.southwest.latitude == -90 || l2.southwest.latitude == -90) {
      return _checkCameraLocation(cameraUpdate);
    }
  }

  /// Sets camera between start and destination. If start or destination is not
  /// given, sets camera to center of Finland.
  void updateCamera(Point? start, Point? destination) {
    if (start != null && destination != null) {
      _updateCameraLocation(
          source: LatLng(start.latitude, start.longitude),
          destination: LatLng(destination.latitude, destination.longitude),
          padding: 80);
    } else {
      _updateCameraLocation();
    }
  }
}
