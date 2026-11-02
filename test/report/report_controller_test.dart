import 'dart:typed_data';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:scarborough_tortoise_watch/features/report/data/incident_repository.dart';
import 'package:scarborough_tortoise_watch/features/report/data/photo_storage.dart';
import 'package:scarborough_tortoise_watch/features/report/domain/incident.dart';
import 'package:scarborough_tortoise_watch/features/report/domain/report_controller.dart';
import 'package:scarborough_tortoise_watch/features/report/domain/report_draft.dart';
import 'package:scarborough_tortoise_watch/features/report/domain/location_service.dart';

class FakeRepository implements IncidentRepository {
  FakeRepository({this.failFirst = false});

  final bool failFirst;
  int calls = 0;
  final Map<String, SubmissionResult> stored = <String, SubmissionResult>{};

  @override
  Future<SubmissionResult> submit(ReportDraft draft) async {
    calls++;
    if (failFirst && calls == 1)
      throw const ReportRepositoryException('temporary failure');
    return stored.putIfAbsent(
      draft.requestId,
      () => SubmissionResult(incidentId: 'incident-${stored.length + 1}'),
    );
  }
}

class FakePhotoStorage implements PhotoStorage {
  FakePhotoStorage({this.fail = false});

  bool fail;
  int calls = 0;
  final attemptedIds = <String>[];
  final attemptedBytes = <Uint8List>[];

  @override
  Future<void> upload(
      {required String incidentId, required Uint8List bytes}) async {
    calls++;
    attemptedIds.add(incidentId);
    attemptedBytes.add(Uint8List.fromList(bytes));
    if (fail) throw const PhotoStorageException('photo unavailable');
  }
}

class FakeLocationService implements LocationService {
  FakeLocationService(this.result);

  final LocationResult result;

  @override
  Future<LocationResult> currentLocation() async => result;
}

