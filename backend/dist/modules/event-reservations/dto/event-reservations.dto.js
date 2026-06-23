import { z } from 'zod';
const reservationBody = z.object({
    event_id: z.string().uuid(),
    reservation_status: z.enum(['reserved', 'checked_in', 'cancelled']).default('reserved'),
    qr_token: z.string().optional(),
    reserved_at: z.string().datetime().optional(),
    checked_in_at: z.string().datetime().optional()
});
export const createEventReservationSchema = z.object({
    body: reservationBody,
    params: z.object({}).default({}),
    query: z.object({}).default({})
});
export const updateEventReservationSchema = z.object({
    body: reservationBody.partial(),
    params: z.object({ id: z.string().uuid() }),
    query: z.object({}).default({})
});
