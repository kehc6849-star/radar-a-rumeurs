# Backend de Radar à Rumeurs

Petit serveur (FastAPI) qui garde la clé d'API côté serveur et interroge **Gemma 4** via l'API Gemini.

| Adresse                  | Rôle                                                                           |
|--------------------------|--------------------------------------------------------------------------------|
| `GET /health`            | État du serveur (`aiConfigured` indique si une clé est présente)               |
| `POST /v1/analyze`       | Analyse d'un texte : `{ "text": "..." }`                                       |
| `POST /v1/analyze-image` | Analyse d'une capture d'écran (champ `image`, JPEG, PNG ou WebP, 4 Mo maximum) |

La page `/` répond **404 : c'est normal**. Pour vérifier que le serveur tourne, ouvrir `/health`.

## Démarrage rapide (Windows, PowerShell)

Depuis le dossier `backend/` :

```powershell
python -m venv .venv
.\.venv\Scripts\python -m pip install -r requirements-dev.txt
.\.venv\Scripts\python -m pytest
copy .env.example .env
.\.venv\Scripts\python -m uvicorn app.main:application --host 127.0.0.1 --port 8000
```

Éditer `.env` pour y mettre `GEMINI_API_KEY`. **Ne jamais publier ce fichier** (il est ignoré par Git ; seul `.env.example` est publié).

Après toute modification du code ou du fichier `.env`, **redémarrer le serveur** (`Ctrl+C`, puis relancer la dernière commande) : il garde en mémoire l'ancienne version.

## Variables d'environnement (`.env`)

La liste complète, avec des commentaires, est dans `.env.example`. Trois variables méritent une explication :

| Variable                   | Rôle                                                                                                                                                                                                  |
|----------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `GEMINI_API_KEY`           | Clé de l'API Gemini (Google AI Studio). Reste uniquement sur le serveur, jamais dans l'application.                                                                                                   |
| `APP_ACCESS_TOKEN`         | Jeton partagé **optionnel**. S'il est rempli, le serveur exige l'en-tête `X-Radar-Access-Token` avec cette valeur. C'est un ralentisseur contre les abus occasionnels, **pas un vrai secret** (il est embarqué dans l'application). **Laisser vide** tant que l'application n'envoie pas cet en-tête, sinon toutes les requêtes sont refusées. |
| `ENABLE_API_DOCUMENTATION` | `false` par défaut. À `true`, FastAPI publie la documentation interactive (`/docs`, `/redoc`) qui permet d'envoyer des requêtes depuis le navigateur. **À activer uniquement sur sa propre machine**, jamais sur un serveur public : elle expose les routes et permet de consommer le quota de l'IA. |

## Tester avec un téléphone Android (câble USB)

Sur le téléphone, `127.0.0.1` désigne le téléphone lui-même, pas l'ordinateur. Il faut donc relier le port du téléphone à celui du PC avec `adb reverse`. Serveur lancé dans un premier terminal, puis dans un second, à la racine du projet :

```powershell
adb devices
adb reverse tcp:8000 tcp:8000
adb reverse --list
flutter run --dart-define=BACKEND_BASE_URL=http://127.0.0.1:8000
```

- `adb devices` doit lister le téléphone ; `adb reverse --list` doit afficher `tcp:8000`.
- La redirection est **perdue quand le câble est débranché** : la refaire à chaque reconnexion.
- Vérification rapide : ouvrir `http://127.0.0.1:8000/health` dans le navigateur **du téléphone**.

**Dépannage.** Le message « Impossible de joindre le serveur d'analyse » signifie que la requête n'atteint pas le serveur. Regarder le terminal d'`uvicorn` : si aucune ligne `POST /v1/analyze` n'apparaît (seulement des `GET /health`), le problème est entre le téléphone et le PC (`adb reverse` oublié, câble débranché, ou application lancée sans `--dart-define`). Le test de connexion à Internet n'y change rien, puisque le serveur est sur le PC.

## Garanties

- Le contenu des messages n'est jamais journalisé (seulement : type, niveau, jetons, durée).
- La réponse du modèle est vérifiée par du code ; le niveau vient du score, jamais des mots du modèle.
- Les textes affichés sont nettoyés par le code : guillemets français, pas de doublons dans les signaux et les conseils.
- Limites par appareil et globale pour protéger le quota (voir `docs/11_AI_QUOTAS_AND_LIMITS.md`).

## Docker

```powershell
docker build -t radar-backend .
docker run --rm -p 8000:8000 --env-file .env radar-backend
```

Sur un serveur public : garder `ENABLE_API_DOCUMENTATION=false`, passer la clé par variable d'environnement ou fichier de configuration sécurisé, et placer le serveur derrière HTTPS.
