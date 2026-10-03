import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../data/csv_exporter.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> {
  late Future<_AdminLoadResult> _load;

  @override
  void initState() {
    super.initState();
    _load = _loadAdmin();
  }

  Future<_AdminLoadResult> _loadAdmin() async {
    final repository = ref.read(adminRepositoryProvider);
    final authorised = await repository.isAuthorised();
    if (!authorised)
      return const _AdminLoadResult(
          authorised: false, records: <AdminIncidentRecord>[]);
    return _AdminLoadResult(
        authorised: true, records: await repository.loadIncidents());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin foundation'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      body: FutureBuilder<_AdminLoadResult>(
        future: _load,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
                child: Text('Administration data could not be loaded.'));
          }
          final result = snapshot.data ??
              const _AdminLoadResult(
                  authorised: false, records: <AdminIncidentRecord>[]);
          if (!result.authorised) return const _UnauthorisedAdmin();
          return _AuthorisedAdmin(records: result.records);
        },
      ),
    );
  }
}

class _UnauthorisedAdmin extends StatelessWidget {
  const _UnauthorisedAdmin();

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
                  Text('Authorised access only',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  const Text(
                      'An admin or analyst Firebase custom claim is required to view exact incidents and private photos.'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthorisedAdmin extends StatelessWidget {
  const _AuthorisedAdmin({required this.records});

  final List<AdminIncidentRecord> records;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: <Widget>[
        Text('Authorised incident review',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
            '${records.length} records loaded. Exact coordinates remain inside this protected view.'),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {
            final csv = CsvExporter.export(records, authorised: true);
            showDialog<void>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('CSV ready'),
                content: SingleChildScrollView(child: SelectableText(csv)),
                actions: <Widget>[
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'))
                ],
              ),
            );
          },
          icon: const Icon(Icons.download),
          label: const Text('Prepare CSV export'),
        ),
      ],
    );
  }
}

class _AdminLoadResult {
  const _AdminLoadResult({required this.authorised, required this.records});

  final bool authorised;
  final List<AdminIncidentRecord> records;
}
