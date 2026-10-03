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
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationException(
          'Location is disabled. Tap the map to choose it manually.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw const LocationException(
          'Location permission was not granted. Tap the map to choose it manually.');
    }
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
    );
    return LocationResult(
      GeoCoordinate(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracyMetres: position.accuracy,
        source: LocationSource.deviceGps,
      ),
    );
  }
}
