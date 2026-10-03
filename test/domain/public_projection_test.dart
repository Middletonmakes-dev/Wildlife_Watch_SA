import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:scarborough_tortoise_watch/core/privacy/public_coordinate_sanitizer.dart';
import 'package:scarborough_tortoise_watch/features/map/domain/public_incident.dart';
import 'package:scarborough_tortoise_watch/features/report/domain/incident.dart';

void main() {
  test('sanitises a coordinate within the configured privacy radius', () {
    const source = GeoCoordinate(
      latitude: -34.126,
      longitude: 18.375,
      source: LocationSource.deviceGps,
    );
    final result = PublicCoordinateSanitizer.randomOffset(
      source,
      random: Random(7),
      minimumMetres: 20,
      maximumMetres: 50,
    );

    expect(result.distanceFrom(source), inInclusiveRange(20, 50));
    expect(result.latitude, isNot(source.latitude));
    expect(result.longitude, isNot(source.longitude));
  });

  test('public serialization exposes only the allowlisted map fields', () {
    const publicIncident = PublicIncident(
      id: 'public-1',
      incidentType: PublicIncidentType.deadRoadkill,
      displayLatitude: -34.1261,
      displayLongitude: 18.3751,
      date: '2026-10-03',
    );

    final json = publicIncident.toJson();

    expect(
        json.keys,
        containsAll(<String>[
          'id',
          'incidentType',
          'displayLatitude',
          'displayLongitude',
          'date',
        ]));
    expect(json.keys, isNot(contains('longitude')));
    expect(json.keys, isNot(contains('note')));
    expect(json.keys, isNot(contains('reporterUid')));
    expect(
      json.keys,
      isNot(contains('photoReferences')),
    );
  });
}
