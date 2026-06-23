# AAURA — Full Project Test Cases

Test plan for **Flutter frontend**, **Express backend**, **FastAPI AI service**, and **end-to-end integration**.

**Environments**

| Layer | URL / command |
|-------|----------------|
| Flutter web | `flutter-app/scripts/run-web.ps1` |
| Backend | `npm run dev` → `http://localhost:4000/api/v1` |
| AI | `npm run dev:ai` → `http://localhost:8000` |
| Supabase | Migrations `0001`–`0024` applied |

**Roles under test**

| Role | Email pattern (provisioning) |
|------|------------------------------|
| Student | `*@student.aaup.edu` |
| Student Affairs | `*@staff.aaup.edu` |
| Dean of Faculty | `*@aaup.edu` (not `admin@aaup.edu`) |
| Admin | `admin@aaup.edu` only |

**Priority**

- **P0** — Blocker / core path
- **P1** — Important feature
- **P2** — Secondary / edge case
- **P3** — Nice-to-have / polish

**Type**

- **FE** — Flutter UI / widget
- **BE** — Backend API
- **AI** — Python ML / NLP service
- **INT** — Cross-layer integration
- **E2E** — Full user journey

---

## 1. Authentication & provisioning

| ID | Type | Priority | Precondition | Steps | Expected result |
|----|------|----------|--------------|-------|-----------------|
| AUTH-01 | FE | P0 | App cold start | Open app | Landing / login shown; no crash |
| AUTH-02 | FE | P0 | Valid student account | Sign up with `@student.aaup.edu` | Email confirmation screen; no stuck on form |
| AUTH-03 | FE | P0 | Confirmed account | Log in | Navigates to Shams onboarding or main shell (not stuck on auth form) |
| AUTH-04 | FE | P1 | Returning user | Log in | Main shell loads; bottom nav visible |
| AUTH-05 | FE | P1 | Wrong password | Submit login | Error message; stays on auth screen |
| AUTH-06 | BE | P0 | No `Authorization` header | `POST /auth/provision` | `401 Unauthorized` |
| AUTH-07 | BE | P0 | Valid JWT, migrations applied | `POST /auth/provision` with `{}` | `201`; `public.users` row created; role matches email domain |
| AUTH-08 | BE | P0 | Valid JWT | `GET /users/me` | `200`; user + student profile payload |
| AUTH-09 | BE | P1 | Provision RPC missing | `POST /auth/provision` | `500` with actionable error in `details` |
| AUTH-10 | INT | P0 | Fresh student signup | Sign up → login → check backend logs | `provision` succeeds; `users/me` `200` |
| AUTH-11 | INT | P1 | Staff email | Login as `@staff.aaup.edu` | Shell shows staff tabs (Events, Hours, Profile) |

---

## 2. Shams profiling & profile

| ID | Type | Priority | Precondition | Steps | Expected result |
|----|------|----------|--------------|-------|-----------------|
| PROF-01 | FE | P0 | Student logged in, backend+AI up | Profile → Chat with Shams → send bio | Preview with Keep / Regenerate |
| PROF-02 | FE | P0 | Shams preview shown | Tap **Keep** | Returns to profile; interests/skills/goals update |
| PROF-03 | FE | P1 | Shams preview shown | Tap **Regenerate** | New intro prompt; draft cleared server-side |
| PROF-04 | FE | P1 | Backend down | Send Shams message | Bot shows “couldn't reach profiling service” |
| PROF-05 | FE | P2 | Staff / affairs account | Open Profile | No Shams button OR chat blocked with clear message |
| PROF-06 | BE | P0 | Student JWT | `POST /profiling/shams/chat` `{ "message": "..." }` | `200`; `preview` + `draft` in response |
| PROF-07 | BE | P0 | Student JWT | `GET /profiling/drafts/me` | `200` draft or `null` |
| PROF-08 | BE | P0 | Draft exists | `POST /profiling/drafts/confirm` | `200`; `student_profiles` upserted; draft deleted |
| PROF-09 | BE | P1 | Affairs JWT | `POST /profiling/shams/chat` | `403` |
| PROF-10 | BE | P1 | No JWT | `GET /profiling/drafts/me` | `401` |
| PROF-11 | AI | P0 | Model loaded | `POST /api/profiling/shams/chat` | `reply`, `traits`, `interests`, `confidence` |
| PROF-12 | INT | P0 | End-to-end Shams | Chat → Keep → `GET /users/me` | `student_profiles` reflects interests/summary |
| PROF-13 | FE | P1 | Profile hero | Join club + join event | Joined clubs/events counts match app state (not check-in only) |

---

## 3. Home & navigation

