/// Thrown when the message given by the user cannot be analyzed.
///
/// The message text is safe to show on screen.
class ContentValidationException implements Exception {
  const ContentValidationException(this.message);

  final String message;
}
