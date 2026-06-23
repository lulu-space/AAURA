-- Student event approval workflow for club organizers.
-- Student Affairs / Dean events are auto-approved on create (backend logic).

alter table public.events
  add column if not exists approval_note text,
  add column if not exists reviewed_by uuid references public.users(id) on delete set null,
  add column if not exists reviewed_at timestamptz;

update public.events
set is_approved = true
where status = 'published' and is_approved = false;

create index if not exists idx_events_approval_pending
  on public.events(is_approved, status, created_at desc);

drop policy if exists events_select_all_authenticated on public.events;
create policy events_select_all_authenticated on public.events
for select using (
  auth.uid() is not null
  and (
    public.current_app_role() in ('student_affairs', 'dean_of_faculty', 'admin')
    or organizer_id = auth.uid()
    or (is_approved = true and status = 'published')
  )
);