| ID | Type | Priority | Precondition | Steps | Expected result |
|----|------|----------|--------------|-------|-----------------|
| HOME-01 | FE | P0 | Student logged in | Open Home | Hero, trending strip, quick links, suggested sections render |
| HOME-02 | FE | P1 | Events exist | Tap trending card | Event details screen opens |
| HOME-03 | FE | P1 | Student | Tap Leaderboard / Feed quick links | Respective screens open |
| HOME-04 | FE | P1 | Student | Tap bottom nav tabs | Correct tab body; active pill highlights |
| HOME-05 | FE | P1 | Affairs role | Inspect nav | Home, Manage, Reviews, Profile only |
| HOME-06 | FE | P1 | Staff role | Inspect nav | Home, Events, Hours, Profile only |
| NAV-01 | FE | P2 | Any role | Rotate / resize web window | Layout readable; no overflow crashes |

---

## 4. Events

| ID | Type | Priority | Precondition | Steps | Expected result |
|----|------|----------|--------------|-------|-----------------|
| EVT-01 | FE | P0 | Student | Events tab → list loads | Events from backend (when connected) |
| EVT-02 | FE | P1 | Student | Filter by category | List filters correctly |
| EVT-03 | FE | P1 | Student | Star event | Favorite persists after refresh |
| EVT-04 | FE | P1 | Student | Join event | Joined state; appears in profile count |
| EVT-05 | FE | P1 | Student | Event details → check-in QR flow | Attend success when valid code |
| EVT-06 | FE | P1 | Affairs | Create event | Form submits; event appears in list |
| EVT-07 | FE | P1 | Affairs | Create event draft | XGBoost preview % shown (live or fallback message) |
| EVT-08 | BE | P0 | JWT | `GET /events` | `200`; array of events |
| EVT-09 | BE | P0 | Manager role | `POST /events` valid body | `201`; event in DB |
| EVT-10 | BE | P1 | Student | `POST /events` | `403` |
| EVT-11 | BE | P0 | Student | `POST /event-reservations/reserve` | Reservation created |
| EVT-12 | BE | P1 | Student | `GET /event-reservations/mine` | Own reservations only |
| EVT-13 | BE | P1 | Manager | `POST /events/predict-draft` | `200`; `success_probability` 0–1 |
| EVT-14 | BE | P1 | Manager | `POST /events/:id/predict-success` | `200`; prediction stored/returned |
| EVT-15 | AI | P0 | Model file present | `POST /api/predictions/event-success` | `success_probability`, `success_label`, `engagement_score` |
| EVT-16 | AI | P1 | Model missing | Same request | `503` with train hint |
| EVT-17 | INT | P0 | Backend + AI up | Create event with preview | Preview matches AI probability; event publish works |
| EVT-18 | INT | P1 | Joined event | Submit feedback after attend | Feedback row in `GET /event-feedback` |

---

## 5. Clubs

| ID | Type | Priority | Precondition | Steps | Expected result |
|----|------|----------|--------------|-------|-----------------|
| CLB-01 | FE | P0 | Student | Clubs tab | Club grid/list loads |
| CLB-02 | FE | P1 | Student | Join club | Joined state; profile club count +1 |
| CLB-03 | FE | P1 | Student | Club details / server view | Messages or activity load without crash |
| CLB-04 | FE | P1 | Student | Request new club (form) | Request submitted; pending state visible |
| CLB-05 | FE | P1 | Affairs | Reviews tab | Pending club requests list |
| CLB-06 | FE | P1 | Affairs | Approve / reject request | Status updates; club created on approve |
| CLB-07 | BE | P0 | JWT | `GET /clubs` | `200` |
| CLB-08 | BE | P0 | Student | `POST /club-membership` join | Membership row created |
| CLB-09 | BE | P1 | Student | `POST /club-requests` | Request `pending` |
| CLB-10 | BE | P1 | Affairs | `PATCH /club-requests/:id/approve` | Club + membership for requester |
| CLB-11 | BE | P2 | Duplicate name | Create club with existing name | `409` or validation error (when enforced) |
| CLB-12 | INT | P1 | Approved club | Student opens club | Can view; join if not auto-joined |

---

## 6. Academics & study sessions

| ID | Type | Priority | Precondition | Steps | Expected result |
|----|------|----------|--------------|-------|-----------------|
| ACA-01 | FE | P0 | Student | Academics tab | Study sessions, planner sections render |
| ACA-02 | FE | P1 | Student | Create study session | Session appears in list |
| ACA-03 | FE | P1 | Student | Join session | Membership reflected |
| ACA-04 | FE | P2 | Student | Study reminder screen | Reminder UI saves without error |
| ACA-05 | BE | P0 | Student | `GET /study-sessions` | `200` |
| ACA-06 | BE | P1 | Student | `POST /study-sessions` | `201` |
| ACA-07 | BE | P1 | Student | `POST /study-session-membership` | Join succeeds |
| ACA-08 | BE | P2 | Student | `GET /study-plans` | Plans or empty list |
| ACA-09 | INT | P1 | Session with members | Open session members UI | Member list matches API |

