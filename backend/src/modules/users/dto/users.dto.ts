import { z } from 'zod';

const updateMeBody = z.object({
  full_name: z.string().min(3).optional(),
  avatar_url: z.string().url().optional(),
  assigned_faculty: z
    .enum(['Engineering', 'Business', 'Arts', 'Sciences', 'Medicine', 'Computer Science'])
    .optional()
});

export const updateMeSchema = z.object({
  body: updateMeBody,
  params: z.object({}).default({}),
  query: z.object({}).default({})
});

const adminUpdateUserBody = z.object({
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
  avatar_url: z.string().url().optional()
});

export const adminUpdateUserSchema = z.object({
  body: adminUpdateUserBody,
  params: z.object({ id: z.string().uuid() }),
  query: z.object({}).default({})
});