void main() {
  test('GPS request reports acceptance and rejects late manual replacement',
      () async {
    final gps = DelayedLocationService();
    final controller = ReportController(
        repository: FakeRepository(),
        photoStorage: FakePhotoStorage(),
        locationService: gps,
        initialDraft: const ReportDraft(requestId: 'fix-result'));
    final pending = controller.startLocation();
    controller.setManualLocation(const GeoCoordinate(
        latitude: 1, longitude: 1, source: LocationSource.manualPin));
    gps.completer.complete(const LocationResult(GeoCoordinate(
        latitude: 0, longitude: 0, source: LocationSource.deviceGps)));
    expect(await pending, false);
    expect(controller.state.draft.location!.source, LocationSource.manualPin);
  });
  test('GPS request returns true only for an applied fix', () async {
    final controller = ReportController(
        repository: FakeRepository(),
        photoStorage: FakePhotoStorage(),
        locationService: FakeLocationService(const LocationResult(GeoCoordinate(
            latitude: 0, longitude: 0, source: LocationSource.deviceGps))),
        initialDraft: const ReportDraft(requestId: 'accepted-fix'));
    expect(await controller.startLocation(), true);
  });
  test('denied GPS request returns false', () async {
    final controller = ReportController(
        repository: FakeRepository(),
        photoStorage: FakePhotoStorage(),
        locationService: const DemoLocationService(),
        initialDraft: const ReportDraft(requestId: 'denied-fix'));
    expect(await controller.startLocation(), false);
    expect(controller.state.draft.location, isNull);
  });
  test('correcting a draft clears obsolete validation feedback', () async {
    final controller = ReportController(
        repository: FakeRepository(),
        photoStorage: FakePhotoStorage(),
        locationService: const DemoLocationService(),
        initialDraft: const ReportDraft(requestId: 'validation'));
    await controller.submit();
    expect(controller.state.message, isNotNull);
    controller.updateDraft(
        controller.state.draft.copyWith(incidentType: IncidentType.injured));
    expect(controller.state.message, isNull);
    await controller.submit();
    expect(controller.state.message, 'Confirm the location');
    controller.setManualLocation(const GeoCoordinate(
        latitude: -34.197,
        longitude: 18.375,
        source: LocationSource.manualPin));
    expect(controller.state.message, isNull);
  });
  test('successful GPS clears a previous missing-location error', () async {
    final controller = ReportController(
        repository: FakeRepository(),
        photoStorage: FakePhotoStorage(),
        locationService: FakeLocationService(const LocationResult(GeoCoordinate(
            latitude: -34.197,
            longitude: 18.375,
            source: LocationSource.deviceGps))),
        initialDraft: const ReportDraft(
            requestId: 'gps-validation', incidentType: IncidentType.injured));
    await controller.submit();
    expect(controller.state.message, 'Confirm the location');
    await controller.startLocation();
    expect(controller.state.message, isNull);
  });
  test('a delayed GPS failure cannot reopen an in-flight submission', () async {
    final location = DelayedLocationService();
    final repository = DelayedRepository();
    final controller = ReportController(
        repository: repository,
        photoStorage: FakePhotoStorage(),
        locationService: location,
        initialDraft: const ReportDraft(
            requestId: 'gps-race',
            incidentType: IncidentType.injured,
            location: GeoCoordinate(
                latitude: -34.197,
                longitude: 18.375,
                source: LocationSource.manualPin)));
    final locating = controller.startLocation();
    final saving = controller.submit();
    location.completer.completeError(const LocationException('denied'));
    await locating;
    expect(controller.state.status, ReportStatus.submitting);
    repository.completer
        .complete(const SubmissionResult(incidentId: 'gps-race'));
    await saving;
    expect(repository.calls, 1);
  });
  test('demo location does not silently confirm a synthetic GPS position',
      () async {
    final controller = ReportController(
        repository: DemoIncidentRepository(),
        photoStorage: DemoPhotoStorage(),
        locationService: const DemoLocationService(),
        initialDraft: const ReportDraft(requestId: 'demo'));
    await controller.startLocation();
    expect(controller.state.draft.location, isNull);
    expect(controller.state.locationMessage, contains('Demo'));
  });
  test('overlapping submissions save the core incident once', () async {
    final repository = DelayedRepository();
    final controller = ReportController(
        repository: repository,
        photoStorage: FakePhotoStorage(),
        locationService: const DemoLocationService(),
        initialDraft: const ReportDraft(
            requestId: 'one',
            location: GeoCoordinate(
                latitude: -34.197,
                longitude: 18.375,
                source: LocationSource.manualPin),
            incidentType: IncidentType.injured));
    final first = controller.submit();
    controller.setManualLocation(const GeoCoordinate(
        latitude: 0, longitude: 0, source: LocationSource.manualPin));
    controller.updateDraft(
        controller.state.draft.copyWith(note: 'edit while saving'));
    await controller.applyLocationResult(const LocationResult(GeoCoordinate(
        latitude: 1, longitude: 1, source: LocationSource.deviceGps)));
    final second = controller.submit();
    expect(repository.calls, 1);
    expect(controller.state.draft.note, isNull);
    expect(controller.state.draft.location!.latitude, -34.197);
    repository.completer.complete(const SubmissionResult(incidentId: 'one'));
    await Future.wait([first, second]);
  });
  final location = const GeoCoordinate(
    latitude: -34.126,
    longitude: 18.375,
    accuracyMetres: 150,
    source: LocationSource.deviceGps,
  );

  test('keeps the draft and request ID after a failed submission for retry',
      () async {
    final repository = FakeRepository(failFirst: true);
    final controller = ReportController(
      repository: repository,
      photoStorage: FakePhotoStorage(),
      locationService: FakeLocationService(LocationResult(location)),
      initialDraft: ReportDraft(
        requestId: 'stable-request',
        location: location,
        incidentType: IncidentType.injured,
        note: 'Keep this note',
      ),
    );

    await controller.submit();
    expect(controller.state.status, ReportStatus.error);
    expect(controller.state.draft.requestId, 'stable-request');
    expect(controller.state.draft.note, 'Keep this note');

    await controller.submit();
    expect(controller.state.status, ReportStatus.submitted);
    expect(controller.state.incidentId, 'incident-1');
    expect(repository.calls, 2);
  });

  test('does not lose a committed report when its optional photo fails',
      () async {
    final photoStorage = FakePhotoStorage(fail: true);
    final repository = FakeRepository();
    final controller = ReportController(
      repository: repository,
      photoStorage: photoStorage,
      locationService: FakeLocationService(LocationResult(location)),
      initialDraft: ReportDraft(
        requestId: 'photo-request',
        location: location,
        incidentType: IncidentType.aliveNearRoad,
        photoBytes: Uint8List.fromList(<int>[1, 2, 3]),
      ),
    );

    await controller.submit();

    expect(controller.state.status, ReportStatus.submitted);
    expect(controller.state.photoUploaded, isFalse);
    expect(controller.state.incidentId, 'incident-1');
    expect(photoStorage.calls, 1);
    photoStorage.fail = false;
    final savedId = controller.state.incidentId;
    final uploaded = await controller.retryPhoto();
    expect(uploaded, isTrue);
    expect(controller.state.incidentId, savedId);
    expect(photoStorage.calls, 2);
    expect(repository.calls, 1);
    expect(photoStorage.attemptedIds, <String>[savedId!, savedId]);
    expect(photoStorage.attemptedBytes[0], <int>[1, 2, 3]);
    expect(photoStorage.attemptedBytes[1], photoStorage.attemptedBytes[0]);
  });

  test(
      'manual location replaces low accuracy GPS and late GPS cannot overwrite it',
      () async {
    final controller = ReportController(
      repository: FakeRepository(),
      photoStorage: FakePhotoStorage(),
      locationService: FakeLocationService(LocationResult(location)),
      initialDraft: ReportDraft(requestId: 'location-request'),
    );

    await controller.startLocation();
    expect(controller.state.draft.location?.accuracyMetres, 150);
    expect(controller.state.locationMessage, contains('accuracy'));

    const manual = GeoCoordinate(
      latitude: -34.127,
      longitude: 18.376,
      source: LocationSource.manualPin,
    );
    controller.setManualLocation(manual);
    await controller.applyLocationResult(LocationResult(location));

    expect(controller.state.draft.location, manual);
  });
}

class DelayedRepository implements IncidentRepository {
  int calls = 0;
  final completer = Completer<SubmissionResult>();
  @override
  Future<SubmissionResult> submit(ReportDraft draft) {
    calls++;
    return completer.future;
  }
}

class DelayedLocationService implements LocationService {
  final completer = Completer<LocationResult>();
  @override
  Future<LocationResult> currentLocation() => completer.future;
}
