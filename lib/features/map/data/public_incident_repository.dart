import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/public_incident.dart';

abstract interface class PublicIncidentRepository {
  Future<List<PublicIncident>> list({
    String? typeFilter,
    DateTime? from,
    DateTime? to,
  });
}

class DemoPublicIncidentRepository implements PublicIncidentRepository {
  const DemoPublicIncidentRepository();

  static const incidents = <PublicIncident>[
    PublicIncident(
      id: 'synthetic-public-1',
      incidentType: PublicIncidentType.aliveCrossingRoad,
      displayLatitude: -34.1973,
      displayLongitude: 18.3752,
      date: '2026-10-03',
    ),
    PublicIncident(
      id: 'synthetic-public-2',
      incidentType: PublicIncidentType.deadRoadkill,
      displayLatitude: -34.1958,
      displayLongitude: 18.3735,
      date: '2026-09-28',
    ),
  ];

  @override
  Future<List<PublicIncident>> list({
    String? typeFilter,
    DateTime? from,
    DateTime? to,
  }) async {
    return _filter(incidents, typeFilter: typeFilter, from: from, to: to);
  }
}

class FirebasePublicIncidentRepository implements PublicIncidentRepository {
  const FirebasePublicIncidentRepository();

  @override
  Future<List<PublicIncident>> list({
    String? typeFilter,
    DateTime? from,
    DateTime? to,
  }) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('publicIncidents')
        .orderBy('date', descending: true)
        .limit(500)
        .get();
    final incidents = snapshot.docs
        .map((doc) => PublicIncident.fromJson(doc.data()))
        .toList(growable: false);
    return _filter(incidents, typeFilter: typeFilter, from: from, to: to);
  }
}

List<PublicIncident> _filter(
  Iterable<PublicIncident> source, {
  String? typeFilter,
  DateTime? from,
  DateTime? to,
}) {
  return source.where((incident) {
    final typeMatches = typeFilter == null ||
        (typeFilter == 'alive'
            ? incident.incidentType.isAlive
            : incident.incidentType.code == typeFilter);
    final date = DateTime.tryParse(incident.date);
    final dateMatches = date == null ||
        (from == null ||
                !date.isBefore(DateTime(from.year, from.month, from.day))) &&
            (to == null ||
                date.isBefore(DateTime(to.year, to.month, to.day + 1)));
    return typeMatches && dateMatches;
  }).toList(growable: false);
}
