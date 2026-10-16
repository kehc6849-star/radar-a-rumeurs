import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/ai_consent_status.dart';
import '../../domain/models/analysis_verdict.dart';
import '../../domain/models/screenshot_input.dart';
import '../../domain/models/shared_content.dart';
import '../../domain/repositories/ai_consent_repository.dart';
import '../../domain/repositories/analysis_history_repository.dart';
import '../../domain/services/content_validation_exception.dart';
import '../../domain/services/content_validator.dart';
import '../../domain/services/screenshot_picker.dart';
import '../../domain/services/shared_content_receiver.dart';
import '../controllers/analysis_controller.dart';
import '../widgets/ai_consent_dialog.dart';
import 'history_screen.dart';
import 'verdict_screen.dart';

/// Colors of the home screen, one set for each theme.
///
/// All the screen colors come from here, so the light and dark themes
/// stay in one place and no color is written twice.
class _HomePalette {
  const _HomePalette({
    required this.background,
    required this.title,
    required this.muted,
    required this.surface,
    required this.border,
    required this.fieldFill,
    required this.hint,
    required this.accent,
    required this.accentBadge,
    required this.accentBorder,
    required this.logoBackground,
    required this.bannerStart,
    required this.bannerEnd,
    required this.privacyBackground,
    required this.privacyBorder,
    required this.privacyText,
    required this.errorBackground,
    required this.errorBorder,
    required this.errorText,
  });

  static const _HomePalette light = _HomePalette(
    background: Color(0xFFF4F7FC),
    title: Color(0xFF102344),
    muted: Color(0xFF718096),
    surface: Colors.white,
    border: Color(0xFFE5EAF3),
    fieldFill: Color(0xFFF8FAFE),
    hint: Color(0xFF9AA7BA),
    accent: Color(0xFF246BFD),
    accentBadge: Color(0xFFEAF1FF),
    accentBorder: Color(0xFFD5E3FF),
    logoBackground: Color(0xFF102344),
    bannerStart: Color(0xFF102344),
    bannerEnd: Color(0xFF1C427B),
    privacyBackground: Color(0xFFEAF4FF),
    privacyBorder: Color(0xFFD9E9FF),
    privacyText: Color(0xFF34557E),
    errorBackground: Color(0xFFFFEEEE),
    errorBorder: Color(0xFFFFD1D1),
    errorText: Color(0xFFC62828),
  );

  static const _HomePalette dark = _HomePalette(
    background: Color(0xFF101827),
    title: Color(0xFFF1F5F9),
    muted: Color(0xFF9AA9BF),
    surface: Color(0xFF1C2739),
    border: Color(0xFF35445B),
    fieldFill: Color(0xFF253247),
    hint: Color(0xFF9AA9BF),
    accent: Color(0xFF6595FF),
    accentBadge: Color(0xFF24385E),
    accentBorder: Color(0xFF2F4A7D),
    logoBackground: Color(0xFF246BFD),
    bannerStart: Color(0xFF16356B),
    bannerEnd: Color(0xFF1F4FA3),
    privacyBackground: Color(0xFF182A45),
    privacyBorder: Color(0xFF2A4167),
    privacyText: Color(0xFFB8CCE8),
    errorBackground: Color(0xFF3A1D22),
    errorBorder: Color(0xFF6B2C33),
    errorText: Color(0xFFFF9C9C),
  );

  factory _HomePalette.of(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return isDark ? dark : light;
  }

