import { SupabaseCrudService } from '../../../shared/utils/supabase-crud.service.js';
export const gamificationService = new SupabaseCrudService('gamification', '*', {
    ownerColumn: 'user_id',
    createRoles: ['student', 'admin'],
    restrictListToOwner: true,
    restrictGetToOwner: true
});
