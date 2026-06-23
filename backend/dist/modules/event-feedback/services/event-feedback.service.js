import { SupabaseCrudService } from '../../../shared/utils/supabase-crud.service.js';
export const eventFeedbackService = new SupabaseCrudService('event_feedback', '*', {
    ownerColumn: 'user_id',
    restrictListToOwner: true,
    restrictGetToOwner: true
});
