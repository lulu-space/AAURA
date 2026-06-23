export interface EventModel {
  id: string;
  organizer_id: string;
  title: string;
  description?: string;
  location?: string;
  starts_at: string;
  ends_at: string;
  capacity: number;
  status: 'draft' | 'published' | 'completed' | 'cancelled';
}
