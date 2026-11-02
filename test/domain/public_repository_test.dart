import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:scarborough_tortoise_watch/features/map/data/public_incident_repository.dart';
import 'package:scarborough_tortoise_watch/features/map/domain/public_incident.dart';

const sighting = PublicIncident(
  id: 'public-only',
  incidentType: PublicIncidentType.injured,
  displayLatitude: -34.1973,
  displayLongitude: 18.3752,
  date: '2026-10-04',
);

void main() {
  test('concurrent filters coalesce one public page and reuse its cache',
      () async {
    final pending = Completer<List<PublicIncident>>();
    var reads = 0;
    final repository = FirebasePublicIncidentRepository(loadPage: () {
      reads++;
      return pending.future;
    });
    final all = repository.list();
    final alive = repository.list(typeFilter: 'alive');
    expect(reads, 1);
    pending.complete([sighting]);
    expect(await all, [sighting]);
    expect(await alive, isEmpty);
    expect(await repository.list(from: DateTime(2026, 10, 5)), isEmpty);
    expect(await repository.list(typeFilter: 'injured'), [sighting]);
    expect(reads, 1);
  });

  test('empty results cache until the exact sixty-second boundary', () async {
    var now = DateTime(2030);
    var reads = 0;
    final repository = FirebasePublicIncidentRepository(
      now: () => now,
      loadPage: () async {
        reads++;
        return reads == 1 ? [] : [sighting];
      },
    );
    expect(await repository.list(), isEmpty);
    now = now.add(const Duration(seconds: 59));
    expect(await repository.list(), isEmpty);
    expect(reads, 1);
    now = now.add(const Duration(seconds: 1));
    expect(await repository.list(), [sighting]);
    expect(reads, 2);
  });

  test('a failed page is not cached or retried automatically', () async {
    var reads = 0;
    final repository = FirebasePublicIncidentRepository(loadPage: () async {
      reads++;
      if (reads == 1) throw StateError('offline');
      return [sighting];
    });
    await expectLater(repository.list(), throwsStateError);
    expect(reads, 1);
    expect(await repository.list(), [sighting]);
    expect(reads, 2);
  });

  test('forced refresh bypasses cache and removes a withdrawn projection',
      () async {
    var withdrawn = false;
    var reads = 0;
    final repository = FirebasePublicIncidentRepository(loadPage: () async {
      reads++;
      return withdrawn ? [] : [sighting];
    });
    expect(await repository.list(), [sighting]);
    withdrawn = true;
    expect(await repository.list(forceRefresh: true), isEmpty);
    expect(await repository.list(), isEmpty);
    expect(reads, 2);
  });

  test('old in-flight result follows the newer refresh and cannot refill cache',
      () async {
    final old = Completer<List<PublicIncident>>();
    final fresh = Completer<List<PublicIncident>>();
    var reads = 0;
    final repository = FirebasePublicIncidentRepository(loadPage: () {
      reads++;
      return reads == 1 ? old.future : fresh.future;
    });
    final first = repository.list();
    final refresh = repository.list(forceRefresh: true);
    fresh.complete([]);
    expect(await refresh, isEmpty);
    old.complete([sighting]);
    expect(await first, isEmpty);
    expect(await repository.list(), isEmpty);
    expect(reads, 2);
  });

  test('superseded load follows refresh failure without starting a third read',
      () async {
    final old = Completer<List<PublicIncident>>();
    final fresh = Completer<List<PublicIncident>>();
    var reads = 0;
    final repository = FirebasePublicIncidentRepository(loadPage: () {
      reads++;
      return reads == 1 ? old.future : fresh.future;
    });
    final first = repository.list();
    final refresh = repository.list(forceRefresh: true);
    final firstError = expectLater(first, throwsStateError);
    final refreshError = expectLater(refresh, throwsStateError);
    fresh.completeError(StateError('offline'));
    await refreshError;
    old.complete([sighting]);
    await firstError;
    expect(reads, 2);
  });
}
