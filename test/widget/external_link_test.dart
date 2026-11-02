import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scarborough_tortoise_watch/app/theme/external_link_button.dart';
import 'package:scarborough_tortoise_watch/app/config/external_links.dart';

void main() {
  testWidgets('opens the exact support destination after tapping',
      (tester) async {
    Uri? opened;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ExternalLinkButton(
      label: 'Support via SnapScan',
      url: ExternalLinks.support,
      opener: (uri) async {
        opened = uri;
        return true;
      },
    ))));
    expect(opened, isNull);
    await tester.tap(find.text('Support via SnapScan'));
    await tester.pump();
    expect(opened.toString(), 'https://pos.snapscan.io/qr/76M6XG6i');
  });
  testWidgets('website destination and failure feedback', (tester) async {
    Uri? opened;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ExternalLinkButton(
      label: 'See more projects by Good Spotting',
      url: ExternalLinks.website,
      opener: (uri) async {
        opened = uri;
        throw Exception('blocked');
      },
    ))));
    await tester.tap(find.text('See more projects by Good Spotting'));
    await tester.pumpAndSettle();
    expect(opened.toString(), 'https://good-spotting.netlify.app/');
    expect(find.text('Could not open the link. Please try again.'),
        findsOneWidget);
  });
}
