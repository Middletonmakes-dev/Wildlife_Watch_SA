import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scarborough_tortoise_watch/app/providers.dart';
import 'package:scarborough_tortoise_watch/features/report/data/incident_repository.dart';
import 'package:scarborough_tortoise_watch/features/report/data/owner_incident_repository.dart';
import 'package:scarborough_tortoise_watch/features/report/domain/incident.dart';
import 'package:scarborough_tortoise_watch/features/report/domain/report_draft.dart';
import 'package:scarborough_tortoise_watch/features/report/presentation/your_reports_screen.dart';

void main() {
  testWidgets('owner can cancel then confirm withdrawal and retain the receipt',
      (tester) async {
    DemoIncidentRepository.clearForTest();
    addTearDown(DemoIncidentRepository.clearForTest);
    await DemoIncidentRepository().submit(const ReportDraft(
      requestId: 'widget-owner-receipt',
      incidentType: IncidentType.injured,
      location: GeoCoordinate(
        latitude: -34.197,
        longitude: 18.375,
        source: LocationSource.manualPin,
      ),
    ));
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          ownerIncidentRepositoryProvider
              .overrideWithValue(const DemoOwnerIncidentRepository()),
        ],
        child: const MaterialApp(home: YourReportsScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Withdraw'), findsOneWidget);

    await tester.tap(find.text('Withdraw'));
    await tester.pumpAndSettle();
    expect(find.text('Withdraw this report?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Withdraw'), findsOneWidget);

    await tester.tap(find.text('Withdraw'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Withdraw report'));
    await tester.pumpAndSettle();
    expect(find.text('Withdrawn'), findsOneWidget);
    expect(find.text('Withdraw'), findsNothing);
  });
}
