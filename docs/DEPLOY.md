# Deploy AAURA for others (shareable link)

This guide deploys:

- **Backend API** → [Render](https://render.com) (free tier)
- **Flutter web app** → [Firebase Hosting](https://firebase.google.com/docs/hosting) (free tier)
- **Database + auth** → Supabase (already cloud-hosted)

You end up with a link like `https://your-project.web.app` that anyone can open.

---

## Prerequisites

- GitHub account (push this repo)
- [Render](https://render.com) account
- [Firebase](https://console.firebase.google.com) account
- [Flutter SDK](https://docs.flutter.dev/get-started/install) on your PC
- [Node.js](https://nodejs.org) 20+ (for Firebase CLI)
- Supabase project with migrations applied

---

## Part 1 — Push code to GitHub

If the repo is not on GitHub yet:

```powershell
cd C:\Users\hashe\OneDrive\Desktop\AAURA
git init
git add .
git commit -m "Prepare AAURA for deployment"
git branch -M main
git remote add origin https://github.com/YOUR_USER/AAURA.git
git push -u origin main
```

Never commit `backend/.env` or `flutter-app/deploy.env` (they contain secrets).

---

## Part 2 — Deploy the backend (Render)

1. Open [Render Dashboard](https://dashboard.render.com) → **New** → **Blueprint**.
2. Connect your GitHub repo and select the `render.yaml` file.
3. When prompted, set these **secret** environment variables:

| Variable | Where to get it |
|----------|-----------------|
| `SUPABASE_URL` | Supabase → Project Settings → API |
| `SUPABASE_ANON_KEY` | Same page (anon / public key) |
| `SUPABASE_SERVICE_ROLE_KEY` | Same page (service_role — **secret**) |
| `CORS_ORIGINS` | Your Firebase URL, e.g. `https://your-project.web.app` (set after Part 3, then update) |

4. Deploy. Wait until status is **Live**.
5. Copy your API URL, e.g. `https://aaura-api.onrender.com`.
6. Test: open `https://aaura-api.onrender.com/api/v1/health` — should return JSON.

> **Free tier note:** Render sleeps after ~15 min idle. First request may take 30–60 seconds to wake up.

> **AI predictions:** Live ML needs the Python service (`npm run dev:ai`). For a demo link, predictions may fall back to stored scores unless you also deploy the AI service. Core app (events, clubs, auth) works without it.

---

## Part 3 — Deploy the web app (Firebase Hosting)

### 3a. Create Firebase project

1. [Firebase Console](https://console.firebase.google.com) → **Add project**.
2. Enable **Hosting** (Build → Hosting → Get started).
3. Note your project ID (e.g. `aaura-campus`).

### 3b. Configure Flutter build

```powershell
cd flutter-app
copy deploy.env.example deploy.env
```

Edit `deploy.env`:

```env
API_BASE_URL=https://aaura-api.onrender.com/api/v1
APP_JOIN_BASE_URL=https://aaura-campus.web.app
SUPABASE_URL=https://njmsxkatexarayrvzcsq.supabase.co
SUPABASE_ANON_KEY=your-anon-key
```

Replace `aaura-api` and `aaura-campus` with your real Render + Firebase names.

Edit `.firebaserc` — set `YOUR_FIREBASE_PROJECT_ID` to your Firebase project ID.

### 3c. Build and deploy

```powershell
cd flutter-app
npm install -g firebase-tools
firebase login
.\scripts\build-web-release.ps1
firebase deploy --only hosting
```

Firebase prints your live URL, e.g. `https://aaura-campus.web.app`.

### 3d. Update Render CORS

In Render → **aaura-api** → **Environment**:

```
CORS_ORIGINS=https://aaura-campus.web.app
```

Save (triggers redeploy). Without this, the browser may block API calls.

---

## Part 4 — Supabase auth URLs

Supabase → **Authentication** → **URL Configuration**:

| Field | Value |
|-------|--------|
| **Site URL** | `https://aaura-campus.web.app` |
| **Redirect URLs** | `https://aaura-campus.web.app/**` and `http://localhost:**` |

This lets sign-up, login, and email links work on the hosted app.

---

## Part 5 — Share the link

Send people:

**`https://aaura-campus.web.app`**

Demo accounts (campus email pattern):

| Role | Email pattern |
|------|----------------|
| Student | `name@student.aaup.edu` |
| Student Affairs | `name@staff.aaup.edu` |
| Dean | `name@aaup.edu` |
| Admin | `admin@aaup.edu` |

If email confirmation is on in Supabase, confirm accounts from the Supabase dashboard or disable confirm for demos.

---

## Updating after code changes

**Backend:**

```powershell
git push origin main
```

Render auto-redeploys if connected to GitHub.

**Web app:**

```powershell
cd flutter-app
.\scripts\build-web-release.ps1
firebase deploy --only hosting
```

---

## Alternative: Netlify (no Firebase CLI)

1. Run `.\scripts\build-web-release.ps1`.
2. Go to [Netlify Drop](https://app.netlify.com/drop).
3. Drag the `flutter-app/build/web` folder onto the page.
4. Set `CORS_ORIGINS` on Render to the Netlify URL (e.g. `https://random-name.netlify.app`).
5. Update Supabase Site URL to match.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Blank screen after deploy | Run build with `deploy.env`; hard-refresh (Ctrl+Shift+R) |
| “Failed to fetch” / CORS error | Set `CORS_ORIGINS` on Render to exact Firebase URL (no trailing slash) |
| API very slow first load | Render free tier waking from sleep — wait ~1 min |
| Login redirect fails | Add hosted URL to Supabase Redirect URLs |
| Join QR links wrong | `APP_JOIN_BASE_URL` in `deploy.env` must match Firebase URL |
