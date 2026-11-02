import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scarborough_tortoise_watch/features/admin/data/admin_repository.dart';
import 'package:scarborough_tortoise_watch/features/admin/data/csv_exporter.dart';

void main() {
  test('publication preconditions remain typed operation errors', () {
    final waiting = moderationError(FirebaseFunctionsException(
        message: 'untrusted server message',
        code: 'failed-precondition',
        details: {
          'reason': 'publication-not-ready',
          'eligibleDate': '2030-01-08'
        }));
    expect(waiting, isA<PublicationNotReadyException>());
    expect(
        (waiting as PublicationNotReadyException).eligibleDate, '2030-01-08');
    expect(waiting.message, contains('2030-01-08'));
    expect(
        moderationError(FirebaseFunctionsException(
            message: 'untrusted server message',
            code: 'failed-precondition',
            details: {'reason': 'incident-withdrawn'})),
        isA<IncidentWithdrawnException>());
    for (final details in [
      null,
      {'reason': 'unknown'},
      {'reason': 'publication-not-ready', 'eligibleDate': '2030-02-30'},
      {'reason': 'publication-not-ready', 'eligibleDate': 'bad'},
      'untrusted'
    ]) {
      final error = moderationError(FirebaseFunctionsException(
          message: 'untrusted server message',
          code: 'failed-precondition',
          details: details));
      expect(error, isA<AdminRepositoryException>());
      expect(error, isNot(isA<PublicationNotReadyException>()));
      expect(error, isNot(isA<AdminAuthorisationException>()));
    }
  });

  test('only authentication or permission denial revokes admin access', () {
    for (final code in ['permission-denied', 'unauthenticated']) {
      expect(
          moderationError(FirebaseFunctionsException(
              message: 'untrusted server message', code: code)),
          isA<AdminAuthorisationException>());
    }
    expect(
        moderationError(FirebaseFunctionsException(
            message: 'untrusted server message', code: 'unavailable')),
        isA<AdminRepositoryException>());
  });
}
