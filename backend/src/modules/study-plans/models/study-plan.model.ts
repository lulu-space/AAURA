export interface StudyPlanModel {
  id: string;
  user_id: string;
  title: string;
  goals: unknown[];
  schedule: unknown[];
  source: 'manual' | 'ai';
  created_at: string;
  updated_at: string;
}

