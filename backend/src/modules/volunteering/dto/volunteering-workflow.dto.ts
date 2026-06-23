import { z } from 'zod';

export const staffActionSchema = z.object({
  body: z.object({ approval_note: z.string().optional() }),
  params: z.object({ id: z.string().uuid() }),
  query: z.object({}).default({})
});
