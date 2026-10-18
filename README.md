# 📡 Zero Trust

> **English summary** — Zero Trust is an open source Flutter app that helps people in Senegal and West Africa spot scams (mobile money, fake scholarships, phishing) and rumors before they act or share. Paste a message, or share a text or a screenshot from another app, and get a clear verdict, the warning signs found, and what to do next. Released under the MIT licence.

Application mobile **open source** (Flutter, IA Gemma 4) qui aide à repérer les **arnaques** (mobile money, fausses bourses, phishing) et les **rumeurs** avant d'agir ou de partager.

Projet réalisé pour le **Open Source × AI Hackathon 2026** (Galsen DEV × Hacktoberfest Hack Day Dakar) — track *Civic Tech & services publics*.

## Pourquoi

Au Sénégal et en Afrique de l'Ouest, les arnaques par SMS, appels et messages (usurpation de comptes Orange Money ou Wave, faux liens, fausses bourses d'études) et les fausses informations circulent surtout par WhatsApp, en vocaux et en captures d'écran. Peu d'outils de vérification existent en français, et ils ne traitent que du texte.

## Ce que fait l'application

L'utilisateur colle un message, ou **partage depuis une autre application** (Photos, WhatsApp, navigateur…) un texte ou une capture d'écran : l'analyse démarre directement. L'application renvoie :

- un **verdict** : *aucun signal détecté*, *douteux* ou *dangereux* (jamais « sûr » : l'absence de signal ne prouve rien) ;
- les **signaux repérés**, expliqués simplement ;
- **que faire maintenant**, selon le type de menace.

Sans l'IA, le texte reste sur le téléphone. Avec l'IA (facultative, après accord de l'utilisateur), il est envoyé à notre serveur puis à **Gemma 4** ; notre serveur ne le conserve pas. L'historique ne garde que les résultats.

## État d'avancement

| Fonctionnalité | État |
|---|---|
| Analyse de texte collé par règles locales, hors-ligne | ✅ Disponible |
| Analyse de captures d'écran (lecture par IA, Gemma 4) | ✅ Disponible |
| Analyse du sens par IA (Gemma 4) avec repli hors-ligne | ✅ Disponible |
| Historique local (sans le contenu analysé) | ✅ Disponible |
| Partage depuis une autre application (image ou texte, menu « Partager » et menu de sélection de texte) | ✅ Disponible (Android) |
| Interface avec mode sombre | ✅ Disponible |
| Serveur d'analyse en ligne (HTTPS) pour la démonstration | ✅ Disponible |
| Partage direct d'un texte depuis WhatsApp | 🔜 Après la version 1.0 (aujourd'hui : copier le texte, puis le coller) |
| Analyse de vocaux (transcription) | ❌ Hors périmètre de la version 1.0 (l'analyse audio n'est pas confirmée par l'API) |

Le détail est dans la [feuille de route](docs/07_ROADMAP.md) et le [journal des modifications](CHANGELOG.md).

## Installation rapide

Prérequis : Flutter stable récent (3.27 ou plus) et Android Studio. Pour l'analyse par IA : Python 3.12 et une clé Google AI Studio (voir le [guide de développement](docs/06_DEVELOPMENT_GUIDE.md)).

```bash
git clone <url-du-depot>
cd radar-a-rumeurs
flutter pub get
flutter run
```

Pour obtenir l'analyse par IA, l'application doit connaître l'adresse du serveur d'analyse :

```bash
flutter run --dart-define=BACKEND_BASE_URL=https://<adresse-du-serveur>
flutter build apk --release --dart-define=BACKEND_BASE_URL=https://<adresse-du-serveur>
```

Sans cette adresse, l'application reste utilisable, avec les seules règles locales.

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
| [10 — Travail en équipe](docs/10_TEAM_WORKFLOW.md) | Branches, pull requests, conventions |
| [11 — Quotas et limites de l'IA](docs/11_AI_QUOTAS_AND_LIMITS.md) | Gérer les limites de Gemma, préparer la démo |
| [Contribuer](CONTRIBUTING.md) | Ajouter une règle, proposer une amélioration |
| [Sécurité](SECURITY.md) | Signaler une vulnérabilité |

## Licence

Code source distribué sous licence [MIT](LICENSE).
