import 'package:flutter_test/flutter_test.dart';
import 'package:scarborough_tortoise_watch/features/report/domain/incident.dart';

void main() {
  group('Incident serialization', () {
    test('round trips a report without losing typed fields', () {
      final incident = Incident(
        id: 'incident-1',
        createdAt: DateTime.utc(2026, 10, 3, 8, 30),
        occurredAt: DateTime.utc(2026, 10, 3, 8, 20),
        location: const GeoCoordinate(
          latitude: -34.126,
          longitude: 18.375,
          accuracyMetres: 12,
          source: LocationSource.deviceGps,
          directionBearing: 92,
        ),
        incidentType: IncidentType.aliveCrossingRoad,
        note: 'Moved safely toward the verge.',
        photoReferences: const ['incidents/incident-1/photo.jpg'],
        reporterUid: 'anon-1',
        moderationStatus: ModerationStatus.pending,
        sourceVersion: 'demo-v1',
        requestId: 'request-1',
      );

      expect(Incident.fromJson(incident.toJson()), incident);
    });

    test('uses stable wire values for every incident type', () {
      expect(
        IncidentType.values.map((value) => value.code),
        containsAll(<String>[
          'alive_crossing_road',
          'alive_near_road',
          'injured',
          'dead_roadkill',
        ]),
      );
    });
  });
}
