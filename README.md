# 📡 Radar à Rumeurs

> **English summary** — Radar à Rumeurs is an open source Flutter app that helps people in Senegal and West Africa spot scams (mobile money, fake scholarships, phishing) and rumors before they act or share. Paste a message, get a clear verdict, the warning signs found, and what to do next. Released under the MIT licence.

Application mobile **open source** (Flutter) qui aide à repérer les **arnaques** (mobile money, fausses bourses, phishing) et les **rumeurs** avant d'agir ou de partager.

Projet réalisé pour le **Open Source × AI Hackathon 2026** (Galsen DEV × Hacktoberfest Hack Day Dakar) — track *Civic Tech & services publics*.

## Pourquoi

Au Sénégal et en Afrique de l'Ouest, les arnaques par SMS, appels et messages (usurpation de comptes Orange Money ou Wave, faux liens, fausses bourses d'études) et les fausses informations circulent surtout par WhatsApp, en vocaux et en captures d'écran. Peu d'outils de vérification existent en français, et ils ne traitent que du texte.

## Ce que fait l'application

L'utilisateur colle un message. L'application renvoie :

- un **verdict** : *aucun signal détecté*, *douteux* ou *dangereux* (jamais « sûr » : l'absence de signal ne prouve rien) ;
- les **signaux repérés**, expliqués simplement ;
- **que faire maintenant**, selon le type de menace.

Le texte analysé n'est ni stocké, ni envoyé, ni journalisé dans la version actuelle.

## État d'avancement

| Fonctionnalité | État |
|---|---|
| Analyse de texte collé par règles locales, hors-ligne | ✅ Disponible |
| Analyse de captures d'écran (lecture par IA) | 🔜 Prévu |
| Analyse de vocaux (transcription par IA) | 🔜 Prévu |
| Analyse du sens et explication par modèle de langage | 🔜 Prévu |
| Partage direct depuis WhatsApp, historique local | 🔜 Prévu |

Le détail est dans la [feuille de route](docs/07_ROADMAP.md) et le [journal des modifications](CHANGELOG.md).

## Installation rapide

Prérequis : Flutter stable récent (3.27 ou plus) et Android Studio.

```bash
git clone <url-du-depot>
cd radar-a-rumeurs
flutter pub get
flutter run
```

Contrôles qualité : `flutter analyze` (zéro avertissement) et `flutter test`.

## Documentation

| Document | Contenu |
|---|---|
| [Index de la documentation](docs/README.md) | Point d'entrée |
| [01 — Problème et solution](docs/01_PROBLEM_AND_SOLUTION.md) | Utilisateurs, besoins, périmètre |
| [02 — Architecture](docs/02_ARCHITECTURE.md) | Couches, flux, choix techniques |
| [03 — Utilisation de l'IA](docs/03_AI_USAGE.md) | Modèles, APIs et outils déclarés |
| [04 — Règles de détection](docs/04_DETECTION_RULES.md) | Catalogue des règles, scores |
| [05 — Confidentialité et sécurité](docs/05_PRIVACY_AND_SECURITY.md) | Données, secrets, limites |
| [06 — Guide de développement](docs/06_DEVELOPMENT_GUIDE.md) | Installation, tests, dépendances |
| [07 — Feuille de route](docs/07_ROADMAP.md) | Ce qui est fait, ce qui vient |
| [08 — Checklist de soumission](docs/08_SUBMISSION_CHECKLIST.md) | Conditions du hackathon |
| [09 — Journal des décisions](docs/09_DECISIONS_LOG.md) | Pourquoi nous avons choisi ceci |
| [Contribuer](CONTRIBUTING.md) | Ajouter une règle, proposer une amélioration |
| [Sécurité](SECURITY.md) | Signaler une vulnérabilité |

## Licence

Code source distribué sous licence [MIT](LICENSE).
