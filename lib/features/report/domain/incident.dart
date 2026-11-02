import 'dart:math' as math;

enum IncidentType {
  aliveCrossingRoad,
  aliveNearRoad,
  injured,
  deadRoadkill,
}

extension IncidentTypeX on IncidentType {
  String get code => switch (this) {
        IncidentType.aliveCrossingRoad => 'alive_crossing_road',
        IncidentType.aliveNearRoad => 'alive_near_road',
        IncidentType.injured => 'injured',
        IncidentType.deadRoadkill => 'dead_roadkill',
      };

  String get label => switch (this) {
        IncidentType.aliveCrossingRoad => 'Alive / crossing road',
        IncidentType.aliveNearRoad => 'Alive / near road',
        IncidentType.injured => 'Injured',
        IncidentType.deadRoadkill => 'Dead / roadkill',
      };

  static IncidentType? fromCode(String? value) {
    for (final type in IncidentType.values) {
      if (type.code == value) return type;
    }
    return null;
  }
}

enum LocationSource { deviceGps, manualPin, unknown }

extension LocationSourceX on LocationSource {
  String get code => switch (this) {
        LocationSource.deviceGps => 'device_gps',
        LocationSource.manualPin => 'manual_pin',
        LocationSource.unknown => 'unknown',
      };

  static LocationSource fromCode(String? value) => switch (value) {
        'device_gps' => LocationSource.deviceGps,
        'manual_pin' => LocationSource.manualPin,
        _ => LocationSource.unknown,
      };
}

enum ModerationStatus { pending, accepted, rejected, duplicate, withdrawn }

extension ModerationStatusX on ModerationStatus {
  String get code => name;

  static ModerationStatus fromCode(String? value) =>
      ModerationStatus.values.firstWhere((status) => status.code == value,
          orElse: () => ModerationStatus.pending);
}

class GeoCoordinate {
  const GeoCoordinate({
    required this.latitude,
    required this.longitude,
    this.accuracyMetres,
    required this.source,
    this.directionBearing,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMetres;
  final LocationSource source;
  final double? directionBearing;

  Map<String, Object?> toJson() => <String, Object?>{
        'latitude': latitude,
        'longitude': longitude,
        'accuracyMetres': accuracyMetres,
        'source': source.code,
        'directionBearing': directionBearing,
      };

  factory GeoCoordinate.fromJson(Map<String, dynamic> json) => GeoCoordinate(
        latitude: _number(json['latitude'], 'latitude'),
        longitude: _number(json['longitude'], 'longitude'),
        accuracyMetres: _nullableNumber(json['accuracyMetres']),
        source: LocationSourceX.fromCode(json['source'] as String?),
        directionBearing: _nullableNumber(json['directionBearing']),
      );

  double distanceFrom(GeoCoordinate other) {
    const earthRadiusMetres = 6371000.0;
    final latitude1 = latitude * math.pi / 180;
    final latitude2 = other.latitude * math.pi / 180;
    final deltaLatitude = (other.latitude - latitude) * math.pi / 180;
    final deltaLongitude = (other.longitude - longitude) * math.pi / 180;
    final a = math.pow(math.sin(deltaLatitude / 2), 2) +
        math.cos(latitude1) *
            math.cos(latitude2) *
            math.pow(math.sin(deltaLongitude / 2), 2);
    return earthRadiusMetres * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  @override
  bool operator ==(Object other) =>
      other is GeoCoordinate &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.accuracyMetres == accuracyMetres &&
      other.source == source &&
      other.directionBearing == directionBearing;

  @override
  int get hashCode => Object.hash(
        latitude,
        longitude,
        accuracyMetres,
        source,
        directionBearing,
      );
}

class Incident {
  const Incident({
    required this.id,
    required this.createdAt,
    this.occurredAt,
    required this.location,
    required this.incidentType,
    this.note,
    this.photoReferences = const <String>[],
    this.reporterUid,
    this.moderationStatus = ModerationStatus.pending,
    this.sourceVersion = 'v1',
    required this.requestId,
    this.serverTimestamp,
  });

  final String id;
  final DateTime createdAt;
  final DateTime? occurredAt;
  final GeoCoordinate location;
  final IncidentType incidentType;
  final String? note;
  final List<String> photoReferences;
  final String? reporterUid;
  final ModerationStatus moderationStatus;
  final String sourceVersion;
  final String requestId;
  final DateTime? serverTimestamp;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'occurredAt': occurredAt?.toIso8601String(),
        'location': location.toJson(),
        'incidentType': incidentType.code,
        'note': note,
        'photoReferences': List<String>.unmodifiable(photoReferences),
        'reporterUid': reporterUid,
        'moderationStatus': moderationStatus.code,
        'sourceVersion': sourceVersion,
        'requestId': requestId,
        'serverTimestamp': serverTimestamp?.toIso8601String(),
      };

  factory Incident.fromJson(Map<String, dynamic> json) {
    final incidentType =
        IncidentTypeX.fromCode(json['incidentType'] as String?);
    if (incidentType == null) {
      throw const FormatException('Unknown incident type');
    }
    return Incident(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      occurredAt: _nullableDate(json['occurredAt']),
      location: GeoCoordinate.fromJson(
          Map<String, dynamic>.from(json['location'] as Map)),
      incidentType: incidentType,
      note: json['note'] as String?,
      photoReferences: List<String>.from(
          json['photoReferences'] as List? ?? const <String>[]),
      reporterUid: json['reporterUid'] as String?,
      moderationStatus:
          ModerationStatusX.fromCode(json['moderationStatus'] as String?),
      sourceVersion: json['sourceVersion'] as String? ?? 'v1',
      requestId: json['requestId'] as String,
      serverTimestamp: _nullableDate(json['serverTimestamp']),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is Incident &&
        other.id == id &&
        other.createdAt == createdAt &&
        other.occurredAt == occurredAt &&
        other.location == location &&
        other.incidentType == incidentType &&
        other.note == note &&
        _listEquals(other.photoReferences, photoReferences) &&
        other.reporterUid == reporterUid &&
        other.moderationStatus == moderationStatus &&
        other.sourceVersion == sourceVersion &&
        other.requestId == requestId &&
        other.serverTimestamp == serverTimestamp;
  }

  @override
  int get hashCode => Object.hash(
        id,
        createdAt,
        occurredAt,
        location,
        incidentType,
        note,
        Object.hashAll(photoReferences),
        reporterUid,
        moderationStatus,
        sourceVersion,
        requestId,
        serverTimestamp,
      );
}

double _number(Object? value, String field) {
  if (value is num) return value.toDouble();
  throw FormatException('$field must be a number');
}

double? _nullableNumber(Object? value) =>
    value == null ? null : _number(value, 'number');

DateTime? _nullableDate(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

bool _listEquals(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
