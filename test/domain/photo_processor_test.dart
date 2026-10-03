import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:scarborough_tortoise_watch/features/report/data/photo_processor.dart';

void main() {
  test('photo processing bounds JPEG dimensions and discards GPS EXIF', () {
    final source = image.Image(width: 2000, height: 1000);
    source.exif.gpsIfd[1] = image.IfdValueAscii('S');
    source.exif.gpsIfd[3] = image.IfdValueAscii('E');
    final encoded = Uint8List.fromList(image.encodeJpg(source));
    expect(image.decodeJpg(encoded)!.exif.gpsIfd.isEmpty, isFalse);
    final result = const PhotoProcessor().process(encoded);
    final decoded = image.decodeJpg(result)!;
    expect(decoded.width, 1600);
    expect(decoded.height, 800);
    expect(decoded.exif.gpsIfd.isEmpty, isTrue);
    expect(result.length, lessThan(2 * 1024 * 1024));
  });
}
