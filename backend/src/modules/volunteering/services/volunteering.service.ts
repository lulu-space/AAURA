import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
import { SupabaseCrudService } from '../../../shared/utils/supabase-crud.service.js';
import type { CrudCreateDto } from '../../../shared/interfaces/crud.types.js';

class VolunteeringService extends SupabaseCrudService {
  async create(userId: string, role: string | undefined, payload: CrudCreateDto) {
    const opportunityId = payload.opportunity_id as string | undefined;

    if (opportunityId) {
      const { data: opp, error: oppError } = await supabaseAdmin
        .from('volunteering_opportunities')
        .select('id, estimated_hours, status, title')
        .eq('id', opportunityId)
        .maybeSingle();

      if (oppError || !opp) {
        throw new ApiError(404, 'Volunteer opportunity not found.', oppError);
      }
      if (opp.status !== 'open') {
        throw new ApiError(400, 'This volunteer opportunity is closed.');
      }

      const { count: existingCount, error: existingError } = await supabaseAdmin
        .from('volunteering_records')
        .select('id', { count: 'exact', head: true })
        .eq('opportunity_id', opportunityId)
        .eq('user_id', userId)
        .neq('status', 'rejected');

      if (existingError) {
        throw new ApiError(500, 'Failed to verify volunteer application.', existingError);
      }
      if ((existingCount ?? 0) > 0) {
        throw new ApiError(409, 'You already applied for this opportunity.');
      }

      payload = {
        ...payload,
        hours: Number(opp.estimated_hours ?? payload.hours ?? 0),
        title:
          (payload.title as string | undefined)?.trim() ||
          String(opp.title ?? 'Volunteer activity')
      };
    }

    return super.create(userId, role, payload);
  }
}

export const volunteeringService = new VolunteeringService('volunteering_records', '*', {
  ownerColumn: 'user_id',
  createRoles: ['student', 'club_organizer', 'admin'],
  restrictListToOwner: true,
  restrictGetToOwner: true
});
