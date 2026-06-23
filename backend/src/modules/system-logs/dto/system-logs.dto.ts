import { z } from 'zod';

const systemLogBody = z.object({
  actor_user_id: z.string().uuid().optional(),
  action: z.string().min(2),
  resource: z.string().min(2),
  resource_id: z.string().uuid().optional(),
  metadata: z.record(z.string(), z.unknown()).optional(),
  severity: z.enum(['info', 'warn', 'error']).optional()
});

export const createSystemLogSchema = z.object({
  body: systemLogBody,
  params: z.object({}).default({}),
  query: z.object({}).default({})
});

export const updateSystemLogSchema = z.object({
  body: systemLogBody.partial(),
  params: z.object({ id: z.string().uuid() }),
  query: z.object({}).default({})
});
