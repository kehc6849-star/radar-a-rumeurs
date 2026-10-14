/// Thrown when an analysis cannot be done now (no server, no consent, no network).
///
/// The message is written for the user and is safe to show.
class AnalysisUnavailableException implements Exception {
  const AnalysisUnavailableException(this.message);

  final String message;
}
