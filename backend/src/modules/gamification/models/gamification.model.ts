export interface GamificationModel {
  id: string;
  user_id: string;
  points: number;
  level: number;
  badges: string[];
  streak_days: number;
}
