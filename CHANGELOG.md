# Journal des modifications

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/). Les versions les plus récentes sont en haut.

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

## [Non publié]

### À venir
- Vocaux, partage depuis WhatsApp, déploiement du serveur (voir [feuille de route](docs/07_ROADMAP.md)).

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
