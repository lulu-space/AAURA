import { randomUUID } from 'node:crypto';
import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
import { SupabaseCrudService } from '../../../shared/utils/supabase-crud.service.js';
import type { CrudCreateDto } from '../../../shared/interfaces/crud.types.js';
import { volunteeringService } from '../../volunteering/services/volunteering.service.js';

class VolunteeringOpportunitiesService extends SupabaseCrudService {
  async create(userId: string, role: string | undefined, payload: CrudCreateDto) {
    const body = {
      ...payload,
      created_by: userId,
      join_token: randomUUID()
    };
    return super.create(userId, role, body);
  }

  async findByJoinToken(token: string) {
    const { data, error } = await supabaseAdmin
      .from('volunteering_opportunities')
      .select('*')
      .eq('join_token', token)
      .maybeSingle();

    if (error) throw new ApiError(500, 'Failed to load volunteer opportunity.', error);
    if (!data) throw new ApiError(404, 'Volunteer opportunity not found.');
    if (data.status !== 'open') {
      throw new ApiError(400, 'This volunteer opportunity is closed.');
    }
    return data;
  }

  async applyByJoinToken(joinToken: string, userId: string, role?: string) {
    const opportunity = await this.findByJoinToken(joinToken);
    const opp = opportunity as Record<string, unknown>;
    return volunteeringService.create(userId, role, {
      opportunity_id: opp.id as string,
      title: String(opp.title ?? 'Volunteer activity'),
      hours: Number(opp.estimated_hours ?? 0),
      occurred_at: new Date().toISOString()
    });
  }

  async list(userId: string, role?: string) {
    const rows = await super.list(userId, role);
    if (!Array.isArray(rows) || rows.length === 0) return rows;

    const typedRows = rows as unknown as Record<string, unknown>[];
    const ids = typedRows
      .map((row) => row.id as string)
      .filter((id) => typeof id === 'string' && id.length > 0);

    if (ids.length === 0) return rows;

    const { data: enrollments, error } = await supabaseAdmin
      .from('volunteering_records')
      .select('opportunity_id')
      .in('opportunity_id', ids)
      .neq('status', 'rejected')
      .eq('hours', 0);

    if (error) {
      throw new ApiError(500, 'Failed to count volunteer enrollments.', error);
    }

    const enrolledByOpportunity = new Map<string, number>();
    for (const row of enrollments ?? []) {
      const opportunityId = row.opportunity_id as string;
      enrolledByOpportunity.set(
        opportunityId,
        (enrolledByOpportunity.get(opportunityId) ?? 0) + 1
      );
    }

    return typedRows.map((row) => ({
      ...row,
      enrolled_count: enrolledByOpportunity.get(row.id as string) ?? 0
    })) as unknown as typeof rows;
  }
}

export const volunteeringOpportunitiesService = new VolunteeringOpportunitiesService(
  'volunteering_opportunities',
  '*',
  {
    ownerColumn: 'created_by',
    createRoles: ['student_affairs', 'dean_of_faculty', 'admin'],
    restrictListToOwner: false,
    restrictGetToOwner: false
  }
);
