import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/public_incident.dart';

abstract interface class PublicIncidentRepository {
  Future<List<PublicIncident>> list({
    String? typeFilter,
    DateTime? from,
    DateTime? to,
    bool forceRefresh = false,
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
    bool forceRefresh = false,
  }) async {
    return _filter(incidents, typeFilter: typeFilter, from: from, to: to);
  }
}

class FirebasePublicIncidentRepository implements PublicIncidentRepository {
  FirebasePublicIncidentRepository({
    Future<List<PublicIncident>> Function()? loadPage,
    DateTime Function()? now,
  })  : _loadPage = loadPage ?? _fetchServerPage,
        _now = now ?? DateTime.now;

  final Future<List<PublicIncident>> Function() _loadPage;
  final DateTime Function() _now;
  List<PublicIncident>? _cached;
  DateTime? _loadedAt;
  Future<List<PublicIncident>>? _inFlight;
  Future<List<PublicIncident>>? _latestLoad;
  int _generation = 0;

  static Future<List<PublicIncident>> _fetchServerPage() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('publicIncidents')
        .orderBy('date', descending: true)
        .limit(500)
        .get(const GetOptions(source: Source.server));
    return snapshot.docs
        .map((doc) => PublicIncident.fromJson(doc.data()))
        .toList(growable: false);
  }

  Future<List<PublicIncident>> _page(bool forceRefresh) {
    if (forceRefresh) {
      _generation++;
      _cached = null;
      _loadedAt = null;
      _inFlight = null;
    }
    final loadedAt = _loadedAt;
    if (_cached != null &&
        loadedAt != null &&
        _now().difference(loadedAt) < const Duration(seconds: 60)) {
      return Future.value(_cached);
    }
    if (_inFlight != null) return _inFlight!;
    final load = _fetch(_generation);
    _latestLoad = load;
    _inFlight = load;
    return load;
  }

  Future<List<PublicIncident>> _fetch(int generation) async {
    try {
      final page = List<PublicIncident>.unmodifiable(await _loadPage());
      // An older request must follow the newest result, including its failure.
      // Retaining that future avoids silently starting a third read on failure.
      if (generation != _generation) return await _latestLoad!;
      _cached = page;
      _loadedAt = _now();
      return page;
    } catch (_) {
      if (generation != _generation) return await _latestLoad!;
      rethrow;
    } finally {
      if (generation == _generation) _inFlight = null;
    }
  }

  @override
  Future<List<PublicIncident>> list({
    String? typeFilter,
    DateTime? from,
    DateTime? to,
    bool forceRefresh = false,
  }) async {
    final incidents = await _page(forceRefresh);
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
