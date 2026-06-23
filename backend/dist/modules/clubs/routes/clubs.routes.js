import { Router } from 'express';
import { buildCrudRouter } from '../../../shared/utils/crud-route-builder.js';
import { asyncHandler } from '../../../shared/middleware/async-handler.js';
import { authorizeRoles } from '../../../shared/middleware/role-based/authorize-roles.js';
import { authorizeCapability } from '../../../shared/middleware/role-based/authorize-capability.js';
import { CLUB_ORGANIZER_ROLES } from '../../../shared/constants/roles.js';
import { clubsController } from '../controllers/clubs.controller.js';
import { clubsWorkflowController } from '../controllers/clubs-workflow.controller.js';
import { createClubSchema, updateClubSchema } from '../dto/clubs.dto.js';
const router = Router();
router.get('/activity/feed', asyncHandler((req, res) => clubsWorkflowController.activityFeed(req, res)));
router.get('/:id/members', asyncHandler((req, res) => clubsWorkflowController.listMembers(req, res)));
router.get('/reports/monthly', authorizeCapability(CLUB_ORGANIZER_ROLES), asyncHandler((req, res) => clubsWorkflowController.monthlyReport(req, res)));
router.post('/system/detect-inactive', authorizeRoles('admin'), asyncHandler((req, res) => clubsWorkflowController.detectInactive(req, res)));
router.patch('/:id/reactivate', authorizeCapability(CLUB_ORGANIZER_ROLES), asyncHandler((req, res) => clubsWorkflowController.reactivate(req, res)));
// Override list with member counts + next event before the generic CRUD list.
router.get('/', asyncHandler((req, res) => clubsWorkflowController.listWithCounts(req, res)));
const crud = buildCrudRouter({
    controller: clubsController,
    createSchema: createClubSchema,
    updateSchema: updateClubSchema
});
router.use(crud);
export default router;
