# Journal des modifications

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/). Les versions les plus récentes sont en haut.

## [Non publié]

### Ajouté
- Partage depuis une autre application (Android) : une image envoyée par le menu « Partager » (par exemple depuis Photos ou WhatsApp), ou un texte sélectionné puis envoyé à « Zero Trust » depuis le menu de sélection de texte (testé dans Chrome) ou par « Partager », ouvre l'application et lance directement l'analyse, avec le même accord IA qu'un texte collé. Si un écran de résultat est déjà ouvert, l'application revient d'abord à l'accueil, montre la progression, puis affiche un seul écran de résultat ; le bouton Retour ramène à l'accueil. Les images sont réduites à 1600 px (JPEG) avant l'envoi ; un texte vide ou de plus de 5000 caractères, ou une image de plus de 4 Mo ou d'un format inconnu, est refusé avec un message clair. Lecture faite côté Android sans nouvelle dépendance (`MainActivity.kt`, `android_shared_content_receiver.dart`). 20 tests ajoutés.
- Icône de l'application : logo (radar dans une bulle de message), en icône classique (5 tailles) et en icône adaptative pour Android 8 et plus (fond en dégradé XML, premier plan en PNG), dans `android/app/src/main/res/`.
- Tests unitaires de la comparaison des conseils (`test/advice_similarity_policy_test.dart`, 7 tests).
- Serveur d'analyse déployé en ligne en HTTPS sur Render (offre gratuite, image Docker construite à partir de `backend/Dockerfile`) : l'application l'utilise avec `--dart-define=BACKEND_BASE_URL=https://…`, sans que le PC ait besoin d'être allumé.

### Corrigé
- Interface : 6 avertissements `withOpacity` (déprécié) remplacés par `withValues` (l'analyse statique ne signale plus rien) ; deux tests de l'écran d'accueil adaptés à la liste défilante ; le titre « Que faire maintenant ? » n'apparaît plus deux fois sur l'écran de résultat.
- Licence : titulaire du droit d'auteur ajouté (« Zero Trust Contributors ») et doublon supprimé dans la ligne Copyright.
- Android : la permission Internet est déclarée dans le manifeste principal (`android/app/src/main/AndroidManifest.xml`). Elle n'existait qu'en mode debug, ce qui aurait empêché la version release d'atteindre le serveur.
- Textes générés par l'IA : guillemets droits remplacés par des guillemets français « », mot anglais « Forwarded » traduit, plus de description de l'écran (« lien bleu »), conseils redondants supprimés, conseil « signalez, puis supprimez » pour ne pas perdre la preuve.
- Conseils affichés : l'application ne montre plus deux fois le même conseil lorsque l'IA reprend, avec d'autres mots, un conseil des règles locales (comparaison des mots importants dans `advice_similarity_policy.dart`, utilisée par la fusion des verdicts).

### Modifié
- Interface : thème, écran d'accueil, écran de résultat et historique redessinés, avec un mode sombre (contribution d'un membre de l'équipe).
- Serveur : l'attente de l'IA est limitée à 36 secondes au total (sous le délai de 40 secondes de l'application) ; le modèle de secours n'est tenté que s'il reste au moins 5 secondes ; chaque échec d'appel écrit une ligne technique `ai_call_failed` (modèle, statut, durée, poids de l'image, jamais le contenu). 3 tests ajoutés.
- Nom de l'application : « Zero Trust » est le nom définitif (choisi le 16 octobre 2026) : étiquette Android, titre et textes de l'application, titre et prompt du serveur, documentation. Les identifiants techniques (paquet Dart, dossier, en-tête HTTP) gardent leur ancien nom.
- Documentation des quotas (`docs/11`) : cas de l'hébergement Render (endormissement, cache vidé), plan de secours par câble USB, journal des incidents.
- Serveur : le prompt envoyé à Gemma 4 contient quatre nouvelles règles de style (`backend/app/prompts.py`), et le texte du verdict est nettoyé par le code (`backend/app/verdict_parser.py`) : guillemets français avec espaces insécables, signaux et conseils en double supprimés. Le texte lu dans une capture n'est jamais modifié.
- `.gitignore` : ajout des caches Python (`__pycache__/`, `.pytest_cache/`) et de l'environnement virtuel (`.venv/`).
- Documentation du serveur (`backend/README.md`) : explication des variables `APP_ACCESS_TOKEN` et `ENABLE_API_DOCUMENTATION`, procédure de test sur téléphone Android par câble USB (`adb reverse`, `--dart-define`), dépannage du message « Impossible de joindre le serveur d'analyse ».

### Vérifié
- Le lot 2 a été validé sur téléphone le 15 octobre 2026 : l'analyse d'un texte collé et d'une capture d'écran (message WhatsApp transféré) fonctionne de bout en bout avec Gemma 4, combinée aux règles locales. L'analyse des captures est donc fonctionnelle, contrairement à ce qu'indique le message du commit du lot 2.
- Le 16 octobre 2026, l'application sur téléphone utilise le serveur Render : l'analyse du texte et de la plupart des captures fonctionne. Certaines captures échouent avec « Le serveur d'analyse est indisponible » (erreur 500 renvoyée par l'API Gemini, puis 503 de notre serveur) : le serveur enchaîne bien sur le modèle de secours, mais l'appel de secours semble expirer à 30 secondes : un budget de temps total et un journal technique ont été ajoutés (voir `docs/11`, section 9). Depuis, aucun échec d'appel à l'IA n'est journalisé côté serveur ; certaines images lourdes peuvent encore échouer dans l'application, cause à confirmer.
- Après les correctifs du 15 octobre : guillemets français, « transféré » et conseils sans répétition vérifiés sur téléphone ; `flutter analyze` sans problème, 68 tests Flutter et 58 tests serveur réussis.

- Les 17 et 18 octobre 2026, sur téléphone : le partage fonctionne (application fermée puis ouverte par un partage, application déjà ouverte sur l'accueil ou sur un écran de résultat, menu « Partager », sélection de texte dans Chrome) ; l'APK release, installé sur téléphone, passe la liste de contrôle (analyse d'un texte avec l'IA, capture depuis la galerie, partage d'une image depuis Photos, texte sélectionné dans Chrome, lancement à froid par un partage) ; le nouveau logo s'affiche. `flutter analyze` sans problème, 90 tests Flutter et 61 tests serveur réussis.

### À venir
- Fiabilisation de l'analyse des images lourdes, relevé des quotas du compte Gemma (voir [feuille de route](docs/07_ROADMAP.md)).
- Partage direct d'un texte depuis WhatsApp (aujourd'hui il faut le copier) et prise en compte de la rotation des photos partagées (non appliquée).
- Hors périmètre de la version 1.0 (décisions du 16 octobre 2026) : messages vocaux (l'analyse audio n'est pas confirmée par l'API) et hébergement GPU Brev.

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
