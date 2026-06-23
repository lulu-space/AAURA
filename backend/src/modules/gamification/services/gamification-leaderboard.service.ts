import { ApiError } from '../../../core/errors/api-error.js';

import { supabaseAdmin } from '../../../config/supabase.js';



type LeaderboardRow = {

  user_id: string;

  points: number;

  level: number;

  badges: unknown;

  full_name: string;

};



export class GamificationLeaderboardService {

  async listTop(limit = 10): Promise<LeaderboardRow[]> {

    const { data, error } = await supabaseAdmin

      .from('gamification')

      .select('points, level, badges, user_id, users(full_name, email)')

      .order('points', { ascending: false })

      .limit(limit);



    if (error) {

      throw new ApiError(500, 'Failed to fetch leaderboard.', error);

    }



    return (data ?? []).map((row) => {

      const users = row.users as { full_name?: string; email?: string } | null;

      const fallbackName = users?.email?.split('@')[0] ?? 'Student';

      return {

        user_id: row.user_id as string,

        points: row.points as number,

        level: row.level as number,

        badges: row.badges,

        full_name: users?.full_name?.trim() || fallbackName,

      };

    });

  }

}



export const gamificationLeaderboardService = new GamificationLeaderboardService();


