# 06 — Guide de développement

*État : lot 2.*

## Prérequis

- Flutter stable récent (3.27 ou plus) et Android Studio, un téléphone Android.
- **Python 3.12 ou plus récent** pour le serveur (vérifier avec `python --version`).
- Une clé d'API Google AI Studio (https://aistudio.google.com/apikey) pour l'analyse par IA.

## Application

```bash
git clone <url-du-depot>
cd radar-a-rumeurs
flutter pub get
flutter analyze   # doit afficher « No issues found »
flutter test
```

Sans serveur configuré, l'application fonctionne avec les règles locales seules.

### Lancer l'application avec le serveur

L'adresse du serveur est donnée à la compilation :

```bash
flutter run --dart-define=BACKEND_BASE_URL=http://127.0.0.1:8000 --dart-define=BACKEND_ACCESS_TOKEN=votre_jeton
```

(`BACKEND_ACCESS_TOKEN` est facultatif : à renseigner seulement si `APP_ACCESS_TOKEN` est défini dans le `.env` du serveur.)

Dans Android Studio : *Run > Edit Configurations > Additional run args*.

**Brancher le téléphone au serveur de votre PC** :
- **Câble USB** (le plus simple, sans pare-feu) : `adb reverse tcp:8000 tcp:8000`, puis utiliser `http://127.0.0.1:8000`. La commande `adb` se trouve dans le dossier `platform-tools` du SDK Android.
- **Même Wi-Fi** : lancer le serveur avec `--host 0.0.0.0`, utiliser `http://ADRESSE_IP_DU_PC:8000`, et autoriser Python dans le pare-feu Windows (réseaux privés).

Le fichier `android/app/src/debug/AndroidManifest.xml` autorise le HTTP simple **en mode debug uniquement**. Pour un APK de production, utiliser une adresse **HTTPS**.

## Serveur

```bash
cd backend
python -m venv .venv
.venv\Scripts\python -m pip install -r requirements-dev.txt     # Windows
.venv\Scripts\python -m pytest                                  # tests du serveur
copy .env.example .env                                          # puis éditer .env
.venv\Scripts\python -m uvicorn app.main:application --host 127.0.0.1 --port 8000
```

Sous Linux ou macOS : `.venv/bin/python` à la place de `.venv\Scripts\python`, et `cp` à la place de `copy`.

Dans `backend/.env`, renseigner au minimum `GEMINI_API_KEY`. Vérification : ouvrir `http://127.0.0.1:8000/health` doit afficher `"aiConfigured": true`.

**Ne jamais publier `.env`.** Seul `.env.example` est dans le dépôt.

## Android : permission Internet

Pour un APK de production (release), ajouter dans `android/app/src/main/AndroidManifest.xml`, avant la balise `<application>` :

```xml
<uses-permission android:name="android.permission.INTERNET"/>
```

## Norme de code du projet

1. **Lisibilité** : code aéré, imports, variables et fonctions séparés par des sauts de ligne.
2. **Noms explicites** : variables, méthodes, classes et paramètres décrivent leur rôle. Pas d'abréviations ambiguës.
3. **Programmation défensive** : gestion explicite de `null`, des exceptions et des cas limites ; vérifications d'entrée avant tout traitement.
4. **Commentaires en anglais simple (niveau B1)**, qui expliquent le *pourquoi*.
5. **Architecture modulaire** : responsabilité unique, séparation de la vue, de la logique métier, des services et de la persistance.
6. **Sécurité et qualité** : aucun secret en dur, entrées nettoyées, aucun journal de données sensibles, code testable, zéro avertissement du linter.

## Historique Git

Petits commits fréquents, messages clairs (`feat:`, `fix:`, `docs:`, `test:`, `chore:`, `ci:`). Voir [10 — Travail en équipe](10_TEAM_WORKFLOW.md).

## Dépendances externes importantes

| Dépendance | Rôle | Licence (à revérifier) |
|---|---|---|
| Flutter SDK et Dart | Framework et langage de l'application | BSD-3-Clause |
| `http` | Appels HTTP vers le serveur | BSD-3-Clause |
| `image_picker` | Choix d'une image dans la galerie | BSD-3-Clause |
| `shared_preferences` | Réglage de consentement et historique local | BSD-3-Clause |
| `flutter_lints`, `flutter_test` | Analyse statique et tests (développement) | BSD-3-Clause |
| FastAPI | Serveur web | MIT |
| Uvicorn | Exécution du serveur | BSD-3-Clause |
| HTTPX | Appels HTTP vers l'API Gemini | BSD-3-Clause |
| python-multipart | Réception des images | Apache-2.0 |
| pytest | Tests du serveur (développement) | MIT |
| Gemma 4 | Modèle d'IA ouvert (appelé via l'API Gemini) | Apache 2.0 (page de licence du modèle) |

Toute dépendance ajoutée sera listée ici avec sa licence.

## Structure du dépôt

Voir [02 — Architecture](02_ARCHITECTURE.md).
