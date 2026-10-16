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

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.analysisController,
    required this.consentRepository,
    required this.historyRepository,
    required this.screenshotPicker,
    required this.isAiAvailable,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  final AnalysisController analysisController;
  final AiConsentRepository consentRepository;
  final AnalysisHistoryRepository historyRepository;
  final ScreenshotPicker screenshotPicker;
  final bool isAiAvailable;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _contentTextController =
  TextEditingController();

  static const Color _navy = Color(0xFF102344);
  static const Color _blue = Color(0xFF246BFD);
  static const Color _background = Color(0xFFF4F7FC);
  static const Color _muted = Color(0xFF718096);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_askForConsentIfUndecided());
    });
  }

  @override
  void dispose() {
    _contentTextController.dispose();
    super.dispose();
  }

  Future<void> _askForConsentIfUndecided() async {
    if (!widget.isAiAvailable) return;

    final AiConsentStatus currentStatus =
    await widget.consentRepository.loadStatus();

    if (!mounted || currentStatus != AiConsentStatus.undecided) {
      return;
    }

    await _requestAiConsent();
  }

  Future<AiConsentStatus> _requestAiConsent() async {
    final AiConsentStatus decision =
    await showAiConsentDialog(context);

    await widget.consentRepository.saveStatus(decision);

    return decision;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Future<void> _pasteFromClipboard() async {
    final ClipboardData? clipboardData =
    await Clipboard.getData(Clipboard.kTextPlain);

    if (!mounted) return;

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

    if (!mounted) return;

    if (currentStatus != AiConsentStatus.granted) {
      final AiConsentStatus decision = await _requestAiConsent();

      if (!mounted || decision != AiConsentStatus.granted) {
        return;
      }
    }

    final ScreenshotInput? pickedScreenshot =
    await _pickScreenshotSafely();

    if (!mounted || pickedScreenshot == null) return;

    await _runAnalysisAndShowVerdict(
          () => widget.analysisController
          .analyzeScreenshot(pickedScreenshot),
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
    final AnalysisController analysisController =
        widget.analysisController;

    await analysisAction();

    if (!mounted) return;

    final AnalysisVerdict? verdict =
        analysisController.latestVerdict;

    if (analysisController.status != AnalysisStatus.success ||
        verdict == null) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => VerdictScreen(verdict: verdict),
      ),
    );

    if (!mounted) return;

    // Confidentialité : effacer le contenu après le retour.
    _contentTextController.clear();
    analysisController.reset();
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => HistoryScreen(
          historyRepository: widget.historyRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: _navy,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.radar_rounded,
                color: Colors.white,
                size: 27,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Radar à Rumeurs',
                    style: textTheme.titleMedium?.copyWith(
                      color: _navy,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Vérifiez avant de partager',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: widget.isDarkMode
                ? 'Activer le mode clair'
                : 'Activer le mode sombre',
            onPressed: () {
              widget.onThemeChanged(!widget.isDarkMode);
            },
            icon: Icon(
              widget.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
          ),
          IconButton(
            tooltip: 'Historique',
            onPressed: () => unawaited(_openHistory()),
            icon: const Icon(
              Icons.history_rounded,
              color: _navy,
            ),
          ),
          IconButton(
            tooltip: 'IA et confidentialité',
            onPressed: widget.isAiAvailable
                ? () => unawaited(_requestAiConsent())
                : null,
            icon: const Icon(
              Icons.shield_outlined,
              color: _navy,
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          keyboardDismissBehavior:
          ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            // Bannière principale
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF102344),
                    Color(0xFF1C427B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: _navy.withOpacity(0.15),
                    blurRadius: 22,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -12,
                    top: -12,
                    child: Icon(
                      Icons.radar_rounded,
                      size: 115,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.15),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 15,
                              color: Color(0xFF9FC2FF),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'INFORMATION & VÉRIFICATION',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Un message vous\nsemble suspect ?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          height: 1.2,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Analysez son contenu avant de lui faire confiance.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 16,
                            color: Color(0xFFBBD4FF),
                          ),
                          SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              'Vérifiez avant de partager.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Analyser un contenu',
              style: TextStyle(
                color: _navy,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Collez un message ou importez une capture.',
              style: TextStyle(
                color: _muted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 17),

            // Carte de saisie
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFE5EAF3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _navy.withOpacity(0.035),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit_note_rounded,
                          color: _blue,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Votre message',
                          style: TextStyle(
                            color: _navy,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.text_fields_rounded,
                        color: Color(0xFF9AA7BA),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _contentTextController,
                    keyboardType: TextInputType.multiline,
                    minLines: 6,
                    maxLines: 12,
                    maxLength: ContentValidator.maximumContentLength,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: _navy,
                    ),
                    decoration: InputDecoration(
                      hintText:
                      'Collez ici le SMS, le message WhatsApp ou l’e-mail à vérifier...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF9AA7BA),
                        fontSize: 13,
                        height: 1.6,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFE),
                      contentPadding: const EdgeInsets.all(15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Color(0xFFE3EAF5),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: Color(0xFFE3EAF5),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: const BorderSide(
                          color: _blue,
                          width: 1.5,
                        ),
                      ),
                      counterStyle: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),

                  // Boutons secondaires
                  ListenableBuilder(
                    listenable: widget.analysisController,
                    builder: (context, child) {
                      final bool isAnalyzing =
                          widget.analysisController.status ==
                              AnalysisStatus.analyzing;

                      return Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: isAnalyzing
                                  ? null
                                  : _pasteFromClipboard,
                              icon: const Icon(
                                Icons.content_paste_rounded,
                                size: 18,
                              ),
                              label: const Text('Coller'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _navy,
                                side: const BorderSide(
                                  color: Color(0xFFDCE5F2),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 13,
                                  horizontal: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(13),
                                ),
                              ),
                            ),
                          ),
                          if (widget.isAiAvailable) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: isAnalyzing
                                    ? null
                                    : _analyzeScreenshot,
                                icon: const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 18,
                                ),
                                label: const Text('Capture'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _blue,
                                  side: const BorderSide(
                                    color: Color(0xFFD5E3FF),
                                  ),
                                  padding:
                                  const EdgeInsets.symmetric(
                                    vertical: 13,
                                    horizontal: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(13),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Bouton principal et états de l'analyse
            ListenableBuilder(
              listenable: widget.analysisController,
              builder: (context, child) {
                final bool isAnalyzing =
                    widget.analysisController.status ==
                        AnalysisStatus.analyzing;
                final String? errorMessage =
                    widget.analysisController.errorMessage;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (errorMessage != null) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEEEE),
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: const Color(0xFFFFD1D1),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Color(0xFFC62828),
                              size: 20,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                errorMessage,
                                style: const TextStyle(
                                  color: Color(0xFFC62828),
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(
                      height: 55,
                      child: FilledButton.icon(
                        onPressed:
                        isAnalyzing ? null : _analyzeText,
                        icon: isAnalyzing
                            ? const SizedBox(
                          height: 19,
                          width: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                            : const Icon(
                          Icons.search_rounded,
                          size: 22,
                        ),
                        label: Text(
                          isAnalyzing
                              ? 'Analyse en cours...'
                              : 'Analyser le message',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                          _blue.withOpacity(0.6),
                          elevation: 2,
                          shadowColor: _blue.withOpacity(0.25),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 26),

            // Accès à l'historique
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                onTap: () => unawaited(_openHistory()),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: const Color(0xFFE5EAF3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1FF),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.history_rounded,
                          color: _blue,
                          size: 23,
                        ),
                      ),
                      const SizedBox(width: 13),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Historique des analyses',
                              style: TextStyle(
                                color: _navy,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Retrouvez vos résultats précédents',
                              style: TextStyle(
                                color: _muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: _muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Confidentialité
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF4FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFFD9E9FF),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFF2864B8),
                    size: 21,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      widget.isAiAvailable
                          ? "L'analyse IA est facultative. Consultez les paramètres de confidentialité via le bouclier en haut de l'écran. Le traitement des données dépend de la configuration de votre application."
                          : "L'analyse IA n'est pas disponible. Cet écran ne transmet pas votre message à un service d'analyse IA.",
                      style: const TextStyle(
                        color: Color(0xFF34557E),
                        fontSize: 12,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}