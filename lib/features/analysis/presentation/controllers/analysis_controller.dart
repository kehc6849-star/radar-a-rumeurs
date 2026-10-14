import 'package:flutter/foundation.dart';

import '../../domain/models/analysis_history_entry.dart';
import '../../domain/models/analysis_input_kind.dart';
import '../../domain/models/analysis_verdict.dart';
import '../../domain/models/screenshot_input.dart';
import '../../domain/repositories/analysis_history_repository.dart';
import '../../domain/services/analysis_unavailable_exception.dart';
import '../../domain/services/content_analyzer.dart';
import '../../domain/services/content_validation_exception.dart';
import '../../domain/services/screenshot_analyzer.dart';

enum AnalysisStatus {
  idle,
  analyzing,
  success,
  failure,
}

/// Holds the state of the current analysis for the screens.
/// It contains no display code, so it is easy to unit test.
class AnalysisController extends ChangeNotifier {
  AnalysisController({
    required this.contentAnalyzer,
    required this.screenshotAnalyzer,
    required this.historyRepository,
  });

  final ContentAnalyzer contentAnalyzer;
  final ScreenshotAnalyzer screenshotAnalyzer;
  final AnalysisHistoryRepository historyRepository;

  AnalysisStatus _status = AnalysisStatus.idle;
  AnalysisVerdict? _latestVerdict;
  String? _errorMessage;
  bool _isDisposed = false;

  AnalysisStatus get status => _status;
  AnalysisVerdict? get latestVerdict => _latestVerdict;
  String? get errorMessage => _errorMessage;

  Future<void> analyzeContent(String rawContent) {
    return _runAnalysis(
      () => contentAnalyzer.analyzeContent(rawContent),
      AnalysisInputKind.text,
    );
  }

  Future<void> analyzeScreenshot(ScreenshotInput screenshot) {
    return _runAnalysis(
      () => screenshotAnalyzer.analyzeScreenshot(screenshot),
      AnalysisInputKind.screenshot,
    );
  }

  /// Forgets the last result so no message stays in memory longer than needed.
  void reset() {
    _status = AnalysisStatus.idle;
    _latestVerdict = null;
    _errorMessage = null;
    _notifyIfActive();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _runAnalysis(
    Future<AnalysisVerdict> Function() analysisAction,
    AnalysisInputKind inputKind,
  ) async {
    // Guard clause: ignore a second tap while an analysis is running.
    if (_status == AnalysisStatus.analyzing) {
      return;
    }

    _status = AnalysisStatus.analyzing;
    _latestVerdict = null;
    _errorMessage = null;
    _notifyIfActive();

    try {
      final AnalysisVerdict verdict = await analysisAction();

      _latestVerdict = verdict;
      _status = AnalysisStatus.success;

      await _recordHistory(verdict, inputKind);
    } on ContentValidationException catch (validationError) {
      _errorMessage = validationError.message;
      _status = AnalysisStatus.failure;
    } on AnalysisUnavailableException catch (unavailableError) {
      _errorMessage = unavailableError.message;
      _status = AnalysisStatus.failure;
    } on Exception {
      // The real cause is not shown: it could contain parts of the message.
      _errorMessage = 'Analyse impossible pour le moment. Veuillez réessayer.';
      _status = AnalysisStatus.failure;
    }

    _notifyIfActive();
  }

  Future<void> _recordHistory(
    AnalysisVerdict verdict,
    AnalysisInputKind inputKind,
  ) async {
    final AnalysisHistoryEntry entry = AnalysisHistoryEntry(
      identifier: DateTime.now().microsecondsSinceEpoch.toString(),
      analyzedAt: verdict.analyzedAt,
      level: verdict.level,
      riskScore: verdict.riskScore,
      inputKind: inputKind,
      source: verdict.source,
      primaryFamily:
          verdict.signals.isEmpty ? null : verdict.signals.first.family,
    );

    try {
      await historyRepository.addEntry(entry);
    } on Exception {
      // The history is a bonus: a storage problem must not hide the result.
      return;
    }
  }

  // The user can leave the app while an analysis is running.
  // Notifying a disposed controller would throw an error.
  void _notifyIfActive() {
    if (_isDisposed) {
      return;
    }

    notifyListeners();
  }
}
