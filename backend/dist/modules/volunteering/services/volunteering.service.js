import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
import { SupabaseCrudService } from '../../../shared/utils/supabase-crud.service.js';
async function assertEnrollmentAllowed(opportunityId, userId) {
    const { data: opp, error } = await supabaseAdmin
        .from('volunteering_opportunities')
        .select('id, slots, status')
        .eq('id', opportunityId)
        .single();
    if (error || !opp) {
        throw new ApiError(404, 'Volunteer opportunity not found.', error);
    }
    if (opp.status !== 'open') {
        throw new ApiError(400, 'This volunteer opportunity is closed.');
    }
    const { count: existingEnrollment, error: existingError } = await supabaseAdmin
        .from('volunteering_records')
        .select('id', { count: 'exact', head: true })
        .eq('opportunity_id', opportunityId)
        .eq('user_id', userId)
        .neq('status', 'rejected');
    if (existingError) {
        throw new ApiError(500, 'Failed to verify enrollment.', existingError);
    }
    if ((existingEnrollment ?? 0) > 0) {
        throw new ApiError(409, 'You are already enrolled in this opportunity.');
    }
    const { count: enrolledCount, error: countError } = await supabaseAdmin
        .from('volunteering_records')
        .select('id', { count: 'exact', head: true })
        .eq('opportunity_id', opportunityId)
        .neq('status', 'rejected')
        .eq('hours', 0);
    if (countError) {
        throw new ApiError(500, 'Failed to verify volunteer seats.', countError);
    }
    if ((enrolledCount ?? 0) >= opp.slots) {
        throw new ApiError(409, 'Seats are full.');
    }
}
class VolunteeringService extends SupabaseCrudService {
    async create(userId, role, payload) {
        const opportunityId = payload.opportunity_id;
        const hours = payload.hours;
        if (opportunityId && hours === 0) {
            await assertEnrollmentAllowed(opportunityId, userId);
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
