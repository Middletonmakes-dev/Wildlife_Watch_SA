import 'package:latlong2/latlong.dart';
import 'branding.dart';

class AppConfig {
  const AppConfig({
    this.useFirebase = false,
    this.demoDeviceGps = false,
    this.publicRadiusMinMetres = 20,
    this.publicRadiusMaxMetres = 50,
    this.photoMaxBytes = 2 * 1024 * 1024,
    this.photoMaxLongestEdge = 1600,
    this.supportUrl,
  });

  factory AppConfig.fromEnvironment() => AppConfig(
        useFirebase:
            const bool.fromEnvironment('USE_FIREBASE', defaultValue: false),
        demoDeviceGps:
            const bool.fromEnvironment('DEMO_DEVICE_GPS', defaultValue: false),
        publicRadiusMinMetres: double.tryParse(const String.fromEnvironment(
                'PUBLIC_COORDINATE_RADIUS_MIN_METRES')) ??
            20,
        publicRadiusMaxMetres: double.tryParse(const String.fromEnvironment(
                'PUBLIC_COORDINATE_RADIUS_MAX_METRES')) ??
            50,
        photoMaxBytes: const int.fromEnvironment(
          'PHOTO_MAX_BYTES',
          defaultValue: 2 * 1024 * 1024,
        ),
        photoMaxLongestEdge: const int.fromEnvironment(
          'PHOTO_MAX_LONGEST_EDGE',
          defaultValue: 1600,
        ),
        supportUrl:
            const String.fromEnvironment('SUPPORT_URL', defaultValue: ''),
      );

  final bool useFirebase;
  final bool demoDeviceGps;
  // Legacy client settings are unused by public projections. Trusted Functions
  // own the publication delay and 100–250 m displacement for new projections.
  final double publicRadiusMinMetres;
  final double publicRadiusMaxMetres;
  final int photoMaxBytes;
  final int photoMaxLongestEdge;
  final String? supportUrl;

  String get appName => applicationName;
  String get geographicFocus => 'Scarborough, Cape Town';
  LatLng get mapCentre => const LatLng(-34.197, 18.375);
  double get initialMapZoom => 14;
  double get reportMapZoom => 17;
  bool get isDemo => !useFirebase;
}
