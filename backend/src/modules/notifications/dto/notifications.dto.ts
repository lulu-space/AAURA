import { z } from 'zod';

const notificationBody = z.object({
  user_id: z.string().uuid().optional(),
  title: z.string().min(2),
  body: z.string().min(2),
  notification_type: z.enum([
    'system',
    'event',
    'study',
    'volunteer',
    'recommendation',
    'message'
  ]),
  is_read: z.boolean().optional(),
  payload: z.record(z.string(), z.unknown()).optional()
});

export const createNotificationSchema = z.object({
  body: notificationBody,
  params: z.object({}).default({}),
  query: z.object({}).default({})
});

export const updateNotificationSchema = z.object({
  body: notificationBody.partial(),
  params: z.object({ id: z.string().uuid() }),
  query: z.object({}).default({})
});
