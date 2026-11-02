import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/providers.dart';
import '../../../app/theme/app_theme.dart';
import '../../../app/theme/journal_widgets.dart';
import '../domain/map_provider.dart';
import '../domain/public_incident.dart';
import '../../report/data/owner_incident_repository.dart';
import 'tortoise_map_marker.dart';

class PublicMapScreen extends ConsumerStatefulWidget {
  const PublicMapScreen({super.key});

  @override
  ConsumerState<PublicMapScreen> createState() => _PublicMapScreenState();
}

class _PublicMapScreenState extends ConsumerState<PublicMapScreen> {
  String? _filter;
  DateTime? _from;
  DateTime? _to;
  late Future<_PublicMapData> _incidents;
  late final TileProvider _tileProvider;

  @override
  void initState() {
    super.initState();
    _tileProvider = ref.read(mapTileProviderFactoryProvider)();
    _reload();
  }

  void _reload({bool forceRefresh = false}) {
    _incidents = _loadMapData(forceRefresh: forceRefresh);
  }

  Future<_PublicMapData> _loadMapData({required bool forceRefresh}) async {
    final incidents = await ref.read(publicIncidentRepositoryProvider).list(
          typeFilter: _filter,
          from: _from,
          to: _to,
          forceRefresh: forceRefresh,
        );
    try {
      final owned = await ref.read(ownerIncidentRepositoryProvider).list();
      return _PublicMapData(
        incidents: incidents,
        ownActiveIds: owned.reports
            .where((receipt) => receipt.canWithdraw)
            .map((receipt) => receipt.id)
            .toSet(),
      );
    } catch (_) {
      // The public map remains useful when the owner-only lookup is unavailable.
      return _PublicMapData(
          incidents: incidents, ownActiveIds: const <String>{});
    }
  }

  Future<void> _showMarkerDetails(
      PublicIncident incident, Set<String> ownActiveIds) async {
    final canWithdraw = ownActiveIds.contains(incident.id);
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(incident.incidentType.label,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Text('Approximate historical location · ${incident.date}'),
              if (canWithdraw) ...<Widget>[
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await _withdrawMarker(incident);
                  },
                  child: const Text('Withdraw this report'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _withdrawMarker(PublicIncident incident) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Withdraw this report?'),
        content: const Text(
            'It will be removed from the public map and active analysis. The private audit record will be retained as Withdrawn.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Withdraw report'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ref.read(ownerIncidentRepositoryProvider).withdraw(incident.id);
      if (!mounted) return;
      setState(() => _reload(forceRefresh: true));
    } on OwnerIncidentRepositoryException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    return Scaffold(
      appBar: AppBar(
        title: const JournalBrand(),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Refresh sightings',
            onPressed: () => setState(() => _reload(forceRefresh: true)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      bottomNavigationBar: JournalNavigation(selected: 2, demo: config.isDemo),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(),
                    const Padding(
                        padding: EdgeInsets.symmetric(vertical: 13),
                        child: Text('SCARBOROUGH TORTOISE WATCH',
                            style:
                                TextStyle(fontSize: 11, letterSpacing: 1.25))),
                    Text('Sightings, in context.',
                        style: Theme.of(context).textTheme.headlineMedium),
                  ])),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Text(
              ref.watch(appConfigProvider).isDemo
                  ? 'Demo mode · synthetic markers only. Public locations are privacy-protected.'
                  : 'Approximate historical sightings · latest 500 records. Markers are not exact crossing locations.',
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
            child: FutureBuilder<_PublicMapData>(
              future: _incidents,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Sightings could not be loaded.'),
                        TextButton(
                          onPressed: () =>
                              setState(() => _reload(forceRefresh: true)),
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  );
                }
                final data = snapshot.data ??
                    const _PublicMapData(
                        incidents: <PublicIncident>[],
                        ownActiveIds: <String>{});
                final incidents = data.incidents;
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
                              child: GestureDetector(
                                onTap: () => _showMarkerDetails(
                                    incident, data.ownActiveIds),
                                child: Semantics(
                                  button: true,
                                  label:
                                      '${incident.incidentType.label} public sighting marker',
                                  child: TortoiseMapMarker(
                                    condition:
                                        TortoiseMarkerConditionX.fromCode(
                                            incident.incidentType.code),
                                  ),
                                ),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(
          children: <Widget>[
            for (final filterOption in <({String? value, String label})>[
              (value: null, label: 'All'),
              (value: 'alive', label: 'Alive'),
              (value: 'injured', label: 'Injured'),
              (value: 'dead_roadkill', label: 'Roadkill'),
            ])
              Expanded(
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          border: Border(
                              bottom: BorderSide(
                                  color: filter == filterOption.value
                                      ? AppTheme.rust
                                      : AppTheme.rule,
                                  width:
                                      filter == filterOption.value ? 2 : 1))),
                      child: TextButton(
                          onPressed: () => onFilter(filterOption.value),
                          child: Text(filterOption.label,
                              style: TextStyle(
                                  color: filter == filterOption.value
                                      ? AppTheme.rust
                                      : AppTheme.ink))))),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: OutlinedButton.icon(
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
        ),
      ]),
    );
  }
}

class _PublicMapData {
  const _PublicMapData({required this.incidents, required this.ownActiveIds});

  final List<PublicIncident> incidents;
  final Set<String> ownActiveIds;
}
