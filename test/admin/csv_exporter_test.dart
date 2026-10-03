import 'package:flutter_test/flutter_test.dart';
import 'package:scarborough_tortoise_watch/features/admin/data/csv_exporter.dart';

void main() {
  test(
      'CSV neutralises whitespace-prefixed formulas and retains numeric coordinates',
      () {
    final csv = CsvExporter.export(const [
      AdminIncidentRecord(
          id: 'safe',
          createdAt: '2026',
          latitude: -34.197,
          longitude: 18.375,
          incidentType: 'injured',
          status: 'pending',
          note: ' \t=1+1')
    ], authorised: true);
    expect(csv, contains("' \t=1+1"));
    expect(csv, contains(',-34.197,18.375,'));
  });
  test('CSV exporter escapes cells and neutralises spreadsheet formulas', () {
    final csv = CsvExporter.export(
      const <AdminIncidentRecord>[
        AdminIncidentRecord(
          id: 'incident-1',
          createdAt: '2026-10-03T08:00:00Z',
          latitude: -34.1,
          longitude: 18.3,
          incidentType: 'injured',
          status: 'pending',
          note: '=HYPERLINK("https://example.test")',
        ),
      ],
      authorised: true,
    );

    expect(csv, contains("'=HYPERLINK(\"\"https://example.test\"\")"));
    expect(csv, contains('"incident-1"'));
    expect(csv.split('\n').length, 2);
  });

  test('CSV export fails closed for unauthorised callers', () {
    expect(
      () =>
          CsvExporter.export(const <AdminIncidentRecord>[], authorised: false),
      throwsA(isA<AdminAuthorisationException>()),
    );
  });
}
