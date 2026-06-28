import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
import type { CreateClubRequestDto } from '../dto/club-requests.dto.js';
import { clubRequestGuardsService } from './club-request-guards.service.js';
import { syncEarnedBadges } from '../../gamification/services/badge-awards.service.js';
import { normalizeClubName } from '../../../shared/utils/normalize-name.js';

const SELECT_WITH_REQUESTER =
  '*, requester:users!club_requests_requester_id_fkey(full_name, email)';

type RequesterJoin = { full_name?: string | null; email?: string | null } | null;
type RequestRow = Record<string, unknown> & {
  requester?: RequesterJoin;
  requester_id?: string;
};

function nameFromRequester(row: RequestRow) {
  const joined = row.requester?.full_name?.trim();
  return joined ? joined : null;
}

function emailFromRequester(row: RequestRow) {
  const joined = row.requester?.email?.trim();
  return joined ? joined : null;
}

async function flattenRequester(rows: RequestRow[] | null) {
  const flattened = (rows ?? []).map((row) => {
    const { requester, ...rest } = row;
    return {
      ...rest,
      requester_name: nameFromRequester(row),
      requester_email: emailFromRequester(row)
    };
  });

  const missingIds = [
    ...new Set(
      flattened
        .filter((row) => !row.requester_name && row.requester_id)
        .map((row) => row.requester_id as string)
    )
  ];
  if (missingIds.length === 0) return flattened;

  const { data: users, error } = await supabaseAdmin
    .from('users')
    .select('id, full_name, email')
    .in('id', missingIds);

  if (error || !users) return flattened;

  const byId = new Map(
    users.map((user) => [
      user.id,
      {
        full_name: user.full_name?.trim() ?? null,
        email: user.email?.trim() ?? null
      }
    ])
  );

  return flattened.map((row) => {
    if (row.requester_name) return row;
    const user = byId.get(row.requester_id as string);
    return {
      ...row,
      requester_name: user?.full_name ?? null,
      requester_email: user?.email ?? row.requester_email
    };
  });
}

export class ClubRequestsService {
  async checkEligibility(requesterId: string) {
    return clubRequestGuardsService.checkEligibility(requesterId);
  }

  /** Student submits a request to found a club. */
  async create(requesterId: string, payload: CreateClubRequestDto) {
    await clubRequestGuardsService.assertCanSubmit(requesterId, payload.proposed_name);
    await clubRequestGuardsService.assertAdvisorDeanExists(payload.advisor_email);

    const coFounders = payload.co_founder_names
      .map((name) => name.trim())
      .filter((name) => name.length >= 2);

    const normalized = normalizeClubName(payload.proposed_name.trim());
    const { data, error } = await supabaseAdmin
      .from('club_requests')
      .insert({
        requester_id: requesterId,
        proposed_name: payload.proposed_name.trim(),
        normalized_name: normalized,
        description: payload.description.trim(),
        category: payload.category?.trim() || 'academic',
        advisor_email: payload.advisor_email.trim().toLowerCase(),
        co_founder_names: coFounders
      })
      .select('*')
      .single();

    if (error) {
      if (error.code === '23505') {
        throw new ApiError(
          409,
          'A club or pending request with this name already exists. Choose a different name.'
        );
      }
      const pgMessage = typeof error.message === 'string' ? error.message : '';
      if (
        error.code === '42703' ||
        pgMessage.includes('advisor_email') ||
        pgMessage.includes('co_founder_names')
      ) {
        throw new ApiError(
          503,
          'Club request storage is not configured on the server. Apply database migration 0021_club_request_guards.sql.'
        );
      }
      throw new ApiError(500, 'Failed to submit club request.', error);
    }
    return data;
  }

  async listMine(requesterId: string) {
    const { data, error } = await supabaseAdmin
      .from('club_requests')
      .select('*')
      .eq('requester_id', requesterId)
      .order('created_at', { ascending: false });

    if (error) throw new ApiError(500, 'Failed to fetch your club requests.', error);
    return data;
  }

  /** Reviewers: all pending requests with requester identity. */
  async listPending() {
    return this.listWithRequester(true);
  }

  /** Reviewers: full history (any status). */
  async listAll() {
    return this.listWithRequester(false);
  }

  private async listWithRequester(pendingOnly: boolean) {
    let query = supabaseAdmin.from('club_requests').select(SELECT_WITH_REQUESTER);
    if (pendingOnly) query = query.eq('status', 'pending');
    query = query.order('created_at', { ascending: false });

    const joined = await query;
    if (!joined.error) {
      return await flattenRequester(joined.data as RequestRow[] | null);
    }

    // Fallback when PostgREST join syntax fails in some environments.
    let plainQuery = supabaseAdmin.from('club_requests').select('*');
    if (pendingOnly) plainQuery = plainQuery.eq('status', 'pending');
    plainQuery = plainQuery.order('created_at', { ascending: false });

    const { data, error } = await plainQuery;
    if (error) {
      throw new ApiError(500, 'Failed to fetch club requests.', error);
    }
    return await flattenRequester(data as RequestRow[] | null);
  }

