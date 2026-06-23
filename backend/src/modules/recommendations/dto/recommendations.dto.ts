import { z } from 'zod';

const recommendationBody = z.object({
  user_id: z.string().uuid().optional(),
  source: z.enum(['rule_based', 'ai']),
  recommendation_type: z.enum(['event', 'club', 'study', 'volunteer']),
  target_id: z.string().uuid().optional(),
  reason: z.string().optional(),
  score: z.number().optional(),
  metadata: z.record(z.string(), z.unknown()).optional()
});

export const createRecommendationSchema = z.object({
  body: recommendationBody,
  params: z.object({}).default({}),
  query: z.object({}).default({})
});

export const updateRecommendationSchema = z.object({
  body: recommendationBody.partial(),
  params: z.object({ id: z.string().uuid() }),
  query: z.object({}).default({})
});
