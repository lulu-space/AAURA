import { z } from 'zod';
const gamificationBody = z.object({
    user_id: z.string().uuid().optional(),
    points: z.number().int().nonnegative().optional(),
    level: z.number().int().positive().optional(),
    badges: z.array(z.string()).optional(),
    streak_days: z.number().int().nonnegative().optional()
});
export const createGamificationSchema = z.object({
    body: gamificationBody,
    params: z.object({}).default({}),
    query: z.object({}).default({})
});
export const updateGamificationSchema = z.object({
    body: gamificationBody.partial(),
    params: z.object({ id: z.string().uuid() }),
    query: z.object({}).default({})
});
