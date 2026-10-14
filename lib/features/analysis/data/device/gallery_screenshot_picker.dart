import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../../domain/models/screenshot_input.dart';
import '../../domain/services/content_validation_exception.dart';
import '../../domain/services/image_mime_type_resolver.dart';
import '../../domain/services/screenshot_picker.dart';

/// Lets the user choose an image in the gallery of the phone.
class GalleryScreenshotPicker implements ScreenshotPicker {
  GalleryScreenshotPicker({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  // Smaller images are faster to send and use less of the AI quota.
  static const double _maximumImageSide = 1600;
  static const int _imageQuality = 85;

  final ImagePicker _imagePicker;

  @override
  Future<ScreenshotInput?> pickScreenshot() async {
    final XFile? pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: _maximumImageSide,
      maxHeight: _maximumImageSide,
      imageQuality: _imageQuality,
    );

    if (pickedFile == null) {
      return null;
    }

    final Uint8List imageBytes = await pickedFile.readAsBytes();

    if (imageBytes.length > ScreenshotInput.maximumImageBytes) {
      throw const ContentValidationException(
        'Image trop volumineuse. Choisissez une image plus légère.',
      );
    }

    final String? mimeType = ImageMimeTypeResolver.resolve(imageBytes);

    if (mimeType == null) {
      throw const ContentValidationException(
        "Format d'image non pris en charge. Utilisez JPEG, PNG ou WebP.",
      );
    }

    return ScreenshotInput(imageBytes: imageBytes, mimeType: mimeType);
  }
}
