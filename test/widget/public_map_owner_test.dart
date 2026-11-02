import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:scarborough_tortoise_watch/app/providers.dart';
import 'package:scarborough_tortoise_watch/features/map/data/public_incident_repository.dart';
import 'package:scarborough_tortoise_watch/features/map/domain/public_incident.dart';
import 'package:scarborough_tortoise_watch/features/map/presentation/public_map_screen.dart';
import 'package:scarborough_tortoise_watch/features/report/data/owner_incident_repository.dart';
import 'package:scarborough_tortoise_watch/features/report/domain/incident.dart';
import 'package:scarborough_tortoise_watch/features/report/domain/owner_incident.dart';

void main() {
  testWidgets('owner marker has a named action and confirms withdrawal',
      (tester) async {
    final owner = _FakeOwnerRepository();
    final public = _FakePublicRepository(removeOnRefresh: true);
    await _pump(tester, owner, public: public);

    final marker = find.bySemanticsLabel('Injured public sighting marker');
    expect(marker, findsOneWidget);
    await tester.tap(marker);
    await tester.pumpAndSettle();
    expect(find.text('Withdraw this report'), findsOneWidget);
    await tester.tap(find.text('Withdraw this report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(owner.withdrawals, 0);

    await tester.tap(marker);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Withdraw this report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Withdraw report'));
    await tester.pumpAndSettle();
    expect(owner.withdrawals, 1);
    expect(public.refreshes, 1);
    expect(marker, findsNothing);
  });

  testWidgets('owner marker withdrawal failure is recoverable', (tester) async {
    final owner = _FakeOwnerRepository()..fail = true;
    await _pump(tester, owner);

    await tester.tap(find.bySemanticsLabel('Injured public sighting marker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Withdraw this report'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Withdraw report'));
    await tester.pumpAndSettle();
    expect(find.text('Preview withdrawal failed.'), findsOneWidget);
  });

  testWidgets('public load error retries only on explicit refresh',
      (tester) async {
    final public = _FakePublicRepository()..fail = true;
    await _pump(tester, _FakeOwnerRepository(), public: public);
    expect(find.text('Sightings could not be loaded.'), findsOneWidget);
    expect(public.loads, 1);
    public.fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(public.loads, 2);
    expect(public.refreshes, 1);
    expect(find.bySemanticsLabel('Injured public sighting marker'),
        findsOneWidget);
    await tester.tap(find.byTooltip('Refresh sightings'));
    await tester.pumpAndSettle();
    expect(public.refreshes, 2);
  });
}

Future<void> _pump(WidgetTester tester, _FakeOwnerRepository owner,
    {_FakePublicRepository? public}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        ownerIncidentRepositoryProvider.overrideWithValue(owner),
        publicIncidentRepositoryProvider
            .overrideWithValue(public ?? _FakePublicRepository()),
        mapTileProviderFactoryProvider.overrideWithValue(() => _MemoryTiles()),
      ],
      child: const MaterialApp(home: PublicMapScreen()),
    ),
  );
  await tester.pump();
  await tester.pump();
}

class _FakePublicRepository implements PublicIncidentRepository {
  _FakePublicRepository({this.removeOnRefresh = false});

  final bool removeOnRefresh;
  bool fail = false;
  int loads = 0;
  int refreshes = 0;

  @override
  Future<List<PublicIncident>> list({
    String? typeFilter,
    DateTime? from,
    DateTime? to,
    bool forceRefresh = false,
  }) async {
    loads++;
    if (forceRefresh) refreshes++;
    if (fail) throw StateError('offline');
    if (removeOnRefresh && refreshes > 0) return [];
    return const <PublicIncident>[
      PublicIncident(
        id: 'owner-marker',
        incidentType: PublicIncidentType.injured,
        displayLatitude: -34.1973,
        displayLongitude: 18.3752,
        date: '2026-10-04',
      ),
    ];
  }
}

class _FakeOwnerRepository implements OwnerIncidentRepository {
  bool fail = false;
  int withdrawals = 0;
  bool withdrawn = false;

  @override
  Future<OwnerIncidentList> list() async => OwnerIncidentList(
        reports: <OwnerIncidentReceipt>[
          OwnerIncidentReceipt(
            id: 'owner-marker',
            incidentType: IncidentType.injured,
            status: withdrawn
                ? OwnerIncidentStatus.withdrawn
                : OwnerIncidentStatus.accepted,
            createdAt: DateTime(2026, 10, 4),
          ),
        ],
        hasMore: false,
      );

  @override
  Future<void> withdraw(String incidentId) async {
    if (fail) {
      throw const OwnerIncidentRepositoryException(
          'Preview withdrawal failed.');
    }
    withdrawals++;
    withdrawn = true;
  }
}

class _MemoryTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(Uint8List.fromList(
          image.encodePng(image.Image(width: 1, height: 1))));
}
