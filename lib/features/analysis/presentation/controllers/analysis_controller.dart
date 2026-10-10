import 'package:flutter/foundation.dart';

import '../../domain/models/analysis_verdict.dart';
import '../../domain/services/content_analyzer.dart';
import '../../domain/services/content_validation_exception.dart';

enum AnalysisStatus {
  idle,
  analyzing,
  success,
  failure,
}

/// Holds the state of the current analysis for the screens.
/// It contains no display code, so it is easy to unit test.
class AnalysisController extends ChangeNotifier {
  AnalysisController({required this.contentAnalyzer});

  final ContentAnalyzer contentAnalyzer;

  AnalysisStatus _status = AnalysisStatus.idle;
  AnalysisVerdict? _latestVerdict;
  String? _errorMessage;
  bool _isDisposed = false;

  AnalysisStatus get status => _status;
  AnalysisVerdict? get latestVerdict => _latestVerdict;
  String? get errorMessage => _errorMessage;

  Future<void> analyzeContent(String rawContent) async {
    // Guard clause: ignore a second tap while an analysis is running.
    if (_status == AnalysisStatus.analyzing) {
      return;
    }

    _status = AnalysisStatus.analyzing;
    _latestVerdict = null;
    _errorMessage = null;
    _notifyIfActive();

    try {
      _latestVerdict = await contentAnalyzer.analyzeContent(rawContent);
      _status = AnalysisStatus.success;
    } on ContentValidationException catch (validationError) {
      _errorMessage = validationError.message;
      _status = AnalysisStatus.failure;
    } on Exception {
      // The real cause is not shown: it could contain parts of the message.
      _errorMessage = 'Analyse impossible pour le moment. Veuillez réessayer.';
      _status = AnalysisStatus.failure;
    }

    _notifyIfActive();
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

  // The user can leave the app while an analysis is running.
  // Notifying a disposed controller would throw an error.
  void _notifyIfActive() {
    if (_isDisposed) {
      return;
    }

    notifyListeners();
  }
}
