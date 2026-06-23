import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
export class GamificationLeaderboardService {
    async listTop(limit = 10) {
        const { data, error } = await supabaseAdmin
            .from('gamification')
            .select('points, level, badges, user_id, users(full_name, email)')
            .order('points', { ascending: false })
            .limit(limit);
        if (error) {
            throw new ApiError(500, 'Failed to fetch leaderboard.', error);
        }
        return (data ?? []).map((row) => {
            const users = row.users;
            const fallbackName = users?.email?.split('@')[0] ?? 'Student';
            return {
                user_id: row.user_id,
                points: row.points,
                level: row.level,
                badges: row.badges,
                full_name: users?.full_name?.trim() || fallbackName,
            };
        });
    }
}
export const gamificationLeaderboardService = new GamificationLeaderboardService();
