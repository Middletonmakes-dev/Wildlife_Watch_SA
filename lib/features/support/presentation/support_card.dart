import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SupportCardPage extends StatelessWidget {
  const SupportCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support the project'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.favorite_border, size: 48),
                  const SizedBox(height: 12),
                  Text('Support the project',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                    'A future support option may help with hosting, mapping, storage and conservation work. Payment processing is intentionally not enabled yet.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                      onPressed: null,
                      child: const Text('Support option coming later')),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