  private async loadPendingRequest(requestId: string) {
    const { data: request, error } = await supabaseAdmin
      .from('club_requests')
      .select('*')
      .eq('id', requestId)
      .maybeSingle();

    if (error) throw new ApiError(500, 'Failed to load club request.', error);
    if (!request) throw new ApiError(404, 'Club request not found.');
    if (request.status !== 'pending') {
      throw new ApiError(400, `Request is already ${request.status}.`);
    }
    return request;
  }

  /**
   * Approve: create the club, make the requester its lead, promote them to
   * club_organizer, and stamp the audit fields on the request.
   */
  async approve(requestId: string, reviewerId: string, reviewNote?: string) {
    const request = await this.loadPendingRequest(requestId);
    await clubRequestGuardsService.assertNameAvailable(
      request.proposed_name as string,
      requestId
    );

    const normalized = normalizeClubName(String(request.proposed_name));
    const { data: club, error: clubError } = await supabaseAdmin
      .from('clubs')
      .insert({
        name: request.proposed_name,
        normalized_name: normalized,
        description: request.description ?? '',
        organizer_id: request.requester_id,
        is_active: true
      })
      .select('*')
      .single();

    if (clubError || !club) {
      // Most likely a unique-name clash.
      throw new ApiError(
        409,
        'Could not create the club (the name may already be taken).',
        clubError
      );
    }

    await supabaseAdmin.from('club_membership').insert({
      club_id: club.id,
      user_id: request.requester_id,
      role: 'lead'
    });

    // Promote the requester so they can publish club events (even if role was stale).
    const { data: requesterUser } = await supabaseAdmin
      .from('users')
      .select('role')
      .eq('id', request.requester_id)
      .maybeSingle();

    if (requesterUser?.role === 'student') {
      await supabaseAdmin
        .from('users')
        .update({ role: 'club_organizer' })
        .eq('id', request.requester_id);
    }

    const { data: updated, error: updateError } = await supabaseAdmin
      .from('club_requests')
      .update({
        status: 'approved',
        reviewed_by: reviewerId,
        reviewed_at: new Date().toISOString(),
        review_note: reviewNote ?? null,
        created_club_id: club.id
      })
      .eq('id', requestId)
      .select('*')
      .single();

    if (updateError) throw new ApiError(500, 'Failed to finalize approval.', updateError);

    await syncEarnedBadges(request.requester_id as string).catch(() => undefined);

    await supabaseAdmin.from('notifications').insert({
      user_id: request.requester_id,
      title: 'Club request approved',
      body: `Your club "${request.proposed_name}" is live. You're now its organizer.`,
      notification_type: 'system',
      payload: { club_id: club.id, request_id: requestId }
    });

    return { request: updated, club };
  }

  async reject(requestId: string, reviewerId: string, reviewNote?: string) {
    const request = await this.loadPendingRequest(requestId);

    const { data: updated, error } = await supabaseAdmin
      .from('club_requests')
      .update({
        status: 'rejected',
        reviewed_by: reviewerId,
        reviewed_at: new Date().toISOString(),
        review_note: reviewNote ?? null
      })
      .eq('id', requestId)
      .select('*')
      .single();

    if (error) throw new ApiError(500, 'Failed to reject club request.', error);

    await supabaseAdmin.from('notifications').insert({
      user_id: request.requester_id,
      title: 'Club request declined',
      body: reviewNote
        ? `Your request for "${request.proposed_name}" was declined: ${reviewNote}`
        : `Your request for "${request.proposed_name}" was declined.`,
      notification_type: 'system',
      payload: { request_id: requestId }
    });

    return updated;
  }

  /**
   * Revoke a previously approved club: deactivate it and, if the organizer no
   * longer leads any active club, demote them back to student.
   */
  async revoke(requestId: string, reviewerId: string, reviewNote?: string) {
    const { data: request, error } = await supabaseAdmin
      .from('club_requests')
      .select('*')
      .eq('id', requestId)
      .maybeSingle();

    if (error) throw new ApiError(500, 'Failed to load club request.', error);
    if (!request) throw new ApiError(404, 'Club request not found.');
    if (request.status !== 'approved' || !request.created_club_id) {
      throw new ApiError(400, 'Only approved requests with a club can be revoked.');
    }

    await supabaseAdmin
      .from('clubs')
      .update({ is_active: false })
      .eq('id', request.created_club_id);

    // Demote the organizer if they no longer run any active club.
    const { data: activeClubs } = await supabaseAdmin
      .from('clubs')
      .select('id')
      .eq('organizer_id', request.requester_id)
      .eq('is_active', true);

    if (!activeClubs || activeClubs.length === 0) {
      await supabaseAdmin
        .from('users')
        .update({ role: 'student' })
        .eq('id', request.requester_id)
        .eq('role', 'club_organizer');
    }

    await supabaseAdmin
      .from('club_requests')
      .update({
        review_note: reviewNote
          ? `[revoked] ${reviewNote}`
          : '[revoked]',
        reviewed_by: reviewerId,
        reviewed_at: new Date().toISOString()
      })
      .eq('id', requestId);

    await supabaseAdmin.from('notifications').insert({
      user_id: request.requester_id,
      title: 'Club organizer access revoked',
      body: `"${request.proposed_name}" has been deactivated by campus staff.`,
      notification_type: 'system',
      payload: { club_id: request.created_club_id, request_id: requestId }
    });

    return { request_id: requestId, club_id: request.created_club_id };
  }
}

export const clubRequestsService = new ClubRequestsService();
