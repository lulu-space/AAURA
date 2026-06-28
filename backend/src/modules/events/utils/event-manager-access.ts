import { supabaseAdmin } from '../../../config/supabase.js';
import { EVENT_MANAGER_ROLES } from '../../../shared/constants/roles.js';

/** True when the user may create or manage campus events (incl. club leads still on role=student). */
export async function userCanManageEvents(
  userId: string,
  role: string | undefined,
  clubId?: string | null
): Promise<boolean> {
  if (role && EVENT_MANAGER_ROLES.includes(role as (typeof EVENT_MANAGER_ROLES)[number])) {
    return true;
  }

  if (clubId) {
    const { data: club } = await supabaseAdmin
      .from('clubs')
      .select('organizer_id, is_active')
      .eq('id', clubId)
      .maybeSingle();

    if (club?.organizer_id === userId && club?.is_active !== false) {
      return true;
    }

    const { data: membership } = await supabaseAdmin
      .from('club_membership')
      .select('role')
      .eq('club_id', clubId)
      .eq('user_id', userId)
      .maybeSingle();

    if (membership?.role === 'lead') {
      return true;
    }
  }

  const { count } = await supabaseAdmin
    .from('clubs')
    .select('id', { count: 'exact', head: true })
    .eq('organizer_id', userId)
    .eq('is_active', true);

  return (count ?? 0) > 0;
}

/** Promote an active club organizer from student → club_organizer after first event create. */
export async function promoteClubOrganizerIfNeeded(userId: string, role: string | undefined) {
  if (role !== 'student') return;

  const { count } = await supabaseAdmin
    .from('clubs')
    .select('id', { count: 'exact', head: true })
    .eq('organizer_id', userId)
    .eq('is_active', true);

  if ((count ?? 0) === 0) return;

  await supabaseAdmin
    .from('users')
    .update({ role: 'club_organizer' })
    .eq('id', userId)
    .eq('role', 'student');
}
