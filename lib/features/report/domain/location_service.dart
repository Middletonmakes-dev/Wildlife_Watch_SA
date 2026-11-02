import 'dart:async';

import 'incident.dart';

import 'package:geolocator/geolocator.dart';

class LocationResult {
  const LocationResult(this.coordinate);

  final GeoCoordinate coordinate;

  bool get isLowAccuracy => (coordinate.accuracyMetres ?? 0) >= 100;
}

abstract interface class LocationService {
  Future<LocationResult> currentLocation();
}

class LocationException implements Exception {
  const LocationException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DemoLocationService implements LocationService {
  const DemoLocationService();

  @override
  Future<LocationResult> currentLocation() async {
    throw const LocationException(
        'Demo: tap or drag the pin to choose a synthetic report location. No device GPS is used.');
  }
}

class DeviceLocationService implements LocationService {
  const DeviceLocationService();

  @override
  Future<LocationResult> currentLocation() async {
    var expired = false;
    const timeoutMessage = 'Location took too long. Try again or place a pin.';
    const blockedMessage =
        'Location access is blocked. Allow location for this site in your browser, or place a pin.';
    void checkDeadline() {
      if (expired) throw const LocationException(timeoutMessage);
    }

    Future<LocationResult> locate() async {
      final enabled = await Geolocator.isLocationServiceEnabled();
      checkDeadline();
      if (!enabled) {
        throw const LocationException(
            'Location is disabled. Tap the map to choose it manually.');
      }
      var permission = await Geolocator.checkPermission();
      checkDeadline();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        checkDeadline();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw const LocationException(blockedMessage);
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
      checkDeadline();
      return LocationResult(
        GeoCoordinate(
          latitude: position.latitude,
          longitude: position.longitude,
          accuracyMetres: position.accuracy,
          source: LocationSource.deviceGps,
        ),
      );
    }

    try {
      // Web permission requests can themselves wait for a position. Bound the
      // entire workflow and stop late stages from starting another request.
      return await locate().timeout(const Duration(seconds: 15), onTimeout: () {
        expired = true;
        throw const LocationException(timeoutMessage);
      });
    } on PermissionDeniedException {
      throw const LocationException(blockedMessage);
    }
  }
}
