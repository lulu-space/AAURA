import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
import type { CrudCreateDto } from '../../../shared/interfaces/crud.types.js';
import {
  assertNoScopedEventDuplicate,
  findCrossOrganizerEventDuplicates
} from '../../../shared/utils/event-duplicate.js';
import { majorsForFaculty } from '../../../shared/utils/faculty-scope.js';
import { syncVolunteerOpportunityFromEvent } from '../../volunteering-opportunities/services/volunteer-opportunity-sync.service.js';
import { isEventVisibleToUser } from '../../../shared/utils/content-visibility.js';
import {
  promoteClubOrganizerIfNeeded,
  userCanManageEvents
} from '../utils/event-manager-access.js';

const AUTO_APPROVE_ROLES = new Set(['student_affairs', 'dean_of_faculty', 'admin']);

const EVENT_SELECT =
  '*, organizer:users!events_organizer_id_fkey(id, full_name, email, role)';

function organizerName(row: Record<string, unknown>): string {
  const organizer = row.organizer as Record<string, unknown> | null | undefined;
  const name = (organizer?.full_name as string | undefined)?.trim();
  if (name) return name;
  const email = (organizer?.email as string | undefined)?.trim();
  return email || 'Student organizer';
}

function mapEventRow(row: Record<string, unknown>) {
  return {
    ...row,
    organizer_name: organizerName(row),
    organizer_role: (row.organizer as Record<string, unknown> | undefined)?.role ?? null
  };
}

export class EventsMutationService {
  async listForUser(userId: string, role?: string) {
    const { data, error } = await supabaseAdmin
      .from('events')
      .select(EVENT_SELECT)
      .order('starts_at', { ascending: true });

    if (error) throw new ApiError(500, 'Failed to fetch events.', error);

    const rows = (data ?? []) as Record<string, unknown>[];
    const filtered = rows.filter((row) => {
      if (!isEventVisibleToUser(row, userId, role)) return false;
      if (role && AUTO_APPROVE_ROLES.has(role)) return true;
      if (row.organizer_id === userId) return true;
      const organizer = row.organizer as Record<string, unknown> | null | undefined;
      if (
        organizer?.role === 'dean_of_faculty' &&
        row.is_approved === true &&
        row.status === 'published'
      ) {
        return true;
      }
      return row.is_approved === true && row.status === 'published';
    });

    return filtered.map(mapEventRow);
  }

  async getByIdForUser(id: string, userId: string, role?: string) {
    const { data, error } = await supabaseAdmin
      .from('events')
      .select(EVENT_SELECT)
      .eq('id', id)
      .single();

    if (error || !data) {
      throw new ApiError(404, 'Event not found.', error);
    }

    const row = data as Record<string, unknown>;
    if (!isEventVisibleToUser(row, userId, role)) {
      throw new ApiError(404, 'Event not found.');
    }

    return mapEventRow(row);
  }

  async create(userId: string, role: string | undefined, payload: CrudCreateDto) {
    const clubId = (payload.club_id as string | null | undefined) ?? null;
    const canManage = await userCanManageEvents(userId, role, clubId);
    if (!canManage) {
      throw new ApiError(
        403,
        'Only club organizers and campus event managers can publish events.'
      );
    }

    const autoApprove = !!role && AUTO_APPROVE_ROLES.has(role);
    const startsAt = String(payload.starts_at ?? '');

    if (!autoApprove && startsAt) {
      await assertNoScopedEventDuplicate({
        organizerId: userId,
        title: String(payload.title ?? ''),
        startsAt,
        clubId
      });
    }

    const dataToInsert = await this.buildCreatePayload(userId, role, payload, autoApprove);

    const { data, error } = await supabaseAdmin
      .from('events')
      .insert(dataToInsert)
      .select(EVENT_SELECT)
      .single();

    if (error) throw new ApiError(500, 'Failed to create event.', error);
    await promoteClubOrganizerIfNeeded(userId, role).catch(() => undefined);
    const mapped = mapEventRow(data as Record<string, unknown>);
    await syncVolunteerOpportunityFromEvent(
      data as Record<string, unknown>,
      userId
    ).catch(() => undefined);
    return mapped;
  }

  async update(
    id: string,
    userId: string,
    role: string | undefined,
    payload: CrudCreateDto
  ) {
    const { data: existing, error: fetchError } = await supabaseAdmin
      .from('events')
      .select('id, organizer_id, club_id, title, starts_at')
      .eq('id', id)
      .single();

    if (fetchError || !existing) {
      throw new ApiError(404, 'Event not found.', fetchError);
    }

    if (role !== 'admin' && existing.organizer_id !== userId) {
      throw new ApiError(403, 'Forbidden.');
    }

    const autoApprove = !!role && AUTO_APPROVE_ROLES.has(role);
    const title = String(payload.title ?? existing.title ?? '');
    const startsAt = String(payload.starts_at ?? existing.starts_at ?? '');
    const clubId =
      (payload.club_id as string | null | undefined) ??
      (existing.club_id as string | null | undefined) ??
      null;

    if (!autoApprove && startsAt) {
      await assertNoScopedEventDuplicate({
        organizerId: existing.organizer_id as string,
        title,
        startsAt,
        clubId,
        excludeEventId: id
      });
    }

    const { data, error } = await supabaseAdmin
      .from('events')
      .update(payload)
      .eq('id', id)
      .select(EVENT_SELECT)
      .single();

    if (error) throw new ApiError(500, 'Failed to update event.', error);
    const mapped = mapEventRow(data as Record<string, unknown>);
    await syncVolunteerOpportunityFromEvent(
      data as Record<string, unknown>,
      existing.organizer_id as string
    ).catch(() => undefined);
    return mapped;
  }

  private async buildCreatePayload(
    userId: string,
    role: string | undefined,
    payload: CrudCreateDto,
    autoApprove: boolean
  ) {
    let enriched: CrudCreateDto = { ...payload };

    if (role === 'dean_of_faculty') {
      const { data: deanUser } = await supabaseAdmin
        .from('users')
        .select('assigned_faculty')
        .eq('id', userId)
        .single();

      const faculty = (deanUser?.assigned_faculty as string | null)?.trim();
      const targets = enriched.target_majors;
      if (faculty && (!Array.isArray(targets) || targets.length === 0)) {
        enriched = { ...enriched, target_majors: majorsForFaculty(faculty) };
      }
    }

    return {
      ...enriched,
      organizer_id: enriched.organizer_id ?? userId,
      is_approved: autoApprove,
      status: autoApprove ? (enriched.status ?? 'published') : 'draft'
    };
  }
}

export const eventsMutationService = new EventsMutationService();
