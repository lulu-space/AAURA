export interface EventReservationModel {
  id: string;
  event_id: string;
  user_id: string;
  reservation_status: 'reserved' | 'checked_in' | 'cancelled';
  qr_token?: string | null;
  reserved_at: string;
  checked_in_at?: string | null;
  created_at: string;
}

