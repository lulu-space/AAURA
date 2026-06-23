import { z } from 'zod';
const profileBody = z.object({
    profile_summary: z.string().optional(),
    strengths: z.array(z.unknown()).default([]),
    goals: z.array(z.unknown()).default([]),
    interests: z.array(z.unknown()).default([]),
    confidence: z.number().min(0).max(100).default(0),
    last_ai_refresh_at: z.string().datetime().optional()
});
export const createStudentProfileSchema = z.object({
    body: profileBody,
    params: z.object({}).default({}),
    query: z.object({}).default({})
});
export const updateStudentProfileSchema = z.object({
    body: profileBody.partial(),
    params: z.object({ id: z.string().uuid() }),
    query: z.object({}).default({})
});
