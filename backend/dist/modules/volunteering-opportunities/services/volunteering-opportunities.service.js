import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
import { SupabaseCrudService } from '../../../shared/utils/supabase-crud.service.js';
class VolunteeringOpportunitiesService extends SupabaseCrudService {
    async list(userId, role) {
        const rows = await super.list(userId, role);
        if (!Array.isArray(rows) || rows.length === 0)
            return rows;
        const typedRows = rows;
        const ids = typedRows
            .map((row) => row.id)
            .filter((id) => typeof id === 'string' && id.length > 0);
        if (ids.length === 0)
            return rows;
        const { data: enrollments, error } = await supabaseAdmin
            .from('volunteering_records')
            .select('opportunity_id')
            .in('opportunity_id', ids)
            .neq('status', 'rejected')
            .eq('hours', 0);
        if (error) {
            throw new ApiError(500, 'Failed to count volunteer enrollments.', error);
        }
        const enrolledByOpportunity = new Map();
        for (const row of enrollments ?? []) {
            const opportunityId = row.opportunity_id;
            enrolledByOpportunity.set(opportunityId, (enrolledByOpportunity.get(opportunityId) ?? 0) + 1);
        }
        return typedRows.map((row) => ({
            ...row,
            enrolled_count: enrolledByOpportunity.get(row.id) ?? 0
        }));
    }
}
export const volunteeringOpportunitiesService = new VolunteeringOpportunitiesService('volunteering_opportunities', '*', {
    ownerColumn: 'created_by',
    createRoles: ['student_affairs', 'dean_of_faculty', 'admin'],
    restrictListToOwner: false,
    restrictGetToOwner: false
});
