import { ApiError } from '../../core/errors/api-error.js';
import { supabaseAdmin } from '../../config/supabase.js';
import { normalizeEventTitle } from './normalize-name.js';

function eventDayKey(startsAt: string): string {
  return startsAt.slice(0, 10);
}

export async function assertNoScopedEventDuplicate(input: {
  organizerId: string;
  title: string;
  startsAt: string;
  clubId?: string | null;
  excludeEventId?: string;
}) {
  const normalized = normalizeEventTitle(input.title);
  const day = eventDayKey(input.startsAt);

  let query = supabaseAdmin
    .from('events')
    .select('id, title, starts_at, status')
    .neq('status', 'cancelled');

  if (input.clubId) {
    query = query.eq('club_id', input.clubId);
  } else {
    query = query.eq('organizer_id', input.organizerId).is('club_id', null);
  }

  const { data, error } = await query;
  if (error) {
    throw new ApiError(500, 'Failed to check for duplicate events.', error);
  }

  const duplicate = (data ?? []).find((row) => {
    if (input.excludeEventId && row.id === input.excludeEventId) return false;
    const rowDay = String(row.starts_at ?? '').slice(0, 10);
    return normalizeEventTitle(String(row.title ?? '')) === normalized && rowDay === day;
  });

  if (duplicate) {
    throw new ApiError(
      409,
      input.clubId
        ? 'This club already has an event with this title on that date.'
        : 'You already have an event with this title on that date.'
    );
  }
}

/** Same title + day, different organizer — flag for affairs review. */
export async function findCrossOrganizerEventDuplicates(input: {
  title: string;
  startsAt: string;
  organizerId: string;
  excludeEventId?: string;
}) {
  const normalized = normalizeEventTitle(input.title);
  const day = eventDayKey(input.startsAt);

  const { data, error } = await supabaseAdmin
    .from('events')
    .select('id, title, starts_at, organizer_id, status')
    .neq('status', 'cancelled')
    .neq('organizer_id', input.organizerId);

  if (error) return [];

  return (data ?? []).filter((row) => {
    if (input.excludeEventId && row.id === input.excludeEventId) return false;
    const rowDay = String(row.starts_at ?? '').slice(0, 10);
    return normalizeEventTitle(String(row.title ?? '')) === normalized && rowDay === day;
  });
}

export function countCrossOrganizerDuplicates(
  rows: Array<{ id?: string; title?: string; starts_at?: string; organizer_id?: string }>,
  target: { id?: string; title: string; starts_at: string; organizer_id: string }
): number {
  const normalized = normalizeEventTitle(target.title);
  const day = eventDayKey(target.starts_at);
  return rows.filter((row) => {
    if (target.id && row.id === target.id) return false;
    if (row.organizer_id === target.organizer_id) return false;
    const rowDay = String(row.starts_at ?? '').slice(0, 10);
    return normalizeEventTitle(String(row.title ?? '')) === normalized && rowDay === day;
  }).length;
}
