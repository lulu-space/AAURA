-- RLS updates for student_affairs, dean_of_faculty, club_organizer.

drop policy if exists events_insert_organizer_admin on public.events;
create policy events_insert_event_managers on public.events
for insert with check (
  public.current_app_role() in ('club_organizer', 'student_affairs', 'dean_of_faculty', 'admin')
  and organizer_id = auth.uid()
);

drop policy if exists events_update_owner_or_admin on public.events;
create policy events_update_owner_or_admin on public.events
for update using (
  organizer_id = auth.uid()
  or public.current_app_role() in ('student_affairs', 'dean_of_faculty', 'admin')
)
with check (
  organizer_id = auth.uid()
  or public.current_app_role() in ('student_affairs', 'dean_of_faculty', 'admin')
);

drop policy if exists events_delete_owner_or_admin on public.events;
create policy events_delete_owner_or_admin on public.events
for delete using (
  organizer_id = auth.uid()
  or public.current_app_role() in ('admin')
);

drop policy if exists clubs_write_organizer_admin on public.clubs;
create policy clubs_write_club_organizer_admin on public.clubs
for all using (organizer_id = auth.uid() or public.current_app_role() = 'admin')
with check (
  public.current_app_role() in ('club_organizer', 'admin')
  and (organizer_id = auth.uid() or public.current_app_role() = 'admin')
);

alter table public.volunteering_opportunities enable row level security;

drop policy if exists volunteering_opportunities_select_authenticated on public.volunteering_opportunities;
create policy volunteering_opportunities_select_authenticated on public.volunteering_opportunities
for select using (auth.uid() is not null);

drop policy if exists volunteering_opportunities_write_faculty on public.volunteering_opportunities;
create policy volunteering_opportunities_write_faculty on public.volunteering_opportunities
for all using (
  public.current_app_role() in ('student_affairs', 'dean_of_faculty', 'admin')
)
with check (
  public.current_app_role() in ('student_affairs', 'dean_of_faculty', 'admin')
  and created_by = auth.uid()
);
