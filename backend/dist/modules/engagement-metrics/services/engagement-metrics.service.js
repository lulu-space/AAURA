import { SupabaseCrudService } from '../../../shared/utils/supabase-crud.service.js';
export const engagementMetricsService = new SupabaseCrudService('engagement_metrics', '*', {
    ownerColumn: 'user_id',
    restrictListToOwner: true,
    restrictGetToOwner: true
});
