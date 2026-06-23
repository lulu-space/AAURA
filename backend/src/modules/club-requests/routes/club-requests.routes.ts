import { Router } from 'express';
import { asyncHandler } from '../../../shared/middleware/async-handler.js';
import { authorizeRoles } from '../../../shared/middleware/role-based/authorize-roles.js';
import { validateRequest } from '../../../shared/middleware/validation/validate-request.js';
import { clubRequestsController } from '../controllers/club-requests.controller.js';
import {
  createClubRequestSchema,
  reviewClubRequestSchema
} from '../dto/club-requests.dto.js';

const REVIEWER_ROLES = ['student_affairs', 'staff', 'dean_of_faculty', 'admin'] as const;

const router = Router();

// Student-facing.
router.get(
  '/eligibility',
  asyncHandler((req, res) => clubRequestsController.eligibility(req, res))
);
router.post(
  '/',
  validateRequest(createClubRequestSchema),
  asyncHandler((req, res) => clubRequestsController.create(req, res))
);
router.get('/mine', asyncHandler((req, res) => clubRequestsController.listMine(req, res)));

// Reviewer-facing.
router.get(
  '/pending',
  authorizeRoles(...REVIEWER_ROLES),
  asyncHandler((req, res) => clubRequestsController.listPending(req, res))
);
router.get(
  '/all',
  authorizeRoles(...REVIEWER_ROLES),
  asyncHandler((req, res) => clubRequestsController.listAll(req, res))
);
router.patch(
  '/:id/approve',
  authorizeRoles(...REVIEWER_ROLES),
  validateRequest(reviewClubRequestSchema),
  asyncHandler((req, res) => clubRequestsController.approve(req, res))
);
router.patch(
  '/:id/reject',
  authorizeRoles(...REVIEWER_ROLES),
  validateRequest(reviewClubRequestSchema),
  asyncHandler((req, res) => clubRequestsController.reject(req, res))
);
router.patch(
  '/:id/revoke',
  authorizeRoles(...REVIEWER_ROLES),
  validateRequest(reviewClubRequestSchema),
  asyncHandler((req, res) => clubRequestsController.revoke(req, res))
);

export default router;
