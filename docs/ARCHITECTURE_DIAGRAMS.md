# AAURA — Architecture Diagrams

Visual reference for the AAURA campus platform (Flutter + Express + Supabase + FastAPI AI).

> **Viewing:** Open this file in GitHub, VS Code, or any Mermaid-compatible viewer. Diagrams render from fenced `mermaid` blocks.

---

## Table of contents

1. [External entities (context diagram)](#1-external-entities-context-diagram)
2. [Deployment diagram](#2-deployment-diagram)
3. [Subsystems & internal services](#3-subsystems--internal-services)
4. [Entity–relationship diagram (ERD)](#4-entityrelationship-diagram-erd)
5. [Class diagram](#5-class-diagram)
6. [Use case diagram](#6-use-case-diagram)
7. [State machine diagrams](#7-state-machine-diagrams)

---

## 1. External entities (context diagram)

High-level view of AAURA and external actors/systems.

```mermaid
flowchart TB
    subgraph actors [External Actors]
        STU[Student]
        ORG[Club Organizer]
        SA[Student Affairs]
        DEAN[Dean of Faculty]
        ADM[System Admin]
    end

    AAURA[AAURA Platform]

    subgraph external [External Systems]
        SB[(Supabase\nAuth + PostgreSQL)]
        ML[AI Service\nFastAPI / Shams + XGBoost]
        EMAIL[Email Provider\nSupabase Auth]
    end

    STU -->|Browse, enroll, volunteer, chat| AAURA
    ORG -->|Create events, manage club| AAURA
    SA -->|Publish opportunities,\napprove hours & clubs| AAURA
    DEAN -->|Faculty events, announcements| AAURA
    ADM -->|Platform admin, content| AAURA

    AAURA -->|JWT auth, CRUD, RLS| SB
    AAURA -->|Profiling, predictions| ML
    SB -->|Confirm / reset emails| EMAIL
```

---

## 2. Deployment diagram

Production topology (see `docs/DEPLOY.md`).

```mermaid
flowchart TB
    subgraph clients [Clients]
        WEB[Browser / Flutter Web]
        MOB[Mobile Web View]
    end

    subgraph firebase [Firebase Hosting]
        SPA[Static Flutter build\nbuild/web]
    end

    subgraph render [Render — free tier]
        API[Express API\nDocker :4000\n/api/v1]
    end

    subgraph supabase [Supabase Cloud]
        AUTH[Auth Service]
        PG[(PostgreSQL\n+ RLS policies)]
        STOR[Storage\navatars, CV]
    end

    subgraph optional [Optional — local / future]
        AI[FastAPI AI :8000\nXGBoost + Shams NLP]
    end

    WEB --> SPA
    MOB --> SPA
    SPA -->|HTTPS REST + JWT| API
    SPA -->|Sign in / sign up| AUTH
    API -->|service_role| PG
    API -->|verify JWT| AUTH
    API -.->|AI_SERVICE_URL| AI
    AUTH --> PG
    SPA --> STOR
```

| Node | Technology | Role |
|------|------------|------|
| Flutter Web | Firebase Hosting | UI, QR scan, role-based shells |
| Express API | Render (Docker) | Business logic, authorization |
| PostgreSQL | Supabase | Persistent data, migrations |
| Auth | Supabase | Campus email login, JWT |
| AI | FastAPI (optional) | Event success prediction, Shams profiling |

---

## 3. Subsystems & internal services

Logical decomposition of the backend API and client.

```mermaid
flowchart TB
    subgraph client [Flutter Client]
        UI[Screens / Widgets]
        STATE[AppState\nProvider]
        REPO[Repositories]
        UI --> STATE --> REPO
    end

    subgraph gateway [API Gateway]
        JWT[JWT Middleware]
        CORS[CORS]
        ROUTER["/api/v1 Router"]
    end

    subgraph identity [Identity & Profiles]
        AUTH_M[Auth / Provision]
        USERS[Users]
        STUDENTS[Students]
        PROFILES[Student Profiles]
        DRAFTS[Profile Drafts]
        PROFILING[Profiling → AI proxy]
    end

    subgraph campus [Campus Life]
        EVENTS[Events + Reviews]
        RESERV[Event Reservations]
        FEEDBACK[Event Feedback]
        CLUBS[Clubs]
        CLUB_REQ[Club Requests]
        MEMBERS[Club Membership]
        CLUB_MSG[Club Messages]
        VOL_OPP[Volunteer Opportunities]
        VOL_REC[Volunteering Records]
    end

    subgraph student_life [Student Experience]
        GAMIF[Gamification]
        SHOP[Shop]
        BADGES[Badges]
        RECO[Recommendations]
        NOTIF[Notifications]
        CAL[Calendar]
        PLANS[Study Plans]
        SESSIONS[Study Sessions]
        CONN[Connections]
        PEER[Peer Messages]
    end

    subgraph leadership [Leadership]
        DEAN_M[Dean Module]
        ADMIN_M[Admin Module]
    end

    subgraph ai_layer [AI Layer]
        AI_PROXY[AI Routes]
        FASTAPI[FastAPI Service]
        AI_PROXY --> FASTAPI
    end

    REPO -->|HTTPS| JWT
    JWT --> ROUTER
    ROUTER --> identity
    ROUTER --> campus
    ROUTER --> student_life
    ROUTER --> leadership
    ROUTER --> AI_PROXY
    PROFILING --> FASTAPI
    EVENTS --> FASTAPI
```

### Backend module map

| Prefix | Module | Primary tables |
|--------|--------|----------------|
| `/auth` | Provision campus users | `users`, `students` |
| `/events` | CRUD + review workflow | `events` |
| `/event-reservations` | Reserve, join QR, check-in | `event_reservation` |
| `/clubs`, `/club-membership` | Clubs & rosters | `clubs`, `club_membership` |
| `/club-requests` | Founding approval | `club_requests` |
| `/volunteering` | Hour submissions & approval | `volunteering_records` |
| `/volunteering-opportunities` | Publish + QR join | `volunteering_opportunities` |
| `/profiling` | Shams onboarding | `student_profiles`, drafts |
| `/gamification`, `/shop`, `/badges` | Points economy | `gamification`, `shop_*` |
| `/dean`, `/admin` | Role dashboards | various |

---

## 4. Entity–relationship diagram (ERD)

Core schema (PostgreSQL / Supabase). Cardinality: `||` one, `o{` many.

```mermaid
erDiagram
    users ||--o| students : "has"
    users ||--o| student_profiles : "has"
    users ||--o| student_profile_drafts : "has"
    users ||--o| gamification : "has"
    users ||--o{ events : "organizes"
    users ||--o{ event_reservation : "reserves"
    users ||--o{ event_feedback : "rates"
    users ||--o{ club_membership : "joins"
    users ||--o{ volunteering_records : "submits"
    users ||--o{ volunteering_opportunities : "creates"
    users ||--o{ club_requests : "requests"
    users ||--o{ notifications : "receives"
    users ||--o{ study_plans : "owns"
    users ||--o{ calendar : "owns"
    users ||--o{ peer_connections : "connects"
    users ||--o{ shop_purchases : "buys"

    events ||--o{ event_reservation : "has"
    events ||--o{ event_feedback : "has"
    events ||--o| volunteering_opportunities : "linked"

    clubs ||--o{ club_membership : "has"
    clubs ||--o{ club_messages : "has"
    clubs ||--o{ club_activity_posts : "has"
    club_requests }o--o| clubs : "creates"

    volunteering_opportunities ||--o{ volunteering_records : "applications"

    study_sessions ||--o{ study_session_membership : "has"

    shop_items ||--o{ shop_purchases : "sold"

    users {
        uuid id PK
        text email UK
        text full_name
        app_role role
        boolean is_suspended
    }

    students {
        uuid id PK
        uuid user_id FK UK
        text university_id UK
        text major
        int academic_year
    }

    student_profiles {
        uuid id PK
        uuid user_id FK UK
        jsonb interests
        jsonb strengths
        jsonb goals
    }

    events {
        uuid id PK
        uuid organizer_id FK
        text title
        timestamptz starts_at
        text status
        boolean is_approved
        boolean is_hidden
        uuid join_token UK
        numeric ai_success_score
    }

    event_reservation {
        uuid id PK
        uuid event_id FK
        uuid user_id FK
        text reservation_status
        uuid qr_token UK
    }

    clubs {
        uuid id PK
        text name UK
        uuid organizer_id FK
        boolean is_active
        boolean is_hidden
    }

    club_requests {
        uuid id PK
        uuid requester_id FK
        text proposed_name
        text status
        uuid created_club_id FK
    }

    volunteering_opportunities {
        uuid id PK
        uuid created_by FK
        uuid event_id FK
        uuid join_token UK
        text status
        numeric estimated_hours
    }

    volunteering_records {
        uuid id PK
        uuid user_id FK
        uuid opportunity_id FK
        numeric hours
        text status
        uuid approved_by_staff_id FK
    }

    gamification {
        uuid id PK
        uuid user_id FK UK
        int points
        jsonb badges
    }
```

### Supporting entities (abbreviated)

| Table | Relates to |
|-------|------------|
| `recommendations` | `users` → events/clubs/study/volunteer targets |
| `notifications` | `users` (inbox) |
| `calendar` | `users` (study/reminder/event items) |
| `study_plans` | `users` |
| `study_sessions` / `study_session_membership` | host + attendees |
| `peer_direct_messages` | student messaging |
| `shop_items` / `shop_purchases` | gamification economy |
| `badge_definitions` | catalog; earned IDs in `gamification.badges` |
| `faculty_announcements` | dean broadcasts |
| `platform_settings` | admin configuration |

---

## 5. Class diagram

Simplified application-layer classes (Flutter domain + backend services).

```mermaid
classDiagram
    direction TB

    class AppState {
        +UserProfile profile
        +List~Event~ events
        +List~Club~ clubs
        +List~VolunteerRequest~ volunteerRequests
        +refreshAll()
        +approveVolunteerRequest()
        +joinEventByToken()
        +applyToVolunteerOpportunityByToken()
    }

    class UserProfile {
        +String name
        +String email
        +UserRole role
        +List~String~ interests
    }

    class UserRole {
        <<enumeration>>
        student
        studentAffairs
        deanOfFaculty
        admin
        staff
    }

    class Event {
        +String id
        +String title
        +String organizer
        +EventCategory category
        +bool isApproved
        +bool isHidden
        +double aiSuccessScore
    }

    class Club {
        +String id
        +String name
        +String organizerId
        +bool isActive
    }

    class VolunteerRequest {
        +String id
        +String studentName
        +int hours
        +VolunteerRequestStatus status
        +String opportunityId
    }

    class VolunteerOpportunity {
        +String id
        +String title
        +int estimatedHours
        +String joinToken
        +bool isOpen
    }

    class ClubRequest {
        +String id
        +String proposedName
        +ClubRequestStatus status
    }

    class ApiClient {
        +get(path)
        +post(path, body)
        +patch(path, body)
    }

    class EventsRepository {
        +list()
        +create()
        +reserve()
        +checkIn()
        +listReviewsAll()
    }

    class VolunteeringRepository {
        +listMine()
        +listAll()
        +approve()
        +reject()
    }

    class VolunteeringOpportunitiesRepository {
        +listOpen()
        +applyByJoinToken()
    }

    class VolunteeringWorkflowService {
        +listPending()
        +listAll()
        +approve()
        +reject()
        +withdraw()
    }

    class VolunteeringOpportunitiesService {
        +create()
        +applyByJoinToken()
        +findByJoinToken()
    }

    class EventsReviewService {
        +listPending()
        +approve()
        +reject()
        +withdraw()
    }

  AppState --> UserProfile
  AppState --> Event
  AppState --> Club
  AppState --> VolunteerRequest
  AppState --> VolunteerOpportunity
  AppState --> ClubRequest
  AppState --> EventsRepository
  AppState --> VolunteeringRepository
  AppState --> VolunteeringOpportunitiesRepository
  UserProfile --> UserRole
  EventsRepository --> ApiClient
  VolunteeringRepository --> ApiClient
  VolunteeringOpportunitiesRepository --> ApiClient
  VolunteeringWorkflowService ..> VolunteeringRepository : implements API
  VolunteeringOpportunitiesService ..> VolunteeringOpportunitiesRepository : implements API
  EventsReviewService ..> EventsRepository : implements API
```

---

## 6. Use case diagram

Actors and major use cases by role.

```mermaid
flowchart LR
    subgraph actors [Actors]
        direction TB
        A1((Student))
        A2((Club Organizer))
        A3((Student Affairs))
        A4((Dean))
        A5((Admin))
        A6((Shams AI))
    end

    subgraph student_uc [Student]
        UC1[Sign up / Log in]
        UC2[Shams onboarding]
        UC3[Browse & enroll events]
        UC4[QR check-in]
        UC5[Join clubs]
        UC6[Apply volunteer hours]
        UC7[Scan volunteer QR]
        UC8[Study planner]
        UC9[Earn points & badges]
        UC10[Connect with peers]
    end

    subgraph organizer_uc [Club Organizer]
        UC11[Submit club founding request]
        UC12[Create & publish events]
        UC13[View event analytics]
        UC14[View AI success score]
    end

    subgraph affairs_uc [Student Affairs]
        UC15[Publish volunteer opportunity]
        UC16[Approve volunteer hours]
        UC17[Review club requests]
        UC18[Review & publish events]
        UC19[Copy join links / QR]
    end

    subgraph dean_uc [Dean]
        UC20[Manage faculty events]
        UC21[Faculty announcements]
        UC22[Review events / clubs]
    end

    subgraph admin_uc [Admin]
        UC23[Platform dashboard]
        UC24[User management]
        UC25[Hide content]
    end

    A1 --> UC1
    A1 --> UC2
    A1 --> UC3
    A1 --> UC4
    A1 --> UC5
    A1 --> UC6
    A1 --> UC7
    A1 --> UC8
    A1 --> UC9
    A1 --> UC10

    A2 --> UC11
    A2 --> UC12
    A2 --> UC13
    A2 --> UC14

    A3 --> UC15
    A3 --> UC16
    A3 --> UC17
    A3 --> UC18
    A3 --> UC19

    A4 --> UC20
    A4 --> UC21
    A4 --> UC22

    A5 --> UC23
    A5 --> UC24
    A5 --> UC25

    A6 -.-> UC2
    A6 -.-> UC14
```

---

## 7. State machine diagrams

### 7.1 Event lifecycle

```mermaid
stateDiagram-v2
    [*] --> draft : create
    draft --> pending_review : submit for review
    pending_review --> published : staff approves
    pending_review --> draft : rejected / withdrawn
    published --> completed : event ends
    published --> cancelled : cancel
    completed --> [*]
    cancelled --> [*]

    note right of pending_review
        is_approved = false
        status may be draft or published
    end note

    note right of published
        is_approved = true
        visible to students
        unless is_hidden (admin)
    end note
```

### 7.2 Event reservation

```mermaid
stateDiagram-v2
    [*] --> reserved : enroll / join QR
    reserved --> checked_in : scan QR at venue
    reserved --> cancelled : cancel reservation
    checked_in --> [*]
    cancelled --> [*]
```

### 7.3 Volunteer hour record

```mermaid
stateDiagram-v2
    [*] --> pending : submit / QR apply
    pending --> approved : staff approves
    pending --> rejected : staff rejects
    approved --> pending : staff withdraws decision
    rejected --> pending : staff withdraws decision
    approved --> [*]
    rejected --> [*]

    note right of approved
        Hours count toward
        120h requirement
    end note
```

### 7.4 Volunteer opportunity

```mermaid
stateDiagram-v2
    [*] --> open : staff publishes
    open --> closed : slots filled / manual close
    closed --> [*]
```

### 7.5 Club founding request

```mermaid
stateDiagram-v2
    [*] --> pending : student submits
    pending --> approved : reviewer approves
    pending --> rejected : reviewer rejects
    approved --> [*] : club created,\nrequester → club_organizer
    rejected --> [*]
```

### 7.6 Authentication & onboarding (student)

```mermaid
stateDiagram-v2
    [*] --> unauthenticated
    unauthenticated --> email_confirm : sign up (confirm required)
    unauthenticated --> shams_onboarding : sign up / first login
    email_confirm --> authenticated : confirm email
    shams_onboarding --> main_app : profile saved
    authenticated --> shams_onboarding : profile incomplete
    authenticated --> main_app : profile complete
    main_app --> [*] : logout
    unauthenticated --> main_app : returning user login
```

---

## Diagram sources

| Diagram | Primary sources |
|---------|-----------------|
| ERD | `backend/supabase/migrations/*.sql` |
| Class | `flutter-app/lib/models/`, `lib/state/app_state.dart`, `backend/src/modules/` |
| Use cases | Role gates in `app_state.dart`, route authorization |
| State machines | `events`, `volunteering_records`, `club_requests`, `event_reservation` constraints |
| Deployment | `docs/DEPLOY.md`, `render.yaml`, `flutter-app/scripts/build-web-release.ps1` |
| Context / services | `backend/src/routes/index.ts`, `ai/main.py` |

---

*Generated for AAURA — Arab American University campus platform.*
