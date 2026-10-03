import 'package:firebase_app_check/firebase_app_check.dart';
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
  test('web App Check uses the Fraud Defense provider', () {
    expect(
      FirebaseBootstrap.webAppCheckProvider('site-key'),
      isA<ReCaptchaEnterpriseProvider>(),
    );
  });
}
