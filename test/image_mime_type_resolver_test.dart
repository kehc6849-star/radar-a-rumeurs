import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/services/image_mime_type_resolver.dart';

Uint8List buildBytes(List<int> header) {
  final Uint8List bytes = Uint8List(32);

  for (int position = 0; position < header.length; position++) {
    bytes[position] = header[position];
  }

  return bytes;
}

void main() {
  group('ImageMimeTypeResolver', () {
    test('detects JPEG, PNG and WebP from the content', () {
      expect(
        ImageMimeTypeResolver.resolve(buildBytes(<int>[0xFF, 0xD8, 0xFF, 0xE0])),
        'image/jpeg',
      );
      expect(
        ImageMimeTypeResolver.resolve(buildBytes(<int>[0x89, 0x50, 0x4E, 0x47])),
        'image/png',
      );
      expect(
        ImageMimeTypeResolver.resolve(
          buildBytes(<int>[0x52, 0x49, 0x46, 0x46, 0, 0, 0, 0, 0x57, 0x45, 0x42, 0x50]),
        ),
        'image/webp',
      );
    });

    test('refuses unknown or too short content', () {
      expect(ImageMimeTypeResolver.resolve(buildBytes(<int>[0x47, 0x49, 0x46])), isNull);
      expect(ImageMimeTypeResolver.resolve(Uint8List.fromList(<int>[0xFF, 0xD8])), isNull);
    });
  });
}
