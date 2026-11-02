import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'app/config/app_config.dart';
import 'app/providers.dart';
import 'core/services/firebase_bootstrap.dart';
import 'features/admin/data/auth_repository.dart';

Future<void> main() => launchApp();

Future<void> launchApp({FirebaseOptions? firebaseOptions}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final config = AppConfig.fromEnvironment();
  final AuthRepository authRepository = config.useFirebase
      ? FirebaseAuthRepository()
      : const DemoAuthRepository();
  try {
    await FirebaseBootstrap.initialize(
      config,
      options: firebaseOptions,
      onFirebaseReady: authRepository.processRedirectResult,
    );
  } on FirebaseSetupException catch (error) {
    runApp(_SetupErrorApp(message: error.message));
    return;
  }
  runApp(
    ProviderScope(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(authRepository),
      ],
      child: const ScarboroughTortoiseWatchApp(),
    ),
  );
}

class _SetupErrorApp extends StatelessWidget {
  const _SetupErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
            child: Padding(
                padding: const EdgeInsets.all(24), child: Text(message))),
      ),
    );
  }
}
