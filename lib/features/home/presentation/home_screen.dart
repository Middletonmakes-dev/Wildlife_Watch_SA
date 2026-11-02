import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/config/guidance.dart';
import '../../../app/config/external_links.dart';
import '../../../app/theme/external_link_button.dart';
import '../../../app/providers.dart';
import '../../../app/theme/journal_widgets.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    return Scaffold(
      appBar:
          AppBar(title: const JournalBrand(), automaticallyImplyLeading: false),
      bottomNavigationBar: JournalNavigation(selected: 0, demo: config.isDemo),
      body: SafeArea(
          child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Divider(),
                          const Padding(
                              padding: EdgeInsets.symmetric(vertical: 13),
                              child: Text('SCARBOROUGH TORTOISE WATCH',
                                  style: TextStyle(
                                      fontSize: 11, letterSpacing: 1.25))),
                          SizedBox(
                              height: MediaQuery.sizeOf(context).height < 780
                                  ? 175
                                  : 220,
                              child: Image.asset(
                                  'assets/images/tortoise-real.jpeg',
                                  fit: BoxFit.cover,
                                  semanticLabel: 'Tortoise walking on gravel')),
                          const SizedBox(height: 15),
                          Text('A small sighting.\nA useful record.',
                              style:
                                  Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 13),
                          const Text(
                              'Your sightings help identify tortoise crossing and roadkill hotspots, '
                              'building the evidence we need to propose practical, local solutions.'),
                          const SizedBox(height: 18),
                          ElevatedButton(
                              onPressed: () => context.go('/report'),
                              child: const Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Text('Report a tortoise')),
                                    Icon(Icons.arrow_forward, size: 20)
                                  ])),
                          const SizedBox(height: 12),
                          const Divider(),
                          TextButton(
                              onPressed: () => context.go('/map'),
                              child: const Text('Explore the public map  →')),
                          TextButton(
                              onPressed: () => context.go('/your-reports'),
                              child: const Text('View your reports  →')),
                          const Divider(),
                          const SizedBox(height: 18),
                          ExpansionTile(
                              tilePadding: EdgeInsets.zero,
                              title: const Text('If you see a live tortoise'),
                              children: [
                                const Text(ConservationGuidance.roadSafety),
                              ]),
                          TextButton(
                              onPressed: () => context.go('/support'),
                              child: const Text('Support the project')),
                          ExternalLinkButton(
                              label: 'See more projects by Good Spotting',
                              url: ExternalLinks.website),
                        ])),
              ))),
    );
  }
}
