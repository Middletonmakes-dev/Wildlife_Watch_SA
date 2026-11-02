import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scarborough_tortoise_watch/features/report/presentation/direction_wheel.dart';

void main() {
  testWidgets('slow touch drag rotates wheel without scrolling its page',
      (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    double? selected;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ListView(controller: scroll, children: [
      const SizedBox(height: 100),
      Center(
          child: DirectionWheel(
              bearing: null, onChanged: (value) => selected = value)),
      const SizedBox(height: 1000),
    ]))));
    final centre = tester.getCenter(find.byKey(const Key('direction-wheel')));
    expect(selected, isNull);
    final gesture = await tester.startGesture(centre + const Offset(0, 65));
    for (var step = 1; step <= 8; step++) {
      await gesture.moveTo(centre + Offset(0, 65 - step * 5));
      await tester.pump(const Duration(milliseconds: 30));
    }
    await gesture.moveTo(centre + const Offset(65, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selected, closeTo(90, .1));
    expect(scroll.offset, 0);
    await tester.dragFrom(const Offset(600, 400), const Offset(0, -80));
    await tester.pumpAndSettle();
    expect(scroll.offset, greaterThan(0),
        reason: 'Swipes outside the wheel must still scroll the page.');
  });
  testWidgets('wheel ignores additional pointers and releases cancelled touch',
      (tester) async {
    double? selected;
    await tester.pumpWidget(MaterialApp(
        home: Center(
            child: DirectionWheel(
                bearing: null, onChanged: (value) => selected = value))));
    final centre = tester.getCenter(find.byKey(const Key('direction-wheel')));
    final first =
        await tester.startGesture(centre + const Offset(65, 0), pointer: 1);
    expect(selected, 90);
    final second =
        await tester.startGesture(centre + const Offset(-65, 0), pointer: 2);
    await second.moveTo(centre + const Offset(0, -65));
    expect(selected, 90);
    await first.cancel();
    await second.moveTo(centre + const Offset(0, 65));
    expect(selected, 90);
    await second.up();
    await tester.tapAt(centre + const Offset(0, -65));
    expect(selected, 0);
  });
  for (final example in [
    (offset: const Offset(0, -65), bearing: 0.0),
    (offset: const Offset(65, 0), bearing: 90.0),
    (offset: const Offset(0, 65), bearing: 180.0),
    (offset: const Offset(-65, 0), bearing: 270.0),
  ]) {
    testWidgets('north-up wheel selects ${example.bearing} privately',
        (tester) async {
      double? selected;
      await tester.pumpWidget(MaterialApp(
          home: Center(
              child: DirectionWheel(
                  bearing: null, onChanged: (value) => selected = value))));
      final centre = tester.getCenter(find.byKey(const Key('direction-wheel')));
      await tester.tapAt(centre);
      expect(selected, isNull,
          reason: 'The pin centre cannot imply a direction.');
      await tester.tapAt(centre + example.offset);
      expect(selected, example.bearing);
    });
  }
  testWidgets('wheel supports keyboard direction with human semantic values',
      (tester) async {
    final semantics = tester.ensureSemantics();
    double? selected;
    await tester.pumpWidget(MaterialApp(
        home: Center(
            child: DirectionWheel(
                bearing: 90, onChanged: (value) => selected = value))));
    final wheel = find.byKey(const Key('direction-wheel'));
    expect(tester.getSemantics(wheel).value, 'East');
    Focus.of(tester.element(wheel)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(selected, 180);
    expect(tester.takeException(), isNull);
    semantics.dispose();
  });
}
