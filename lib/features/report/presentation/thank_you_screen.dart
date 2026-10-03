import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/config/guidance.dart';
import '../domain/incident.dart';

class ThankYouData {
  const ThankYouData({
    this.message,
    this.hasPhoto = false,
    this.photoUploaded = false,
    this.demo = false,
    this.incidentType,
    this.retryPhoto,
  });

  final String? message;
  final bool hasPhoto;
  final bool photoUploaded;
  final bool demo;
  final IncidentType? incidentType;
  final Future<bool> Function()? retryPhoto;
}

class ThankYouScreen extends StatefulWidget {
  const ThankYouScreen({super.key});

  @override
  State<ThankYouScreen> createState() => _ThankYouScreenState();
}

class _ThankYouScreenState extends State<ThankYouScreen> {
  bool _retrying = false;
  bool _photoRecovered = false;

  @override
  Widget build(BuildContext context) {
    final data = GoRouterState.of(context).extra as ThankYouData?;
    return Scaffold(
      appBar: AppBar(title: const Text('Thank you')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: <Widget>[
                const Icon(Icons.check_circle_outline,
                    size: 72, color: Colors.green),
                const SizedBox(height: 16),
                Text(
                    data?.message ?? 'No report was submitted in this session.',
                    style: Theme.of(context).textTheme.headlineMedium),
                if (data?.hasPhoto == true &&
                    data?.photoUploaded == false &&
                    !_photoRecovered) ...<Widget>[
                  const SizedBox(height: 8),
                  const Text(
                      'The core report was saved, but the optional photo could not be uploaded.'),
                  if (data?.retryPhoto != null)
                    TextButton(
                        onPressed: _retrying
                            ? null
                            : () async {
                                setState(() => _retrying = true);
                                final success = await data!.retryPhoto!();
                                if (!mounted) return;
                                setState(() {
                                  _retrying = false;
                                  _photoRecovered = success;
                                });
                              },
                        child: Text(_retrying
                            ? 'Retrying photo…'
                            : 'Retry optional photo')),
                ],
                if (_photoRecovered) const Text('Photo uploaded.'),
                const SizedBox(height: 16),
                if (data?.incidentType == IncidentType.aliveCrossingRoad ||
                    data?.incidentType == IncidentType.aliveNearRoad)
                  const Text(ConservationGuidance.roadSafety),
                const SizedBox(height: 8),
                Text(
                  ConservationGuidance.draftNotice,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                if (data?.demo == true) ...<Widget>[
                  const SizedBox(height: 8),
                  const Text(
                      'Demo mode: this report stayed local to the browser.'),
                ],
                const SizedBox(height: 24),
                OutlinedButton(
                    onPressed: () => context.go('/map'),
                    child: const Text('View sightings map')),
                const SizedBox(height: 8),
                TextButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Back to home')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
