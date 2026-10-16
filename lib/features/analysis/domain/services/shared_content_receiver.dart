import '../models/shared_content.dart';

/// Contract for receiving content shared from other apps.
///
/// The domain does not know how the phone delivers the content.
abstract interface class SharedContentReceiver {
  /// Content shared while the application is already open.
  Stream<SharedContent> get sharedContentStream;

  /// Content that opened the application, or null when it was opened normally.
  /// The content is given only once: a second call returns null.
  Future<SharedContent?> takeInitialContent();

  /// Stops listening. The receiver cannot be used afterwards.
  void close();
}