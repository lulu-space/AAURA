export interface SearchHistoryModel {
  id: string;
  user_id: string;
  query: string;
  filters: Record<string, unknown>;
  created_at: string;
}

