import { Router } from 'express';
import { asyncHandler } from '../../../shared/middleware/async-handler.js';
import { authorizeRoles } from '../../../shared/middleware/role-based/authorize-roles.js';
import { validateRequest } from '../../../shared/middleware/validation/validate-request.js';
import { usersController } from '../controllers/users.controller.js';
import { adminUpdateUserSchema, updateMeSchema } from '../dto/users.dto.js';

const router = Router();

router.get('/me', asyncHandler((req, res) => usersController.me(req, res)));
router.patch('/me', validateRequest(updateMeSchema), asyncHandler((req, res) => usersController.updateMe(req, res)));

router.get('/', authorizeRoles('admin'), asyncHandler((req, res) => usersController.adminList(req, res)));
router.get('/:id', authorizeRoles('admin'), asyncHandler((req, res) => usersController.adminGetById(req, res)));
router.patch(
  '/:id',
  authorizeRoles('admin'),
  validateRequest(adminUpdateUserSchema),
  asyncHandler((req, res) => usersController.adminUpdate(req, res))
);

export default router;

