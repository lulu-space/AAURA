import { CLUB_ORGANIZER_ROLES } from '../../../shared/constants/roles.js';
import { SupabaseCrudService } from '../../../shared/utils/supabase-crud.service.js';
export const clubsService = new SupabaseCrudService('clubs', '*', {
    ownerColumn: 'organizer_id',
    createRoles: [...CLUB_ORGANIZER_ROLES]
});
