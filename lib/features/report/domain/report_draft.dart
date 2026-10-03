import 'dart:typed_data';

import 'incident.dart';

class ReportDraft {
  const ReportDraft({
    required this.requestId,
    this.location,
    this.incidentType,
    this.occurredAt,
    this.note,
    this.photoBytes,
  });

  final String requestId;
  final GeoCoordinate? location;
  final IncidentType? incidentType;
  final DateTime? occurredAt;
  final String? note;
  final Uint8List? photoBytes;

  ReportDraft copyWith({
    GeoCoordinate? location,
    IncidentType? incidentType,
    DateTime? occurredAt,
    String? note,
    Uint8List? photoBytes,
    bool clearPhoto = false,
  }) {
    return ReportDraft(
      requestId: requestId,
      location: location ?? this.location,
      incidentType: incidentType ?? this.incidentType,
      occurredAt: occurredAt ?? this.occurredAt,
      note: note ?? this.note,
      photoBytes: clearPhoto ? null : photoBytes ?? this.photoBytes,
    );
  }

  List<String> validate() {
    final errors = <String>[];
    if (requestId.trim().isEmpty) errors.add('request ID is required');
    if (incidentType == null) errors.add('Choose what happened');
    if (location == null) {
      errors.add('Confirm the location');
    } else {
      errors.addAll(validateCoordinate(location!));
    }
    final trimmedNote = note?.trim() ?? '';
    if (trimmedNote.length > 500)
      errors.add('Note must be 500 characters or fewer');
    final bearing = location?.directionBearing;
    if (bearing != null &&
        (!bearing.isFinite || bearing < 0 || bearing >= 360)) {
      errors.add('Enter a numeric compass bearing from 0 to less than 360.');
    }
    return errors;
  }
}

List<String> validateCoordinate(GeoCoordinate coordinate) {
  final errors = <String>[];
  if (!coordinate.latitude.isFinite) {
    errors.add('latitude must be finite');
  } else if (coordinate.latitude < -90 || coordinate.latitude > 90) {
    errors.add('latitude must be between -90 and 90');
  }
  if (!coordinate.longitude.isFinite) {
    errors.add('longitude must be finite');
  } else if (coordinate.longitude < -180 || coordinate.longitude > 180) {
    errors.add('longitude must be between -180 and 180');
  }
  final accuracy = coordinate.accuracyMetres;
  if (accuracy != null && (!accuracy.isFinite || accuracy < 0)) {
    errors.add('accuracy must be a finite positive number');
  }
  return errors;
}
