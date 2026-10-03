import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'csv_exporter.dart';

abstract interface class AdminRepository {
  Future<List<AdminIncidentRecord>> loadIncidents();
  Future<bool> isAuthorised();
}

class DemoAdminRepository implements AdminRepository {
  const DemoAdminRepository();

  @override
  Future<bool> isAuthorised() async => false;

  @override
  Future<List<AdminIncidentRecord>> loadIncidents() async =>
      const <AdminIncidentRecord>[];
}

class FirebaseAdminRepository implements AdminRepository {
  const FirebaseAdminRepository();

  @override
  Future<bool> isAuthorised() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final token = await user.getIdTokenResult(true);
    final claims = token.claims ?? const <String, Object?>{};
    return claims['admin'] == true ||
        claims['role'] == 'admin' ||
        claims['role'] == 'analyst';
  }

  @override
  Future<List<AdminIncidentRecord>> loadIncidents() async {
    if (!await isAuthorised()) throw const AdminAuthorisationException();
    final snapshot = await FirebaseFirestore.instance
        .collection('incidents')
        .orderBy('createdAt', descending: true)
        .limit(500)
        .get();
    return snapshot.docs.map((document) {
      final data = document.data();
      return AdminIncidentRecord(
        id: document.id,
        createdAt: _formatDate(data['createdAt']),
        latitude: (data['latitude'] as num).toDouble(),
        longitude: (data['longitude'] as num).toDouble(),
        incidentType: data['incidentType'] as String? ?? 'unknown',
        status: data['moderationStatus'] as String? ?? 'pending',
        note: data['note'] as String?,
      );
    }).toList(growable: false);
  }
}

String _formatDate(Object? value) {
  if (value is Timestamp) return value.toDate().toIso8601String();
  return value?.toString() ?? '';
}
