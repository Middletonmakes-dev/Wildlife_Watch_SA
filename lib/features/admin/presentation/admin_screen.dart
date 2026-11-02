import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../app/config/app_config.dart';
import '../../../app/providers.dart';
import '../../map/domain/map_provider.dart';
import '../../map/presentation/tortoise_map_marker.dart';
import '../data/admin_repository.dart';
import '../data/auth_repository.dart';
import '../data/csv_exporter.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  late final AuthRepository _auth;
  late final AdminRepository _repository;
  StreamSubscription<dynamic>? _authSubscription;
  StreamSubscription<dynamic>? _idTokenSubscription;
  int _accessCheckGeneration = 0;
  bool _checking = true;
  bool _authorised = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _auth = ref.read(authRepositoryProvider);
    _repository = ref.read(adminRepositoryProvider);
    _authSubscription =
        _auth.authStateChanges.listen((_) => unawaited(_checkAccess()));
    _idTokenSubscription =
        _auth.idTokenChanges.listen((_) => unawaited(_checkAccess()));
    unawaited(_checkAccess());
  }

  Future<void> _checkAccess({bool forceRefresh = false}) async {
    if (!mounted) return;
    final generation = ++_accessCheckGeneration;
    setState(() {
      _checking = true;
      _message = _auth.redirectError;
    });
    try {
      final authorised = await _auth.checkAccess(forceRefresh: forceRefresh);
      if (!mounted || generation != _accessCheckGeneration) return;
      setState(() {
        _authorised = authorised;
        _checking = false;
      });
    } on AuthRepositoryException catch (error) {
      if (!mounted || generation != _accessCheckGeneration) return;
      setState(() {
        _authorised = false;
        _checking = false;
        _message = error.message;
      });
    } catch (_) {
      if (!mounted || generation != _accessCheckGeneration) return;
      setState(() {
        _authorised = false;
        _checking = false;
        _message = 'Access could not be checked. Please try again.';
      });
    }
  }

  void _revokeAccess() {
    _accessCheckGeneration++;
    if (mounted)
      setState(() {
        _authorised = false;
        _checking = false;
      });
  }

  Future<void> _signIn() async {
    setState(() {
      _checking = true;
      _message = null;
    });
    try {
      await _auth.signInWithGoogle();
    } on AuthRepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _message = error.message;
      });
    }
  }

  Future<void> _signOut() async {
    _accessCheckGeneration++;
    if (mounted) {
      setState(() {
        _authorised = false;
        _checking = true;
        _message = null;
      });
    }
    await _auth.signOut();
    if (!mounted) return;
    setState(() {
      _authorised = false;
      _checking = false;
      _message = null;
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _idTokenSubscription?.cancel();
    _accessCheckGeneration++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    final signedIn = user != null && !user.isAnonymous;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Private admin map'),
        leading: BackButton(onPressed: () => context.go('/')),
        actions: <Widget>[
          if (signedIn)
            IconButton(
              tooltip: 'Sign out',
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
            ),
        ],
      ),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : _authorised
              ? AdminMapView(
                  repository: _repository,
                  showDemoBanner: ref.read(appConfigProvider).isDemo,
                  tileProvider: ref.read(mapTileProviderFactoryProvider)(),
                  onAccessDenied: _revokeAccess,
                )
              : _UnauthorisedAdmin(
                  signedIn: signedIn,
                  message: _message,
                  onSignIn: _signIn,
                  onRefresh: () => _checkAccess(forceRefresh: true),
                ),
    );
  }
}

class _UnauthorisedAdmin extends StatelessWidget {
  const _UnauthorisedAdmin({
    required this.signedIn,
    required this.message,
    required this.onSignIn,
    required this.onRefresh,
  });

