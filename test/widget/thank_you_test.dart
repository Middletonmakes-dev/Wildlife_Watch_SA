import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:scarborough_tortoise_watch/features/report/presentation/thank_you_screen.dart';

void main() {
  for (final kind in ['production', 'demo', 'direct']) {
    testWidgets(
        'review expectation is shown only after a real saved report: $kind',
        (tester) async {
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const ThankYouScreen()),
      ]);
      addTearDown(router.dispose);
      if (kind != 'direct') {
        router.go('/',
            extra:
                ThankYouData(message: 'Report saved.', demo: kind == 'demo'));
      }
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      expect(
          find.text(
              'Your report is saved and waiting for review. Approved reports appear on the public map with their locations obscured.'),
          kind == 'production' ? findsOneWidget : findsNothing);
    });
  }
}
