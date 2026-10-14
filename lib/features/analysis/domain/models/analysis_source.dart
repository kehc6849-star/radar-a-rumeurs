/// Tells the user which engines produced the verdict.
enum AnalysisSource {
  /// Only the rules that run on the phone.
  localRules,

  /// Local rules combined with the AI model.
  hybrid,
}
