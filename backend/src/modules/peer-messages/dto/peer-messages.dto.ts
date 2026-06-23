import { z } from 'zod';

export const listPeerMessagesSchema = z.object({
  body: z.object({}).default({}),
  params: z.object({}).default({}),
  query: z.object({
    user_id: z.string().uuid()
  })
});

export const sendPeerMessageSchema = z.object({
  body: z.object({
    recipient_user_id: z.string().uuid(),
    body: z.string().trim().min(1).max(2000)
  }),
  params: z.object({}).default({}),
  query: z.object({}).default({})
});

export const markPeerConversationReadSchema = z.object({
  body: z.object({
    user_id: z.string().uuid()
  }),
  params: z.object({}).default({}),
  query: z.object({}).default({})
});
