import 'dart:math' as math;

import '../../features/report/domain/incident.dart';

class PublicCoordinateSanitizer {
  const PublicCoordinateSanitizer._();

  static GeoCoordinate randomOffset(
    GeoCoordinate source, {
    required math.Random random,
    double minimumMetres = 20,
    double maximumMetres = 50,
  }) {
    if (minimumMetres < 0 || maximumMetres < minimumMetres) {
      throw ArgumentError('Invalid privacy radius');
    }
    final distance =
        minimumMetres + random.nextDouble() * (maximumMetres - minimumMetres);
    final bearing = random.nextDouble() * 2 * math.pi;
    const metresPerDegree = 111320.0;
    final latitudeRadians = source.latitude * math.pi / 180;
    final deltaLatitude = distance * math.cos(bearing) / metresPerDegree;
    final longitudeScale = metresPerDegree * math.cos(latitudeRadians).abs();
    final deltaLongitude =
        longitudeScale == 0 ? 0 : distance * math.sin(bearing) / longitudeScale;
    return GeoCoordinate(
      latitude: source.latitude + deltaLatitude,
      longitude: source.longitude + deltaLongitude,
      source: LocationSource.unknown,
    );
  }
}
