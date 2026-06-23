export interface SystemLogModel {
  id: string;
  actor_user_id?: string;
  action: string;
  resource: string;
  resource_id?: string;
  severity: 'info' | 'warn' | 'error';
}
