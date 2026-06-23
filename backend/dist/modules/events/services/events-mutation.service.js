import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
import { EVENT_MANAGER_ROLES } from '../../../shared/constants/roles.js';
import { assertNoScopedEventDuplicate } from '../../../shared/utils/event-duplicate.js';
import { majorsForFaculty } from '../../../shared/utils/faculty-scope.js';
const AUTO_APPROVE_ROLES = new Set(['student_affairs', 'dean_of_faculty', 'admin']);
const EVENT_SELECT = '*, organizer:users!events_organizer_id_fkey(id, full_name, email, role)';
function organizerName(row) {
    const organizer = row.organizer;
    const name = organizer?.full_name?.trim();
    if (name)
        return name;
    const email = organizer?.email?.trim();
    return email || 'Student organizer';
}
function mapEventRow(row) {
    return {
        ...row,
        organizer_name: organizerName(row),
        organizer_role: row.organizer?.role ?? null
    };
}
export class EventsMutationService {
    async listForUser(userId, role) {
        const { data, error } = await supabaseAdmin
            .from('events')
            .select(EVENT_SELECT)
            .order('starts_at', { ascending: true });
        if (error)
            throw new ApiError(500, 'Failed to fetch events.', error);
        const rows = (data ?? []);
        const filtered = rows.filter((row) => {
            if (role && AUTO_APPROVE_ROLES.has(role))
                return true;
            if (row.organizer_id === userId)
                return true;
            return row.is_approved === true && row.status === 'published';
        });
        return filtered.map(mapEventRow);
    }
    async create(userId, role, payload) {
        if (!role || !EVENT_MANAGER_ROLES.includes(role)) {
            throw new ApiError(403, 'Forbidden.');
        }
        const autoApprove = !!role && AUTO_APPROVE_ROLES.has(role);
        const startsAt = String(payload.starts_at ?? '');
        const clubId = payload.club_id ?? null;
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
        if (error)
            throw new ApiError(500, 'Failed to create event.', error);
        return mapEventRow(data);
    }
    async update(id, userId, role, payload) {
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
        const clubId = payload.club_id ??
            existing.club_id ??
            null;
        if (!autoApprove && startsAt) {
            await assertNoScopedEventDuplicate({
                organizerId: existing.organizer_id,
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
        if (error)
            throw new ApiError(500, 'Failed to update event.', error);
        return mapEventRow(data);
    }
    async buildCreatePayload(userId, role, payload, autoApprove) {
        let enriched = { ...payload };
        if (role === 'dean_of_faculty') {
            const { data: deanUser } = await supabaseAdmin
                .from('users')
                .select('assigned_faculty')
                .eq('id', userId)
                .single();
            const faculty = deanUser?.assigned_faculty?.trim();
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
