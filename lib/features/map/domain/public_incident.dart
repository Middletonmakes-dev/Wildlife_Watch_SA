enum PublicIncidentType {
  aliveCrossingRoad,
  aliveNearRoad,
  injured,
  deadRoadkill,
}

extension PublicIncidentTypeX on PublicIncidentType {
  String get code => switch (this) {
        PublicIncidentType.aliveCrossingRoad => 'alive_crossing_road',
        PublicIncidentType.aliveNearRoad => 'alive_near_road',
        PublicIncidentType.injured => 'injured',
        PublicIncidentType.deadRoadkill => 'dead_roadkill',
      };

  String get label => switch (this) {
        PublicIncidentType.aliveCrossingRoad => 'Alive / crossing road',
        PublicIncidentType.aliveNearRoad => 'Alive / near road',
        PublicIncidentType.injured => 'Injured',
        PublicIncidentType.deadRoadkill => 'Dead / roadkill',
      };

  bool get isAlive =>
      this == PublicIncidentType.aliveCrossingRoad ||
      this == PublicIncidentType.aliveNearRoad;

  static PublicIncidentType? fromCode(String? value) {
    for (final type in PublicIncidentType.values) {
      if (type.code == value) return type;
    }
    return null;
  }
}

class PublicIncident {
  const PublicIncident({
    required this.id,
    required this.incidentType,
    required this.displayLatitude,
    required this.displayLongitude,
    required this.date,
  });

  final String id;
  final PublicIncidentType incidentType;
  final double displayLatitude;
  final double displayLongitude;
  final String date;

  Map<String, Object?> toJson() => <String, Object?>{
        'id': id,
        'incidentType': incidentType.code,
        'displayLatitude': displayLatitude,
        'displayLongitude': displayLongitude,
        'date': date,
      };

  factory PublicIncident.fromJson(Map<String, dynamic> json) {
    final incidentType =
        PublicIncidentTypeX.fromCode(json['incidentType'] as String?);
    if (incidentType == null) {
      throw const FormatException('Unknown public incident type');
    }
    return PublicIncident(
      id: json['id'] as String,
      incidentType: incidentType,
      displayLatitude: (json['displayLatitude'] as num).toDouble(),
      displayLongitude: (json['displayLongitude'] as num).toDouble(),
      date: json['date'] as String,
    );
  }
}
