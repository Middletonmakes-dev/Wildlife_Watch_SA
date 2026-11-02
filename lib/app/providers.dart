import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';

import '../features/report/data/incident_repository.dart';
import '../features/report/data/photo_storage.dart';
import '../features/report/domain/location_service.dart';
import '../features/map/data/public_incident_repository.dart';
import '../features/admin/data/admin_repository.dart';
import '../features/admin/data/auth_repository.dart';
import '../features/report/data/owner_incident_repository.dart';
import 'config/app_config.dart';

final appConfigProvider =
    Provider<AppConfig>((ref) => AppConfig.fromEnvironment());

// Each map owns its tile provider; tests can supply in-memory tiles.
final mapTileProviderFactoryProvider =
    Provider<TileProvider Function()>((ref) => () => NetworkTileProvider());

final incidentRepositoryProvider = Provider<IncidentRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useFirebase) return const FirebaseIncidentRepository();
  return DemoIncidentRepository();
});

final photoStorageProvider = Provider<PhotoStorage>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.useFirebase) return const FirebasePhotoStorage();
  return DemoPhotoStorage();
});

final locationServiceProvider = Provider<LocationService>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.useFirebase || config.demoDeviceGps
      ? const DeviceLocationService()
      : const DemoLocationService();
});

final publicIncidentRepositoryProvider =
    Provider<PublicIncidentRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.useFirebase
      ? FirebasePublicIncidentRepository()
      : const DemoPublicIncidentRepository();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.useFirebase
      ? const FirebaseAdminRepository()
      : const DemoAdminRepository();
});

final ownerIncidentRepositoryProvider =
    Provider<OwnerIncidentRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.useFirebase
      ? const FirebaseOwnerIncidentRepository()
      : const DemoOwnerIncidentRepository();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.useFirebase
      ? FirebaseAuthRepository()
      : const DemoAuthRepository();
});
