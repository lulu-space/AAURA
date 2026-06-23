import { z } from 'zod';

export const adminUpdateUserSchema = z.object({
  body: z.object({
    role: z
      .enum([
        'student',
        'club_organizer',
        'student_affairs',
        'dean_of_faculty',
        'staff',
        'admin'
      ])
      .optional(),
    is_suspended: z.boolean().optional(),
    full_name: z.string().min(3).optional(),
    assigned_faculty: z
      .enum(['Engineering', 'Business', 'Arts', 'Sciences', 'Medicine', 'Computer Science'])
      .nullable()
      .optional()
  }),
  params: z.object({ id: z.string().uuid() }),
  query: z.object({}).default({})
});

export const adminModerateEventSchema = z.object({
  body: z.object({ action: z.enum(['hide', 'unhide', 'cancel']) }),
  params: z.object({ id: z.string().uuid() }),
  query: z.object({}).default({})
});

export const adminModerateClubSchema = z.object({
  body: z.object({ action: z.enum(['deactivate', 'reactivate', 'hide_posts']) }),
  params: z.object({ id: z.string().uuid() }),
  query: z.object({}).default({})
});

export const adminModerateHiddenSchema = z.object({
  body: z.object({ hidden: z.boolean() }),
  params: z.object({ id: z.string().uuid() }),
  query: z.object({}).default({})
});

export const adminSettingsSchema = z.object({
  body: z.object({ value: z.record(z.string(), z.unknown()) }),
  params: z.object({ key: z.enum(['ai_settings', 'points_rules', 'event_categories']) }),
  query: z.object({}).default({})
});

export const adminBadgeUpdateSchema = z.object({
  body: z.object({
    name: z.string().min(2).optional(),
    description: z.string().optional(),
    locked_by_default: z.boolean().optional(),
    sort_order: z.number().int().optional()
  }),
  params: z.object({ id: z.string().min(2) }),
  query: z.object({}).default({})
});

export const adminAnnouncementSchema = z.object({
  body: z.object({
    title: z.string().min(3).max(120),
    body: z.string().min(3).max(2000)
  }),
  params: z.object({}).default({}),
  query: z.object({}).default({})
});

export const adminVolunteerEmergencySchema = z.object({
  body: z.object({
    approval_note: z.string().optional(),
    emergency_override: z.literal(true)
  }),
  params: z.object({ id: z.string().uuid() }),
  query: z.object({}).default({})
});
