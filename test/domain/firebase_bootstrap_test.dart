import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
// Existing SDK platform interface is used only to exercise the bootstrap boundary.
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scarborough_tortoise_watch/app/config/app_config.dart';
import 'package:scarborough_tortoise_watch/core/services/firebase_bootstrap.dart';

void main() {
  test('bootstrap loads the SDK before any browser app-list lookup', () async {
    final previous = Firebase.delegatePackingProperty;
    final platform = _FreshBrowserFirebase();
    Firebase.delegatePackingProperty = platform;
    addTearDown(() => Firebase.delegatePackingProperty = previous);
    await FirebaseBootstrap.initialize(const AppConfig(useFirebase: true),
        options: _options);
    expect(platform.initializeCalls, 1);
    expect(platform.appsReads, 0);
  });

  test('bootstrap runs the auth redirect handoff after Firebase setup',
      () async {
    final previous = Firebase.delegatePackingProperty;
    Firebase.delegatePackingProperty = _FreshBrowserFirebase();
    addTearDown(() => Firebase.delegatePackingProperty = previous);
    var handoffCalls = 0;
    await FirebaseBootstrap.initialize(
      const AppConfig(useFirebase: true),
      options: _options,
      onFirebaseReady: () async => handoffCalls++,
    );
    expect(handoffCalls, 1);
  });
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

const _options = FirebaseOptions(
    apiKey: 'synthetic-key',
    appId: 'synthetic-app',
    messagingSenderId: 'synthetic-sender',
    projectId: 'demo-startup-test');

class _FreshBrowserFirebase extends FirebasePlatform {
  int initializeCalls = 0;
  int appsReads = 0;
  @override
  List<FirebaseAppPlatform> get apps {
    appsReads++;
    throw StateError(
        "can't access property getApps, firebase_core is undefined");
  }

  @override
  Future<FirebaseAppPlatform> initializeApp(
      {String? name, FirebaseOptions? options}) async {
    initializeCalls++;
    return FirebaseAppPlatform('[DEFAULT]', options!);
  }

  @override
  FirebaseAppPlatform app([String name = '[DEFAULT]']) =>
      FirebaseAppPlatform(name, _options);
}
