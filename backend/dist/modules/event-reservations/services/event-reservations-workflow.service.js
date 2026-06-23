import { randomUUID } from 'node:crypto';
import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
export class EventReservationsWorkflowService {
    async reserve(eventId, userId) {
        const { data: event, error: eventError } = await supabaseAdmin
            .from('events')
            .select('id, capacity, status, starts_at')
            .eq('id', eventId)
            .single();
        if (eventError || !event) {
            throw new ApiError(404, 'Event not found.', eventError);
        }
        if (event.status !== 'published') {
            throw new ApiError(400, 'Only published events can be reserved.');
        }
        const { count, error: countError } = await supabaseAdmin
            .from('event_reservation')
            .select('id', { count: 'exact', head: true })
            .eq('event_id', eventId)
            .neq('reservation_status', 'cancelled');
        if (countError) {
            throw new ApiError(500, 'Failed to check event capacity.', countError);
        }
        if ((count ?? 0) >= event.capacity) {
            throw new ApiError(409, 'Event is at full capacity.');
        }
        const { data, error } = await supabaseAdmin
            .from('event_reservation')
            .insert({
            event_id: eventId,
            user_id: userId,
            reservation_status: 'reserved',
            qr_token: randomUUID()
        })
            .select('*')
            .single();
        if (error) {
            if (error.code === '23505') {
                throw new ApiError(409, 'You already have a reservation for this event.');
            }
            throw new ApiError(500, 'Failed to create reservation.', error);
        }
        return data;
    }
    async checkInByQrToken(qrToken, actorUserId, actorRole) {
        const { data: reservation, error } = await supabaseAdmin
            .from('event_reservation')
            .select('*, events(organizer_id, title)')
            .eq('qr_token', qrToken)
            .single();
        if (error || !reservation) {
            throw new ApiError(404, 'Invalid QR token.', error);
        }
        const event = reservation.events;
        const isOrganizer = event?.organizer_id === actorUserId;
        const isAdmin = actorRole === 'admin';
        const isSelf = reservation.user_id === actorUserId;
        if (!isOrganizer && !isAdmin && !isSelf) {
            throw new ApiError(403, 'Not allowed to check in this reservation.');
        }
        if (reservation.reservation_status === 'checked_in') {
            throw new ApiError(409, 'Already checked in.');
        }
        if (reservation.reservation_status === 'cancelled') {
            throw new ApiError(400, 'Reservation was cancelled.');
        }
        const { data: updated, error: updateError } = await supabaseAdmin
            .from('event_reservation')
            .update({
            reservation_status: 'checked_in',
            checked_in_at: new Date().toISOString()
        })
            .eq('id', reservation.id)
            .select('*')
            .single();
        if (updateError) {
            throw new ApiError(500, 'Failed to check in.', updateError);
        }
        return { reservation: updated, eventTitle: event?.title ?? null };
    }
    async listMine(userId) {
        const { data, error } = await supabaseAdmin
            .from('event_reservation')
            .select('*, events(id, title, starts_at, location)')
            .eq('user_id', userId)
            .order('reserved_at', { ascending: false });
        if (error)
            throw new ApiError(500, 'Failed to fetch reservations.', error);
        return data;
    }
    async listEventAttendees(eventId, actorUserId, actorRole) {
        const { data: event, error: eventError } = await supabaseAdmin
            .from('events')
            .select('id, organizer_id')
            .eq('id', eventId)
            .single();
        if (eventError || !event) {
            throw new ApiError(404, 'Event not found.', eventError);
        }
        const isOrganizer = event.organizer_id === actorUserId;
        const isAdmin = actorRole === 'admin';
        if (!isOrganizer && !isAdmin) {
            const { data: mine, error: mineError } = await supabaseAdmin
                .from('event_reservation')
                .select('id')
                .eq('event_id', eventId)
                .eq('user_id', actorUserId)
                .neq('reservation_status', 'cancelled')
                .maybeSingle();
            if (mineError)
                throw new ApiError(500, 'Failed to verify enrollment.', mineError);
            if (!mine) {
                throw new ApiError(403, 'Enroll in this event to see who is attending.');
            }
        }
        const { data, error } = await supabaseAdmin
            .from('event_reservation')
            .select('id, reservation_status, checked_in_at, users(id, full_name, email, students(major, academic_year))')
            .eq('event_id', eventId)
            .neq('reservation_status', 'cancelled')
            .order('reserved_at', { ascending: true });
        if (error)
            throw new ApiError(500, 'Failed to fetch attendees.', error);
        return (data ?? []).map((row) => {
            const users = row.users;
            const student = Array.isArray(users?.students)
                ? users?.students[0]
                : users?.students;
            const email = users?.email ?? '';
            return {
                user_id: users?.id ?? null,
                full_name: users?.full_name?.trim() || email.split('@')[0] || 'Student',
                major: student?.major ?? null,
                academic_year: student?.academic_year ?? null,
                reservation_status: row.reservation_status,
                checked_in_at: row.checked_in_at
            };
        });
    }
}
export const eventReservationsWorkflowService = new EventReservationsWorkflowService();
