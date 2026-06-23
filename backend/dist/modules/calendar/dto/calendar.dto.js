import { z } from 'zod';
const calendarBody = z.object({
    title: z.string().min(2),
    item_type: z.enum(['event', 'study', 'reminder']),
    starts_at: z.string().datetime(),
    ends_at: z.string().datetime().optional(),
    reference_id: z.string().uuid().optional()
});
export const createCalendarSchema = z.object({
    body: calendarBody,
    params: z.object({}).default({}),
    query: z.object({}).default({})
});
export const updateCalendarSchema = z.object({
    body: calendarBody.partial(),
    params: z.object({ id: z.string().uuid() }),
    query: z.object({}).default({})
});
