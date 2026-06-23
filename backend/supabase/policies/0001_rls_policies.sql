-- AAURA Phase 1: RLS policies and role-based access control.

alter table public.users enable row level security;
alter table public.students enable row level security;
alter table public.student_profile_drafts enable row level security;
alter table public.student_profiles enable row level security;
alter table public.events enable row level security;
alter table public.event_reservation enable row level security;
alter table public.event_feedback enable row level security;
alter table public.clubs enable row level security;
alter table public.club_membership enable row level security;
alter table public.volunteering_records enable row level security;
alter table public.recommendations enable row level security;
alter table public.search_history enable row level security;
alter table public.engagement_metrics enable row level security;
alter table public.study_plans enable row level security;
alter table public.calendar enable row level security;
alter table public.study_sessions enable row level security;
alter table public.study_session_membership enable row level security;
alter table public.gamification enable row level security;
alter table public.notifications enable row level security;
alter table public.system_logs enable row level security;

-- users
drop policy if exists users_select_self_or_admin on public.users;
create policy users_select_self_or_admin on public.users
for select using (id = auth.uid() or public.is_app_admin());

drop policy if exists users_update_self_or_admin on public.users;
create policy users_update_self_or_admin on public.users
for update using (id = auth.uid() or public.is_app_admin())
with check (id = auth.uid() or public.is_app_admin());

drop policy if exists users_insert_self_or_admin on public.users;
create policy users_insert_self_or_admin on public.users
for insert with check (id = auth.uid() or public.is_app_admin());

-- student entities (self/admin)
drop policy if exists students_self_admin_all on public.students;
create policy students_self_admin_all on public.students
for all using (user_id = auth.uid() or public.current_app_role() = 'admin')
with check (user_id = auth.uid() or public.current_app_role() = 'admin');

drop policy if exists student_profile_drafts_self_admin_all on public.student_profile_drafts;
create policy student_profile_drafts_self_admin_all on public.student_profile_drafts
for all using (user_id = auth.uid() or public.current_app_role() = 'admin')
with check (user_id = auth.uid() or public.current_app_role() = 'admin');

drop policy if exists student_profiles_self_admin_all on public.student_profiles;
create policy student_profiles_self_admin_all on public.student_profiles
for all using (user_id = auth.uid() or public.current_app_role() = 'admin')
with check (user_id = auth.uid() or public.current_app_role() = 'admin');

-- events
drop policy if exists events_select_all_authenticated on public.events;
create policy events_select_all_authenticated on public.events
for select using (auth.uid() is not null);

drop policy if exists events_insert_organizer_admin on public.events;
create policy events_insert_event_managers on public.events
for insert with check (
  public.current_app_role() in ('club_organizer', 'student_affairs', 'dean_of_faculty', 'admin')
  and organizer_id = auth.uid()
);

drop policy if exists events_update_owner_or_admin on public.events;
create policy events_update_owner_or_admin on public.events
for update using (organizer_id = auth.uid() or public.current_app_role() = 'admin')
with check (organizer_id = auth.uid() or public.current_app_role() = 'admin');

drop policy if exists events_delete_owner_or_admin on public.events;
create policy events_delete_owner_or_admin on public.events
for delete using (organizer_id = auth.uid() or public.current_app_role() = 'admin');

-- event reservations and feedback
drop policy if exists event_reservation_self_or_event_organizer_or_admin on public.event_reservation;
create policy event_reservation_self_or_event_organizer_or_admin on public.event_reservation
for all using (
  user_id = auth.uid()
  or public.current_app_role() = 'admin'
  or exists (select 1 from public.events e where e.id = event_id and e.organizer_id = auth.uid())
)
with check (
  user_id = auth.uid()
  or public.current_app_role() = 'admin'
  or exists (select 1 from public.events e where e.id = event_id and e.organizer_id = auth.uid())
);

drop policy if exists event_feedback_self_or_event_organizer_or_admin on public.event_feedback;
create policy event_feedback_self_or_event_organizer_or_admin on public.event_feedback
for all using (
  user_id = auth.uid()
  or public.current_app_role() = 'admin'
  or exists (select 1 from public.events e where e.id = event_id and e.organizer_id = auth.uid())
)
with check (
  user_id = auth.uid()
  or public.current_app_role() = 'admin'
  or exists (select 1 from public.events e where e.id = event_id and e.organizer_id = auth.uid())
);

-- clubs and membership
drop policy if exists clubs_select_all_authenticated on public.clubs;
create policy clubs_select_all_authenticated on public.clubs
for select using (auth.uid() is not null);

drop policy if exists clubs_write_organizer_admin on public.clubs;
create policy clubs_write_club_organizer_admin on public.clubs
for all using (organizer_id = auth.uid() or public.current_app_role() = 'admin')
with check (
  public.current_app_role() in ('club_organizer', 'admin')
  and (organizer_id = auth.uid() or public.current_app_role() = 'admin')
);

