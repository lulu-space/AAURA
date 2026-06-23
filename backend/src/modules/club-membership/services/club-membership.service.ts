import { SupabaseCrudService } from '../../../shared/utils/supabase-crud.service.js';

export const clubMembershipService = new SupabaseCrudService('club_membership', '*', {
  ownerColumn: 'user_id',
  restrictListToOwner: true,
  restrictGetToOwner: true
});

