import { SupabaseCrudService } from '../../../shared/utils/supabase-crud.service.js';

export const eventReservationsService = new SupabaseCrudService('event_reservation', '*', {
  ownerColumn: 'user_id',
  restrictListToOwner: true,
  restrictGetToOwner: true
});

