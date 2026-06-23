import { randomUUID } from 'node:crypto';
import { supabaseAdmin } from '../../../config/supabase.js';

type EventRow = Record<string, unknown>;

export async function syncVolunteerOpportunityFromEvent(
  event: EventRow,
  organizerId: string
): Promise<void> {
  const eventId = event.id as string | undefined;
  if (!eventId) return;

  const category = String(event.category ?? '');
  const volunteerHours = Number(event.volunteer_hours ?? 0);
  const isPublished =
    event.status === 'published' && event.is_approved !== false;

  const { data: existing } = await supabaseAdmin
    .from('volunteering_opportunities')
    .select('id, join_token')
    .eq('event_id', eventId)
    .maybeSingle();

  if (category !== 'serve' || volunteerHours <= 0 || !isPublished) {
    if (existing?.id) {
      await supabaseAdmin
        .from('volunteering_opportunities')
        .update({ status: 'closed' })
        .eq('id', existing.id as string);
    }
    return;
  }

  const payload = {
    title: String(event.title ?? 'Volunteer event'),
    description: String(event.description ?? ''),
    department: 'Campus events',
    estimated_hours: volunteerHours,
    slots: Math.max(1, Number(event.capacity ?? 50)),
    status: 'open' as const,
    event_id: eventId,
    starts_at: (event.starts_at as string | null) ?? null,
    ends_at: (event.ends_at as string | null) ?? null,
    created_by: organizerId,
    join_token: (existing?.join_token as string | undefined) ?? randomUUID()
  };

  if (existing?.id) {
    await supabaseAdmin
      .from('volunteering_opportunities')
      .update(payload)
      .eq('id', existing.id as string);
    return;
  }

  await supabaseAdmin.from('volunteering_opportunities').insert(payload);
}
