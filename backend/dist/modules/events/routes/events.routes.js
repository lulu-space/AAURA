import { Router } from 'express';
import { buildCrudRouter } from '../../../shared/utils/crud-route-builder.js';
import { asyncHandler } from '../../../shared/middleware/async-handler.js';
import { authorizeCapability } from '../../../shared/middleware/role-based/authorize-capability.js';
import { authorizeRoles } from '../../../shared/middleware/role-based/authorize-roles.js';
import { EVENT_MANAGER_ROLES } from '../../../shared/constants/roles.js';
import { eventsController } from '../controllers/events.controller.js';
import { eventsReviewController } from '../controllers/events-review.controller.js';
import { eventsWorkflowController } from '../controllers/events-workflow.controller.js';
import { createEventSchema, updateEventSchema } from '../dto/events.dto.js';
import { reviewEventSchema } from '../dto/events-review.dto.js';
import { predictDraftSchema, predictSuccessSchema } from '../dto/events-workflow.dto.js';
import { validateRequest } from '../../../shared/middleware/validation/validate-request.js';
const REVIEWER_ROLES = ['student_affairs', 'dean_of_faculty', 'admin'];
const router = Router();
router.get('/reviews/pending', authorizeRoles(...REVIEWER_ROLES), asyncHandler((req, res) => eventsReviewController.listPending(req, res)));
router.get('/reviews/all', authorizeRoles(...REVIEWER_ROLES), asyncHandler((req, res) => eventsReviewController.listAll(req, res)));
router.patch('/:id/approve', authorizeRoles(...REVIEWER_ROLES), validateRequest(reviewEventSchema), asyncHandler((req, res) => eventsReviewController.approve(req, res)));
router.patch('/:id/reject', authorizeRoles(...REVIEWER_ROLES), validateRequest(reviewEventSchema), asyncHandler((req, res) => eventsReviewController.reject(req, res)));
router.patch('/:id/withdraw-approval', authorizeRoles(...REVIEWER_ROLES), validateRequest(reviewEventSchema), asyncHandler((req, res) => eventsReviewController.withdraw(req, res)));
router.get('/organizer/dashboard', authorizeCapability(EVENT_MANAGER_ROLES), asyncHandler((req, res) => eventsWorkflowController.organizerDashboard(req, res)));
router.post('/predict-draft', authorizeCapability(EVENT_MANAGER_ROLES), validateRequest(predictDraftSchema), asyncHandler((req, res) => eventsWorkflowController.predictDraft(req, res)));
router.get('/:id/analytics', authorizeCapability(EVENT_MANAGER_ROLES), asyncHandler((req, res) => eventsWorkflowController.analytics(req, res)));
router.post('/:id/predict-success', authorizeCapability(EVENT_MANAGER_ROLES), validateRequest(predictSuccessSchema), asyncHandler((req, res) => eventsWorkflowController.predictSuccess(req, res)));
const crud = buildCrudRouter({
    controller: eventsController,
    createSchema: createEventSchema,
    updateSchema: updateEventSchema
});
router.use(crud);
export default router;
