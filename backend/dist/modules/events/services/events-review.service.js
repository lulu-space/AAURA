import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
import { countCrossOrganizerDuplicates } from '../../../shared/utils/event-duplicate.js';
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
function isStudentOrganizer(row) {
    const organizer = row.organizer;
    const role = organizer?.role;
    return role === 'club_organizer' || role === 'student';
}
export class EventsReviewService {
    async listAll() {
        const { data, error } = await supabaseAdmin
            .from('events')
            .select(EVENT_SELECT)
            .order('created_at', { ascending: false });
        if (error)
            throw new ApiError(500, 'Failed to load event reviews.', error);
        const rows = (data ?? [])
            .filter(isStudentOrganizer)
            .map(mapEventRow);
        return this.enrichWithDuplicateFlags(rows);
    }
    async listPending() {
        const all = await this.listAll();
        return all.filter((row) => row.is_approved === false && row.status !== 'cancelled');
    }
    async enrichWithDuplicateFlags(rows) {
        const { data: eventIndex, error } = await supabaseAdmin
            .from('events')
            .select('id, title, starts_at, organizer_id, status')
            .neq('status', 'cancelled');
        if (error)
            return rows;
        const indexRows = (eventIndex ?? []);
        return rows.map((row) => {
            const duplicateMatches = countCrossOrganizerDuplicates(indexRows, {
                id: row.id,
                title: String(row.title ?? ''),
                starts_at: String(row.starts_at ?? ''),
                organizer_id: String(row.organizer_id ?? '')
            });
            return mapEventRow({
                ...row,
                possible_duplicate: duplicateMatches > 0,
                duplicate_match_count: duplicateMatches
            });
        });
    }
    async loadReviewTarget(eventId) {
        const { data, error } = await supabaseAdmin
            .from('events')
            .select(EVENT_SELECT)
            .eq('id', eventId)
            .single();
        if (error || !data) {
            throw new ApiError(404, 'Event not found.', error);
        }
        const row = data;
        if (!isStudentOrganizer(row)) {
            throw new ApiError(400, 'Only student-submitted events can be reviewed.');
        }
        return row;
    }
    async approve(eventId, reviewerId, approvalNote) {
        const existing = await this.loadReviewTarget(eventId);
        if (existing.is_approved === true && existing.status === 'published') {
            throw new ApiError(400, 'Event is already approved.');
        }
        const { data, error } = await supabaseAdmin
            .from('events')
            .update({
            is_approved: true,
            status: 'published',
            approval_note: approvalNote ?? null,
            reviewed_by: reviewerId,
            reviewed_at: new Date().toISOString()
        })
            .eq('id', eventId)
            .select(EVENT_SELECT)
            .single();
        if (error)
            throw new ApiError(500, 'Failed to approve event.', error);
        if (existing.organizer_id) {
            await supabaseAdmin.from('notifications').insert({
                user_id: existing.organizer_id,
                title: 'Event approved',
                body: `Your event "${existing.title}" is now live on campus.`,
                notification_type: 'system',
                payload: { event_id: eventId }
            });
        }
        return mapEventRow(data);
    }
    async reject(eventId, reviewerId, approvalNote) {
        const existing = await this.loadReviewTarget(eventId);
        if (existing.status === 'cancelled' && existing.is_approved === false) {
            throw new ApiError(400, 'Event is already rejected.');
        }
        const { data, error } = await supabaseAdmin
            .from('events')
            .update({
            is_approved: false,
            status: 'cancelled',
            approval_note: approvalNote ?? null,
            reviewed_by: reviewerId,
            reviewed_at: new Date().toISOString()
        })
            .eq('id', eventId)
            .select(EVENT_SELECT)
            .single();
        if (error)
            throw new ApiError(500, 'Failed to reject event.', error);
        if (existing.organizer_id) {
            await supabaseAdmin.from('notifications').insert({
                user_id: existing.organizer_id,
                title: 'Event declined',
                body: approvalNote?.trim()
                    ? `Your event "${existing.title}" was declined: ${approvalNote.trim()}`
                    : `Your event "${existing.title}" was declined by Student Affairs.`,
                notification_type: 'system',
                payload: { event_id: eventId }
            });
        }
        return mapEventRow(data);
    }
    async withdraw(eventId, reviewerId, approvalNote) {
        const existing = await this.loadReviewTarget(eventId);
        if (existing.is_approved !== true) {
            throw new ApiError(400, 'Only approved events can be withdrawn.');
        }
        const { data, error } = await supabaseAdmin
            .from('events')
            .update({
            is_approved: false,
            status: 'draft',
            approval_note: approvalNote ?? null,
            reviewed_by: reviewerId,
            reviewed_at: new Date().toISOString()
        })
            .eq('id', eventId)
            .select(EVENT_SELECT)
            .single();
        if (error)
            throw new ApiError(500, 'Failed to withdraw event approval.', error);
        if (existing.organizer_id) {
            await supabaseAdmin.from('notifications').insert({
                user_id: existing.organizer_id,
                title: 'Event approval withdrawn',
                body: approvalNote?.trim()
                    ? `Approval for "${existing.title}" was withdrawn: ${approvalNote.trim()}`
                    : `Approval for "${existing.title}" was withdrawn by Student Affairs.`,
                notification_type: 'system',
                payload: { event_id: eventId }
            });
        }
        return mapEventRow(data);
    }
}
export const eventsReviewService = new EventsReviewService();
