import 'package:flutter_test/flutter_test.dart';
import 'package:scarborough_tortoise_watch/app/config/app_config.dart';
import 'package:scarborough_tortoise_watch/core/services/firebase_bootstrap.dart';

void main() {
  test('demo requires no generated Firebase options', () async {
    await FirebaseBootstrap.initialize(const AppConfig());
  });
  test('Firebase mode fails closed before any SDK call without options',
      () async {
    await expectLater(
        FirebaseBootstrap.initialize(const AppConfig(useFirebase: true)),
        throwsA(isA<FirebaseSetupException>()));
  });
}
