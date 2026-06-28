import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';

type LeaderboardRow = {
  user_id: string;
  points: number;
  level: number;
  badges: unknown;
  full_name: string;
};

function mapLeaderboardRows(
  rows: Array<Record<string, unknown>>,
  usersById: Map<string, { full_name?: string | null; email?: string | null }>
): LeaderboardRow[] {
  return rows.map((row) => {
    const userId = row.user_id as string;
    const joined = row.users as { full_name?: string; email?: string } | null | undefined;
    const user = usersById.get(userId);
    const fallbackName = user?.email?.split('@')[0] ?? joined?.email?.split('@')[0] ?? 'Student';
    const fullName =
      joined?.full_name?.trim() ||
      user?.full_name?.trim() ||
      fallbackName;

    return {
      user_id: userId,
      points: Number(row.points ?? 0),
      level: Number(row.level ?? 1),
      badges: row.badges,
      full_name: fullName
    };
  });
}

export class GamificationLeaderboardService {
  async listTop(limit = 10): Promise<LeaderboardRow[]> {
    const capped = Math.min(Math.max(limit, 1), 50);

    const joined = await supabaseAdmin
      .from('gamification')
      .select('points, level, badges, user_id, users(full_name, email)')
      .order('points', { ascending: false })
      .limit(capped);

    if (!joined.error) {
      return mapLeaderboardRows(
        (joined.data ?? []) as Record<string, unknown>[],
        new Map()
      );
    }

    const { data, error } = await supabaseAdmin
      .from('gamification')
      .select('points, level, badges, user_id')
      .order('points', { ascending: false })
      .limit(capped);

    if (error) {
      throw new ApiError(500, 'Failed to fetch leaderboard.', error);
    }

    const rows = (data ?? []) as Record<string, unknown>[];
    const userIds = rows
      .map((row) => row.user_id as string)
      .filter((id) => typeof id === 'string' && id.length > 0);

    const usersById = new Map<string, { full_name?: string | null; email?: string | null }>();
    if (userIds.length > 0) {
      const { data: users } = await supabaseAdmin
        .from('users')
        .select('id, full_name, email')
        .in('id', userIds);

      for (const user of users ?? []) {
        usersById.set(user.id as string, {
          full_name: user.full_name as string | null,
          email: user.email as string | null
        });
      }
    }

    return mapLeaderboardRows(rows, usersById);
  }
}

export const gamificationLeaderboardService = new GamificationLeaderboardService();
