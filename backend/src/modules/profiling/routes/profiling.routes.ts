import { Router } from 'express';
import { asyncHandler } from '../../../shared/middleware/async-handler.js';
import { denyFacultyOps } from '../../../shared/middleware/role-based/deny-faculty-ops.js';
import { validateRequest } from '../../../shared/middleware/validation/validate-request.js';
import { profilingWorkflowController } from '../controllers/profiling-workflow.controller.js';
import { shamsChatSchema } from '../dto/profiling.dto.js';

const router = Router();

router.use(denyFacultyOps());

router.post(
  '/shams/chat',
  validateRequest(shamsChatSchema),
  asyncHandler((req, res) => profilingWorkflowController.shamsChat(req, res))
);
router.get('/drafts/me', asyncHandler((req, res) => profilingWorkflowController.getMyDraft(req, res)));
router.post('/drafts/confirm', asyncHandler((req, res) => profilingWorkflowController.confirmDraft(req, res)));
router.post(
  '/drafts/regenerate',
  asyncHandler((req, res) => profilingWorkflowController.regenerateDraft(req, res))
);

export default router;
