import { z } from 'zod';

const engagementBody = z.object({
  event_id: z.string().uuid().optional(),
  metric_type: z.enum(['view', 'click', 'join', 'complete']),
  value: z.number().default(1),
  metadata: z.record(z.string(), z.unknown()).default({})
});

export const createEngagementMetricSchema = z.object({
  body: engagementBody,
  params: z.object({}).default({}),
  query: z.object({}).default({})
});

export const updateEngagementMetricSchema = z.object({
  body: engagementBody.partial(),
  params: z.object({ id: z.string().uuid() }),
  query: z.object({}).default({})
});

