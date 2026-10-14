import 'package:radar_a_rumeurs/features/analysis/domain/models/ai_consent_status.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/analysis_history_entry.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/analysis_input_kind.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/analysis_source.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/analysis_verdict.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/remote_analysis_result.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/screenshot_input.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/threat_family.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/verdict_level.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/repositories/ai_consent_repository.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/repositories/analysis_history_repository.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/rules/scam_rule_catalog.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/services/remote_analysis_gateway.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/services/rule_based_content_analyzer.dart';

RuleBasedContentAnalyzer buildLocalAnalyzer() {
  return RuleBasedContentAnalyzer(rules: ScamRuleCatalog.buildDefaultRules());
}

RemoteAnalysisResult buildRemoteResult({
  int riskScore = 70,
  ThreatFamily? threatFamily = ThreatFamily.phishing,
  List<RemoteSignal> signals = const <RemoteSignal>[
    RemoteSignal(title: 'Signal IA', explanation: 'Explication IA.'),
  ],
  List<String> recommendedActions = const <String>['Action IA 1'],
  String? extractedText,
}) {
  return RemoteAnalysisResult(
    riskScore: riskScore,
    threatFamily: threatFamily,
    signals: signals,
    recommendedActions: recommendedActions,
    modelName: 'Gemma test',
    extractedText: extractedText,
  );
}

AnalysisVerdict buildVerdict({
  VerdictLevel level = VerdictLevel.dangerous,
  int riskScore = 70,
}) {
  return AnalysisVerdict(
    level: level,
    riskScore: riskScore,
    signals: const [],
    summary: 'Résumé de test',
    recommendedActions: const [],
    analyzedAt: DateTime(2026, 10, 12, 10, 30),
  );
}

AnalysisHistoryEntry buildHistoryEntry({String identifier = '1'}) {
  return AnalysisHistoryEntry(
    identifier: identifier,
    analyzedAt: DateTime(2026, 10, 12, 10, 30),
    level: VerdictLevel.dangerous,
    riskScore: 70,
    inputKind: AnalysisInputKind.text,
    source: AnalysisSource.localRules,
    primaryFamily: ThreatFamily.phishing,
  );
}

class FakeAiConsentRepository implements AiConsentRepository {
  FakeAiConsentRepository(this.status);

  AiConsentStatus status;

  @override
  Future<AiConsentStatus> loadStatus() async => status;

  @override
  Future<void> saveStatus(AiConsentStatus newStatus) async {
    status = newStatus;
  }
}

class FakeRemoteAnalysisGateway implements RemoteAnalysisGateway {
  FakeRemoteAnalysisGateway({
    this.isConfigured = true,
    this.result,
    this.failure,
  });

  @override
  final bool isConfigured;

  final RemoteAnalysisResult? result;
  final RemoteAnalysisException? failure;

  int textCallCount = 0;
  int screenshotCallCount = 0;

  @override
  Future<RemoteAnalysisResult> analyzeText(String text) async {
    textCallCount++;
    return _answer();
  }

  @override
  Future<RemoteAnalysisResult> analyzeScreenshot(
    ScreenshotInput screenshot,
  ) async {
    screenshotCallCount++;
    return _answer();
  }

  RemoteAnalysisResult _answer() {
    final RemoteAnalysisException? plannedFailure = failure;

    if (plannedFailure != null) {
      throw plannedFailure;
    }

    final RemoteAnalysisResult? plannedResult = result;

    if (plannedResult == null) {
      throw StateError('The fake gateway has no planned result.');
    }

    return plannedResult;
  }
}

class FakeHistoryRepository implements AnalysisHistoryRepository {
  FakeHistoryRepository({this.shouldFail = false});

  final bool shouldFail;
  final List<AnalysisHistoryEntry> entries = <AnalysisHistoryEntry>[];

  @override
  Future<List<AnalysisHistoryEntry>> loadEntries() async => entries;

  @override
  Future<void> addEntry(AnalysisHistoryEntry entry) async {
    if (shouldFail) {
      throw Exception('storage failure');
    }

    entries.insert(0, entry);
  }

  @override
  Future<void> clearEntries() async {
    entries.clear();
  }
}
