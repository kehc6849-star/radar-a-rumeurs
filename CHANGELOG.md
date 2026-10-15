# Journal des modifications

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/). Les versions les plus récentes sont en haut.

## [Non publié]

### Corrigé
- Textes générés par l'IA : guillemets droits remplacés par des guillemets français « », mot anglais « Forwarded » traduit, plus de description de l'écran (« lien bleu »), conseils redondants supprimés, conseil « signalez, puis supprimez » pour ne pas perdre la preuve.
- Conseils affichés : l'application ne montre plus deux fois le même conseil lorsque l'IA reprend, avec d'autres mots, un conseil des règles locales (comparaison des mots importants dans `advice_similarity_policy.dart`, utilisée par la fusion des verdicts).

### Modifié
- Serveur : le prompt envoyé à Gemma 4 contient quatre nouvelles règles de style (`backend/app/prompts.py`), et le texte du verdict est nettoyé par le code (`backend/app/verdict_parser.py`) : guillemets français avec espaces insécables, signaux et conseils en double supprimés. Le texte lu dans une capture n'est jamais modifié.
- `.gitignore` : ajout des caches Python (`__pycache__/`, `.pytest_cache/`) et de l'environnement virtuel (`.venv/`).
- Documentation du serveur (`backend/README.md`) : explication des variables `APP_ACCESS_TOKEN` et `ENABLE_API_DOCUMENTATION`, procédure de test sur téléphone Android par câble USB (`adb reverse`, `--dart-define`), dépannage du message « Impossible de joindre le serveur d'analyse ».

### Vérifié
- Le lot 2 a été validé sur téléphone le 15 octobre 2026 : l'analyse d'un texte collé et d'une capture d'écran (message WhatsApp transféré) fonctionne de bout en bout avec Gemma 4, combinée aux règles locales. L'analyse des captures est donc fonctionnelle, contrairement à ce qu'indique le message du commit du lot 2.

### À venir
- Vocaux (si l'audio est confirmé par l'API), partage depuis WhatsApp, déploiement du serveur en HTTPS pour la démonstration, choix du nom définitif de l'application, relevé des quotas du compte Gemma (voir [feuille de route](docs/07_ROADMAP.md)).

## [0.2.0] — Lot 2 : IA Gemma 4

### Ajouté
- Serveur FastAPI (`backend/`) : analyse de texte et de captures d'écran par Gemma 4, modèle de secours, cache, limites de débit, validation stricte, tests.
- Moteur hybride : règles locales + IA, fusion des résultats (l'IA ne baisse jamais le risque), repli automatique hors-ligne.
- Analyse de captures d'écran (choix d'une image dans la galerie).
- Écran de consentement avant tout envoi à l'IA, modifiable à tout moment.
- Historique local des résultats (sans le contenu analysé).
- Documentation : quotas et limites de l'IA (`docs/11`), déclaration de l'IA, confidentialité, architecture, guide de développement.
- Intégration continue du serveur.

### Modifié
- Le verdict indique désormais quels moteurs ont produit le résultat et affiche une note si l'IA est indisponible.

## [0.1.1] — Correctifs du lot 1

### Ajouté
- 8 nouveaux motifs : faux proche avec nouveau numéro, demande d'argent avec prétexte pressant, lien pour « vérifier » un compte, demande de pièce d'identité, promesse de gains garantis, frais pour emploi ou visa, formules d'arnaque en anglais, invitation à cliquer.
- Nouvelle famille de menaces : offre frauduleuse.
- 5 tests supplémentaires.

### Modifié
- L'écran de résultat affiche « Peu de signaux détectés » lorsque seuls des signaux faibles existent.

### Corrigé
- 3 avertissements du linter (`prefer_initializing_formals`).

## [0.1.0] — Lot 1

### Ajouté
- Squelette Flutter organisé en couches (domaine, présentation).
- Moteur d'analyse local à base de règles, hors-ligne.
- Écran d'accueil (collage du message) et écran de résultat (verdict, signaux, conseils).
- Tests unitaires et tests d'écran, intégration continue GitHub.
- Licence MIT, README.
