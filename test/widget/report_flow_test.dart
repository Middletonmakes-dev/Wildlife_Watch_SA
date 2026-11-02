import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:scarborough_tortoise_watch/app/app.dart';
import 'package:scarborough_tortoise_watch/app/providers.dart';
import 'package:scarborough_tortoise_watch/features/report/data/incident_repository.dart';
import 'package:scarborough_tortoise_watch/features/report/domain/incident.dart';
import 'package:scarborough_tortoise_watch/features/report/domain/location_service.dart';
import 'package:scarborough_tortoise_watch/features/report/domain/report_draft.dart';

void main() {
  testWidgets(
      'GPS pending and denial feedback is visible above the small-phone map',
      (tester) async {
    final gps = _Gps(pending: Completer<LocationResult>());
    await _open(tester, gps: gps);
    tester.view.physicalSize = const Size(360, 649);
    await tester.pump();
    await tester.tap(find.text('Crossing road'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use my location'));
    await tester.pump();
    final waiting =
        find.text('Waiting for your browser… You can place a pin instead.');
    expect(waiting.hitTestable(), findsOneWidget);
    expect(tester.getBottomLeft(waiting).dy,
        lessThan(tester.getTopLeft(find.byType(FlutterMap)).dy));
    gps.pending!.completeError(const LocationException(
        'Location access is blocked. Allow location for this site in your browser, or place a pin.'));
    await tester.pumpAndSettle();
    final denied = find.text(
        'Location access is blocked. Allow location for this site in your browser, or place a pin.');
    expect(denied.hitTestable(), findsOneWidget);
    expect(tester.getBottomLeft(denied).dy,
        lessThan(tester.getTopLeft(find.byType(FlutterMap)).dy));
    expect(find.text('Use my location').hitTestable(), findsOneWidget);
    expect(find.text('Place a pin').hitTestable(), findsOneWidget);
  });
  testWidgets('GPS retry restores close zoom and clears skipped direction',
      (tester) async {
    await _open(tester);
    await tester.tap(find.text('Crossing road'));
    await tester.pumpAndSettle();
    final map =
        tester.widget<FlutterMap>(find.byType(FlutterMap)).mapController!;
    expect(map.camera.zoom, 17);
    await tester.tap(find.byIcon(Icons.location_pin));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Skip direction'));
    await tester.pump();
    map.move(map.camera.center, 14);
    await tester.tap(find.text('Use my location'));
    await tester.pumpAndSettle();
    expect(map.camera.zoom, 17);
    expect(find.text('Direction optional'), findsOneWidget);
    map.move(map.camera.center, 16);
    await tester.tapAt(
        tester.getCenter(find.byKey(const Key('direction-wheel'))) +
            const Offset(65, 0));
    await tester.pump();
    expect(map.camera.zoom, 16);
  });
  for (final type in ['Crossing road', 'Roadkill']) {
    testWidgets('pending GPS automatically confirms location for $type',
        (tester) async {
      final gps = _Gps(pending: Completer<LocationResult>());
      await _open(tester, gps: gps);
      await tester.tap(find.text(type));
      await tester.pumpAndSettle();
      expect(gps.calls, 0);
      await tester.tap(find.text('Use my location'));
      await tester.pump();
      expect(find.byKey(const Key('direction-wheel')), findsNothing);
      gps.pending!.complete(const LocationResult(GeoCoordinate(
          latitude: -34.197,
          longitude: 18.375,
          source: LocationSource.deviceGps)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('direction-wheel')),
          type == 'Roadkill' ? findsNothing : findsOneWidget);
      expect(find.text('Location ready. You can move the pin if needed.'),
          findsOneWidget);
    });
  }
  testWidgets(
      'switching to manual placement keeps editing when late GPS resolves',
      (tester) async {
    final gps = _Gps(pending: Completer<LocationResult>());
    final repository = _Reports();
    await _open(tester, gps: gps, repository: repository);
    await tester.tap(find.text('Crossing road'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use my location'));
    await tester.pump();
    await tester.tap(find.text('Place a pin'));
    await tester.pump();
    gps.pending!.complete(const LocationResult(GeoCoordinate(
        latitude: 0, longitude: 0, source: LocationSource.deviceGps)));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('direction-wheel')), findsNothing);
    expect(find.byIcon(Icons.location_pin), findsOneWidget);
    final camera = tester
        .widget<FlutterMap>(find.byType(FlutterMap))
        .mapController!
        .camera;
    expect(camera.center.latitude, -34.197);
    expect(camera.center.longitude, 18.375);
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();
    expect(repository.draft, isNull);
    expect(find.text('Confirm the location'), findsOneWidget);
  });
  testWidgets('GPS retry denial remains visible beside an existing direction',
      (tester) async {
    await _open(tester, gps: _Gps(failRetry: true));
    await _locate(tester);
    await tester.tap(find.text('Use my location'));
    await tester.pumpAndSettle();
    expect(
        find.text('Permission denied. Place a pin instead.'), findsOneWidget);
    expect(find.byKey(const Key('direction-wheel')), findsOneWidget);
  });
  testWidgets('tapping the manual pin confirms the map centre', (tester) async {
    final repository = _Reports();
    await _open(tester, repository: repository);
    await tester.tap(find.text('Crossing road'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Place a pin'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.location_pin));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();
    expect(repository.draft, isNotNull);
    expect(repository.draft!.location!.source, LocationSource.manualPin);
  });
  testWidgets('GPS is requested only after the resident chooses it',
      (tester) async {
    final gps = _Gps();
    await _open(tester, gps: gps);
    expect(gps.calls, 0);
    await tester.tap(find.text('Crossing road'));
    await tester.pumpAndSettle();
    expect(gps.calls, 0);
    expect(find.text('Where was it?'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Use my location'));
    await tester.pumpAndSettle();
    expect(gps.calls, 1);
    expect(find.byKey(const Key('direction-wheel')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('untouched direction remains absent from submitted report',
      (tester) async {
    final repository = _Reports();
    await _open(tester, repository: repository);
    await _locate(tester);
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();
    expect(repository.draft!.location!.directionBearing, isNull);
    expect(repository.draft!.note, isNull);
    expect(repository.draft!.photoBytes, isNull);
    expect(find.text('Thank you'), findsOneWidget);
  });
  testWidgets(
      'wheel follows roads north-up and skip clears its previous choice',
      (tester) async {
    final repository = _Reports();
    await _open(tester, repository: repository);
    await _locate(tester);
    final wheel = find.byKey(const Key('direction-wheel'));
    await tester.tapAt(tester.getCenter(wheel) + const Offset(65, 0));
    await tester.pump();
    expect(find.text('Direction selected'), findsOneWidget);
    await tester.tap(find.text('Skip direction'));
    await tester.pump();
    expect(find.text('Direction skipped'), findsOneWidget);
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();
    expect(repository.draft!.location!.directionBearing, isNull);
  });
  testWidgets('dragging arrow changes direction without moving the report pin',
      (tester) async {
    final repository = _Reports();
    await _open(tester, repository: repository);
    await _locate(tester);
    final centre = tester.getCenter(find.byKey(const Key('direction-wheel')));
    final gesture = await tester.startGesture(centre + const Offset(0, -65));
    await gesture.moveTo(centre + const Offset(65, 0));
    await gesture.up();
    await tester.pump();
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();
    final location = repository.draft!.location!;
    expect(location.latitude, -34.197);
    expect(location.longitude, 18.375);
    expect(location.directionBearing, closeTo(90, .1));
  });
  testWidgets(
      'back preserves draft; roadkill hides and clears previous direction',
      (tester) async {
    final repository = _Reports();
    await _open(tester, repository: repository);
    await _locate(tester);
    await tester.tapAt(
        tester.getCenter(find.byKey(const Key('direction-wheel'))) +
            const Offset(0, -65));
    await tester.pump();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Crossing road'));
    await tester.pumpAndSettle();
    expect(find.text('Direction selected'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Roadkill'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('direction-wheel')), findsNothing);
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();
    expect(repository.draft!.incidentType, IncidentType.deadRoadkill);
    expect(repository.draft!.location!.directionBearing, isNull);
  });
  testWidgets(
      'manual location remains available while GPS is pending and wins late result',
      (tester) async {
    final gps = _Gps(pending: Completer<LocationResult>());
    final repository = _Reports();
    await _open(tester, gps: gps, repository: repository);
    await tester.tap(find.text('Near the road'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use my location'));
    await tester.pump();
    await tester.tap(find.text('Place a pin'));
    await tester.pump();
    await tester.tapAt(
        tester.getCenter(find.byType(FlutterMap)) + const Offset(40, 20));
    await tester.pumpAndSettle();
    gps.pending!.complete(const LocationResult(GeoCoordinate(
        latitude: 0, longitude: 0, source: LocationSource.deviceGps)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();
    expect(repository.draft!.location!.source, LocationSource.manualPin);
    expect(repository.draft!.location!.latitude, isNot(0));
  });
}

Future<void> _locate(WidgetTester tester) async {
  await tester.tap(find.text('Crossing road'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Use my location'));
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester,
    {_Gps? gps, _Reports? repository}) async {
  tester.view.physicalSize = const Size(360, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ProviderScope(overrides: [
    mapTileProviderFactoryProvider.overrideWithValue(() => _MemoryTiles()),
    locationServiceProvider.overrideWithValue(gps ?? _Gps()),
    incidentRepositoryProvider.overrideWithValue(repository ?? _Reports()),
  ], child: const ScarboroughTortoiseWatchApp()));
  await tester.tap(find.text('Report a tortoise'));
  await tester.pumpAndSettle();
}

class _Gps implements LocationService {
  _Gps({this.pending, this.failRetry = false});
  final bool failRetry;
  final Completer<LocationResult>? pending;
  int calls = 0;
  @override
  Future<LocationResult> currentLocation() async {
    calls++;
    if (failRetry && calls > 1)
      throw const LocationException('Permission denied. Place a pin instead.');
    if (pending != null) return pending!.future;
    return const LocationResult(GeoCoordinate(
        latitude: -34.197,
        longitude: 18.375,
        source: LocationSource.deviceGps));
  }
}

class _Reports implements IncidentRepository {
  ReportDraft? draft;
  @override
  Future<SubmissionResult> submit(ReportDraft value) async {
    draft = value;
    return const SubmissionResult(incidentId: 'test-report');
  }
}

class _MemoryTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(Uint8List.fromList(
          image.encodePng(image.Image(width: 1, height: 1))));
}
