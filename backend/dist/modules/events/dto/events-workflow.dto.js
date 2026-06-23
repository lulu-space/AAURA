import { z } from 'zod';
export const predictSuccessSchema = z.object({
    body: z
        .object({
        student_major: z.string().min(2).optional(),
        event_type: z.string().min(2).optional(),
        department: z.string().min(2).optional(),
        organizer_type: z
            .enum(['club_student', 'club_event', 'student_affairs', 'dean_of_faculty'])
            .optional(),
        expected_attendance: z.number().int().positive().optional(),
        interest_match_score: z.number().min(0).max(1).optional(),
        skill_match_score: z.number().min(0).max(1).optional(),
        target_major_count: z.number().int().min(0).optional(),
        target_interest_count: z.number().int().min(0).optional()
    })
        .default({}),
    params: z.object({ id: z.string().uuid() }),
    query: z.object({}).default({})
});
export const predictDraftSchema = z.object({
    body: z.object({
        title: z.string().min(2),
        description: z.string().optional(),
        category: z.string().optional(),
        format: z.string().optional(),
        capacity: z.number().int().positive(),
        promotion_level: z.number().int().min(1).max(5).optional(),
        target_majors: z.array(z.string()).default([]),
        target_interests: z.array(z.string()).default([]),
        target_skills: z.array(z.string()).default([]),
        tags: z.array(z.string()).default([]),
        club_id: z.string().uuid().nullable().optional(),
        department: z.string().optional()
    }),
    params: z.object({}).default({}),
    query: z.object({}).default({})
});
