-- Club-founding / organizer requests.
-- A student submits a request to start a club; Student Affairs or Staff review
-- it. On approval the club is created, the requester becomes its lead, and the
-- requester is promoted to club_organizer so they can manage their club/events.
-- The row itself is the audit trail (who reviewed, when, and why).

create table if not exists public.club_requests (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.users(id) on delete cascade,
  proposed_name text not null,
  description text not null default '',
  category text not null default 'academic',
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  review_note text,
  reviewed_by uuid references public.users(id) on delete set null,
  reviewed_at timestamptz,
  created_club_id uuid references public.clubs(id) on delete set null,
  created_at timestamptz not null default now()
);

create index if not exists idx_club_requests_status
  on public.club_requests(status, created_at desc);
create index if not exists idx_club_requests_requester
  on public.club_requests(requester_id, created_at desc);

alter table public.club_requests enable row level security;

-- Students can create and read their own requests.
drop policy if exists club_requests_insert_own on public.club_requests;
create policy club_requests_insert_own on public.club_requests
  for insert to authenticated
  with check (requester_id = auth.uid());

drop policy if exists club_requests_select_own_or_reviewer on public.club_requests;
create policy club_requests_select_own_or_reviewer on public.club_requests
  for select to authenticated
  using (
    requester_id = auth.uid()
    or public.current_app_role() in ('staff', 'student_affairs', 'dean_of_faculty', 'admin')
  );

-- Only reviewers (staff / student affairs / admin) can update (approve/reject).
drop policy if exists club_requests_update_reviewer on public.club_requests;
create policy club_requests_update_reviewer on public.club_requests
  for update to authenticated
  using (
    public.current_app_role() in ('staff', 'student_affairs', 'dean_of_faculty', 'admin')
  )
  with check (
    public.current_app_role() in ('staff', 'student_affairs', 'dean_of_faculty', 'admin')
  );
