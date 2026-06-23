export interface EventFeedbackModel {
  id: string;
  event_id: string;
  user_id: string;
  rating: number;
  comment?: string | null;
  created_at: string;
}

