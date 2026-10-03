import 'dart:typed_data';

import 'package:image/image.dart' as image;

class PhotoProcessor {
  const PhotoProcessor({this.maxLongestEdge = 1600, this.quality = 82});

  final int maxLongestEdge;
  final int quality;

  Uint8List process(Uint8List bytes) {
    final decoded = image.decodeImage(bytes);
    if (decoded == null)
      throw const FormatException('Image could not be decoded');
    final longestEdge =
        decoded.width > decoded.height ? decoded.width : decoded.height;
    final resized = longestEdge > maxLongestEdge
        ? image.copyResize(
            decoded,
            width: decoded.width >= decoded.height
                ? maxLongestEdge
                : (decoded.width * maxLongestEdge / decoded.height).round(),
            height: decoded.height >= decoded.width
                ? maxLongestEdge
                : (decoded.height * maxLongestEdge / decoded.width).round(),
          )
        : decoded;
    final oriented = image.bakeOrientation(resized);
    // Fresh pixels deliberately discard EXIF/GPS and other source metadata.
    final clean = image.Image(
        width: oriented.width, height: oriented.height, numChannels: 3);
    image.compositeImage(clean, oriented);
    return Uint8List.fromList(image.encodeJpg(clean, quality: quality));
  }
}
