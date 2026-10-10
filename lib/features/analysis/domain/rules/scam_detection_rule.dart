import '../models/detected_signal.dart';
import '../models/normalized_content.dart';

/// One detection rule. Rules must be pure: same input, same output,
/// no network, no storage, no logging of the message.
abstract interface class ScamDetectionRule {
  String get identifier;

  /// Returns the signals found in the content (an empty list if none).
  List<DetectedSignal> evaluate(NormalizedContent content);
}
