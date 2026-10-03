import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app/app.dart';
import 'app/config/app_config.dart';
import 'core/services/firebase_bootstrap.dart';

Future<void> main() => launchApp();

Future<void> launchApp({FirebaseOptions? firebaseOptions}) async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await FirebaseBootstrap.initialize(AppConfig.fromEnvironment(),
        options: firebaseOptions);
  } on FirebaseSetupException catch (error) {
    runApp(_SetupErrorApp(message: error.message));
    return;
  }
  runApp(const ProviderScope(child: ScarboroughTortoiseWatchApp()));
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
