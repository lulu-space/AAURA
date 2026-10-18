# AAURA

Campus platform for Arab American University (AAUP) students. It covers events, clubs, volunteer hours, event check-in, gamification, a personalized home feed, and Shams onboarding.

Layan Diab built the API, database, authentication, and machine-learning service. A teammate built the Flutter client. AAUP students used the system, and account verification email was sent through Supabase.

## Layout

| Folder | What it is |
| --- | --- |
| `backend` | Node.js, TypeScript, and Express API on port 4000. Authentication uses Supabase JWTs. |
| `ai` | FastAPI service on port 8000. Shams builds a student profile from a lexicon. Event success scores come from an XGBoost model trained on synthetic data. |
| `flutter-app` | Flutter client. |
| `docs` | Architecture, deployment, test cases, and model notes. |

Shams is rule-based. It is not a large language model. Treat the event scores as decision support. Details are in [docs/MODEL_INSIGHTS.md](docs/MODEL_INSIGHTS.md).

## Run locally

You need Node.js, Python, and the Flutter SDK.

1. Copy `backend/.env.example` to `backend/.env` and fill in the Supabase values. Do not commit `.env`.
2. Install and start the API:

```powershell
npm install --prefix backend
npm run dev
```

3. Install and start the AI service. Train the model once if `ai/app/ml/models/event_success_xgb.joblib` is missing:

```powershell
py -m pip install -r ai/requirements.txt
npm run train:ai
npm run dev:ai
```

4. Start the Flutter app:

```powershell
npm run dev:app
```

More client setup is in [flutter-app/README.md](flutter-app/README.md). Deployment is in [docs/DEPLOY.md](docs/DEPLOY.md).
