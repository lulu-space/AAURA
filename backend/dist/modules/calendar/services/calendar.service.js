import { SupabaseCrudService } from '../../../shared/utils/supabase-crud.service.js';
export const calendarService = new SupabaseCrudService('calendar', '*', {
    ownerColumn: 'user_id',
    createRoles: ['student', 'club_organizer', 'staff', 'admin'],
    restrictListToOwner: true,
    restrictGetToOwner: true
});
