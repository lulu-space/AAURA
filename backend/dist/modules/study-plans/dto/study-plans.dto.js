import { z } from 'zod';
const studyPlanBody = z.object({
    title: z.string().min(3),
    goals: z.array(z.unknown()).default([]),
    schedule: z.array(z.unknown()).default([]),
    source: z.enum(['manual', 'ai']).default('manual')
});
export const createStudyPlanSchema = z.object({
    body: studyPlanBody,
    params: z.object({}).default({}),
    query: z.object({}).default({})
});
export const updateStudyPlanSchema = z.object({
    body: studyPlanBody.partial(),
    params: z.object({ id: z.string().uuid() }),
    query: z.object({}).default({})
});
