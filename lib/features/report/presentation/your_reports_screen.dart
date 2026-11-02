import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/theme/journal_widgets.dart';
import '../data/owner_incident_repository.dart';
import '../domain/incident.dart';
import '../domain/owner_incident.dart';

class YourReportsScreen extends ConsumerStatefulWidget {
  const YourReportsScreen({super.key});

  @override
  ConsumerState<YourReportsScreen> createState() => _YourReportsScreenState();
}

class _YourReportsScreenState extends ConsumerState<YourReportsScreen> {
  late Future<OwnerIncidentList> _reports;
  String? _withdrawingId;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _reports = ref.read(ownerIncidentRepositoryProvider).list();
  }

  Future<void> _withdraw(OwnerIncidentReceipt report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw this report?'),
        content: const Text(
          'It will be removed from the public map and active analysis. The private audit record will be retained as Withdrawn.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Withdraw report'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _withdrawingId = report.id);
    try {
      await ref.read(ownerIncidentRepositoryProvider).withdraw(report.id);
      if (!mounted) return;
      setState(() {
        _withdrawingId = null;
        _reload();
      });
    } on OwnerIncidentRepositoryException catch (error) {
      if (!mounted) return;
      setState(() => _withdrawingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(appConfigProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your reports'),
        leading: BackButton(onPressed: () => context.go('/')),
      ),
      bottomNavigationBar: JournalNavigation(selected: 3, demo: config.isDemo),
      body: FutureBuilder<OwnerIncidentList>(
        future: _reports,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _ReportsMessage(
              message: 'Your reports could not be loaded.',
              actionLabel: 'Try again',
              onAction: () => setState(_reload),
            );
          }
          final page = snapshot.data ??
              const OwnerIncidentList(
                reports: <OwnerIncidentReceipt>[],
                hasMore: false,
              );
          final reports = page.reports;
          if (reports.isEmpty) {
            return _ReportsMessage(
              message: 'No submitted reports were found in this browser yet.',
              detail:
                  'Use the same browser or device used to submit a report. Anonymous reports do not require a new account just to view this page.',
              actionLabel: 'Try again',
              onAction: () => setState(_reload),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => setState(_reload),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                const Text(
                  'Only a report’s original reporter can withdraw it.',
                ),
                if (page.hasMore) ...<Widget>[
                  const SizedBox(height: 8),
                  const Text(
                    'Showing the latest 500 reports. Older reports are not shown.',
                  ),
                ],
                const SizedBox(height: 12),
                for (final report in reports)
                  Card(
                    child: ListTile(
                      title: Text(report.incidentType.label),
                      subtitle: Text(_dateLabel(report)),
                      isThreeLine: true,
                      trailing: report.status == OwnerIncidentStatus.withdrawn
                          ? const Text('Withdrawn')
                          : _withdrawingId == report.id
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(),
                                )
                              : TextButton(
                                  onPressed: () => _withdraw(report),
                                  child: const Text('Withdraw'),
                                ),
                      leading: _statusIcon(report.status),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReportsMessage extends StatelessWidget {
  const _ReportsMessage({
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.detail,
  });

  final String message;
  final String? detail;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(message, textAlign: TextAlign.center),
              if (detail != null) ...<Widget>[
                const SizedBox(height: 8),
                Text(detail!, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 16),
              OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
            ],
          ),
        ),
      );
}

Widget _statusIcon(OwnerIncidentStatus status) => Icon(
      status == OwnerIncidentStatus.withdrawn
          ? Icons.remove_circle_outline
          : status == OwnerIncidentStatus.accepted
              ? Icons.check_circle_outline
              : Icons.schedule,
    );

String _dateLabel(OwnerIncidentReceipt report) =>
    '${report.status.label}\n${report.createdAt?.toIso8601String().substring(0, 10) ?? 'Date unavailable'}';
