import 'dart:typed_data';

/// An image chosen by the user, ready to be analyzed.
class ScreenshotInput {
  const ScreenshotInput({
    required this.imageBytes,
    required this.mimeType,
  });

  /// Large images are slow to send and use more of the AI quota.
  static const int maximumImageBytes = 4000000;

  final Uint8List imageBytes;
  final String mimeType;
}
