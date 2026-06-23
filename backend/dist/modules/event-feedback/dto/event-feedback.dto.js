import { z } from 'zod';
const feedbackBody = z.object({
    event_id: z.string().uuid(),
    rating: z.number().int().min(1).max(5),
    comment: z.string().optional()
});
export const createEventFeedbackSchema = z.object({
    body: feedbackBody,
    params: z.object({}).default({}),
    query: z.object({}).default({})
});
export const updateEventFeedbackSchema = z.object({
    body: feedbackBody.partial(),
    params: z.object({ id: z.string().uuid() }),
    query: z.object({}).default({})
});
