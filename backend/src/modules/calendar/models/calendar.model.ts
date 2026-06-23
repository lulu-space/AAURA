export interface CalendarModel {
  id: string;
  user_id: string;
  title: string;
  item_type: 'event' | 'study' | 'reminder';
  starts_at: string;
  ends_at?: string;
}
