import { gamificationLeaderboardService } from '../services/gamification-leaderboard.service.js';
export class GamificationLeaderboardController {
    async list(req, res) {
        const limit = Math.min(Number(req.query.limit) || 10, 50);
        const data = await gamificationLeaderboardService.listTop(limit);
        res.json({ message: 'Leaderboard fetched successfully.', data });
    }
}
export const gamificationLeaderboardController = new GamificationLeaderboardController();
