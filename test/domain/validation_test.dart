import 'package:flutter_test/flutter_test.dart';
import 'package:scarborough_tortoise_watch/features/report/domain/incident.dart';
import 'package:scarborough_tortoise_watch/features/report/domain/report_draft.dart';

void main() {
  group('ReportDraft validation', () {
    test('rejects non-finite and out-of-range coordinates', () {
      final errors = ReportDraft(
        requestId: 'request-1',
        location: const GeoCoordinate(
          latitude: double.nan,
          longitude: 181,
          source: LocationSource.manualPin,
        ),
        incidentType: IncidentType.injured,
      ).validate();

      expect(errors, contains('latitude must be finite'));
      expect(errors, contains('longitude must be between -180 and 180'));
    });

    test('requires an incident type and confirmed location', () {
      final errors = ReportDraft(requestId: 'request-1').validate();

      expect(errors, contains('Choose what happened'));
      expect(errors, contains('Confirm the location'));
    });

    test('limits notes and bearings to safe values', () {
      final errors = ReportDraft(
        requestId: 'request-1',
        location: const GeoCoordinate(
          latitude: -34,
          longitude: 18,
          source: LocationSource.manualPin,
          directionBearing: 360,
        ),
        incidentType: IncidentType.aliveNearRoad,
        note: 'a' * 501,
      ).validate();

      expect(errors, contains('Note must be 500 characters or fewer'));
      expect(errors,
          contains('Enter a numeric compass bearing from 0 to less than 360.'));
    });
  });
}
