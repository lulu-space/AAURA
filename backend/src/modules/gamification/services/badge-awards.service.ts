import { supabaseAdmin } from '../../../config/supabase.js';

const MAX_SKILL_PROGRESS = 0.9;

export async function syncEarnedBadges(userId: string): Promise<string[]> {
  const { data: gamification, error } = await supabaseAdmin
    .from('gamification')
    .select('id, points, badges')
    .eq('user_id', userId)
    .maybeSingle();

  if (error || !gamification) return [];

  const earned = new Set(
    ((gamification.badges as string[] | null) ?? []).map((badge) => badge.trim()).filter(Boolean)
  );
  const points = (gamification.points as number | null) ?? 0;

  if (points >= 2000) earned.add('b-top-contributor');

  const { data: volunteerRows } = await supabaseAdmin
    .from('volunteering_records')
    .select('hours')
    .eq('user_id', userId)
    .eq('status', 'approved');

  const volunteerHours = (volunteerRows ?? []).reduce(
    (sum, row) => sum + Number(row.hours ?? 0),
    0
  );
  if (volunteerHours >= 50) earned.add('b-volunteer-champion');

  const { data: profile } = await supabaseAdmin
    .from('student_profiles')
    .select('strengths')
    .eq('user_id', userId)
    .maybeSingle();

  const strengths = profile?.strengths;
  if (Array.isArray(strengths)) {
    for (const row of strengths) {
      if (typeof row !== 'object' || row == null) continue;
      const progress = Number((row as Record<string, unknown>).progress ?? 0);
      const normalized = progress > 1 ? progress / 100 : progress;
      if (normalized >= MAX_SKILL_PROGRESS) {
        earned.add('b-skill-builder');
        break;
      }
    }
  }

  const { data: ledClubs } = await supabaseAdmin
    .from('clubs')
    .select('id')
    .eq('organizer_id', userId)
    .eq('is_active', true)
    .limit(1);
  if ((ledClubs?.length ?? 0) > 0) earned.add('b-campus-leader');

  const { data: hostedSessions } = await supabaseAdmin
    .from('study_sessions')
    .select('id')
    .eq('host_id', userId)
    .limit(3);
  if ((hostedSessions?.length ?? 0) >= 2) earned.add('b-study-streak');

  const next = [...earned];
  const previous = (gamification.badges as string[] | null) ?? [];
  if (next.length !== previous.length || next.some((badge) => !previous.includes(badge))) {
    await supabaseAdmin
      .from('gamification')
      .update({ badges: next })
      .eq('id', gamification.id as string);
  }

  return next;
}
