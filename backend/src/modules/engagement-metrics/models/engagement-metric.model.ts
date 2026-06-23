export interface EngagementMetricModel {
  id: string;
  user_id: string;
  event_id?: string | null;
  metric_type: 'view' | 'click' | 'join' | 'complete';
  value: number;
  metadata: Record<string, unknown>;
  created_at: string;
}

