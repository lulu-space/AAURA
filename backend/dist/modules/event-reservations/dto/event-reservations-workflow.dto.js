import { z } from 'zod';
export const reserveEventSchema = z.object({
    body: z.object({ event_id: z.string().uuid() }),
    params: z.object({}).default({}),
    query: z.object({}).default({})
});
export const checkInSchema = z.object({
    body: z.object({ qr_token: z.string().uuid() }),
    params: z.object({}).default({}),
    query: z.object({}).default({})
});
export const listEventAttendeesSchema = z.object({
    body: z.object({}).default({}),
    params: z.object({ eventId: z.string().uuid() }),
    query: z.object({}).default({})
});
