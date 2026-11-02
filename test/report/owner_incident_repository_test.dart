import 'package:flutter_test/flutter_test.dart';
import 'package:scarborough_tortoise_watch/features/report/data/owner_incident_repository.dart';
import 'package:scarborough_tortoise_watch/features/report/data/incident_repository.dart';
import 'package:scarborough_tortoise_watch/features/report/domain/incident.dart';
import 'package:scarborough_tortoise_watch/features/report/domain/owner_incident.dart';
import 'package:scarborough_tortoise_watch/features/report/domain/report_draft.dart';

void main() {
  test('demo owner receipts discover existing reports and retain withdrawal',
      () async {
    final incidents = DemoIncidentRepository();
    final result = await incidents.submit(const ReportDraft(
      requestId: 'owner-receipt-test',
      incidentType: IncidentType.injured,
      location: GeoCoordinate(
        latitude: -34.197,
        longitude: 18.375,
        source: LocationSource.manualPin,
      ),
    ));

    final receipts = await DemoOwnerIncidentRepository().list();
    expect(receipts.reports.single.id, result.incidentId);
    expect(receipts.reports.single.status, OwnerIncidentStatus.pending);

    await DemoOwnerIncidentRepository().withdraw(result.incidentId);
    final withdrawn = await DemoOwnerIncidentRepository().list();
    expect(withdrawn.reports.single.status, OwnerIncidentStatus.withdrawn);
  });

  test('withdrawn is a distinct moderation status', () {
    expect(ModerationStatusX.fromCode('withdrawn'), ModerationStatus.withdrawn);
  });
}
