import '../models/detected_signal.dart';
import '../models/normalized_content.dart';
import '../models/threat_family.dart';
import 'scam_detection_rule.dart';

/// A rule that triggers when EVERY group of patterns has at least one match.
///
/// Inside a group, patterns are alternatives (logical OR).
/// Between groups, it is a logical AND. This keeps false alarms low:
/// for example "code" alone is harmless, but "code" + "send it to us" is not.
class KeywordCombinationRule implements ScamDetectionRule {
  KeywordCombinationRule({
    required this.identifier,
    required this.family,
    required this.title,
    required this.explanation,
    required this.weight,
    required List<List<RegExp>> requiredPatternGroups,
  })  : assert(requiredPatternGroups.isNotEmpty),
        _requiredPatternGroups =
            List<List<RegExp>>.unmodifiable(requiredPatternGroups);

  @override
  final String identifier;

  final ThreatFamily family;
  final String title;
  final String explanation;
  final int weight;

  final List<List<RegExp>> _requiredPatternGroups;

  @override
  List<DetectedSignal> evaluate(NormalizedContent content) {
    final bool matchesEveryGroup = _requiredPatternGroups.every(
      (List<RegExp> alternativePatterns) => alternativePatterns.any(
        (RegExp pattern) => pattern.hasMatch(content.matchingText),
      ),
    );

    if (!matchesEveryGroup) {
      return const <DetectedSignal>[];
    }

    return <DetectedSignal>[
      DetectedSignal(
        ruleIdentifier: identifier,
        title: title,
        explanation: explanation,
        weight: weight,
        family: family,
      ),
    ];
  }
}
