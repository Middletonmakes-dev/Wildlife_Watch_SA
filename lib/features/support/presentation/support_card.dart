import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/config/external_links.dart';
import '../../../app/theme/external_link_button.dart';

class SupportCardPage extends StatelessWidget {
  const SupportCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support the project'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: SingleChildScrollView(
          child: Center(
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
                    'If you would like to support Good Spotting, you can make an optional contribution via SnapScan. Reporting sightings is free.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ExternalLinkButton(
                      label: 'Support via SnapScan',
                      url: ExternalLinks.support),
                  const Text('Opens SnapScan in a new tab',
                      textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
      )),
    );
  }
}
