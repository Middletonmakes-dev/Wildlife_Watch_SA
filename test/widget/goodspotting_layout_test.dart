import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scarborough_tortoise_watch/features/home/presentation/home_screen.dart';
import 'package:scarborough_tortoise_watch/features/support/presentation/support_card.dart';

void main() {
  testWidgets('home logo and links fit a narrow phone', (tester) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(ProviderScope(
        child: MaterialApp(
            home: RepaintBoundary(key: key, child: const HomeScreen()))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('See more projects by Good Spotting'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('support fits a narrow phone at large text size', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: SupportCardPage())));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Support via SnapScan'));
    expect(tester.takeException(), isNull);
  });
}
