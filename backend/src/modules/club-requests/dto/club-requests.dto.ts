import { z } from 'zod';

export const createClubRequestSchema = z.object({
  body: z.object({
    proposed_name: z.string().min(3).max(120),
    description: z.string().min(50).max(2000),
    category: z.string().max(60).optional(),
    advisor_email: z.string().email().max(254),
    co_founder_names: z
      .preprocess(
        (value) => {
          if (!Array.isArray(value)) return [];
          return value
            .map((name) => String(name).trim())
            .filter((name) => name.length >= 2);
        },
        z.array(z.string().max(80)).max(10)
      )
      .optional()
      .default([])
  }),
  params: z.object({}).default({}),
  query: z.object({}).default({})
});

export const reviewClubRequestSchema = z.object({
  body: z.object({
    review_note: z.string().max(2000).optional()
  }),
  params: z.object({ id: z.string().uuid() }),
  query: z.object({}).default({})
});

export type CreateClubRequestDto = z.infer<typeof createClubRequestSchema>['body'];
