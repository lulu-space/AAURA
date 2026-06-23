import { Router } from 'express';
import { asyncHandler } from '../../../shared/middleware/async-handler.js';
import { authenticateJwt } from '../../../shared/middleware/auth/authenticate-jwt.js';
import { aiController } from '../controllers/ai.controller.js';

const router = Router();

router.get('/health', asyncHandler((req, res) => aiController.health(req, res)));

router.use(authenticateJwt);
router.post(
  '/predictions/event-success',
  asyncHandler((req, res) => aiController.predictEventSuccess(req, res))
);
router.post('/profiling/shams/chat', asyncHandler((req, res) => aiController.shamsChat(req, res)));
router.post(
  '/recommendations/generate',
  asyncHandler((req, res) => aiController.generateRecommendations(req, res))
);
router.post(
  '/study-plans/generate',
  asyncHandler((req, res) => aiController.generateStudyPlan(req, res))
);

export default router;
