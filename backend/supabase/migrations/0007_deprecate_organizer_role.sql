-- Deprecate app_role 'organizer': migrate existing users to club_organizer and refresh RLS.
-- The enum value may remain in Postgres but must not be assigned to new users.

update public.users
set role = 'club_organizer'
where role = 'organizer';

drop policy if exists events_insert_event_managers on public.events;
create policy events_insert_event_managers on public.events
for insert with check (
  public.current_app_role() in ('club_organizer', 'student_affairs', 'dean_of_faculty', 'admin')
  and organizer_id = auth.uid()
);

drop policy if exists engagement_metrics_self_organizer_admin on public.engagement_metrics;
create policy engagement_metrics_event_managers on public.engagement_metrics
for all using (
  user_id = auth.uid()
  or public.current_app_role() = 'admin'
  or (
    public.current_app_role() in ('club_organizer', 'student_affairs', 'dean_of_faculty')
    and exists (
      select 1 from public.events e
      where e.id = event_id and e.organizer_id = auth.uid()
    )
  )
)
with check (
  user_id = auth.uid()
  or public.current_app_role() = 'admin'
  or (
    public.current_app_role() in ('club_organizer', 'student_affairs', 'dean_of_faculty')
    and exists (
      select 1 from public.events e
      where e.id = event_id and e.organizer_id = auth.uid()
    )
  )
);
