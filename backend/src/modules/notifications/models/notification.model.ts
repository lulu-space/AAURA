export interface NotificationModel {
  id: string;
  user_id: string;
  title: string;
  body: string;
  notification_type: 'system' | 'event' | 'study' | 'volunteer' | 'recommendation';
  is_read: boolean;
}
