import { SupabaseCrudService } from '../../../shared/utils/supabase-crud.service.js';
export const recommendationsService = new SupabaseCrudService('recommendations', '*', {
    ownerColumn: 'user_id',
    createRoles: ['student', 'club_organizer', 'staff', 'admin'],
    restrictListToOwner: true,
    restrictGetToOwner: true
});
