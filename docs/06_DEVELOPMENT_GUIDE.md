# 06 — Guide de développement

*État : lot 1.*

## Prérequis

- Flutter stable récent (3.27 ou plus) et Android Studio.
- Un téléphone Android (ou un émulateur) pour tester.

## Installation

```bash
git clone <url-du-depot>
cd radar-a-rumeurs
flutter pub get
flutter run
```

## Contrôles qualité

```bash
flutter analyze   # doit afficher « No issues found »
flutter test      # tous les tests doivent passer
```

Ces deux commandes sont aussi exécutées automatiquement par l'intégration continue (`.github/workflows/continuous_integration.yml`) à chaque envoi de code.

## Norme de code du projet

Le projet suit les règles suivantes :

1. **Lisibilité** : code aéré, imports, variables et fonctions séparés par des sauts de ligne.
2. **Noms explicites** : variables, méthodes, classes et paramètres décrivent leur rôle. Pas d'abréviations ambiguës.
3. **Programmation défensive** : gestion explicite de `null`, des exceptions et des cas limites ; vérifications d'entrée avant tout traitement.
4. **Commentaires en anglais simple (niveau B1)**, qui expliquent le *pourquoi* et pas la paraphrase du code.
5. **Architecture modulaire** : responsabilité unique, séparation de la vue, de la logique métier, des services et de la persistance.
6. **Sécurité et qualité** : aucun secret en dur, entrées nettoyées, aucun journal de données sensibles, code testable, zéro avertissement du linter.

## Historique Git

Faites des commits **courts et fréquents** avec un message clair. L'historique doit montrer l'évolution réelle du projet.

## Dépendances externes importantes

| Dépendance | Rôle | Licence |
|---|---|---|
| Flutter SDK et Dart | Framework et langage de l'application | BSD-3-Clause |
| `flutter_lints` | Règles d'analyse statique (développement) | BSD-3-Clause |
| `flutter_test` | Tests (développement) | BSD-3-Clause |

Aucune autre dépendance externe n'est utilisée dans le lot 1. Toute dépendance ajoutée sera listée ici avec sa licence.

## Structure du dépôt

Voir [02 — Architecture](02_ARCHITECTURE.md).
