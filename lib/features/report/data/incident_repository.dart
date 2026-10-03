import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/incident.dart';
import '../domain/report_draft.dart';

abstract interface class IncidentRepository {
  Future<SubmissionResult> submit(ReportDraft draft);
}

class SubmissionResult {
  const SubmissionResult({required this.incidentId});

  final String incidentId;
}

class ReportRepositoryException implements Exception {
  const ReportRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DemoIncidentRepository implements IncidentRepository {
  final Map<String, SubmissionResult> _submissions =
      <String, SubmissionResult>{};

  @override
  Future<SubmissionResult> submit(ReportDraft draft) async {
    final errors = draft.validate();
    if (errors.isNotEmpty) throw ReportRepositoryException(errors.first);
    return _submissions.putIfAbsent(
      draft.requestId,
      () => SubmissionResult(incidentId: 'demo-${_submissions.length + 1}'),
    );
  }
}

class FirebaseIncidentRepository implements IncidentRepository {
  const FirebaseIncidentRepository();

  @override
  Future<SubmissionResult> submit(ReportDraft draft) async {
    try {
      if (FirebaseAuth.instance.currentUser == null) {
        await FirebaseAuth.instance.signInAnonymously();
      }
      final callable =
          FirebaseFunctions.instance.httpsCallable('submitIncident');
      final payload = <String, Object?>{
        'requestId': draft.requestId,
        'latitude': draft.location!.latitude,
        'longitude': draft.location!.longitude,
        'locationSource': draft.location!.source.code,
        'incidentType': draft.incidentType!.code,
      };
      if (draft.location!.accuracyMetres != null) {
        payload['locationAccuracyMetres'] = draft.location!.accuracyMetres;
      }
      if (draft.location!.directionBearing != null) {
        payload['directionBearing'] = draft.location!.directionBearing;
      }
      if (draft.note?.trim().isNotEmpty == true)
        payload['note'] = draft.note!.trim();
      if (draft.occurredAt != null)
        payload['occurredAt'] = draft.occurredAt!.toIso8601String();
      final response = await callable.call(payload);
      final data = Map<String, dynamic>.from(response.data as Map);
      return SubmissionResult(incidentId: data['incidentId'] as String);
    } on FirebaseFunctionsException catch (error) {
      final safeMessage = switch (error.code) {
        'unauthenticated' =>
          'Please try again so we can protect the report endpoint.',
        'invalid-argument' => 'Please check the location and report details.',
        'resource-exhausted' =>
          'Please wait a moment before submitting another report.',
        'failed-precondition' =>
          'This report was saved with earlier details. Return home to start another report.',
        _ => 'The report could not be saved. Please try again.',
      };
      throw ReportRepositoryException(safeMessage);
    } on FirebaseAuthException {
      throw const ReportRepositoryException(
          'Could not connect securely. Check your connection and try again.');
    } catch (_) {
      throw const ReportRepositoryException(
          'The report could not be saved. Please try again.');
    }
  }
}
