class AdminIncidentRecord {
  const AdminIncidentRecord({
    required this.id,
    required this.createdAt,
    required this.latitude,
    required this.longitude,
    required this.incidentType,
    required this.status,
    this.note,
  });

  final String id;
  final String createdAt;
  final double latitude;
  final double longitude;
  final String incidentType;
  final String status;
  final String? note;
}

class AdminAuthorisationException implements Exception {
  const AdminAuthorisationException();
}

class CsvExporter {
  const CsvExporter._();

  static String export(
    List<AdminIncidentRecord> records, {
    required bool authorised,
    bool includeWithdrawn = false,
  }) {
    if (!authorised) throw const AdminAuthorisationException();
    final exportRecords = includeWithdrawn
        ? records
        : records.where((record) => record.status != 'withdrawn').toList();
    final rows = <List<Object>>[
      <Object>[
        'id',
        'createdAt',
        'latitude',
        'longitude',
        'incidentType',
        'status',
        'note',
      ],
      ...exportRecords.map(
        (record) => <Object>[
          record.id,
          record.createdAt,
          record.latitude,
          record.longitude,
          record.incidentType,
          record.status,
          record.note ?? '',
        ],
      ),
    ];
    return rows.map((row) => row.map(_cell).join(',')).join('\n');
  }

  static String _cell(Object field) {
    if (field is num) {
      if (!field.isFinite) throw ArgumentError('CSV numbers must be finite');
      return field.toString();
    }
    final value = field.toString();
    final safeValue = value.trimLeft().startsWith(RegExp(r'[=+\-@]')) ||
            value.startsWith(RegExp(r'[\t\r\n]'))
        ? "'$value"
        : value;
    return '"${safeValue.replaceAll('"', '""')}"';
  }
}
