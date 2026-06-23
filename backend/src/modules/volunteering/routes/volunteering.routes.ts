import { Router } from 'express';
import { buildCrudRouter } from '../../../shared/utils/crud-route-builder.js';
import { asyncHandler } from '../../../shared/middleware/async-handler.js';
import { denyFacultyOps } from '../../../shared/middleware/role-based/deny-faculty-ops.js';
import { authorizeRoles } from '../../../shared/middleware/role-based/authorize-roles.js';
import { validateRequest } from '../../../shared/middleware/validation/validate-request.js';
import { volunteeringController } from '../controllers/volunteering.controller.js';
import { volunteeringWorkflowController } from '../controllers/volunteering-workflow.controller.js';
import { VOLUNTEER_REVIEWER_ROLES } from '../../../shared/constants/roles.js';
import { createVolunteeringSchema, updateVolunteeringSchema } from '../dto/volunteering.dto.js';
import { staffActionSchema } from '../dto/volunteering-workflow.dto.js';

const router = Router();

router.get(
  '/pending',
  authorizeRoles(...VOLUNTEER_REVIEWER_ROLES),
  asyncHandler((req, res) => volunteeringWorkflowController.listPending(req, res))
);
router.get(
  '/all',
  authorizeRoles(...VOLUNTEER_REVIEWER_ROLES),
  asyncHandler((req, res) => volunteeringWorkflowController.listAll(req, res))
);
router.patch(
  '/:id/approve',
  authorizeRoles(...VOLUNTEER_REVIEWER_ROLES),
  validateRequest(staffActionSchema),
  asyncHandler((req, res) => volunteeringWorkflowController.approve(req, res))
);
router.patch(
  '/:id/reject',
  authorizeRoles(...VOLUNTEER_REVIEWER_ROLES),
  validateRequest(staffActionSchema),
  asyncHandler((req, res) => volunteeringWorkflowController.reject(req, res))
);
router.patch(
  '/:id/withdraw',
  authorizeRoles(...VOLUNTEER_REVIEWER_ROLES),
  validateRequest(staffActionSchema),
  asyncHandler((req, res) => volunteeringWorkflowController.withdraw(req, res))
);

const crud = buildCrudRouter({
  controller: volunteeringController,
  createSchema: createVolunteeringSchema,
  updateSchema: updateVolunteeringSchema
});

router.use(denyFacultyOps(), crud);

export default router;
