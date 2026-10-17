# Contribuer à Zero Trust

Merci de votre intérêt ! Le moyen le plus simple d'aider est d'**ajouter un exemple d'arnaque réel** (anonymisé) que l'application ne détecte pas encore.

## Avant de commencer

- Lisez le [guide de développement](docs/06_DEVELOPMENT_GUIDE.md).
- Le projet suit la norme de code décrite dans ce guide (noms explicites, commentaires en anglais simple, gestion défensive des cas limites).
- **Ne publiez jamais** de vrais numéros de téléphone, noms ou identifiants dans un exemple. Remplacez-les par des valeurs fictives.

## Ajouter une règle de détection

1. Ouvrez `lib/features/analysis/domain/rules/scam_rule_catalog.dart`.
2. Ajoutez une entrée `KeywordCombinationRule` : identifiant, famille de menace, titre, explication en français simple, poids, groupes de motifs.
3. Écrivez les motifs pour du texte **normalisé** (minuscules, sans accents).
4. Ajoutez au moins un test d'arnaque et un test de message légitime dans `test/rule_based_content_analyzer_test.dart`.
5. Lancez `flutter analyze` et `flutter test` : tout doit passer, sans avertissement.
6. Documentez la règle dans [docs/04_DETECTION_RULES.md](docs/04_DETECTION_RULES.md).

## Proposer un changement

1. Ouvrez une *issue* pour discuter d'un changement important.
2. Créez une branche, faites des commits courts avec des messages clairs.
3. Ouvrez une *pull request* qui explique le **pourquoi** du changement.

## Code de conduite

Soyez respectueux et bienveillant. Les échanges se font dans le respect de chacun, sans harcèlement ni discrimination.
