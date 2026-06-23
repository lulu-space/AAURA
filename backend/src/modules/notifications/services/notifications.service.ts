import { SupabaseCrudService } from '../../../shared/utils/supabase-crud.service.js';

export const notificationsService = new SupabaseCrudService('notifications', '*', {
  ownerColumn: 'user_id',
  createRoles: ['student', 'club_organizer', 'staff', 'admin'],
  restrictListToOwner: true,
  restrictGetToOwner: true
});
