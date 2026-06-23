import { SupabaseCrudService } from '../../../shared/utils/supabase-crud.service.js';

export const searchHistoryService = new SupabaseCrudService('search_history', '*', {
  ownerColumn: 'user_id',
  restrictListToOwner: true,
  restrictGetToOwner: true
});

