import { SupabaseCrudService } from '../../../shared/utils/supabase-crud.service.js';

export const studySessionsService = new SupabaseCrudService('study_sessions', '*', {
  ownerColumn: 'host_user_id',
  createRoles: ['student', 'club_organizer', 'admin']
});
