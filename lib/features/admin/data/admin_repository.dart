import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/firebase_functions.dart';
import 'csv_exporter.dart';

abstract interface class AdminRepository {
  Future<List<AdminIncidentRecord>> loadIncidents();
  Future<bool> isAuthorised();

  Stream<List<AdminIncidentRecord>> watchIncidents({
    Set<String> statuses = const <String>{'pending'},
  }) =>
      throw const AdminAuthorisationException();

  Future<void> setModeration(
          {required String incidentId, required String status}) =>
      throw const AdminAuthorisationException();
}

class DemoAdminRepository implements AdminRepository {
  const DemoAdminRepository({this.records = const <AdminIncidentRecord>[]});

  final List<AdminIncidentRecord> records;

  @override
  Future<bool> isAuthorised() async => false;

  @override
  Future<List<AdminIncidentRecord>> loadIncidents() async => records;

  @override
  Future<void> setModeration({
    required String incidentId,
    required String status,
  }) async {
    throw const AdminAuthorisationException();
  }

  @override
  Stream<List<AdminIncidentRecord>> watchIncidents({
    Set<String> statuses = const <String>{'pending'},
  }) async* {
    yield records
        .where((record) => statuses.contains(record.status))
        .toList(growable: false);
  }
}

class FirebaseAdminRepository implements AdminRepository {
  const FirebaseAdminRepository();

  @override
  Future<bool> isAuthorised() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    // AdminScreen performs the explicit refresh for manual access checks. A
    // record stream must not refresh tokens again when an ID-token event is
    // already being observed, or it can create a refresh loop.
    final token = await user.getIdTokenResult(false);
    final claims = token.claims ?? const <String, Object?>{};
    return claims['admin'] == true ||
        claims['role'] == 'admin' ||
        claims['role'] == 'analyst';
  }

  @override
  Future<List<AdminIncidentRecord>> loadIncidents() async {
    if (!await isAuthorised()) throw const AdminAuthorisationException();
    return watchIncidents(statuses: const <String>{
      'pending',
      'accepted',
      'rejected',
      'duplicate',
      'withdrawn',
    }).first;
  }

  @override
  Stream<List<AdminIncidentRecord>> watchIncidents({
    Set<String> statuses = const <String>{'pending'},
  }) async* {
    if (!await isAuthorised()) throw const AdminAuthorisationException();
    await for (final snapshot in FirebaseFirestore.instance
        .collection('incidents')
        .orderBy('createdAt', descending: true)
        .limit(500)
        .snapshots()) {
      yield snapshot.docs
          .map(_recordFromDocument)
          .where((record) => statuses.contains(record.status))
          .toList(growable: false);
    }
  }

  @override
  Future<void> setModeration({
    required String incidentId,
    required String status,
  }) async {
    if (!await isAuthorised()) throw const AdminAuthorisationException();
    try {
      await firebaseFunctionsForApp()
          .httpsCallable('setIncidentModeration')
          .call(
        <String, Object?>{'incidentId': incidentId, 'status': status},
      );
    } on FirebaseFunctionsException catch (error) {
      throw moderationError(error);
    } catch (_) {
      throw const AdminRepositoryException(
        'The moderation change could not be saved. Please try again.',
      );
    }
  }
}

class AdminRepositoryException implements Exception {
  const AdminRepositoryException(this.message);

  final String message;
}

class PublicationNotReadyException extends AdminRepositoryException {
  PublicationNotReadyException(this.eligibleDate)
      : super('This report can be published from $eligibleDate (UTC).');
  final String eligibleDate;
}

class IncidentWithdrawnException extends AdminRepositoryException {
  const IncidentWithdrawnException()
      : super('This report has been withdrawn and cannot be moderated.');
}

Exception moderationError(FirebaseFunctionsException error) {
  if (error.code == 'permission-denied' || error.code == 'unauthenticated') {
    return const AdminAuthorisationException();
  }
  if (error.code == 'failed-precondition' && error.details is Map) {
    final details = error.details as Map;
    if (details['reason'] == 'incident-withdrawn') {
      return const IncidentWithdrawnException();
    }
    final date = details['eligibleDate'];
    if (details['reason'] == 'publication-not-ready' &&
        date is String &&
        RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
      final parsed = DateTime.tryParse('${date}T00:00:00Z');
      if (parsed != null && parsed.toIso8601String().substring(0, 10) == date) {
        return PublicationNotReadyException(date);
      }
    }
  }
  return const AdminRepositoryException(
      'The moderation change could not be saved. Please try again.');
}

AdminIncidentRecord _recordFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document) {
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
}

String _formatDate(Object? value) {
  if (value is Timestamp) return value.toDate().toIso8601String();
  return value?.toString() ?? '';
}
