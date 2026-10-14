import 'dart:typed_data';

/// Finds the image type from the first bytes of the file.
///
/// The file name is never trusted: only the real content decides.
class ImageMimeTypeResolver {
  const ImageMimeTypeResolver._();

  static const int _minimumHeaderLength = 12;

  static String? resolve(Uint8List imageBytes) {
    if (imageBytes.length < _minimumHeaderLength) {
      return null;
    }

    final bool isJpeg = imageBytes[0] == 0xFF &&
        imageBytes[1] == 0xD8 &&
        imageBytes[2] == 0xFF;

    if (isJpeg) {
      return 'image/jpeg';
    }

    final bool isPng = imageBytes[0] == 0x89 &&
        imageBytes[1] == 0x50 &&
        imageBytes[2] == 0x4E &&
        imageBytes[3] == 0x47;

    if (isPng) {
      return 'image/png';
    }

    final bool hasRiffHeader = imageBytes[0] == 0x52 &&
        imageBytes[1] == 0x49 &&
        imageBytes[2] == 0x46 &&
        imageBytes[3] == 0x46;
    final bool hasWebpMarker = imageBytes[8] == 0x57 &&
        imageBytes[9] == 0x45 &&
        imageBytes[10] == 0x42 &&
        imageBytes[11] == 0x50;

    if (hasRiffHeader && hasWebpMarker) {
      return 'image/webp';
    }

    return null;
  }
}
