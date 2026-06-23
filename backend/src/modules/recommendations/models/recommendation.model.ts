export interface RecommendationModel {
  id: string;
  user_id: string;
  source: 'rule_based' | 'ai';
  recommendation_type: 'event' | 'club' | 'study' | 'volunteer';
  target_id?: string;
  reason?: string;
  score?: number;
}
