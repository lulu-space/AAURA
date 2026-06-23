import { z } from 'zod';

const membershipBody = z.object({
  club_id: z.string().uuid(),
  role: z.enum(['member', 'lead']).default('member'),
  joined_at: z.string().datetime().optional()
});

export const createClubMembershipSchema = z.object({
  body: membershipBody,
  params: z.object({}).default({}),
  query: z.object({}).default({})
});

export const updateClubMembershipSchema = z.object({
  body: membershipBody.partial(),
  params: z.object({ id: z.string().uuid() }),
  query: z.object({}).default({})
});

