import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/firebase_functions.dart';
import '../domain/owner_incident.dart';
import 'incident_repository.dart';

abstract interface class OwnerIncidentRepository {
  Future<OwnerIncidentList> list();
  Future<void> withdraw(String incidentId);
}

class OwnerIncidentList {
  const OwnerIncidentList({required this.reports, required this.hasMore});

  final List<OwnerIncidentReceipt> reports;
  final bool hasMore;
}

class OwnerIncidentRepositoryException implements Exception {
  const OwnerIncidentRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DemoOwnerIncidentRepository implements OwnerIncidentRepository {
  const DemoOwnerIncidentRepository();

  @override
  Future<OwnerIncidentList> list() async => OwnerIncidentList(
        reports: List<OwnerIncidentReceipt>.unmodifiable(
          DemoIncidentRepository.receipts,
        ),
        hasMore: false,
      );

  @override
  Future<void> withdraw(String incidentId) async {
    if (!DemoIncidentRepository.withdrawReceipt(incidentId)) {
      throw const OwnerIncidentRepositoryException(
        'That demo report could not be withdrawn.',
      );
    }
  }
}

class FirebaseOwnerIncidentRepository implements OwnerIncidentRepository {
  const FirebaseOwnerIncidentRepository();

  @override
  Future<OwnerIncidentList> list() async {
    if (FirebaseAuth.instance.currentUser == null) {
      return const OwnerIncidentList(
          reports: <OwnerIncidentReceipt>[], hasMore: false);
    }
    try {
      final response = await firebaseFunctionsForApp()
          .httpsCallable('listOwnIncidents')
          .call();
      final data = Map<String, dynamic>.from(response.data as Map);
      final reports = (data['reports'] as List? ?? const [])
          .map((entry) => OwnerIncidentReceipt.fromJson(
              Map<String, dynamic>.from(entry as Map)))
          .toList(growable: false);
      return OwnerIncidentList(
        reports: reports,
        hasMore: data['hasMore'] == true,
      );
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'unauthenticated') {
        return const OwnerIncidentList(
          reports: <OwnerIncidentReceipt>[],
          hasMore: false,
        );
      }
      throw const OwnerIncidentRepositoryException(
        'Your reports could not be loaded. Please try again.',
      );
    } catch (_) {
      throw const OwnerIncidentRepositoryException(
        'Your reports could not be loaded. Please try again.',
      );
    }
  }

  @override
  Future<void> withdraw(String incidentId) async {
    if (FirebaseAuth.instance.currentUser == null) {
      throw const OwnerIncidentRepositoryException(
        'Sign in on the same browser used to submit this report.',
      );
    }
    try {
      await firebaseFunctionsForApp().httpsCallable('withdrawIncident').call(
        <String, Object?>{'incidentId': incidentId},
      );
    } on FirebaseFunctionsException catch (error) {
      final message = switch (error.code) {
        'permission-denied' =>
          'This report could not be withdrawn from this browser.',
        'failed-precondition' =>
          'This report is no longer available to withdraw.',
        _ => 'The report could not be withdrawn. Please try again.',
      };
      throw OwnerIncidentRepositoryException(message);
    } catch (_) {
      throw const OwnerIncidentRepositoryException(
        'The report could not be withdrawn. Please try again.',
      );
    }
  }
}
