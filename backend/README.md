# Backend de Radar à Rumeurs

Petit serveur (FastAPI) qui garde la clé d'API côté serveur et interroge **Gemma 4** via l'API Gemini.

| Adresse | Rôle |
|---|---|
| `GET /health` | État du serveur (`aiConfigured` indique si une clé est présente) |
| `POST /v1/analyze` | Analyse d'un texte : `{ "text": "..." }` |
| `POST /v1/analyze-image` | Analyse d'une capture d'écran (champ `image`, JPEG, PNG ou WebP, 4 Mo maximum) |

## Démarrage rapide (Windows)

```bash
python -m venv .venv
.venv\Scripts\python -m pip install -r requirements-dev.txt
.venv\Scripts\python -m pytest
copy .env.example .env
.venv\Scripts\python -m uvicorn app.main:application --host 127.0.0.1 --port 8000
```

Éditer `.env` pour y mettre `GEMINI_API_KEY`. **Ne jamais publier ce fichier.**

## Garanties

- Le contenu des messages n'est jamais journalisé (seulement : type, niveau, jetons, durée).
- La réponse du modèle est vérifiée par du code ; le niveau vient du score, jamais des mots du modèle.
- Limites par appareil et globale pour protéger le quota (voir `docs/11_AI_QUOTAS_AND_LIMITS.md`).

## Docker

```bash
docker build -t radar-backend .
docker run --rm -p 8000:8000 --env-file .env radar-backend
```
