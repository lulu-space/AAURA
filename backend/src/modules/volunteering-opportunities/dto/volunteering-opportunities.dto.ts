import { z } from 'zod';

const opportunityBody = z.object({
  title: z.string().min(3),
  description: z.string().optional(),
  department: z.string().optional(),
  estimated_hours: z.number().nonnegative(),
  slots: z.number().int().positive().default(1),
  status: z.enum(['open', 'closed']).default('open'),
  starts_at: z.string().datetime().optional(),
  ends_at: z.string().datetime().optional()
});

export const createVolunteeringOpportunitySchema = z.object({
  body: opportunityBody,
  params: z.object({}).default({}),
  query: z.object({}).default({})
});

export const updateVolunteeringOpportunitySchema = z.object({
  body: opportunityBody.partial(),
  params: z.object({ id: z.string().uuid() }),
  query: z.object({}).default({})
});
