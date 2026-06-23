import { z } from 'zod';
export const provisionUserSchema = z.object({
    body: z.object({
        // Optional: when omitted, server derives from Auth user_metadata / email (see auth.service).
        fullName: z.string().min(3).optional(),
        universityId: z.string().min(3).optional(),
        major: z.string().min(2).optional(),
        department: z.string().min(2).optional(),
        academicYear: z.number().int().min(1).optional()
    }),
    params: z.object({}).default({}),
    query: z.object({}).default({})
});
