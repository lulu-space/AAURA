import { Router } from 'express';
import { buildCrudRouter } from '../../../shared/utils/crud-route-builder.js';
import { asyncHandler } from '../../../shared/middleware/async-handler.js';
import { validateRequest } from '../../../shared/middleware/validation/validate-request.js';
import { studySessionsController } from '../controllers/study-sessions.controller.js';
import { studySessionsWorkflowController } from '../controllers/study-sessions-workflow.controller.js';
import {
  createStudySessionSchema,
  updateStudySessionSchema
} from '../dto/study-sessions.dto.js';
import { z } from 'zod';

const notifyMembersSchema = z.object({
  body: z.object({
    title: z.string().min(2),
    body: z.string().min(2),
    kind: z.enum(['updated', 'cancelled']).default('updated')
  }),
  params: z.object({ id: z.string().uuid() }),
  query: z.object({}).default({})
});

const router = Router();

router.post(
  '/:id/notify-members',
  validateRequest(notifyMembersSchema),
  asyncHandler((req, res) => studySessionsWorkflowController.notifyMembers(req, res))
);

const crud = buildCrudRouter({
  controller: studySessionsController,
  createSchema: createStudySessionSchema,
  updateSchema: updateStudySessionSchema
});

router.use(crud);

export default router;