---

## 7. Connections & peer messages

| ID | Type | Priority | Precondition | Steps | Expected result |
|----|------|----------|--------------|-------|-----------------|
| CON-01 | FE | P1 | Student | Connections screen | Suggested / connected lists |
| CON-02 | FE | P1 | Student | Send connection request | Pending → connected flow |
| CON-03 | FE | P1 | Connected users | Open chat | Messages send and appear |
| CON-04 | FE | P1 | Messages tab | Inbox | Conversations with unread counts |
| CON-05 | FE | P1 | New DM received | Tap notification | Opens correct conversation |
| CON-06 | BE | P0 | Student A JWT | `POST /connections` to B | Request created |
| CON-07 | BE | P1 | Student B | Accept connection | Both see connected state |
| CON-08 | BE | P0 | Connected A→B | `POST /peer-messages` | `201`; message persisted |
| CON-09 | BE | P1 | Not connected | `POST /peer-messages` | `403` |
| CON-10 | BE | P1 | Recipient | `GET /peer-messages/inbox` | Conversation list + unread |
| CON-11 | BE | P1 | Recipient | `POST /peer-messages/read` | Unread cleared |
| CON-12 | INT | P0 | A sends message | B refreshes inbox | Message visible; notification type `message` |
| CON-13 | INT | P1 | Poll / refresh | Send while chat open | New message appears within poll interval |

---

## 8. Volunteer hours & staff approvals

| ID | Type | Priority | Precondition | Steps | Expected result |
|----|------|----------|--------------|-------|-----------------|
| VOL-01 | FE | P0 | Student | Profile → Volunteer Hours | List loads; pull-to-refresh works |
| VOL-02 | FE | P0 | Staff approved hours | Student refreshes volunteer screen | Status **Approved** (not stale Pending) |
| VOL-03 | FE | P1 | Student | Submit hours request | Pending row created |
| VOL-04 | FE | P1 | Staff | Hours tab → approve | Student sees approved on refresh |
| VOL-05 | FE | P1 | Staff | Reject with reason | Student sees rejection |
| VOL-06 | BE | P1 | Student | `POST /volunteering` | Request created |
| VOL-07 | BE | P1 | Staff | `PATCH /volunteering/:id/approve` | Status `approved` |
| VOL-08 | INT | P0 | Approve flow | Staff approves → student pull refresh | Hours total updates |

---

## 9. Gamification, shop, badges, notifications

| ID | Type | Priority | Precondition | Steps | Expected result |
|----|------|----------|--------------|-------|-----------------|
| GAM-01 | FE | P1 | New student | First login | Points start at **0** (not hardcoded mock) |
| GAM-02 | FE | P1 | Student | Join event / activity | Points increment (if rules apply) |
| GAM-03 | FE | P1 | Home → Leaderboard | Leaderboard loads ranks |
| GAM-04 | BE | P0 | JWT | `GET /gamification` | Points + level payload |
| GAM-05 | BE | P1 | JWT | `GET /gamification/leaderboard` | Ordered entries |
| SHP-01 | FE | P2 | Student | Shop screen | Items list; purchase flow |
| SHP-02 | BE | P1 | JWT | `GET /shop/items` | `200` |
| SHP-03 | BE | P1 | Sufficient points | `POST /shop/purchase` | Purchase recorded; points deducted |
| BDG-01 | FE | P1 | Profile badges | View badges | Locked/unlocked states correct |
| BDG-02 | BE | P1 | JWT | `GET /badges` | Definitions list |
| NTF-01 | FE | P1 | Trigger notification | Profile → notifications | Item appears; tap navigates correctly |
| NTF-02 | BE | P1 | JWT | `GET /notifications` | User-scoped list |

---

## 10. ML model (XGBoost event success)

| ID | Type | Priority | Precondition | Steps | Expected result |
|----|------|----------|--------------|-------|-----------------|
| ML-01 | AI | P0 | `event_success_xgb.joblib` exists | `npm run train:ai` | CV ~0.90; model saved |
| ML-02 | AI | P1 | Trained model | Predict sample features | `success_probability` ∈ [0,1] |
| ML-03 | AI | P1 | Threshold 0.5 | `proba=0.49` vs `0.51` | Label 0 vs 1 |
| ML-04 | BE | P1 | AI down | `POST /events/predict-draft` | Graceful error / fallback (no crash) |
| ML-05 | INT | P1 | Create event UI | Draft prediction | UI shows % and confidence band (High ≥0.75, Medium ≥0.5) |

