import 'dart:async';
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:flutter/services.dart';

import '../../domain/models/screenshot_input.dart';
import '../../domain/models/shared_content.dart';
import '../../domain/services/content_validation_exception.dart';
import '../../domain/services/content_validator.dart';
import '../../domain/services/image_mime_type_resolver.dart';
import '../../domain/services/shared_content_receiver.dart';

/// Receives the texts and images that other Android apps share with this app.
///
/// The Android side (`MainActivity.kt`) reads the share and sends a simple map
/// through a method channel. This class checks it with the same rules as a
/// pasted text and a gallery image, then gives the domain a [SharedContent].
class AndroidSharedContentReceiver implements SharedContentReceiver {
  AndroidSharedContentReceiver({
    MethodChannel channel = const MethodChannel(channelName),
    ContentValidator contentValidator = const ContentValidator(),
  })  : _channel = channel,
        _contentValidator = contentValidator {
    _channel.setMethodCallHandler(_handleNativeCall);
  }

  /// Must be the same name as in `MainActivity.kt`.
  static const String channelName = 'zero_trust/shared_content';

  static const String _takeInitialContentMethod = 'takeInitialContent';
  static const String _contentReceivedMethod = 'contentReceived';

  static const String _textKind = 'text';
  static const String _imageKind = 'image';
  static const String _unreadableKind = 'unreadable';

  static const String _unreadableMessage =
      'Impossible de lire le contenu partagé.';

  final MethodChannel _channel;
  final ContentValidator _contentValidator;
  final StreamController<SharedContent> _streamController =
      StreamController<SharedContent>.broadcast();

  bool _isInitialContentTaken = false;
  bool _isClosed = false;

  @override
  Stream<SharedContent> get sharedContentStream => _streamController.stream;

  @override
  Future<SharedContent?> takeInitialContent() async {
    // Guard clause: the content is given only once.
    if (_isClosed || _isInitialContentTaken) {
      return null;
    }

    _isInitialContentTaken = true;

    try {
      final Object? rawContent = await _channel.invokeMethod<Object?>(
        _takeInitialContentMethod,
      );

      return _convert(rawContent);
    } on MissingPluginException {
      // Not running on Android (or in a test): nothing was shared.
      return null;
    } on PlatformException {
      return const SharedContentRejected(_unreadableMessage);
    }
  }

  @override
  void close() {
    if (_isClosed) {
      return;
    }

    _isClosed = true;
    _channel.setMethodCallHandler(null);
    unawaited(_streamController.close());
  }

  // Android sends a new share while the app is already open.
  Future<void> _handleNativeCall(MethodCall call) async {
    if (call.method != _contentReceivedMethod || _isClosed) {
      return;
    }

    final SharedContent? content = _convert(call.arguments);

    if (content == null) {
      return;
    }

    _streamController.add(content);
  }

  SharedContent? _convert(Object? rawContent) {
    if (rawContent is! Map<Object?, Object?>) {
      return null;
    }

    final Object? kind = rawContent['type'];

    if (kind == _textKind) {
      return _convertText(rawContent['text']);
    }

    if (kind == _imageKind) {
      return _convertImage(rawContent['bytes']);
    }

    if (kind == _unreadableKind) {
      return const SharedContentRejected(_unreadableMessage);
    }

    return null;
  }

  SharedContent _convertText(Object? rawText) {
    if (rawText is! String) {
      return const SharedContentRejected(_unreadableMessage);
    }

    if (rawText.trim().isEmpty) {
      return const SharedContentRejected('Le texte partagé est vide.');
    }

    try {
      return SharedTextContent(_contentValidator.validate(rawText));
    } on ContentValidationException catch (validationError) {
      return SharedContentRejected(validationError.message);
    }
  }

  // The same checks as the gallery picker: size first, then the real format.
  SharedContent _convertImage(Object? rawBytes) {
    if (rawBytes is! Uint8List) {
      return const SharedContentRejected(_unreadableMessage);
    }

    if (rawBytes.length > ScreenshotInput.maximumImageBytes) {
      return const SharedContentRejected(
        'Image trop volumineuse. Choisissez une image plus légère.',
      );
    }

    final String? mimeType = ImageMimeTypeResolver.resolve(rawBytes);

    if (mimeType == null) {
      return const SharedContentRejected(
        "Format d'image non pris en charge. Utilisez JPEG, PNG ou WebP.",
      );
    }

    return SharedScreenshotContent(
      ScreenshotInput(imageBytes: rawBytes, mimeType: mimeType),
    );
  }
}
