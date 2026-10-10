import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/analysis_verdict.dart';
import '../../domain/services/content_validator.dart';
import '../controllers/analysis_controller.dart';
import 'verdict_screen.dart';

/// Entry screen: the user pastes a message and starts the analysis.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.analysisController});

  final AnalysisController analysisController;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _contentTextController = TextEditingController();

  @override
  void dispose() {
    _contentTextController.dispose();
    super.dispose();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le presse-papiers est vide.')),
      );
      return;
    }

    _contentTextController.text = clipboardText;
  }

  Future<void> _analyzeContent() async {
    final AnalysisController analysisController = widget.analysisController;

    await analysisController.analyzeContent(_contentTextController.text);

    if (!mounted) {
      return;
    }

    final AnalysisVerdict? verdict = analysisController.latestVerdict;

    if (analysisController.status != AnalysisStatus.success || verdict == null) {
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

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Radar à Rumeurs')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: <Widget>[
            Text('Un message vous semble louche ?', style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              "Collez le texte reçu (SMS, WhatsApp, e-mail) : Radar à Rumeurs repère les signes d'arnaque ou de désinformation.",
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
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _pasteFromClipboard,
                icon: const Icon(Icons.content_paste),
                label: const Text('Coller'),
              ),
            ),
            const SizedBox(height: 16),
            ListenableBuilder(
              listenable: widget.analysisController,
              builder: (BuildContext builderContext, Widget? unusedChild) {
                final bool isAnalyzing =
                    widget.analysisController.status == AnalysisStatus.analyzing;
                final String? errorMessage = widget.analysisController.errorMessage;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
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
                      onPressed: isAnalyzing ? null : _analyzeContent,
                      icon: isAnalyzing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.search),
                      label: Text(
                        isAnalyzing ? 'Analyse en cours...' : 'Analyser le message',
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              "Votre message n'est ni enregistré ni envoyé : l'analyse se fait sur votre téléphone.",
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
