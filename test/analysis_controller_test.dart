import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/analysis_input_kind.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/analysis_verdict.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/models/screenshot_input.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/services/analysis_unavailable_exception.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/services/content_analyzer.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/services/content_validation_exception.dart';
import 'package:radar_a_rumeurs/features/analysis/domain/services/screenshot_analyzer.dart';
import 'package:radar_a_rumeurs/features/analysis/presentation/controllers/analysis_controller.dart';

import 'support/test_fakes.dart';

class StubContentAnalyzer implements ContentAnalyzer {
  StubContentAnalyzer(this.answer);

  final Future<AnalysisVerdict> Function() answer;

  @override
  Future<AnalysisVerdict> analyzeContent(String rawContent) => answer();
}

class StubScreenshotAnalyzer implements ScreenshotAnalyzer {
  StubScreenshotAnalyzer(this.answer);

  final Future<AnalysisVerdict> Function() answer;

  @override
  Future<AnalysisVerdict> analyzeScreenshot(ScreenshotInput screenshot) =>
      answer();
}

AnalysisController buildController({
  required Future<AnalysisVerdict> Function() textAnswer,
  Future<AnalysisVerdict> Function()? screenshotAnswer,
  FakeHistoryRepository? historyRepository,
}) {
  return AnalysisController(
    contentAnalyzer: StubContentAnalyzer(textAnswer),
    screenshotAnalyzer: StubScreenshotAnalyzer(
      screenshotAnswer ?? () async => buildVerdict(),
    ),
    historyRepository: historyRepository ?? FakeHistoryRepository(),
  );
}

void main() {
  group('AnalysisController', () {
    test('stores the verdict and records one history entry', () async {
      final FakeHistoryRepository historyRepository = FakeHistoryRepository();
      final AnalysisController controller = buildController(
        textAnswer: () async => buildVerdict(),
        historyRepository: historyRepository,
      );

      await controller.analyzeContent('hello');

      expect(controller.status, AnalysisStatus.success);
      expect(controller.latestVerdict, isNotNull);
      expect(historyRepository.entries.single.inputKind, AnalysisInputKind.text);
    });

    test('marks screenshot analyses in the history', () async {
      final FakeHistoryRepository historyRepository = FakeHistoryRepository();
      final AnalysisController controller = buildController(
        textAnswer: () async => buildVerdict(),
        historyRepository: historyRepository,
      );

      await controller.analyzeScreenshot(
        ScreenshotInput(imageBytes: _singleByte(), mimeType: 'image/png'),
      );

      expect(
        historyRepository.entries.single.inputKind,
        AnalysisInputKind.screenshot,
      );
    });

    test('a history storage problem does not hide the result', () async {
      final AnalysisController controller = buildController(
        textAnswer: () async => buildVerdict(),
        historyRepository: FakeHistoryRepository(shouldFail: true),
      );

      await controller.analyzeContent('hello');

      expect(controller.status, AnalysisStatus.success);
      expect(controller.latestVerdict, isNotNull);
    });

    test('shows the message of a validation error', () async {
      final AnalysisController controller = buildController(
        textAnswer: () async =>
            throw const ContentValidationException('Message vide.'),
      );

      await controller.analyzeContent('');

      expect(controller.status, AnalysisStatus.failure);
      expect(controller.errorMessage, 'Message vide.');
    });

    test('shows the message when the analysis is unavailable', () async {
      final AnalysisController controller = buildController(
        textAnswer: () async => buildVerdict(),
        screenshotAnswer: () async =>
            throw const AnalysisUnavailableException('Pas de serveur.'),
      );

      await controller.analyzeScreenshot(
        ScreenshotInput(imageBytes: _singleByte(), mimeType: 'image/png'),
      );

      expect(controller.status, AnalysisStatus.failure);
      expect(controller.errorMessage, 'Pas de serveur.');
    });

    test('hides technical errors behind a generic message', () async {
      final AnalysisController controller = buildController(
        textAnswer: () async => throw Exception('secret technical detail'),
      );

      await controller.analyzeContent('hello');

      expect(controller.status, AnalysisStatus.failure);
      expect(controller.errorMessage, isNot(contains('secret')));
    });

    test('ignores a second request while one is running', () async {
      final Completer<AnalysisVerdict> completer = Completer<AnalysisVerdict>();
      int callCount = 0;

      final AnalysisController controller = buildController(
        textAnswer: () {
          callCount++;
          return completer.future;
        },
      );

      final Future<void> firstAnalysis = controller.analyzeContent('one');
      await controller.analyzeContent('two');

      completer.complete(buildVerdict());
      await firstAnalysis;

      expect(callCount, 1);
      expect(controller.status, AnalysisStatus.success);
    });

    test('reset forgets the result', () async {
      final AnalysisController controller =
          buildController(textAnswer: () async => buildVerdict());

      await controller.analyzeContent('hello');
      controller.reset();

      expect(controller.status, AnalysisStatus.idle);
      expect(controller.latestVerdict, isNull);
    });
  });
}

Uint8List _singleByte() => Uint8List.fromList(<int>[1]);
