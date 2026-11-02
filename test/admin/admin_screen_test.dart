import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:scarborough_tortoise_watch/app/providers.dart';
import 'package:scarborough_tortoise_watch/features/admin/data/admin_repository.dart';
import 'package:scarborough_tortoise_watch/features/admin/data/auth_repository.dart';
import 'package:scarborough_tortoise_watch/features/admin/data/csv_exporter.dart';
import 'package:scarborough_tortoise_watch/features/admin/presentation/admin_screen.dart';

void main() {
  testWidgets(
      'publication operation errors preserve the private admin view while denial removes it',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final error in <Exception>[
      PublicationNotReadyException('2030-01-08'),
      const IncidentWithdrawnException(),
      const AdminRepositoryException(
          'The moderation change could not be saved. Please try again.'),
      const AdminAuthorisationException(),
    ]) {
      await tester.pumpWidget(const SizedBox());
      final auth = _FakeAuthRepository()..access = true;
      final repository = _FakeAdminRepository(
          records: [_record('one', 'pending', -34.197, 18.375, 'injured')])
        ..moderationFailure = error;
      await _pumpAdmin(tester, auth, repository);
      await tester.tap(find.byTooltip('Moderate report'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Approve'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();
      if (error is AdminAuthorisationException) {
        expect(find.text('Private exact locations · latest 500 reports'),
            findsNothing);
      } else {
        expect(find.text('Private exact locations · latest 500 reports'),
            findsOneWidget);
        expect(find.text((error as AdminRepositoryException).message),
            findsOneWidget);
        expect(repository.watchCount, 1);
      }
    }
  });
  testWidgets(
      'anonymous users see Google sign-in without a false signed-in claim',
      (tester) async {
    final auth = _FakeAuthRepository()
      ..access = false
      ..user = _AnonymousUser();
    final repository = _FakeAdminRepository();
    await _pumpAdmin(tester, auth, repository);

    expect(find.text('Authorised access only'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(
      find.textContaining('This Google account is signed in'),
      findsNothing,
    );
    expect(find.byTooltip('Sign out'), findsNothing);
  });

  testWidgets('anonymous redirect failures stay visible without signing out',
      (tester) async {
    final auth = _FakeAuthRepository()
      ..user = _AnonymousUser()
      ..redirectFailure =
          'That Google account is already attached elsewhere. Open a separate browser for admin access so this reporter account stays linked to its reports.';
    final repository = _FakeAdminRepository();
    await _pumpAdmin(tester, auth, repository);

    expect(find.textContaining('already attached elsewhere'), findsOneWidget);
    expect(find.text('Sign in with Google'), findsOneWidget);
    expect(find.byTooltip('Sign out'), findsNothing);
  });

  testWidgets('ungranted admin access never subscribes to private records',
      (tester) async {
    final auth = _FakeAuthRepository()..access = false;
    final repository = _FakeAdminRepository();
    await _pumpAdmin(tester, auth, repository);

    expect(find.text('Authorised access only'), findsOneWidget);
    expect(repository.watchCount, 0);
    expect(auth.forceRefreshes, everyElement(false));

    await tester.tap(find.text('Check access again'));
    await tester.pump();
    expect(auth.forceRefreshes, contains(true));
  });

  testWidgets('ID-token claim changes revoke private UI without a refresh loop',
      (tester) async {
    final auth = _FakeAuthRepository()..access = true;
    final repository = _FakeAdminRepository();
    await _pumpAdmin(tester, auth, repository);
    expect(find.text('Private exact locations · latest 500 reports'),
        findsOneWidget);

    auth.access = false;
    auth.tokenEvents.add(null);
    await tester.pump();
    await tester.pump();

    expect(find.text('Authorised access only'), findsOneWidget);
    expect(auth.forceRefreshes, everyElement(false),
        reason: 'automatic token events must not force another refresh');
    expect(repository.watchCount, 1);
  });

  testWidgets('stale authorised access completion cannot restore private UI',
      (tester) async {
    final auth = _FakeAuthRepository();
    final repository = _FakeAdminRepository();
    await _pumpAdmin(tester, auth, repository);

    final stale = Completer<bool>();
    auth.pending = stale;
    auth.tokenEvents.add(null);
    await tester.pump();
    auth.access = false;
    auth.tokenEvents.add(null);
    await tester.pump();
    stale.complete(true);
    await tester.pump();

    expect(find.text('Authorised access only'), findsOneWidget);
    expect(find.text('Private exact locations · latest 500 reports'),
        findsNothing);
  });

  testWidgets('admin map keeps live records, filters, fit and named markers',
      (tester) async {
    final repository = _FakeAdminRepository(records: <AdminIncidentRecord>[
      _record('pending-one', 'pending', -34.197, 18.375, 'injured'),
    ]);
    await _pumpMap(tester, repository);

    expect(find.text('Demo / synthetic data · no production records are shown'),
        findsOneWidget);
    expect(
        find.bySemanticsLabel('Injured tortoise Pending private report marker'),
        findsOneWidget);

    repository.emit(<AdminIncidentRecord>[
      _record('pending-one', 'pending', -34.197, 18.375, 'injured'),
      _record('accepted-one', 'accepted', -34.45, 18.08, 'alive_near_road'),
    ]);
    await tester.pump();
    expect(find.text('Live tortoise near road · Accepted'), findsNothing);

    await tester.tap(find.text('All active'));
    await tester.pump();
    expect(repository.watchCount, 2);
    repository.emit(repository.records);
    await tester.pump();
    expect(find.text('Live tortoise near road · Accepted'), findsOneWidget);
    await tester.tap(find.text('Fit reports'));
    await tester.pump();
  });

  test('moderation repository success and error stay explicit', () async {
    final repository = _FakeAdminRepository(records: <AdminIncidentRecord>[
      _record('pending-one', 'pending', -34.197, 18.375, 'injured'),
    ]);
    await repository.setModeration(
        incidentId: 'pending-one', status: 'rejected');
    expect(repository.records.single.status, 'rejected');

    repository.failModeration = true;
    await expectLater(
      repository.setModeration(incidentId: 'pending-one', status: 'accepted'),
      throwsA(isA<AdminRepositoryException>()),
    );
  });

  test('Google credential conflicts have a recovery message', () {
    expect(
      authErrorMessage(
          FirebaseAuthException(code: 'credential-already-in-use')),
      contains('separate browser'),
    );
  });
}

Future<void> _pumpAdmin(
  WidgetTester tester,
  _FakeAuthRepository auth,
  _FakeAdminRepository repository,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(auth),
        adminRepositoryProvider.overrideWithValue(repository),
        mapTileProviderFactoryProvider.overrideWithValue(() => _MemoryTiles()),
      ],
      child: const MaterialApp(home: AdminScreen()),
    ),
  );
  await tester.pump();
  await tester.pump();
}

