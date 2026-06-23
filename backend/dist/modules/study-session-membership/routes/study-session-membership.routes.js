import { Router } from 'express';
import { buildCrudRouter } from '../../../shared/utils/crud-route-builder.js';
import { asyncHandler } from '../../../shared/middleware/async-handler.js';
import { denyFacultyOps } from '../../../shared/middleware/role-based/deny-faculty-ops.js';
import { validateRequest } from '../../../shared/middleware/validation/validate-request.js';
import { studySessionMembershipController } from '../controllers/study-session-membership.controller.js';
import { studySessionMembershipWorkflowController } from '../controllers/study-session-membership-workflow.controller.js';
import { createStudySessionMembershipSchema, listSessionMembersSchema, updateStudySessionMembershipSchema } from '../dto/study-session-membership.dto.js';
const router = Router();
router.use(denyFacultyOps());
router.post('/join', validateRequest(createStudySessionMembershipSchema), asyncHandler((req, res) => studySessionMembershipWorkflowController.join(req, res)));
router.get('/session/:sessionId/members', validateRequest(listSessionMembersSchema), asyncHandler((req, res) => studySessionMembershipWorkflowController.listMembers(req, res)));
const crud = buildCrudRouter({
    controller: studySessionMembershipController,
    createSchema: createStudySessionMembershipSchema,
    updateSchema: updateStudySessionMembershipSchema
});
router.use(crud);
export default router;
