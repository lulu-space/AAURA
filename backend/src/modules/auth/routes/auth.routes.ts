import { Router } from 'express';
import { authController } from '../controllers/auth.controller.js';
import { asyncHandler } from '../../../shared/middleware/async-handler.js';
import { authenticateJwt } from '../../../shared/middleware/auth/authenticate-jwt.js';
import { validateRequest } from '../../../shared/middleware/validation/validate-request.js';
import { provisionUserSchema } from '../dto/auth.dto.js';

const router = Router();

router.post(
  '/provision',
  authenticateJwt,
  validateRequest(provisionUserSchema),
  asyncHandler((req, res) => authController.provision(req, res))
);

export default router;
