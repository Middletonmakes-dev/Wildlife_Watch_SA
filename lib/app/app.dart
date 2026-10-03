import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'providers.dart';
import 'theme/app_theme.dart';

class ScarboroughTortoiseWatchApp extends ConsumerStatefulWidget {
  const ScarboroughTortoiseWatchApp({super.key});

  @override
  ConsumerState<ScarboroughTortoiseWatchApp> createState() => _AppState();
}

class _AppState extends ConsumerState<ScarboroughTortoiseWatchApp> {
  late final router = buildRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: ref.watch(appConfigProvider).appName,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