  final bool signedIn;
  final String? message;
  final VoidCallback onSignIn;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.lock_outline, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    signedIn ? 'Access not granted' : 'Authorised access only',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    signedIn
                        ? 'This Google account is signed in, but an explicit admin or analyst custom claim is still required.'
                        : 'Sign in with Google to check access. Authentication alone never grants access to exact locations.',
                    textAlign: TextAlign.center,
                  ),
                  if (message != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(message!, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 16),
                  if (!signedIn)
                    ElevatedButton.icon(
                      onPressed: onSignIn,
                      icon: const Icon(Icons.login),
                      label: const Text('Sign in with Google'),
                    ),
                  OutlinedButton(
                    onPressed: onRefresh,
                    child: const Text('Check access again'),
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

class AdminMapView extends StatefulWidget {
  const AdminMapView({
    required this.repository,
    this.showDemoBanner = false,
    this.tileProvider,
    this.onAccessDenied,
    super.key,
  });

  final AdminRepository repository;
  final bool showDemoBanner;
  final TileProvider? tileProvider;
  final VoidCallback? onAccessDenied;

  @override
  State<AdminMapView> createState() => _AdminMapViewState();
}

class _AdminMapViewState extends State<AdminMapView> {
  final MapController _mapController = MapController();
  late TileProvider _tileProvider;
  late Stream<List<AdminIncidentRecord>> _recordsStream;
  Set<String> _statuses = const <String>{'pending'};
  AdminIncidentRecord? _selected;
  String? _error;
  bool _accessDenied = false;

  static const _activeStatuses = <String>{
    'pending',
    'accepted',
    'rejected',
    'duplicate',
  };

  @override
  void initState() {
    super.initState();
    _tileProvider = widget.tileProvider ?? NetworkTileProvider();
    _recordsStream = _watchRecords();
  }

  Stream<List<AdminIncidentRecord>> _watchRecords() =>
      widget.repository.watchIncidents(statuses: _statuses);

  void _setStatuses(Set<String> statuses) {
    setState(() {
      _statuses = statuses;
      _recordsStream = _watchRecords();
      _selected = null;
    });
  }

  @override
  void didUpdateWidget(covariant AdminMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tileProvider != widget.tileProvider) {
      _tileProvider = widget.tileProvider ?? NetworkTileProvider();
    }
    if (oldWidget.repository != widget.repository) {
      _recordsStream = _watchRecords();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _select(AdminIncidentRecord record) {
    setState(() => _selected = record);
    _mapController.move(LatLng(record.latitude, record.longitude), 16);
  }

  void _fitReports(List<AdminIncidentRecord> records) {
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('There are no reports in this view.')),
      );
      return;
    }
    _mapController.fitCamera(CameraFit.coordinates(
      coordinates: records
          .map((record) => LatLng(record.latitude, record.longitude))
          .toList(growable: false),
      padding: const EdgeInsets.all(48),
      maxZoom: 16,
    ));
  }

  Future<void> _moderate(AdminIncidentRecord record, String status) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${_moderationAction(status)} report?'),
        content: Text('Change this report to $status?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.repository
          .setModeration(incidentId: record.id, status: status);
      if (mounted) setState(() => _error = null);
    } on AdminAuthorisationException {
      if (mounted) {
        setState(() => _accessDenied = true);
        widget.onAccessDenied?.call();
      }
    } on AdminRepositoryException catch (error) {
      if (mounted) setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_accessDenied) {
      return const Center(
          child: Text('Authorised administration access is required.'));
    }
    return StreamBuilder<List<AdminIncidentRecord>>(
      stream: _recordsStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(_error ?? 'Administration data could not be loaded.'),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final records = snapshot.data ?? const <AdminIncidentRecord>[];
        return Column(
          children: <Widget>[
            if (widget.showDemoBanner)
              Container(
                width: double.infinity,
                color: Colors.amber.shade100,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: const Text(
                  'Demo / synthetic data · no production records are shown',
                  textAlign: TextAlign.center,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text(
                    'Private exact locations · latest 500 reports',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                      'Use this protected view to spot implausible points, including offshore locations. Coordinates are never public.'),
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(_error!),
                  ],
                  Wrap(
                    spacing: 6,
                    children: <Widget>[
                      ChoiceChip(
                        label: const Text('Pending'),
                        selected: _statuses.length == 1 &&
                            _statuses.contains('pending'),
                        onSelected: (_) => _setStatuses(const {'pending'}),
                      ),
                      ChoiceChip(
                        label: const Text('All active'),
                        selected: _statuses.length == _activeStatuses.length &&
                            _statuses.containsAll(_activeStatuses),
                        onSelected: (_) => _setStatuses(_activeStatuses),
                      ),
                      ChoiceChip(
                        label: const Text('Withdrawn audit'),
                        selected: _statuses.length == 1 &&
                            _statuses.contains('withdrawn'),
                        onSelected: (_) => _setStatuses(const {'withdrawn'}),
                      ),
                    ],
                  ),
                  Row(
                    children: <Widget>[
                      Text(
                          '${records.length} ${_statuses.contains('withdrawn') ? 'audit' : 'active'} records'),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _fitReports(records),
                        icon: const Icon(Icons.fit_screen),
                        label: const Text('Fit reports'),
                      ),
                      TextButton.icon(
                        onPressed: () => _showCsv(records),
                        icon: const Icon(Icons.download),
                        label: const Text('CSV'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: AppConfig().mapCentre,
                  initialZoom: AppConfig().initialMapZoom,
                ),
                children: <Widget>[
                  TileLayer(
                    tileProvider: _tileProvider,
                    urlTemplate: const OpenStreetMapProvider().tileUrl,
                    userAgentPackageName: 'za.scarborough.tortoise_watch',
                  ),
                  MarkerLayer(
                    markers: records.map((record) {
                      final selected = record.id == _selected?.id;
                      return Marker(
                        point: LatLng(record.latitude, record.longitude),
                        width: selected ? 48 : 36,
                        height: selected ? 48 : 36,
                        child: GestureDetector(
                          onTap: () => _select(record),
                          child: Semantics(
                            button: true,
                            label:
                                '${_incidentLabel(record.incidentType)} ${_statusLabel(record.status)} private report marker',
                            child: TortoiseMapMarker(
                              condition: TortoiseMarkerConditionX.fromCode(
                                  record.incidentType),
                              selected: selected,
                            ),
                          ),
                        ),
                      );
                    }).toList(growable: false),
                  ),
                  const RichAttributionWidget(
                    attributions: <TextSourceAttribution>[
                      TextSourceAttribution('© OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: _ReportList(
                records: records,
                selected: _selected,
                onSelect: _select,
                onModerate: _moderate,
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCsv(List<AdminIncidentRecord> records) {
    final csv = CsvExporter.export(
      records,
      authorised: true,
      includeWithdrawn: _statuses.contains('withdrawn'),
    );
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_statuses.contains('withdrawn')
            ? 'Withdrawn audit CSV'
            : 'Active records CSV'),
        content: SingleChildScrollView(child: SelectableText(csv)),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _ReportList extends StatelessWidget {
  const _ReportList({
    required this.records,
    required this.selected,
    required this.onSelect,
    required this.onModerate,
  });

  final List<AdminIncidentRecord> records;
  final AdminIncidentRecord? selected;
  final void Function(AdminIncidentRecord record) onSelect;
  final Future<void> Function(AdminIncidentRecord record, String status)
      onModerate;

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty)
      return const Center(child: Text('No reports in this view.'));
    return ListView.builder(
      itemCount: records.length,
      itemBuilder: (context, index) {
        final record = records[index];
        final isSelected = record.id == selected?.id;
        return ListTile(
          selected: isSelected,
          onTap: () => onSelect(record),
          title: Text(
              '${_incidentLabel(record.incidentType)} · ${_statusLabel(record.status)}'),
          subtitle: Text(
            '${_humanDate(record.createdAt)}\n${record.latitude.toStringAsFixed(6)}, ${record.longitude.toStringAsFixed(6)}',
          ),
          isThreeLine: true,
          trailing: record.status == 'withdrawn'
              ? const Text('Audit')
              : PopupMenuButton<String>(
                  tooltip: 'Moderate report',
                  onSelected: (status) => onModerate(record, status),
                  itemBuilder: (_) => const <PopupMenuEntry<String>>[
                    PopupMenuItem(value: 'accepted', child: Text('Approve')),
                    PopupMenuItem(value: 'rejected', child: Text('Reject')),
                    PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                  ],
                ),
        );
      },
    );
  }
}

String _moderationAction(String status) => switch (status) {
      'accepted' => 'Approve',
      'rejected' => 'Reject',
      'duplicate' => 'Mark as duplicate',
      _ => status,
    };

String _incidentLabel(String code) => switch (code) {
      'alive' => 'Live tortoise',
      'injured' => 'Injured tortoise',
      'dead_roadkill' => 'Roadkill',
      'alive_near_road' => 'Live tortoise near road',
      _ => code.replaceAll('_', ' '),
    };

String _statusLabel(String code) => switch (code) {
      'pending' => 'Pending',
      'accepted' => 'Accepted',
      'rejected' => 'Rejected',
      'duplicate' => 'Duplicate',
      'withdrawn' => 'Withdrawn',
      _ => code,
    };

String _humanDate(String value) {
  final parsed = DateTime.tryParse(value)?.toLocal();
  if (parsed == null) return value;
  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '$day/$month/${parsed.year} $hour:$minute';
}
