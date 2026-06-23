import { z } from 'zod';

const studySessionBody = z.object({
  title: z.string().min(3),
  topic: z.string().optional(),
  location: z.string().optional(),
  starts_at: z.string().datetime(),
  ends_at: z.string().datetime(),
  capacity: z.number().int().positive()
});

export const createStudySessionSchema = z.object({
  body: studySessionBody,
  params: z.object({}).default({}),
  query: z.object({}).default({})
});

export const updateStudySessionSchema = z.object({
  body: studySessionBody.partial(),
  params: z.object({ id: z.string().uuid() }),
  query: z.object({}).default({})
});
