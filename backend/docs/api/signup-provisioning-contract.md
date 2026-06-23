# AAURA Signup Provisioning Contract

## Purpose
This contract defines the backend endpoint that provisions the application-level user record after a successful Supabase Auth signup.

The flow is:

1. Flutter signs the user up through Supabase Auth.
2. Supabase creates a row in `auth.users`.
3. The backend receives the authenticated user's UUID and profile payload.
4. The backend calls `public.provision_application_user(...)`.
5. The backend returns the application user profile to the client.

This keeps authentication in Supabase and business roles in `public.users`.

## Endpoint
- Method: `POST`
- Path: `/api/v1/auth/provision`
- Auth: `Bearer JWT required`
- Caller: authenticated newly signed-up user

## Behavior
- Verifies the JWT and extracts `auth.uid()`.
- Confirms the request user matches the authenticated subject.
- Creates or updates the row in `public.users`.
- Creates or updates the optional row in `public.students`.
- Assigns the default role `student`.
- Returns the provisioned application user data.

## Request Body
```json
{
  "fullName": "Hashem Ali",
  "universityId": "2026-00124",
  "major": "Computer Science",
  "department": "Faculty of Computing",
  "academicYear": 4
}
```

## Validation Rules
- `fullName`: required, string, min length 3
- `universityId`: optional, string, unique if provided
- `major`: optional, string
- `department`: optional, string
- `academicYear`: optional, integer, minimum 1

## Backend Mapping
- JWT subject -> `p_user_id`
- Supabase Auth email -> `p_email`
- request `fullName` -> `p_full_name`
- request `universityId` -> `p_university_id`
- request `major` -> `p_major`
- request `department` -> `p_department`
- request `academicYear` -> `p_academic_year`

## Database Call
```sql
select public.provision_application_user(
  p_user_id => :auth_user_id,
  p_email => :auth_email,
  p_full_name => :full_name,
  p_university_id => :university_id,
  p_major => :major,
  p_department => :department,
  p_academic_year => :academic_year
);
```

## Success Response
Status: `201 Created`

```json
{
  "message": "Application user provisioned successfully.",
  "data": {
    "id": "0f9a6f49-8b0f-4ac1-8a7b-20cf2b9f4d50",
    "email": "student@aaura.edu",
    "fullName": "Hashem Ali",
    "role": "student",
    "isSuspended": false,
    "student": {
      "universityId": "2026-00124",
      "major": "Computer Science",
      "department": "Faculty of Computing",
      "academicYear": 4
    }
  }
}
```

## Error Responses

### `400 Bad Request`
Invalid payload or validation failure.

```json
{
  "message": "Validation failed.",
  "errors": {
    "fullName": ["Full name is required."]
  }
}
```

### `401 Unauthorized`
Missing or invalid JWT.

```json
{
  "message": "Unauthorized."
}
```

### `409 Conflict`
Profile collision such as duplicate `universityId`.

```json
{
  "message": "University ID already exists."
}
```

### `500 Internal Server Error`
Provisioning failure between auth and app profile creation.

```json
{
  "message": "Failed to provision application user."
}
```

## Idempotency
This endpoint should be safe to call more than once for the same user.

- If `public.users` already exists, update mutable profile fields.
- If `public.students` already exists, update student fields.
- Never create duplicate application user rows.
- Never allow the client to set `role`.

## Security Rules
- Only these campus emails may sign up or provision (all others are rejected):
  - `@student.aaup.edu` → `student`
  - `@staff.aaup.edu` → `student_affairs`
  - `admin@aaup.edu` → `admin`
  - any other `@aaup.edu` → `dean_of_faculty`
- The request must not accept `role`, `isSuspended`, or any admin-only fields.
- The backend must trust the JWT subject and email, not client-supplied identity values.

## Notes For Phase 2
- The backend service should wrap this as an `AuthProvisionService`.
- Add request DTO validation before calling the SQL function.
- Log provisioning actions into `system_logs`.
- Return the normalized app user object used by Flutter dashboards.
