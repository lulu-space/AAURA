# AAURA Flutter App

Campus app for AAUP — wired to the Express backend (`:4000`) and Supabase Auth.

## Run (recommended)

**Terminal 1 — backend + AI:**
```powershell
cd C:\Users\hashe\OneDrive\Desktop\AAURA
npm run dev
```

**Terminal 1b — AI model (required for live event success scores):**
```powershell
cd C:\Users\hashe\OneDrive\Desktop\AAURA
npm run train:ai   # once, if models/event_success_xgb.joblib is missing
npm run dev:ai     # keep running on :8000
```

**Terminal 2 — Flutter (web / Edge):**
```powershell
cd C:\Users\hashe\OneDrive\Desktop\AAURA\flutter-app
.\scripts\run-web.ps1
```

Use `run-web.ps1` instead of plain `flutter run` when the project is under OneDrive — it clears locked `build/` folders first.

From repo root: `npm run dev:app`

## Auth flow

| Action | Result |
|--------|--------|
| **Sign up** (email confirm required) | Confirm-email screen → log in |
| **Sign up** (session created) | Shams profiling chat |
| **First log in** (student, profile incomplete) | Shams profiling chat |
| **Log in** (returning user) | Dashboard |

Campus emails: `@student.aaup.edu` (students), `@staff.aaup.edu` (Student Affairs), `@aaup.edu` (Dean of Faculty), `admin@aaup.edu` (admin only)

## Backend integration

| Feature | API |
|---------|-----|
| Auth | Supabase JWT + `POST /auth/provision`, `GET /users/me` |
| Events | `GET/POST/PATCH/DELETE /events`, `POST /event-reservations/reserve` |
| Clubs | `GET/POST/PATCH/DELETE /clubs`, `GET/POST/DELETE /club-membership` |
| Gamification | `GET/POST/PATCH /gamification` (starts at **0** points; synced on join & shop) |
| AI prediction | `POST /events/:id/predict-success` (uses enrollments + Shams `student_profiles.interests`) |
| Study sessions | `GET/POST /study-sessions`, `POST/DELETE /study-session-membership` |
| Volunteering | `GET/POST /volunteering`, staff `GET /volunteering/pending`, `PATCH .../approve\|reject` |
| Recommendations | `GET /recommendations` (suggested events on Home) |
| Notifications | `GET/PATCH /notifications` |
| Calendar / study plans | `GET /calendar`, `GET /study-plans` (Academics planner) |
| Leaderboard | `GET /gamification/leaderboard` |
| Volunteer opportunities | `GET /volunteering-opportunities` |
| Volunteer submit | `POST /volunteering` (Profile → Volunteer Hours) |
| Event check-in | `POST /event-reservations/check-in` (Profile → Scan) |
| Shop | `GET /shop/items`, `GET /shop/purchases/mine`, `POST /shop/purchase` |
| Connections | `GET /connections/suggestions`, `POST /connections/connect` |
| Club chat | `GET/POST /club-messages` (join club first) |
| Club members | `GET /clubs/:id/members` (join club first) |
| Club activity feed | `GET /clubs/activity/feed` |
| Event feedback | `GET/POST /event-feedback` (after enrolling) |
| Badge catalog | `GET /badges` (migration `0011_badges_activity.sql`) |
| Skills / goals | `GET /student-profiles`, `GET /study-plans` |
| Badges earned | `gamification.badges` array unlocks catalog entries |

Offline mode shows empty lists until you sign in; form pick-lists live in `lib/data/campus_form_options.dart`.

## Config (optional)

```powershell
flutter run -d edge `
  --dart-define=API_BASE_URL=http://localhost:4000/api/v1 `
  --dart-define=SUPABASE_URL=https://your-project.supabase.co `
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

## Analyze / test

```powershell
flutter analyze
flutter test
```

## Project layout

```
lib/
  core/config/          # API URL, Supabase keys
  core/network/         # ApiClient
  data/repositories/    # events, gamification, predictions
  data/api_mappers.dart # backend JSON → UI models
  state/app_state.dart  # auth, CRUD state, persistence
  screens/auth/         # login, sign-up, email confirm
  screens/onboarding/   # Shams chat profiling
  theme/app_theme.dart  # sunbird palette
```

## Testing checklist (seed Supabase first)

Run `npm run dev` + `.\scripts\run-web.ps1`, then log in with campus test accounts. Many screens **fall back to mock data** when the backend returns empty lists — seed rows to see live data:

