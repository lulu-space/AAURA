export interface StudentProfileDraftModel {
  id: string;
  user_id: string;
  profile_text?: string;
  traits: Record<string, unknown>;
  confidence: number;
  source: string;
  created_at: string;
  updated_at: string;
}

