import { Router } from 'express';
import { buildCrudRouter } from '../../../shared/utils/crud-route-builder.js';
import { asyncHandler } from '../../../shared/middleware/async-handler.js';
import { gamificationController } from '../controllers/gamification.controller.js';
import { gamificationLeaderboardController } from '../controllers/gamification-leaderboard.controller.js';
import { syncEarnedBadges } from '../services/badge-awards.service.js';
import {
  createGamificationSchema,
  updateGamificationSchema
} from '../dto/gamification.dto.js';

const router = Router();

router.get(
  '/leaderboard',
  asyncHandler((req, res) => gamificationLeaderboardController.list(req, res))
);

router.post(
  '/sync-badges',
  asyncHandler(async (req, res) => {
    const badges = await syncEarnedBadges(req.authUser!.id);
    res.json({ message: 'Badges synced.', data: { badges } });
  })
);

const crud = buildCrudRouter({
  controller: gamificationController,
  createSchema: createGamificationSchema,
  updateSchema: updateGamificationSchema
});

router.use(crud);

export default router;

