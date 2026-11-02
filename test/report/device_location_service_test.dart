import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:scarborough_tortoise_watch/features/report/domain/location_service.dart';

void main() {
  late GeolocatorPlatform previous;
  setUp(() => previous = GeolocatorPlatform.instance);
  tearDown(() => GeolocatorPlatform.instance = previous);

  for (final stage in ['permission check', 'permission request', 'position']) {
    testWidgets('whole GPS deadline bounds $stage and discards late completion',
        (tester) async {
      final platform = _Platform(stage);
      GeolocatorPlatform.instance = platform;
      Object? failure;
      final request = const DeviceLocationService()
          .currentLocation()
          .then<void>((_) => fail('An expired request must not produce a fix'),
              onError: (Object error) {
        failure = error;
      });
      await tester.pump();
      await tester.pump(const Duration(seconds: 15));
      expect(failure, isA<LocationException>());
      expect((failure as LocationException).message,
          'Location took too long. Try again or place a pin.');
      final callsAtExpiry = platform.positionCalls;
      platform.permission.complete(LocationPermission.whileInUse);
      platform.position.complete(_position);
      await tester.pump();
      await request;
      expect(platform.positionCalls, callsAtExpiry);
    });
  }
  test('blocked permission explains browser recovery without requesting a fix',
      () async {
    final platform = _Platform('blocked');
    GeolocatorPlatform.instance = platform;
    await expectLater(
        const DeviceLocationService().currentLocation(),
        throwsA(isA<LocationException>().having(
            (error) => error.message,
            'recovery',
            'Location access is blocked. Allow location for this site in your browser, or place a pin.')));
    expect(platform.positionCalls, 0);
  });
}

final _position = Position(
    latitude: 0,
    longitude: 0,
    timestamp: DateTime(2026),
    accuracy: 10,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0);

class _Platform extends GeolocatorPlatform {
  _Platform(this.stage);
  final String stage;
  final permission = Completer<LocationPermission>();
  final position = Completer<Position>();
  int positionCalls = 0;
  @override
  Future<bool> isLocationServiceEnabled() async => true;
  @override
  Future<LocationPermission> checkPermission() async => switch (stage) {
        'permission check' => await permission.future,
        'permission request' => LocationPermission.denied,
        'blocked' => LocationPermission.deniedForever,
        _ => LocationPermission.whileInUse,
      };
  @override
  Future<LocationPermission> requestPermission() => permission.future;
  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    positionCalls++;
    return position.future;
  }
}
