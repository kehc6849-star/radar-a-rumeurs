/// A message in two forms: the original one and a simplified one for matching.
class NormalizedContent {
  const NormalizedContent({
    required this.originalText,
    required this.matchingText,
  });

  final String originalText;

  /// Lower case, without accents, with single spaces.
  /// Rules always search in this version so that "Félicitations"
  /// and "felicitations" give the same result.
  final String matchingText;
}
