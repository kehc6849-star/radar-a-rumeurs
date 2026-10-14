import 'analysis_input_kind.dart';
import 'analysis_source.dart';
import 'threat_family.dart';
import 'verdict_level.dart';

/// One line of the history.
///
/// Privacy: it keeps the result only. The analyzed message or image is never
/// stored, so the history cannot leak what the user received.
class AnalysisHistoryEntry {
  const AnalysisHistoryEntry({
    required this.identifier,
    required this.analyzedAt,
    required this.level,
    required this.riskScore,
    required this.inputKind,
    required this.source,
    this.primaryFamily,
  });

  final String identifier;
  final DateTime analyzedAt;
  final VerdictLevel level;
  final int riskScore;
  final AnalysisInputKind inputKind;
  final AnalysisSource source;
  final ThreatFamily? primaryFamily;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'identifier': identifier,
      'analyzedAt': analyzedAt.toIso8601String(),
      'level': level.name,
      'riskScore': riskScore,
      'inputKind': inputKind.name,
      'source': source.name,
      'primaryFamily': primaryFamily?.name,
    };
  }

  /// Returns null when the stored data is damaged or from an unknown version.
  static AnalysisHistoryEntry? tryParse(Object? decodedJson) {
    if (decodedJson is! Map<String, Object?>) {
      return null;
    }

    final Object? identifier = decodedJson['identifier'];
    final Object? analyzedAtText = decodedJson['analyzedAt'];
    final Object? levelName = decodedJson['level'];
    final Object? riskScore = decodedJson['riskScore'];
    final Object? inputKindName = decodedJson['inputKind'];
    final Object? sourceName = decodedJson['source'];
    final Object? familyName = decodedJson['primaryFamily'];

    if (identifier is! String ||
        analyzedAtText is! String ||
        levelName is! String ||
        riskScore is! int ||
        inputKindName is! String ||
        sourceName is! String) {
      return null;
    }

    final DateTime? analyzedAt = DateTime.tryParse(analyzedAtText);

    if (analyzedAt == null) {
      return null;
    }

    try {
      return AnalysisHistoryEntry(
        identifier: identifier,
        analyzedAt: analyzedAt,
        level: VerdictLevel.values.byName(levelName),
        riskScore: riskScore,
        inputKind: AnalysisInputKind.values.byName(inputKindName),
        source: AnalysisSource.values.byName(sourceName),
        primaryFamily: familyName is String
            ? ThreatFamily.values.byName(familyName)
            : null,
      );
    } on ArgumentError {
      return null;
    }
  }
}
