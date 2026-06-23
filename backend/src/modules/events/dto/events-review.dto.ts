import { z } from 'zod';

export const reviewEventSchema = z.object({
  body: z.object({
    approval_note: z.string().max(2000).optional()
  }),
  params: z.object({ id: z.string().uuid() }),
  query: z.object({}).default({})
});
