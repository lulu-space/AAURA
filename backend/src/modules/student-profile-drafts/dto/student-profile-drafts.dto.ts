import { z } from 'zod';

const draftBody = z.object({
  profile_text: z.string().optional(),
  traits: z.record(z.string(), z.unknown()).default({}),
  confidence: z.number().min(0).max(100).default(0),
  source: z.string().default('manual')
});

export const createStudentProfileDraftSchema = z.object({
  body: draftBody,
  params: z.object({}).default({}),
  query: z.object({}).default({})
});

export const updateStudentProfileDraftSchema = z.object({
  body: draftBody.partial(),
  params: z.object({ id: z.string().uuid() }),
  query: z.object({}).default({})
});