Future<void> _pumpMap(
    WidgetTester tester, _FakeAdminRepository repository) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: AdminMapView(
          repository: repository,
          showDemoBanner: true,
          tileProvider: _MemoryTiles(),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

AdminIncidentRecord _record(
  String id,
  String status,
  double latitude,
  double longitude,
  String incidentType,
) =>
    AdminIncidentRecord(
      id: id,
      createdAt: '2026-10-04T08:00:00Z',
      latitude: latitude,
      longitude: longitude,
      incidentType: incidentType,
      status: status,
    );

class _FakeAdminRepository implements AdminRepository {
  _FakeAdminRepository({List<AdminIncidentRecord>? records})
      : records = records ?? <AdminIncidentRecord>[];

  List<AdminIncidentRecord> records;
  final _changes = StreamController<List<AdminIncidentRecord>>.broadcast();
  int watchCount = 0;
  bool failModeration = false;
  Exception? moderationFailure;

  void emit(List<AdminIncidentRecord> next) {
    records = next;
    _changes.add(next);
  }

  @override
  Future<bool> isAuthorised() async => true;

  @override
  Future<List<AdminIncidentRecord>> loadIncidents() async => records;

  @override
  Stream<List<AdminIncidentRecord>> watchIncidents({
    Set<String> statuses = const <String>{'pending'},
  }) async* {
    watchCount++;
    yield records.where((record) => statuses.contains(record.status)).toList();
    await for (final next in _changes.stream) {
      yield next.where((record) => statuses.contains(record.status)).toList();
    }
  }

  @override
  Future<void> setModeration({
    required String incidentId,
    required String status,
  }) async {
    if (moderationFailure != null) throw moderationFailure!;
    if (failModeration) {
      throw const AdminRepositoryException(
          'The moderation change could not be saved. Please try again.');
    }
    emit(records
        .map((record) => record.id == incidentId
            ? AdminIncidentRecord(
                id: record.id,
                createdAt: record.createdAt,
                latitude: record.latitude,
                longitude: record.longitude,
                incidentType: record.incidentType,
                status: status,
                note: record.note,
              )
            : record)
        .toList());
  }
}

class _FakeAuthRepository implements AuthRepository {
  final authEvents = StreamController<User?>.broadcast();
  final tokenEvents = StreamController<User?>.broadcast();
  final forceRefreshes = <bool>[];
  User? user;
  String? redirectFailure;
  bool access = false;
  Completer<bool>? pending;

  @override
  User? get currentUser => user;

  @override
  String? get redirectError => redirectFailure;

  @override
  Stream<User?> get authStateChanges => authEvents.stream;

  @override
  Stream<User?> get idTokenChanges => tokenEvents.stream;

  @override
  Future<void> signInWithGoogle() async {}

  @override
  Future<void> processRedirectResult() async {}

  @override
  Future<bool> checkAccess({bool forceRefresh = false}) async {
    forceRefreshes.add(forceRefresh);
    final wait = pending;
    if (wait != null) {
      pending = null;
      return wait.future;
    }
    return access;
  }

  @override
  Future<void> signOut() async {}
}

class _AnonymousUser implements User {
  @override
  bool get isAnonymous => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MemoryTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(Uint8List.fromList(
          image.encodePng(image.Image(width: 1, height: 1))));
}
