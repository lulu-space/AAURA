import { z } from 'zod';

const eventBody = z.object({
  title: z.string().min(3),
  description: z.string().optional(),
  what_to_expect: z.string().optional(),
  location: z.string().optional(),
  starts_at: z.string().datetime(),
  ends_at: z.string().datetime(),
  capacity: z.number().int().positive(),
  status: z.enum(['draft', 'published', 'completed', 'cancelled']).default('draft'),
  is_approved: z.boolean().optional(),
  ai_success_score: z.number().optional(),
  ai_engagement_score: z.number().optional(),
  category: z.enum(['learn', 'serve', 'connect', 'explore']).optional(),
  reward_points: z.number().int().min(0).max(1000).optional(),
  format: z.string().optional(),
  promotion_level: z.number().int().min(1).max(5).optional(),
  tags: z.array(z.string()).optional(),
  target_majors: z.array(z.string()).optional(),
  target_years: z.array(z.string()).optional(),
  target_interests: z.array(z.string()).optional(),
  club_id: z.string().uuid().nullable().optional(),
  volunteer_hours: z.number().nonnegative().optional()
});

export const createEventSchema = z.object({
  body: eventBody,
  params: z.object({}).default({}),
  query: z.object({}).default({})
});

export const updateEventSchema = z.object({
  body: eventBody.partial(),
  params: z.object({ id: z.string().uuid() }),
  query: z.object({}).default({})
});
