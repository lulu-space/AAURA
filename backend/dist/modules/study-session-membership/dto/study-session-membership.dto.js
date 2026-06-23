import { z } from 'zod';
const membershipBody = z.object({
    study_session_id: z.string().uuid()
});
export const createStudySessionMembershipSchema = z.object({
    body: membershipBody,
    params: z.object({}).default({}),
    query: z.object({}).default({})
});
export const updateStudySessionMembershipSchema = z.object({
    body: membershipBody.partial(),
    params: z.object({ id: z.string().uuid() }),
    query: z.object({}).default({})
});
export const listSessionMembersSchema = z.object({
    body: z.object({}).default({}),
    params: z.object({ sessionId: z.string().uuid() }),
    query: z.object({}).default({})
});
