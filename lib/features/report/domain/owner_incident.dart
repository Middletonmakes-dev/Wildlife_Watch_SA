import 'incident.dart';

enum OwnerIncidentStatus { pending, accepted, rejected, duplicate, withdrawn }

extension OwnerIncidentStatusX on OwnerIncidentStatus {
  String get code => name;

  String get label => switch (this) {
        OwnerIncidentStatus.pending => 'Pending review',
        OwnerIncidentStatus.accepted => 'Accepted',
        OwnerIncidentStatus.rejected => 'Rejected',
        OwnerIncidentStatus.duplicate => 'Duplicate',
        OwnerIncidentStatus.withdrawn => 'Withdrawn',
      };

  static OwnerIncidentStatus fromCode(String? value) =>
      OwnerIncidentStatus.values.firstWhere(
        (status) => status.code == value,
        orElse: () => OwnerIncidentStatus.pending,
      );
}

class OwnerIncidentReceipt {
  const OwnerIncidentReceipt({
    required this.id,
    required this.incidentType,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final IncidentType incidentType;
  final OwnerIncidentStatus status;
  final DateTime? createdAt;

  bool get canWithdraw => status != OwnerIncidentStatus.withdrawn;

  factory OwnerIncidentReceipt.fromJson(Map<String, dynamic> json) {
    final type = IncidentTypeX.fromCode(json['incidentType'] as String?);
    if (type == null) throw const FormatException('Unknown incident type');
    return OwnerIncidentReceipt(
      id: json['id'] as String,
      incidentType: type,
      status:
          OwnerIncidentStatusX.fromCode(json['moderationStatus'] as String?),
      createdAt: _parseDate(json['createdAt']),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'incidentType': incidentType.code,
        'moderationStatus': status.code,
        'createdAt': createdAt?.toIso8601String(),
      };
}

DateTime? _parseDate(Object? value) =>
    value == null ? null : DateTime.tryParse(value.toString());
