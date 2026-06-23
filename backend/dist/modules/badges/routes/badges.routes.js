import { Router } from 'express';
import { asyncHandler } from '../../../shared/middleware/async-handler.js';
import { denyFacultyOps } from '../../../shared/middleware/role-based/deny-faculty-ops.js';
import { badgesController } from '../controllers/badges.controller.js';
const router = Router();
router.use(denyFacultyOps());
router.get('/', asyncHandler((req, res) => badgesController.listDefinitions(req, res)));
export default router;
