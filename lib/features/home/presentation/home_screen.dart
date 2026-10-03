import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/guidance.dart';
import '../../../app/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return Scaffold(
      appBar: AppBar(title: Text(config.appName)),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 620),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (config.isDemo) const _DemoBanner(),
                  Text(
                      'Help us understand tortoise crossings in ${config.geographicFocus}.',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  const Text(
                    'A quick report helps build useful local evidence while keeping exact locations private.',
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => context.go('/report'),
                    icon: const Icon(Icons.edit_location_alt),
                    label: const Text('Report a tortoise'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/map'),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('View sightings map'),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('If you see a live tortoise',
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          const Text(ConservationGuidance.roadSafety),
                          const SizedBox(height: 8),
                          Text(
                            ConservationGuidance.draftNotice,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => context.go('/support'),
                    icon: const Icon(Icons.favorite_border),
                    label: const Text('Support the project'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
            'Demo mode: reports stay local to this browser and use synthetic map data.'),
      ),
    );
  }
}
