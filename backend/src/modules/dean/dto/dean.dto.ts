import { z } from 'zod';

export const deanAnnouncementSchema = z.object({
  body: z.object({
    title: z.string().min(3).max(120),
    body: z.string().min(3).max(2000)
  }),
  params: z.object({}).default({}),
  query: z.object({}).default({})
});

export const deanReportParamsSchema = z.object({
  body: z.object({}).default({}),
  params: z.object({
    type: z.enum(['events', 'clubs', 'volunteering', 'engagement'])
  }),
  query: z.object({}).default({})
});
