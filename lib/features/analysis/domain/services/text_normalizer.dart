import '../models/normalized_content.dart';

/// Simplifies text so that rules do not depend on accents or capital letters.
class TextNormalizer {
  const TextNormalizer();

  static const Map<String, String> _characterReplacements = <String, String>{
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'á': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'í': 'i',
    'ô': 'o',
    'ö': 'o',
    'ó': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ú': 'u',
    'ç': 'c',
    'ñ': 'n',
    'œ': 'oe',
    // Phone keyboards often use curly apostrophes.
    '’': "'",
    '‘': "'",
    '´': "'",
  };

  static final RegExp _whitespacePattern = RegExp(r'\s+');

  NormalizedContent normalize(String rawContent) {
    final String trimmedContent = rawContent.trim();
    final String lowerCaseContent = trimmedContent.toLowerCase();
    final StringBuffer simplifiedBuffer = StringBuffer();

    for (final String character in lowerCaseContent.split('')) {
      simplifiedBuffer.write(_characterReplacements[character] ?? character);
    }

    final String matchingText = simplifiedBuffer
        .toString()
        .replaceAll(_whitespacePattern, ' ')
        .trim();

    return NormalizedContent(
      originalText: trimmedContent,
      matchingText: matchingText,
    );
  }
}
