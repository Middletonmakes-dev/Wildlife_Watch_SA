// ignore_for_file: depend_on_referenced_packages

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:scarborough_tortoise_watch/app/app.dart';
import 'package:scarborough_tortoise_watch/app/providers.dart';

void main() {
  late ImagePickerPlatform originalPlatform;
  late _FakeImagePickerPlatform fakePlatform;

  setUp(() {
    originalPlatform = ImagePickerPlatform.instance;
    fakePlatform = _FakeImagePickerPlatform();
    ImagePickerPlatform.instance = fakePlatform;
  });

  tearDown(() {
    ImagePickerPlatform.instance = originalPlatform;
  });

  testWidgets('photo button offers camera and existing-photo choices',
      (tester) async {
    await _openReport(tester);

    await tester.tap(find.text('Add an optional photo'));
    await tester.pumpAndSettle();

    expect(find.text('Take photo'), findsOneWidget);
    expect(find.text('Choose existing photo'), findsOneWidget);
  });

  testWidgets('photo choices route to the selected image source',
      (tester) async {
    await _openReport(tester);

    await tester.tap(find.text('Add an optional photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose existing photo'));
    await tester.pumpAndSettle();
    expect(fakePlatform.lastSource, ImageSource.gallery);

    await tester.tap(find.text('Add an optional photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take photo'));
    await tester.pumpAndSettle();
    expect(fakePlatform.lastSource, ImageSource.camera);
  });

  testWidgets('cancelling photo selection preserves the existing draft photo',
      (tester) async {
    fakePlatform.pickedFile = XFile.fromData(
      Uint8List.fromList(image.encodeJpg(image.Image(width: 2, height: 2))),
      name: 'tortoise.jpg',
    );
    await _openReport(tester);

    await tester.tap(find.text('Add an optional photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose existing photo'));
    await tester.pumpAndSettle();
    expect(find.text('Photo selected'), findsOneWidget);

    fakePlatform.pickedFile = null;
    await tester.tap(find.text('Photo selected'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Choose existing photo'));
    await tester.pumpAndSettle();

    expect(find.text('Photo selected'), findsOneWidget);
  });
}

Future<void> _openReport(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        mapTileProviderFactoryProvider.overrideWithValue(() => _MemoryTiles()),
      ],
      child: const ScarboroughTortoiseWatchApp(),
    ),
  );
  await tester.tap(find.text('Report a tortoise'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Crossing road'));
  await tester.pumpAndSettle();
}

class _FakeImagePickerPlatform extends ImagePickerPlatform
    with MockPlatformInterfaceMixin {
  ImageSource? lastSource;
  XFile? pickedFile;

  @override
  Future<XFile?> getImageFromSource({
    required ImageSource source,
    ImagePickerOptions options = const ImagePickerOptions(),
  }) async {
    lastSource = source;
    return pickedFile;
  }
}

class _MemoryTiles extends TileProvider {
  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) =>
      MemoryImage(Uint8List.fromList(
          image.encodePng(image.Image(width: 1, height: 1))));
}
