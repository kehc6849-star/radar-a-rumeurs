import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/ai_consent_status.dart';
import '../../domain/models/analysis_verdict.dart';
import '../../domain/models/screenshot_input.dart';
import '../../domain/repositories/ai_consent_repository.dart';
import '../../domain/repositories/analysis_history_repository.dart';
import '../../domain/services/content_validation_exception.dart';
import '../../domain/services/content_validator.dart';
import '../../domain/services/screenshot_picker.dart';
import '../controllers/analysis_controller.dart';
import '../widgets/ai_consent_dialog.dart';
import 'history_screen.dart';
import 'verdict_screen.dart';

/// Entry screen: the user pastes a message or chooses a screenshot.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.analysisController,
    required this.consentRepository,
    required this.historyRepository,
    required this.screenshotPicker,
    required this.isAiAvailable,
  });

  final AnalysisController analysisController;
  final AiConsentRepository consentRepository;
  final AnalysisHistoryRepository historyRepository;
  final ScreenshotPicker screenshotPicker;

  /// False when no analysis server is configured: AI features are then hidden.
  final bool isAiAvailable;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _contentTextController = TextEditingController();

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((Duration frameTimestamp) {
      unawaited(_askForConsentIfUndecided());
    });
  }

  @override
  void dispose() {
    _contentTextController.dispose();
    super.dispose();
  }

  Future<void> _askForConsentIfUndecided() async {
    if (!widget.isAiAvailable) {
      return;
    }

    final AiConsentStatus currentStatus =
        await widget.consentRepository.loadStatus();

    if (!mounted || currentStatus != AiConsentStatus.undecided) {
      return;
    }

    await _requestAiConsent();
  }

  Future<AiConsentStatus> _requestAiConsent() async {
    final AiConsentStatus decision = await showAiConsentDialog(context);

    await widget.consentRepository.saveStatus(decision);

    return decision;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final ClipboardData? clipboardData =
        await Clipboard.getData(Clipboard.kTextPlain);

    // The screen may be closed while we wait for the clipboard.
    if (!mounted) {
      return;
    }

    final String? clipboardText = clipboardData?.text;

    if (clipboardText == null || clipboardText.trim().isEmpty) {
      _showMessage('Le presse-papiers est vide.');
      return;
    }

    _contentTextController.text = clipboardText;
  }

  Future<void> _analyzeText() {
    return _runAnalysisAndShowVerdict(
      () => widget.analysisController
          .analyzeContent(_contentTextController.text),
    );
  }

  Future<void> _analyzeScreenshot() async {
    final AiConsentStatus currentStatus =
        await widget.consentRepository.loadStatus();

    if (!mounted) {
      return;
    }

    if (currentStatus != AiConsentStatus.granted) {
      final AiConsentStatus decision = await _requestAiConsent();

      if (!mounted || decision != AiConsentStatus.granted) {
        return;
      }
    }

    final ScreenshotInput? pickedScreenshot = await _pickScreenshotSafely();

    if (!mounted || pickedScreenshot == null) {
      return;
    }

    await _runAnalysisAndShowVerdict(
      () => widget.analysisController.analyzeScreenshot(pickedScreenshot),
    );
  }

  Future<ScreenshotInput?> _pickScreenshotSafely() async {
    try {
      return await widget.screenshotPicker.pickScreenshot();
    } on ContentValidationException catch (validationError) {
      if (mounted) {
        _showMessage(validationError.message);
      }

      return null;
    }
  }

  Future<void> _runAnalysisAndShowVerdict(
    Future<void> Function() analysisAction,
  ) async {
    final AnalysisController analysisController = widget.analysisController;

    await analysisAction();

    if (!mounted) {
      return;
    }

    final AnalysisVerdict? verdict = analysisController.latestVerdict;

    if (analysisController.status != AnalysisStatus.success ||
        verdict == null) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext routeContext) => VerdictScreen(verdict: verdict),
      ),
    );

    if (!mounted) {
      return;
    }

    // Privacy: clear the message and the result as soon as the user is back.
    _contentTextController.clear();
    analysisController.reset();
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (BuildContext routeContext) => HistoryScreen(
          historyRepository: widget.historyRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Radar à Rumeurs'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Historique',
            icon: const Icon(Icons.history),
            onPressed: () {
              unawaited(_openHistory());
            },
          ),
          IconButton(
            tooltip: 'Analyse IA et confidentialité',
            icon: const Icon(Icons.shield_outlined),
            onPressed: widget.isAiAvailable
                ? () {
                    unawaited(_requestAiConsent());
                  }
                : null,
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Text(
              'Un message vous semble louche ?',
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              "Collez le texte reçu (SMS, WhatsApp, e-mail) ou choisissez une capture d'écran : Radar à Rumeurs repère les signes d'arnaque ou de désinformation.",
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _contentTextController,
              keyboardType: TextInputType.multiline,
              minLines: 6,
              maxLines: 12,
              maxLength: ContentValidator.maximumContentLength,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Collez ici le message à vérifier...',
              ),
            ),
            const SizedBox(height: 8),
            ListenableBuilder(
              listenable: widget.analysisController,
              builder: (BuildContext builderContext, Widget? unusedChild) {
                final bool isAnalyzing = widget.analysisController.status ==
                    AnalysisStatus.analyzing;
                final String? errorMessage =
                    widget.analysisController.errorMessage;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        OutlinedButton.icon(
                          onPressed: isAnalyzing ? null : _pasteFromClipboard,
                          icon: const Icon(Icons.content_paste),
                          label: const Text('Coller'),
                        ),
                        if (widget.isAiAvailable)
                          OutlinedButton.icon(
                            onPressed: isAnalyzing ? null : _analyzeScreenshot,
                            icon: const Icon(Icons.image_outlined),
                            label: const Text("Capture d'écran"),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          errorMessage,
                          style: TextStyle(
                            color: Theme.of(builderContext).colorScheme.error,
                          ),
                        ),
                      ),
                    FilledButton.icon(
                      onPressed: isAnalyzing ? null : _analyzeText,
                      icon: isAnalyzing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: Text(
                        isAnalyzing
                            ? 'Analyse en cours...'
                            : 'Analyser le message',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              widget.isAiAvailable
                  ? "Sans l'analyse IA, tout reste sur votre téléphone. Avec l'analyse IA (facultative, icône bouclier), le contenu est envoyé pour analyse puis oublié par notre serveur. Seuls les résultats sont gardés dans l'historique."
                  : "Votre message n'est ni enregistré ni envoyé : l'analyse se fait sur votre téléphone.",
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
