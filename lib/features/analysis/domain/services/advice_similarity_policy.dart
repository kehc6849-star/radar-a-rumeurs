/// Tells if a piece of advice repeats another one that is already shown.
///
/// Comparing the exact text is not enough: "Ne cliquez sur aucun lien." and
/// "Ne cliquez sur aucun lien contenu dans ce message." give the same advice
/// but are different strings. So we compare the meaningful words instead.
class AdviceSimilarityPolicy {
  const AdviceSimilarityPolicy._();

  /// Share of common words, measured against the SHORTER advice, from which
  /// two pieces of advice are treated as the same one.
  static const double _similarityThreshold = 0.6;

  static const int _minimumMeaningfulWordLength = 3;

  // Common small words carry no meaning for this comparison.
  static const Set<String> _ignoredWords = <String>{
    'les', 'des', 'une', 'ces', 'cette', 'aux', 'dans', 'pour',
    'par', 'avec', 'que', 'qui', 'son', 'ses', 'vos', 'vous',
    'votre', 'est', 'sont', 'pas', 'sur', 'comme', 'puis', 'plus',
    'tout', 'tous', 'leur', 'elle', 'ils', 'mais', 'donc', 'sans',
    'sous', 'chez',
  };

  static final RegExp _wordSeparatorPattern = RegExp(
    r'[^\p{L}\p{N}]+',
    unicode: true,
  );

  /// Returns true when [candidateAdvice] says (almost) the same thing as one
  /// of [existingAdvices], or when it is empty and so adds nothing.
  static bool isTooSimilar({
    required String candidateAdvice,
    required Iterable<String> existingAdvices,
  }) {
    final String normalizedCandidate = candidateAdvice.trim().toLowerCase();

    if (normalizedCandidate.isEmpty) {
      return true;
    }

    final Set<String> candidateWords =
        _extractMeaningfulWords(normalizedCandidate);

    for (final String existingAdvice in existingAdvices) {
      final String normalizedExisting = existingAdvice.trim().toLowerCase();

      if (normalizedExisting == normalizedCandidate) {
        return true;
      }

      // Guard clause: without meaningful words we cannot compare by meaning.
      if (candidateWords.isEmpty) {
        continue;
      }

      final Set<String> existingWords =
          _extractMeaningfulWords(normalizedExisting);

      if (existingWords.isEmpty) {
        continue;
      }

      final int sharedWordCount =
          candidateWords.intersection(existingWords).length;
      final int shorterWordCount = candidateWords.length < existingWords.length
          ? candidateWords.length
          : existingWords.length;

      if (sharedWordCount / shorterWordCount >= _similarityThreshold) {
        return true;
      }
    }

    return false;
  }

  static Set<String> _extractMeaningfulWords(String normalizedText) {
    final Set<String> meaningfulWords = <String>{};

    for (final String word in normalizedText.split(_wordSeparatorPattern)) {
      if (word.length < _minimumMeaningfulWordLength) {
        continue;
      }

      if (_ignoredWords.contains(word)) {
        continue;
      }

      meaningfulWords.add(word);
    }

    return meaningfulWords;
  }
}