drop policy if exists club_membership_self_or_club_organizer_or_admin on public.club_membership;
create policy club_membership_self_or_club_organizer_or_admin on public.club_membership
for all using (
  user_id = auth.uid()
  or public.current_app_role() = 'admin'
  or exists (select 1 from public.clubs c where c.id = club_id and c.organizer_id = auth.uid())
)
with check (
  user_id = auth.uid()
  or public.current_app_role() = 'admin'
  or exists (select 1 from public.clubs c where c.id = club_id and c.organizer_id = auth.uid())
);

-- volunteering (staff approval)
drop policy if exists volunteering_self_staff_admin on public.volunteering_records;
create policy volunteering_self_staff_admin on public.volunteering_records
for select using (
  user_id = auth.uid() or public.current_app_role() in ('staff', 'admin')
);

drop policy if exists volunteering_insert_self_admin on public.volunteering_records;
create policy volunteering_insert_self_admin on public.volunteering_records
for insert with check (user_id = auth.uid() or public.current_app_role() = 'admin');

drop policy if exists volunteering_update_self_staff_admin on public.volunteering_records;
create policy volunteering_update_self_staff_admin on public.volunteering_records
for update using (
  user_id = auth.uid() or public.current_app_role() in ('staff', 'admin')
)
with check (
  user_id = auth.uid()
  or public.current_app_role() = 'admin'
  or (public.current_app_role() = 'staff' and approved_by_staff_id = auth.uid())
);

-- user-owned tables
drop policy if exists recommendations_self_or_admin on public.recommendations;
create policy recommendations_self_or_admin on public.recommendations
for all using (user_id = auth.uid() or public.current_app_role() = 'admin')
with check (user_id = auth.uid() or public.current_app_role() = 'admin');

drop policy if exists search_history_self_or_admin on public.search_history;
create policy search_history_self_or_admin on public.search_history
for all using (user_id = auth.uid() or public.current_app_role() = 'admin')
with check (user_id = auth.uid() or public.current_app_role() = 'admin');

drop policy if exists engagement_metrics_self_organizer_admin on public.engagement_metrics;
create policy engagement_metrics_event_managers on public.engagement_metrics
for all using (
  user_id = auth.uid()
  or public.current_app_role() = 'admin'
  or (
    public.current_app_role() in ('club_organizer', 'student_affairs', 'dean_of_faculty')
    and exists (select 1 from public.events e where e.id = event_id and e.organizer_id = auth.uid())
  )
)
with check (
  user_id = auth.uid()
  or public.current_app_role() = 'admin'
  or (
    public.current_app_role() in ('club_organizer', 'student_affairs', 'dean_of_faculty')
    and exists (select 1 from public.events e where e.id = event_id and e.organizer_id = auth.uid())
  )
);

drop policy if exists study_plans_self_or_admin on public.study_plans;
create policy study_plans_self_or_admin on public.study_plans
for all using (user_id = auth.uid() or public.current_app_role() = 'admin')
with check (user_id = auth.uid() or public.current_app_role() = 'admin');

drop policy if exists calendar_self_or_admin on public.calendar;
create policy calendar_self_or_admin on public.calendar
for all using (user_id = auth.uid() or public.current_app_role() = 'admin')
with check (user_id = auth.uid() or public.current_app_role() = 'admin');

drop policy if exists study_sessions_select_authenticated on public.study_sessions;
create policy study_sessions_select_authenticated on public.study_sessions
for select using (auth.uid() is not null);

drop policy if exists study_sessions_write_host_or_admin on public.study_sessions;
create policy study_sessions_write_host_or_admin on public.study_sessions
for all using (host_user_id = auth.uid() or public.current_app_role() = 'admin')
with check (
  host_user_id = auth.uid() or public.current_app_role() = 'admin'
);

drop policy if exists study_session_membership_self_or_host_or_admin on public.study_session_membership;
create policy study_session_membership_self_or_host_or_admin on public.study_session_membership
for all using (
  user_id = auth.uid()
  or public.current_app_role() = 'admin'
  or exists (
    select 1 from public.study_sessions s
    where s.id = study_session_id and s.host_user_id = auth.uid()
  )
)
with check (
  user_id = auth.uid()
  or public.current_app_role() = 'admin'
  or exists (
    select 1 from public.study_sessions s
    where s.id = study_session_id and s.host_user_id = auth.uid()
  )
);

drop policy if exists gamification_self_or_admin on public.gamification;
create policy gamification_self_or_admin on public.gamification
for all using (user_id = auth.uid() or public.current_app_role() = 'admin')
with check (user_id = auth.uid() or public.current_app_role() = 'admin');

drop policy if exists notifications_self_or_admin on public.notifications;
create policy notifications_self_or_admin on public.notifications
for all using (user_id = auth.uid() or public.current_app_role() = 'admin')
with check (user_id = auth.uid() or public.current_app_role() = 'admin');

-- system logs
drop policy if exists system_logs_staff_admin_select on public.system_logs;
create policy system_logs_staff_admin_select on public.system_logs
for select using (public.current_app_role() in ('staff', 'admin'));

drop policy if exists system_logs_admin_write on public.system_logs;
create policy system_logs_admin_write on public.system_logs
for all using (public.current_app_role() = 'admin')
with check (public.current_app_role() = 'admin');
