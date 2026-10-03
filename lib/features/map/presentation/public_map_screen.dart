import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/providers.dart';
import '../domain/map_provider.dart';
import '../domain/public_incident.dart';

class PublicMapScreen extends ConsumerStatefulWidget {
  const PublicMapScreen({super.key});

  @override
  ConsumerState<PublicMapScreen> createState() => _PublicMapScreenState();
}

class _PublicMapScreenState extends ConsumerState<PublicMapScreen> {
  String? _filter;
  DateTime? _from;
  DateTime? _to;
  late Future<List<PublicIncident>> _incidents;
  late final TileProvider _tileProvider;

  @override
  void initState() {
    super.initState();
    _tileProvider = ref.read(mapTileProviderFactoryProvider)();
    _reload();
  }

  void _reload() {
    _incidents = ref.read(publicIncidentRepositoryProvider).list(
          typeFilter: _filter,
          from: _from,
          to: _to,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Public sightings map'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              ref.watch(appConfigProvider).isDemo
                  ? 'Demo mode · synthetic markers only. Public locations are privacy-protected.'
                  : 'Privacy-protected accepted sightings · latest 500 records. Exact locations stay private.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          _FilterBar(
            filter: _filter,
            from: _from,
            to: _to,
            onFilter: (value) {
              setState(() {
                _filter = value;
                _reload();
              });
            },
            onDateRange: (range) {
              setState(() {
                _from = range?.start;
                _to = range?.end;
                _reload();
              });
            },
          ),
          Expanded(
            child: FutureBuilder<List<PublicIncident>>(
              future: _incidents,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Sightings could not be loaded.'));
                }
                final incidents = snapshot.data ?? const <PublicIncident>[];
                return FlutterMap(
                  options: MapOptions(
                    initialCenter: ref.read(appConfigProvider).mapCentre,
                    initialZoom: ref.read(appConfigProvider).initialMapZoom,
                  ),
                  children: <Widget>[
                    TileLayer(
                      tileProvider: _tileProvider,
                      urlTemplate: const OpenStreetMapProvider().tileUrl,
                      userAgentPackageName: 'za.scarborough.tortoise_watch',
                    ),
                    MarkerLayer(
                      markers: incidents
                          .map(
                            (incident) => Marker(
                              point: LatLng(
                                incident.displayLatitude,
                                incident.displayLongitude,
                              ),
                              width: 44,
                              height: 44,
                              child: Icon(
                                incident.incidentType ==
                                        PublicIncidentType.deadRoadkill
                                    ? Icons.warning_amber
                                    : Icons.eco,
                                color: incident.incidentType ==
                                        PublicIncidentType.deadRoadkill
                                    ? Colors.red
                                    : Colors.green,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        margin: const EdgeInsets.all(8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        color: Colors.white.withValues(alpha: 0.9),
                        child: Text(const OpenStreetMapProvider().attribution),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.filter,
    required this.from,
    required this.to,
    required this.onFilter,
    required this.onDateRange,
  });

  final String? filter;
  final DateTime? from;
  final DateTime? to;
  final ValueChanged<String?> onFilter;
  final ValueChanged<DateTimeRange?> onDateRange;

  @override
  Widget build(BuildContext context) {
    final dateLabel = from == null || to == null
        ? 'Date range'
        : '${from!.toIso8601String().substring(0, 10)} – ${to!.toIso8601String().substring(0, 10)}';
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: <Widget>[
          for (final filterOption in <({String? value, String label})>[
            (value: null, label: 'All'),
            (value: 'alive', label: 'Alive'),
            (value: 'injured', label: 'Injured'),
            (value: 'dead_roadkill', label: 'Roadkill'),
          ])
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filterOption.label),
                selected: filter == filterOption.value,
                onSelected: (_) => onFilter(filterOption.value),
              ),
            ),
          OutlinedButton.icon(
            onPressed: () async {
              final selected = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                initialDateRange: from != null && to != null
                    ? DateTimeRange(start: from!, end: to!)
                    : null,
              );
              if (selected != null) onDateRange(selected);
            },
            icon: const Icon(Icons.date_range),
            label: Text(dateLabel),
          ),
        ],
      ),
    );
  }
}
