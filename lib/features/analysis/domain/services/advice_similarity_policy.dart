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

  // With fewer meaningful words, a "same meaning" guess is too weak: only an
  // identical text counts as a repeat.
  static const int _minimumWordCountForComparison = 2;

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

      final Set<String> existingWords =
          _extractMeaningfulWords(normalizedExisting);
      final int shorterWordCount = candidateWords.length < existingWords.length
          ? candidateWords.length
          : existingWords.length;

      // Guard clause: too few words to compare by meaning (also avoids a
      // division by zero below).
      if (shorterWordCount < _minimumWordCountForComparison) {
        continue;
      }

      final int sharedWordCount =
          candidateWords.intersection(existingWords).length;

      if (sharedWordCount / shorterWordCount >= _similarityThreshold) {
        return true;
      }
    }

    return false;
  }

  static Set<String> _extractMeaningfulWords(String normalizedText) {
    final Set<String> meaningfulWords = <String>{};

    for (final String word in normalizedText.split(_wordSeparatorPattern)) {
      // Numbers always matter, even when they are short ("1" is not "2").
      final bool isNumber = int.tryParse(word) != null;

      if (word.length < _minimumMeaningfulWordLength && !isNumber) {
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
