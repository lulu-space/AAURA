export interface StudentProfileModel {
  id: string;
  user_id: string;
  profile_summary?: string;
  strengths: unknown[];
  goals: unknown[];
  interests: unknown[];
  confidence: number;
  last_ai_refresh_at?: string | null;
  created_at: string;
  updated_at: string;
}

