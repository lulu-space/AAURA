import { z } from 'zod';

export const shamsChatSchema = z.object({
  body: z.object({
    message: z.string().min(1).max(4000)
  }),
  params: z.object({}).default({}),
  query: z.object({}).default({})
});
