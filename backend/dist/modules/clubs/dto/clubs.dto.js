import { z } from 'zod';
const clubBody = z.object({
    name: z.string().min(2),
    description: z.string().optional(),
    is_active: z.boolean().optional()
});
export const createClubSchema = z.object({
    body: clubBody,
    params: z.object({}).default({}),
    query: z.object({}).default({})
});
export const updateClubSchema = z.object({
    body: clubBody.partial(),
    params: z.object({ id: z.string().uuid() }),
    query: z.object({}).default({})
});
