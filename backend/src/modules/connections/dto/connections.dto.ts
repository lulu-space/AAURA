import { z } from 'zod';

export const connectSchema = z.object({
  body: z.object({ user_id: z.string().uuid() }),
  params: z.object({}).default({}),
  query: z.object({}).default({})
});

export const disconnectParamsSchema = z.object({
  body: z.object({}).default({}),
  params: z.object({ userId: z.string().uuid() }),
  query: z.object({}).default({})
});
