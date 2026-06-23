import { SupabaseCrudService } from '../../../shared/utils/supabase-crud.service.js';

export const studentsService = new SupabaseCrudService('students', '*', {
  ownerColumn: 'user_id',
  restrictListToOwner: true,
  restrictGetToOwner: true
});

