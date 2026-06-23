import { z } from 'zod';

const volunteeringBody = z.object({
  title: z.string().min(3),
  hours: z.number().nonnegative(),
  occurred_at: z.string().datetime(),
  opportunity_id: z.string().uuid().optional(),
  status: z.enum(['pending', 'approved', 'rejected']).optional(),
  approved_by_staff_id: z.string().uuid().nullable().optional(),
  approval_note: z.string().optional()
});

export const createVolunteeringSchema = z.object({
  body: volunteeringBody.omit({ status: true, approved_by_staff_id: true, approval_note: true }),
  params: z.object({}).default({}),
  query: z.object({}).default({})
});

export const updateVolunteeringSchema = z.object({
  body: volunteeringBody.partial(),
  params: z.object({ id: z.string().uuid() }),
  query: z.object({}).default({})
});
