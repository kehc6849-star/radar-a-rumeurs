import 'content_validation_exception.dart';

/// Guard clauses applied before any processing of user input.
class ContentValidator {
  const ContentValidator();

  /// Long texts slow down the analysis and are rarely a single message.
  static const int maximumContentLength = 5000;

  /// Returns the trimmed content, or throws [ContentValidationException].
  String validate(String rawContent) {
    final String trimmedContent = rawContent.trim();

    if (trimmedContent.isEmpty) {
      throw const ContentValidationException(
        'Veuillez coller ou saisir un message à analyser.',
      );
    }

    if (trimmedContent.length > maximumContentLength) {
      throw ContentValidationException(
        'Le message est trop long (maximum $maximumContentLength caractères).',
      );
    }

    return trimmedContent;
  }
}