  final Color background;
  final Color title;
  final Color muted;
  final Color surface;
  final Color border;
  final Color fieldFill;
  final Color hint;
  final Color accent;
  final Color accentBadge;
  final Color accentBorder;
  final Color logoBackground;
  final Color bannerStart;
  final Color bannerEnd;
  final Color privacyBackground;
  final Color privacyBorder;
  final Color privacyText;
  final Color errorBackground;
  final Color errorBorder;
  final Color errorText;
}

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
    this.sharedContentReceiver,
  });

  final AnalysisController analysisController;
  final AiConsentRepository consentRepository;
  final AnalysisHistoryRepository historyRepository;
  final ScreenshotPicker screenshotPicker;
  final bool isAiAvailable;
  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  /// Gives the content shared from other apps. Null means "not supported".
  final SharedContentReceiver? sharedContentReceiver;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color _buttonBlue = Color(0xFF246BFD);

  final TextEditingController _contentTextController = TextEditingController();

  StreamSubscription<SharedContent>? _sharedContentSubscription;

  @override
  void initState() {
    super.initState();

    _listenToSharedContent();

    WidgetsBinding.instance.addPostFrameCallback((Duration frameTimestamp) {
      unawaited(_startAfterFirstFrame());
    });
  }

  @override
  void dispose() {
    unawaited(_sharedContentSubscription?.cancel());
    _contentTextController.dispose();
    super.dispose();
  }

  // The consent question comes first, so a shared message found at launch
  // is analyzed with the real choice of the user.
  Future<void> _startAfterFirstFrame() async {
    await _askForConsentIfUndecided();

    if (!mounted) {
      return;
    }

    await _handleInitialSharedContent();
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

  // True when the user allows the AI analysis. Asks the question if needed.
  Future<bool> _ensureAiConsent() async {
    final AiConsentStatus currentStatus =
    await widget.consentRepository.loadStatus();

    if (!mounted) {
      return false;
    }

    if (currentStatus == AiConsentStatus.granted) {
      return true;
    }

    final AiConsentStatus decision = await _requestAiConsent();

    return mounted && decision == AiConsentStatus.granted;
  }

  void _listenToSharedContent() {
    final SharedContentReceiver? receiver = widget.sharedContentReceiver;

    if (receiver == null) {
      return;
    }

    _sharedContentSubscription = receiver.sharedContentStream.listen(
          (SharedContent sharedContent) {
        unawaited(_handleSharedContent(sharedContent));
      },
    );
  }

  Future<void> _handleInitialSharedContent() async {
    final SharedContentReceiver? receiver = widget.sharedContentReceiver;

    if (receiver == null) {
      return;
    }

    final SharedContent? initialContent = await receiver.takeInitialContent();

    if (!mounted || initialContent == null) {
      return;
    }

    await _handleSharedContent(initialContent);
  }

  Future<void> _handleSharedContent(SharedContent sharedContent) async {
    // Guard clauses: the screen can be closed, or busy with another analysis.
    if (!mounted) {
      return;
    }

    if (sharedContent is SharedContentRejected) {
      _showMessage(sharedContent.message);
      return;
    }

    if (widget.analysisController.status == AnalysisStatus.analyzing) {
      _showMessage(
        'Une analyse est déjà en cours. Partagez à nouveau dans un instant.',
      );
      return;
    }

    if (sharedContent is SharedTextContent) {
      await _analyzeSharedText(sharedContent.text);
      return;
    }

    if (sharedContent is SharedScreenshotContent) {
      await _analyzeSharedScreenshot(sharedContent.screenshot);
    }
  }

  Future<void> _analyzeSharedText(String sharedText) {
    // The text is shown in the field, so the user sees what is analyzed.
    _contentTextController.text = sharedText;

    return _runAnalysisAndShowVerdict(
          () => widget.analysisController.analyzeContent(sharedText),
    );
  }

  Future<void> _analyzeSharedScreenshot(ScreenshotInput screenshot) async {
    if (!widget.isAiAvailable) {
      _showMessage(
        "La lecture d'une image demande l'analyse IA, qui n'est pas disponible ici.",
      );
      return;
    }

    final bool hasAiConsent = await _ensureAiConsent();

    if (!mounted) {
      return;
    }

    if (!hasAiConsent) {
      _showMessage(
        "Une image ne peut être lue qu'avec l'analyse IA autorisée (icône bouclier).",
      );
      return;
    }

    await _runAnalysisAndShowVerdict(
          () => widget.analysisController.analyzeScreenshot(screenshot),
    );
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
          () => widget.analysisController.analyzeContent(
        _contentTextController.text,
      ),
    );
  }

  Future<void> _analyzeScreenshot() async {
    final bool hasAiConsent = await _ensureAiConsent();

    if (!mounted || !hasAiConsent) {
      return;
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
        builder: (_) => VerdictScreen(verdict: verdict),
      ),
    );

    if (!mounted) {
      return;
    }

    // Privacy: erase the content when the user comes back.
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
    final _HomePalette palette = _HomePalette.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      appBar: _buildAppBar(textTheme, palette),
      body: SafeArea(
        top: false,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: <Widget>[
            _buildBanner(palette),
            const SizedBox(height: 28),
            Text(
              'Analyser un contenu',
              style: TextStyle(
                color: palette.title,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Collez un message ou importez une capture.',
              style: TextStyle(color: palette.muted, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Astuce : depuis une autre application, utilisez « Partager » puis choisissez Radar à Rumeurs.',
              style: TextStyle(color: palette.muted, fontSize: 12),
            ),
            const SizedBox(height: 17),
            _buildInputCard(palette),
            const SizedBox(height: 18),
            _buildMainAction(palette),
            const SizedBox(height: 26),
            _buildHistoryShortcut(palette),
            const SizedBox(height: 20),
            _buildPrivacyNotice(palette),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(TextTheme textTheme, _HomePalette palette) {
    return AppBar(
      backgroundColor: palette.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      titleSpacing: 20,
      title: Row(
        children: <Widget>[
          Container(
            width: 43,
            height: 43,
            decoration: BoxDecoration(
              color: palette.logoBackground,
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
              children: <Widget>[
                Text(
                  'Radar à Rumeurs',
                  style: textTheme.titleMedium?.copyWith(
                    color: palette.title,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Vérifiez avant de partager',
                  style: TextStyle(color: palette.muted, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: <Widget>[
        // The icon shows the theme we switch TO: moon in light mode,
        // sun in dark mode.
        IconButton(
          tooltip: widget.isDarkMode
              ? 'Activer le mode clair'
              : 'Activer le mode sombre',
          onPressed: () => widget.onThemeChanged(!widget.isDarkMode),
          icon: Icon(
            widget.isDarkMode
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            color: palette.title,
          ),
        ),
        IconButton(
          tooltip: 'Historique',
          onPressed: () => unawaited(_openHistory()),
          icon: Icon(Icons.history_rounded, color: palette.title),
        ),
        IconButton(
          tooltip: 'IA et confidentialité',
          onPressed: widget.isAiAvailable
              ? () => unawaited(_requestAiConsent())
              : null,
          icon: Icon(Icons.shield_outlined, color: palette.title),
        ),
        const SizedBox(width: 6),
      ],
    );
  }

  Widget _buildBanner(_HomePalette palette) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[palette.bannerStart, palette.bannerEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Positioned(
            right: -12,
            top: -12,
            child: Icon(
              Icons.radar_rounded,
              size: 115,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
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
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 20),
              const Row(
                children: <Widget>[
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 16,
                    color: Color(0xFFBBD4FF),
                  ),
                  SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Vérifiez avant de partager.',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(15),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  Widget _buildInputCard(_HomePalette palette) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: palette.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: palette.accentBadge,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.edit_note_rounded,
                  color: palette.accent,
                  size: 23,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Votre message',
                  style: TextStyle(
                    color: palette.title,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Icon(Icons.text_fields_rounded, color: palette.hint),
            ],
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _contentTextController,
            keyboardType: TextInputType.multiline,
            minLines: 6,
            maxLines: 12,
            maxLength: ContentValidator.maximumContentLength,
            style: TextStyle(fontSize: 14, height: 1.6, color: palette.title),
            decoration: InputDecoration(
              hintText:
              'Collez ici le SMS, le message WhatsApp ou l’e-mail à vérifier...',
              hintStyle: TextStyle(
                color: palette.hint,
                fontSize: 13,
                height: 1.6,
              ),
              filled: true,
              fillColor: palette.fieldFill,
              contentPadding: const EdgeInsets.all(15),
              border: _fieldBorder(palette.border),
              enabledBorder: _fieldBorder(palette.border),
              focusedBorder: _fieldBorder(palette.accent, width: 1.5),
              counterStyle: TextStyle(color: palette.muted, fontSize: 11),
            ),
          ),
          const SizedBox(height: 13),
          ListenableBuilder(
            listenable: widget.analysisController,
            builder: (BuildContext context, Widget? child) {
              final bool isAnalyzing = widget.analysisController.status ==
                  AnalysisStatus.analyzing;

              return Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: isAnalyzing ? null : _pasteFromClipboard,
                      icon: const Icon(Icons.content_paste_rounded, size: 18),
                      label: const Text('Coller'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: palette.title,
                        side: BorderSide(color: palette.border),
                        padding: const EdgeInsets.symmetric(
                          vertical: 13,
                          horizontal: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                    ),
                  ),
                  if (widget.isAiAvailable) ...<Widget>[
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: isAnalyzing ? null : _analyzeScreenshot,
                        icon: const Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 18,
                        ),
                        label: const Text("Capture d'écran"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.accent,
                          side: BorderSide(color: palette.accentBorder),
                          padding: const EdgeInsets.symmetric(
                            vertical: 13,
                            horizontal: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
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
    );
  }

  Widget _buildMainAction(_HomePalette palette) {
    return ListenableBuilder(
      listenable: widget.analysisController,
      builder: (BuildContext context, Widget? child) {
        final bool isAnalyzing =
            widget.analysisController.status == AnalysisStatus.analyzing;
        final String? errorMessage = widget.analysisController.errorMessage;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (errorMessage != null) ...<Widget>[
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: palette.errorBackground,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: palette.errorBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.error_outline_rounded,
                      color: palette.errorText,
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: TextStyle(
                          color: palette.errorText,
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
                onPressed: isAnalyzing ? null : _analyzeText,
                icon: isAnalyzing
                    ? const SizedBox(
                  height: 19,
                  width: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.search_rounded, size: 22),
                label: Text(
                  isAnalyzing ? 'Analyse en cours...' : 'Analyser le message',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _buttonBlue,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _buttonBlue.withValues(alpha: 0.6),
                  elevation: 2,
                  shadowColor: _buttonBlue.withValues(alpha: 0.25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryShortcut(_HomePalette palette) {
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: () => unawaited(_openHistory()),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: palette.border),
          ),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: palette.accentBadge,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.history_rounded,
                  color: palette.accent,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Historique des analyses',
                      style: TextStyle(
                        color: palette.title,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Retrouvez vos résultats précédents',
                      style: TextStyle(color: palette.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: palette.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyNotice(_HomePalette palette) {
    final String noticeText = widget.isAiAvailable
        ? "L'analyse IA est facultative. Consultez les paramètres de confidentialité via le bouclier en haut de l'écran. Le traitement des données dépend de la configuration de votre application."
        : "L'analyse IA n'est pas disponible. Cet écran ne transmet pas votre message à un service d'analyse IA.";

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: palette.privacyBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.privacyBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            Icons.lock_outline_rounded,
            color: palette.privacyText,
            size: 21,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              noticeText,
              style: TextStyle(
                color: palette.privacyText,
                fontSize: 12,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }
}