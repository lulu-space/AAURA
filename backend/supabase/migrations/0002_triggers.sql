-- AAURA Phase 1: shared triggers/functions.

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_users_updated_at on public.users;
create trigger trg_users_updated_at before update on public.users for each row execute function public.set_updated_at();

drop trigger if exists trg_students_updated_at on public.students;
create trigger trg_students_updated_at before update on public.students for each row execute function public.set_updated_at();

drop trigger if exists trg_student_profile_drafts_updated_at on public.student_profile_drafts;
create trigger trg_student_profile_drafts_updated_at before update on public.student_profile_drafts for each row execute function public.set_updated_at();

drop trigger if exists trg_student_profiles_updated_at on public.student_profiles;
create trigger trg_student_profiles_updated_at before update on public.student_profiles for each row execute function public.set_updated_at();

drop trigger if exists trg_events_updated_at on public.events;
create trigger trg_events_updated_at before update on public.events for each row execute function public.set_updated_at();

drop trigger if exists trg_clubs_updated_at on public.clubs;
create trigger trg_clubs_updated_at before update on public.clubs for each row execute function public.set_updated_at();

drop trigger if exists trg_volunteering_records_updated_at on public.volunteering_records;
create trigger trg_volunteering_records_updated_at before update on public.volunteering_records for each row execute function public.set_updated_at();

drop trigger if exists trg_study_plans_updated_at on public.study_plans;
create trigger trg_study_plans_updated_at before update on public.study_plans for each row execute function public.set_updated_at();

drop trigger if exists trg_calendar_updated_at on public.calendar;
create trigger trg_calendar_updated_at before update on public.calendar for each row execute function public.set_updated_at();

drop trigger if exists trg_study_sessions_updated_at on public.study_sessions;
create trigger trg_study_sessions_updated_at before update on public.study_sessions for each row execute function public.set_updated_at();

drop trigger if exists trg_gamification_updated_at on public.gamification;
create trigger trg_gamification_updated_at before update on public.gamification for each row execute function public.set_updated_at();