| Screen / feature | Tables / API to seed |
|------------------|----------------------|
| Home → Suggested Events | `recommendations` (`recommendation_type = 'event'`, `target_id` = real event UUID) |
| Home → Feed | `notifications` for your user |
| Home → Leaderboard | `gamification` rows for several users (with points) |
| Academics → planner | `calendar` (`item_type`: `study`, `reminder`, or `event`) + `study_plans` (`schedule` JSON) |
| Profile → Notifications | `notifications` |
| Shop / points | Earn points → Shop (migration `0009_shop.sql`) |
| Connections | Other students in DB → Profile → **Connect** (migration `0010_social_club.sql`) |
| Club founding request | Student: Clubs → My Clubs → **+** → submit proposal; Staff/Affairs: Profile → **Club Requests** → approve |
| Club members drawer | Join club → server → members panel (`0010` + member rows in `club_membership`) |
| Club activity feed | Join clubs + run `0011_badges_activity.sql` (posts match club names) |
| Event feedback | Enroll in event → **Rate this event** on event details |
| Badge catalog | Run `0011_badges_activity.sql`; earned IDs still from `gamification.badges` |
| Skills / goals | Seed `student_profiles.strengths` / `goals` JSON after Shams |
| Volunteer approvals (Staff) | `volunteering_records` with `status = 'pending'`; backend role `staff` or `admin` |
| Student volunteer hours | `volunteering_records` for the student (`approved` rows sum to profile hours) |
| Volunteer hours submit | Profile → **Volunteer Hours** → pick opportunity → submit (needs `volunteering_opportunities` rows) |
| Event check-in | Join/reserve an event first; check-in uses `qr_token` from `event_reservation` via Profile → **Scan** |
| Badges on profile | Add badge id strings to `gamification.badges` (e.g. `b-volunteer-champion`) |

**Migrations:** run `0009_shop.sql`, `0010_social_club.sql`, `0011_badges_activity.sql`, `0012_event_metadata.sql`, `0013_cv_storage.sql`, and `0014_club_requests.sql` in Supabase.

> `0014_club_requests.sql` adds the club-founding approval workflow. Students submit requests; Staff or Student Affairs approve → club is created and the requester becomes `club_organizer`.

**Roles:** Staff volunteer queue needs backend role `staff` or `admin`. Club founding approvals need `staff`, `student_affairs`, `dean_of_faculty`, or `admin`. New signups always start as `student`; organizers are promoted only after a club request is approved (or manually by admin).

### Live event success prediction (real ML, not mock)

1. **Start services:** `npm run dev`, `npm run dev:ai`, and `.\scripts\run-web.ps1`.
2. **Train once** if needed: `npm run train:ai` (creates `ai/app/ml/models/event_success_xgb.joblib`).
3. **Organizer account:** sign up as a student → Clubs → **+** → submit a founding request → log in as Staff or Student Affairs → Profile → **Club Requests** → **Approve**. The student is promoted to `club_organizer` and the club is created automatically. (Admins can still set `users.role` manually in Supabase if needed.)
4. **Create event:** Staff → **Manage Events** → Create → Publish. Title/description keywords matter (e.g. “AI workshop”, “hackathon”) — they feed `event_type` and interest matching.
5. **Student accounts (2–3):** sign up → complete **Shams** chat → confirm profile (writes `student_profiles.interests`).
6. **Enroll:** each student opens the event → **Enroll** (creates `event_reservation` rows).
7. **Predict:** as the **organizer**, open the event → **Overview** → tap **Refresh** on the AI card (or publish already ran an initial predict). The card should say *Live ML model (enrollments + Shams profiles)* with enrollment count and interest match in the reasons list.
8. **Score changes with data:** enroll more students or change title/tags to match their Shams interests, then **Refresh** again — `ai_success_score` on the event row updates in Supabase.

**Model inputs (real data):** current enrollment count, dominant enrolled majors, interest overlap between Shams profiles and event text, inferred event type from title/description.

## Still mock (not wired yet)

| Area | Backend exists? | Notes |
|------|-----------------|-------|
| **Search history / engagement metrics** | Yes | Not wired |
| **Club channels list** | No | Channel tabs still from mock catalog |
| **Shams picklists** | No | Majors/years/interests still local mock |
| **Event prediction audience** | Partial | Live score from backend; segment list still mock |

| Event edit/delete | Staff **Manage Events** — long-press card or tap **Manage** → edit; long-press → delete |
| Study session join | Academics tab → join a session (uses `/study-session-membership/join`) |
| Shop purchase | Earn points → Shop → buy item |
| Connections | Profile → **Connect** (needs `0010_social_club.sql`) |
| Club chat | Join club → server screen (needs `0010_social_club.sql`) |
| Event feedback | Enroll → event details → **Rate this event** |
| Club members | Join club → server → open members drawer |

If you want to keep going: **search history**, **engagement metrics**, **club channel API**.