---

## 11. RBAC & security matrix

| ID | Type | Priority | Endpoint / action | Student | Staff | Affairs |
|----|------|----------|-------------------|---------|-------|---------|
| RBAC-01 | BE | P0 | `POST /profiling/*` | Allow | Deny | Deny |
| RBAC-02 | BE | P0 | `POST /events` (create) | Deny | Deny* | Allow |
| RBAC-03 | BE | P0 | `POST /event-reservations/reserve` | Allow | Deny | Deny |
| RBAC-04 | BE | P1 | `PATCH /volunteering/*/approve` | Deny | Allow | Deny |
| RBAC-05 | BE | P1 | `PATCH /club-requests/*/approve` | Deny | Deny | Allow |
| RBAC-06 | BE | P1 | `POST /peer-messages` (non-connected) | Deny | — | — |
| RBAC-07 | INT | P0 | Wrong role in Flutter shell | Login each role | Only role-appropriate tabs/screens |

\*Staff may have read-only event access per product rules — verify against current `authorizeCapability` config.

---

## 12. Resilience & offline

| ID | Type | Priority | Precondition | Steps | Expected result |
|----|------|----------|--------------|-------|-----------------|
| RES-01 | FE | P1 | `BACKEND_ENABLED=true`, backend stopped | Browse app | Mock fallback or clear errors; no white screen |
| RES-02 | INT | P1 | Backend restarts mid-session | Pull refresh | Recovers when backend returns |
| RES-03 | FE | P2 | Slow network | Load home | Loading indicators; timeout handled |
| RES-04 | BE | P1 | Invalid JWT | Any protected route | `401` |
| RES-05 | BE | P1 | Suspended user | Protected route | `403 Account suspended` |

---

## 13. End-to-end journeys (E2E)

| ID | Type | Priority | Journey | Expected result |
|----|------|----------|---------|-----------------|
| E2E-01 | E2E | P0 | **New student**: Sign up → confirm → login → Shams → main shell | Full onboarding without manual DB fixes |
| E2E-02 | E2E | P0 | **Campus day**: Home → join event → attend QR → profile history | Event in history; feedback optional |
| E2E-03 | E2E | P1 | **Club life**: Request club → affairs approve → join → club chat | Club visible; membership works |
| E2E-04 | E2E | P1 | **Study**: Create session → peer joins → academics list updated | Both users see session |
| E2E-05 | E2E | P1 | **Social**: Connect → DM → notification tap | Message delivered both ways |
| E2E-06 | E2E | P1 | **Volunteer**: Submit hours → staff approve → student refresh | Approved hours on profile |
| E2E-07 | E2E | P1 | **Affairs event**: Create event → AI preview → publish → student discovers | Event on Events tab with prediction metadata |
| E2E-08 | E2E | P2 | **Profile refresh**: Shams update from Profile → Keep | Interests/goals sync to backend |

---

## 14. Automated test mapping (suggested)

| Area | Tool | Location / command |
|------|------|-------------------|
| Flutter widget/smoke | `flutter_test` | `flutter-app/test/` — extend beyond `widget_test.dart` |
| Flutter integration | `integration_test` | `flutter-app/integration_test/` (add) |
| Backend unit/API | Vitest or Supertest | `backend/src/**/*.test.ts` (add) |
| AI unit | `pytest` | `ai/tests/` (add) |
| API manual/regression | Postman | `backend/postman/collections/` |
| E2E API | Newman CI | Run Postman collection against local stack |

**Existing automated coverage**

- `flutter-app/test/widget_test.dart` — app boots to landing (`AUTH-01` partial)

**Recommended next P0 automations**

1. `GET /health`, `GET /ai/health`, `POST /auth/provision` (mocked Supabase)
2. `ProfilingRepository` + `PredictionsRepository` contract tests (Flutter)
3. `train_event_success` + predict round-trip (AI)
4. Integration: provision → users/me → profiling chat (against local Supabase test project)

---

## 15. Test data checklist

| Item | Example |
|------|---------|
| Student A | `student1@student.aaup.edu` |
| Student B | `student2@student.aaup.edu` |
| Staff | `staff1@staff.aaup.edu` |
| Affairs | `affairs@staff.aaup.edu` |
| Dean | `dean@aaup.edu` |
| Admin | `admin@aaup.edu` |
| Event QR code | From created event `check_in_code` |
| Club request | Unique name per run to avoid UNIQUE conflicts |

---

*Generated for AAURA monorepo (Flutter + Express + FastAPI). Update IDs when adding features or migrations.*
