import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:scarborough_tortoise_watch/app/app.dart';
import 'package:scarborough_tortoise_watch/app/providers.dart';
import 'package:scarborough_tortoise_watch/features/report/domain/incident.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:typed_data';
import 'package:image/image.dart' as image;

void main() {
  testWidgets('resident can open the report flow without an account',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(overrides: [
      mapTileProviderFactoryProvider.overrideWithValue(() => _MemoryTiles())
    ], child: const ScarboroughTortoiseWatchApp()));
    expect(find.text('Report a tortoise'), findsOneWidget);

    await tester.tap(find.text('Report a tortoise'));
    await tester.pumpAndSettle();
    expect(find.text('Location first'), findsOneWidget);
    expect(find.text('What happened?'), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<IncidentType>), findsOneWidget);
    expect(find.textContaining('Demo mode'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<IncidentType>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alive / crossing road').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'abc');
    // A visible map centre is insufficient: submission still requires a chosen pin.
    await tester.ensureVisible(find.text('Submit report'));
    await tester.tap(find.text('Submit report'));
    await tester.pump();
    expect(find.text('Confirm the location'), findsOneWidget);
    await tester.ensureVisible(find.byIcon(Icons.location_pin));
    await tester.timedDrag(find.byIcon(Icons.location_pin),
        const Offset(60, 20), const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text('Manual location selected.'), findsOneWidget);
    await tester.tap(find.text('Submit report'));
    await tester.pump();
    expect(
        find.text('Enter a numeric compass bearing from 0 to less than 360.'),
        findsOneWidget);
    await tester.ensureVisible(find.byType(TextField).first);
    await tester.enterText(find.byType(TextField).first, '90');
    await tester.enterText(
        find.byType(TextField).last, 'Synthetic widget test note');
    await tester.ensureVisible(find.text('Submit report'));
    await tester.tap(find.text('Submit report'));
    await tester.pumpAndSettle();
    expect(find.text('Thank you'), findsOneWidget);
    expect(find.textContaining('Demo mode:'), findsOneWidget);
    expect(find.textContaining('same direction'), findsOneWidget);
  });
}

class _MemoryTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(Uint8List.fromList(
          image.encodePng(image.Image(width: 1, height: 1))));
}
