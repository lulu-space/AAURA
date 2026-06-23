import { EVENT_MANAGER_ROLES } from '../../../shared/constants/roles.js';
import { SupabaseCrudService } from '../../../shared/utils/supabase-crud.service.js';
export const eventsService = new SupabaseCrudService('events', '*', {
    ownerColumn: 'organizer_id',
    createRoles: [...EVENT_MANAGER_ROLES]
});
