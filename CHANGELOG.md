# Journal des modifications

Format inspiré de [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/). Les versions les plus récentes sont en haut.

## [Non publié]

### À venir
- Analyse de captures d'écran, de vocaux et explication par modèle de langage (voir [feuille de route](docs/07_ROADMAP.md)).

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
