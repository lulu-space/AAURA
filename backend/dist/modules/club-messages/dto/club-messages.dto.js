import { z } from 'zod';
export const listClubMessagesSchema = z.object({
    body: z.object({}).default({}),
    params: z.object({}).default({}),
    query: z.object({
        club_id: z.string().uuid(),
        channel_id: z.string().min(1).optional()
    })
});
export const sendClubMessageSchema = z.object({
    body: z.object({
        club_id: z.string().uuid(),
        channel_id: z.string().min(1).optional(),
        body: z.string().min(1).max(2000)
    }),
    params: z.object({}).default({}),
    query: z.object({}).default({})
});
