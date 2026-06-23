import { SupabaseCrudService } from '../../../shared/utils/supabase-crud.service.js';

export const studentProfilesService = new SupabaseCrudService('student_profiles', '*', {
  ownerColumn: 'user_id',
  restrictListToOwner: true,
  restrictGetToOwner: true
});

