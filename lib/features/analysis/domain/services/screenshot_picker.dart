import '../models/screenshot_input.dart';

/// Contract for choosing an image on the phone.
///
/// Returns null when the user closes the picker without choosing.
/// Throws a ContentValidationException when the image cannot be used.
abstract interface class ScreenshotPicker {
  Future<ScreenshotInput?> pickScreenshot();
}
