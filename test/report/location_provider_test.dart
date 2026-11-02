import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scarborough_tortoise_watch/app/config/app_config.dart';
import 'package:scarborough_tortoise_watch/app/providers.dart';
import 'package:scarborough_tortoise_watch/features/report/domain/location_service.dart';
import 'package:scarborough_tortoise_watch/features/report/data/incident_repository.dart';
import 'package:scarborough_tortoise_watch/features/report/data/photo_storage.dart';
import 'package:scarborough_tortoise_watch/features/map/data/public_incident_repository.dart';

void main() {
  test('preview GPS opt-in changes only the location service', () {
    final container = ProviderContainer(overrides: [
      appConfigProvider.overrideWithValue(AppConfig.fromEnvironment()),
    ]);
    addTearDown(container.dispose);
    const enabled = bool.fromEnvironment('DEMO_DEVICE_GPS');
    expect(container.read(locationServiceProvider),
        enabled ? isA<DeviceLocationService>() : isA<DemoLocationService>());
    expect(container.read(incidentRepositoryProvider),
        isA<DemoIncidentRepository>());
    expect(container.read(photoStorageProvider), isA<DemoPhotoStorage>());
    expect(container.read(publicIncidentRepositoryProvider),
        isA<DemoPublicIncidentRepository>());
  });
  test('ordinary demo constructor keeps GPS disabled', () {
    final container = ProviderContainer(overrides: [
      appConfigProvider.overrideWithValue(const AppConfig()),
    ]);
    addTearDown(container.dispose);
    expect(container.read(locationServiceProvider), isA<DemoLocationService>());
  });
}
