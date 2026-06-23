import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
const INACTIVE_DAYS = 60;
export class ClubsWorkflowService {
    /**
     * Marks clubs with no activity for INACTIVE_DAYS as inactive and notifies organizers.
     * Frontend should gray out clubs where is_active = false.
     */
    async detectInactiveClubs() {
        const cutoff = new Date();
        cutoff.setDate(cutoff.getDate() - INACTIVE_DAYS);
        const cutoffIso = cutoff.toISOString();
        const { data: staleClubs, error } = await supabaseAdmin
            .from('clubs')
            .select('id, name, organizer_id, last_activity_at, is_active')
            .eq('is_active', true)
            .lt('last_activity_at', cutoffIso);
        if (error)
            throw new ApiError(500, 'Failed to scan clubs.', error);
        const results = [];
        for (const club of staleClubs ?? []) {
            const { error: updateError } = await supabaseAdmin
                .from('clubs')
                .update({ is_active: false, inactive_notified_at: new Date().toISOString() })
                .eq('id', club.id);
            if (updateError)
                continue;
            if (club.organizer_id) {
                await supabaseAdmin.from('notifications').insert({
                    user_id: club.organizer_id,
                    title: 'Club marked inactive',
                    body: `"${club.name}" has been inactive for ${INACTIVE_DAYS}+ days. Update activities to reactivate.`,
                    notification_type: 'system',
                    payload: { club_id: club.id, reason: 'dead_club_detection' }
                });
            }
            results.push({ club_id: club.id, name: club.name, notified: !!club.organizer_id });
        }
        return {
            scanned_cutoff: cutoffIso,
            inactive_days_threshold: INACTIVE_DAYS,
            deactivated_count: results.length,
            clubs: results
        };
    }
    async reactivateClub(clubId, organizerId, actorRole) {
        const { data: club, error } = await supabaseAdmin
            .from('clubs')
            .select('id, organizer_id')
            .eq('id', clubId)
            .single();
        if (error || !club)
            throw new ApiError(404, 'Club not found.', error);
        if (actorRole !== 'admin' && club.organizer_id !== organizerId) {
            throw new ApiError(403, 'Forbidden.');
        }
        const { data: updated, error: updateError } = await supabaseAdmin
            .from('clubs')
            .update({
            is_active: true,
            last_activity_at: new Date().toISOString(),
            inactive_notified_at: null
        })
            .eq('id', clubId)
            .select('*')
            .single();
        if (updateError)
            throw new ApiError(500, 'Failed to reactivate club.', updateError);
        return updated;
    }
    /** Monthly activity report for club organizers (student + club lead). */
    async getMonthlyReport(organizerId, year, month) {
        const start = new Date(Date.UTC(year, month - 1, 1));
        const end = new Date(Date.UTC(year, month, 1));
        const { data: clubs, error: clubsError } = await supabaseAdmin
            .from('clubs')
            .select('id, name, is_active, last_activity_at')
            .eq('organizer_id', organizerId);
        if (clubsError)
            throw new ApiError(500, 'Failed to load clubs.', clubsError);
        const clubIds = (clubs ?? []).map((c) => c.id);
        const { data: events, error: eventsError } = await supabaseAdmin
            .from('events')
            .select('id, title, starts_at, status, ai_success_score, capacity')
            .eq('organizer_id', organizerId)
            .gte('starts_at', start.toISOString())
            .lt('starts_at', end.toISOString());
        if (eventsError)
            throw new ApiError(500, 'Failed to load events.', eventsError);
        let newMembers = 0;
        if (clubIds.length > 0) {
            const { count } = await supabaseAdmin
                .from('club_membership')
                .select('id', { count: 'exact', head: true })
                .in('club_id', clubIds)
                .gte('joined_at', start.toISOString())
                .lt('joined_at', end.toISOString());
            newMembers = count ?? 0;
        }
        const eventIds = (events ?? []).map((e) => e.id);
        let reservations = 0;
        if (eventIds.length > 0) {
            const { count } = await supabaseAdmin
                .from('event_reservation')
                .select('id', { count: 'exact', head: true })
                .in('event_id', eventIds)
                .neq('reservation_status', 'cancelled');
            reservations = count ?? 0;
        }
        return {
            period: { year, month, from: start.toISOString(), to: end.toISOString() },
            clubs: {
                total: clubs?.length ?? 0,
                active: clubs?.filter((c) => c.is_active).length ?? 0,
                inactive: clubs?.filter((c) => !c.is_active).length ?? 0,
                items: clubs ?? []
            },
            events: {
                total: events?.length ?? 0,
                items: events ?? []
            },
            engagement: {
                new_club_members: newMembers,
                event_reservations: reservations
            }
        };
    }
    async touchClubActivity(clubId) {
        await supabaseAdmin
            .from('clubs')
            .update({ last_activity_at: new Date().toISOString(), is_active: true })
            .eq('id', clubId);
    }
    /** Clubs with real member counts + next upcoming event, for list views. */
    async listWithCounts() {
        const { data: clubs, error } = await supabaseAdmin
            .from('clubs')
            .select('*')
            .order('name', { ascending: true });
        if (error)
            throw new ApiError(500, 'Failed to fetch clubs.', error);
        if (!clubs || clubs.length === 0)
            return [];
        const clubIds = clubs.map((c) => c.id);
        const { data: memberships } = await supabaseAdmin
            .from('club_membership')
            .select('club_id')
            .in('club_id', clubIds);
        const counts = new Map();
        for (const row of memberships ?? []) {
            const id = row.club_id;
            counts.set(id, (counts.get(id) ?? 0) + 1);
        }
        const nowIso = new Date().toISOString();
        const { data: upcoming } = await supabaseAdmin
            .from('events')
            .select('club_id, title, starts_at')
            .in('club_id', clubIds)
            .gte('starts_at', nowIso)
            .order('starts_at', { ascending: true });
        const nextEventByClub = new Map();
        for (const ev of upcoming ?? []) {
            const id = ev.club_id;
            if (id && !nextEventByClub.has(id)) {
                nextEventByClub.set(id, ev.title);
            }
        }
        return clubs.map((club) => ({
            ...club,
            member_count: counts.get(club.id) ?? 0,
            next_event: nextEventByClub.get(club.id) ?? null
        }));
    }
    async listMembers(clubId, userId) {
        const { data: membership, error: memberError } = await supabaseAdmin
            .from('club_membership')
            .select('id')
            .eq('club_id', clubId)
            .eq('user_id', userId)
            .maybeSingle();
        if (memberError)
            throw new ApiError(500, 'Failed to verify club membership.', memberError);
        if (!membership)
            throw new ApiError(403, 'Join the club to view members.');
        const { data, error } = await supabaseAdmin
            .from('club_membership')
            .select('role, joined_at, users(full_name)')
            .eq('club_id', clubId)
            .order('role', { ascending: true })
            .order('joined_at', { ascending: true });
        if (error)
            throw new ApiError(500, 'Failed to fetch club members.', error);
        return data;
    }
    /** Activity posts from clubs the user joined, or recent global posts when none joined. */
    async listActivityFeed(userId, limit = 20) {
        const { data: memberships, error: membershipError } = await supabaseAdmin
            .from('club_membership')
            .select('club_id')
            .eq('user_id', userId);
        if (membershipError) {
            throw new ApiError(500, 'Failed to load club memberships.', membershipError);
        }
        const clubIds = (memberships ?? []).map((row) => row.club_id);
        let query = supabaseAdmin
            .from('club_activity_posts')
            .select('*, clubs(name)')
            .order('created_at', { ascending: false })
            .limit(limit);
        if (clubIds.length > 0) {
            query = query.in('club_id', clubIds);
        }
        const { data, error } = await query;
        if (error)
            throw new ApiError(500, 'Failed to fetch club activity feed.', error);
        return data;
    }
}
export const clubsWorkflowService = new ClubsWorkflowService();
