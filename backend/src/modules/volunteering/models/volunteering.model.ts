export interface VolunteeringModel {
  id: string;
  user_id: string;
  title: string;
  hours: number;
  occurred_at: string;
  status: 'pending' | 'approved' | 'rejected';
}
