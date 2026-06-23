import { Router } from 'express';
import { asyncHandler } from '../../../shared/middleware/async-handler.js';
import { authorizeRoles } from '../../../shared/middleware/role-based/authorize-roles.js';
import { validateRequest } from '../../../shared/middleware/validation/validate-request.js';
import { adminController } from '../controllers/admin.controller.js';
import {
  adminAnnouncementSchema,
  adminBadgeUpdateSchema,
  adminModerateClubSchema,
  adminModerateEventSchema,
  adminModerateHiddenSchema,
  adminSettingsSchema,
  adminUpdateUserSchema
} from '../dto/admin.dto.js';

const router = Router();
const adminOnly = authorizeRoles('admin');

router.get('/dashboard', adminOnly, asyncHandler((req, res) => adminController.dashboard(req, res)));
router.get('/users', adminOnly, asyncHandler((req, res) => adminController.users(req, res)));
router.patch(
  '/users/:id',
  adminOnly,
  validateRequest(adminUpdateUserSchema),
  asyncHandler((req, res) => adminController.updateUser(req, res))
);

router.get('/content', adminOnly, asyncHandler((req, res) => adminController.content(req, res)));
router.patch(
  '/content/events/:id',
  adminOnly,
  validateRequest(adminModerateEventSchema),
  asyncHandler((req, res) => adminController.moderateEvent(req, res))
);
router.patch(
  '/content/clubs/:id',
  adminOnly,
  validateRequest(adminModerateClubSchema),
  asyncHandler((req, res) => adminController.moderateClub(req, res))
);
router.patch(
  '/content/posts/:id',
  adminOnly,
  validateRequest(adminModerateHiddenSchema),
  asyncHandler((req, res) => adminController.moderatePost(req, res))
);
router.patch(
  '/content/messages/:id',
  adminOnly,
  validateRequest(adminModerateHiddenSchema),
  asyncHandler((req, res) => adminController.moderateMessage(req, res))
);

router.get('/analytics', adminOnly, asyncHandler((req, res) => adminController.analytics(req, res)));
router.get('/volunteering', adminOnly, asyncHandler((req, res) => adminController.volunteering(req, res)));

router.get('/settings', adminOnly, asyncHandler((req, res) => adminController.settings(req, res)));
router.patch(
  '/settings/:key',
  adminOnly,
  validateRequest(adminSettingsSchema),
  asyncHandler((req, res) => adminController.updateSettings(req, res))
);
router.get('/badges', adminOnly, asyncHandler((req, res) => adminController.badges(req, res)));
router.patch(
  '/badges/:id',
  adminOnly,
  validateRequest(adminBadgeUpdateSchema),
  asyncHandler((req, res) => adminController.updateBadge(req, res))
);
router.get('/audit-logs', adminOnly, asyncHandler((req, res) => adminController.auditLogs(req, res)));

router.post(
  '/announcements',
  adminOnly,
  validateRequest(adminAnnouncementSchema),
  asyncHandler((req, res) => adminController.announce(req, res))
);

export default router;
