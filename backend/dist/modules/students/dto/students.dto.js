import { z } from 'zod';
const studentBody = z.object({
    university_id: z.string().min(3),
    major: z.string().min(2).optional(),
    department: z.string().min(2).optional(),
    academic_year: z.number().int().min(1).optional()
});
export const createStudentSchema = z.object({
    body: studentBody,
    params: z.object({}).default({}),
    query: z.object({}).default({})
});
export const updateStudentSchema = z.object({
    body: studentBody.partial(),
    params: z.object({ id: z.string().uuid() }),
    query: z.object({}).default({})
});
