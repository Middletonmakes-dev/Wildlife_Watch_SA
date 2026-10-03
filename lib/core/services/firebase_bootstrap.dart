import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

import '../../app/config/app_config.dart';

class FirebaseSetupException implements Exception {
  const FirebaseSetupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<void> initialize(AppConfig config,
      {FirebaseOptions? options}) async {
    if (!config.useFirebase) return;
    if (options == null) {
      throw const FirebaseSetupException(
          'Firebase is enabled without generated options. Follow docs/DEVELOPMENT.md to configure the Firebase entry point.');
    }
    const useEmulators = bool.fromEnvironment('USE_FIREBASE_EMULATORS');
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: options);
      }
      FirebaseFirestore.instance.settings =
          const Settings(persistenceEnabled: false);
      if (kIsWeb && !useEmulators) {
        final appCheckKey = const String.fromEnvironment('APP_CHECK_WEB_KEY');
        if (appCheckKey.isEmpty) {
          throw const FirebaseSetupException(
            'Firebase is enabled but APP_CHECK_WEB_KEY is missing; App Check is required.',
          );
        }
        await FirebaseAppCheck.instance.activate(
          webProvider: ReCaptchaV3Provider(appCheckKey),
        );
      }
      if (useEmulators) {
        const host = String.fromEnvironment('FIREBASE_EMULATOR_HOST',
            defaultValue: '127.0.0.1');
        if (!options.projectId.startsWith('demo-'))
          throw const FirebaseSetupException(
              'Local emulators require a demo- project ID.');
        FirebaseFirestore.instance.useFirestoreEmulator(
            host,
            const int.fromEnvironment('FIRESTORE_EMULATOR_PORT',
                defaultValue: 18080));
        await FirebaseAuth.instance.useAuthEmulator(
            host,
            const int.fromEnvironment('AUTH_EMULATOR_PORT',
                defaultValue: 19099));
        FirebaseFunctions.instance.useFunctionsEmulator(
            host,
            const int.fromEnvironment('FUNCTIONS_EMULATOR_PORT',
                defaultValue: 15001));
        FirebaseStorage.instance.useStorageEmulator(
            host,
            const int.fromEnvironment('STORAGE_EMULATOR_PORT',
                defaultValue: 19199));
      }
    } on Object catch (_) {
      throw const FirebaseSetupException(
        'Firebase setup is incomplete. Run flutterfire configure and provide App Check configuration, then retry.',
      );
    }
  }
}
