export interface StudySessionModel {
  id: string;
  host_user_id: string;
  title: string;
  topic?: string;
  location?: string;
  starts_at: string;
  ends_at: string;
  capacity: number;
}
