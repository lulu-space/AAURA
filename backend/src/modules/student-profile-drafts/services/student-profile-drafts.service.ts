import { SupabaseCrudService } from '../../../shared/utils/supabase-crud.service.js';

export const studentProfileDraftsService = new SupabaseCrudService('student_profile_drafts', '*', {
  ownerColumn: 'user_id',
  restrictListToOwner: true,
  restrictGetToOwner: true
});

