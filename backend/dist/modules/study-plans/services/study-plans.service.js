import { SupabaseCrudService } from '../../../shared/utils/supabase-crud.service.js';
export const studyPlansService = new SupabaseCrudService('study_plans', '*', {
    ownerColumn: 'user_id',
    restrictListToOwner: true,
    restrictGetToOwner: true
});
