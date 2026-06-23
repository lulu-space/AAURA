import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
import { normalizeClubName } from '../../../shared/utils/normalize-name.js';
export const CLUB_REQUEST_COOLDOWN_DAYS = 30;
export const MIN_CLUB_FOUNDER_ACADEMIC_YEAR = 2;
export class ClubRequestGuardsService {
    async checkEligibility(requesterId) {
        const reasons = [];
        const { data: user, error: userError } = await supabaseAdmin
            .from('users')
            .select('id, role')
            .eq('id', requesterId)
            .single();
        if (userError || !user) {
            throw new ApiError(404, 'User not found.', userError);
        }
        if (user.role === 'club_organizer') {
            reasons.push('You are already a club organizer.');
        }
        const { data: activeClubs } = await supabaseAdmin
            .from('clubs')
            .select('id')
            .eq('organizer_id', requesterId)
            .eq('is_active', true);
        if ((activeClubs?.length ?? 0) > 0) {
            reasons.push('You already lead an active club.');
        }
        const { data: pending } = await supabaseAdmin
            .from('club_requests')
            .select('id')
            .eq('requester_id', requesterId)
            .eq('status', 'pending')
            .limit(1);
        if ((pending?.length ?? 0) > 0) {
            reasons.push('You already have a pending club request.');
        }
        const cooldownUntil = await this.cooldownUntil(requesterId);
        if (cooldownUntil) {
            reasons.push(`You can submit again after ${cooldownUntil.toLocaleDateString('en-GB', {
                day: 'numeric',
                month: 'short',
                year: 'numeric'
            })}.`);
        }
        const { data: student } = await supabaseAdmin
            .from('students')
            .select('academic_year')
            .eq('user_id', requesterId)
            .maybeSingle();
        const year = student?.academic_year;
        if (year == null || year < MIN_CLUB_FOUNDER_ACADEMIC_YEAR) {
            reasons.push('Club founding is available from 2nd year onward.');
        }
        const { data: profile } = await supabaseAdmin
            .from('student_profiles')
            .select('user_id')
            .eq('user_id', requesterId)
            .maybeSingle();
        if (!profile) {
            reasons.push('Complete your onboarding profile before requesting a club.');
        }
        return {
            eligible: reasons.length === 0,
            reasons,
            cooldown_until: cooldownUntil?.toISOString() ?? null
        };
    }
    async assertCanSubmit(requesterId, proposedName) {
        const eligibility = await this.checkEligibility(requesterId);
        if (!eligibility.eligible) {
            throw new ApiError(400, eligibility.reasons[0] ?? 'Not eligible to submit a club request.');
        }
        await this.assertNameAvailable(proposedName);
    }
    async assertAdvisorDeanExists(advisorEmail) {
        const email = advisorEmail.trim().toLowerCase();
        const { data, error } = await supabaseAdmin
            .from('users')
            .select('id, role, is_suspended')
            .ilike('email', email)
            .limit(1)
            .maybeSingle();
        if (error) {
            throw new ApiError(500, 'Failed to verify faculty advisor.', error);
        }
        if (!data) {
            throw new ApiError(400, 'No dean account exists for that advisor email. Ask your faculty dean to sign up first.');
        }
        if (data.role !== 'dean_of_faculty') {
            throw new ApiError(400, 'Faculty advisor email must belong to a dean of faculty account.');
        }
        if (data.is_suspended) {
            throw new ApiError(400, 'That faculty advisor account is suspended.');
        }
    }
    async assertNameAvailable(proposedName, excludeRequestId) {
        const normalized = normalizeClubName(proposedName);
        if (normalized.length < 3) {
            throw new ApiError(400, 'Club name is too short after normalization.');
        }
        const { data: existingClub } = await supabaseAdmin
            .from('clubs')
            .select('id, name')
            .eq('normalized_name', normalized)
            .maybeSingle();
        if (existingClub) {
            throw new ApiError(409, `A club named "${existingClub.name}" already exists. Choose a different name.`);
        }
        let pendingQuery = supabaseAdmin
            .from('club_requests')
            .select('id, proposed_name')
            .eq('normalized_name', normalized)
            .eq('status', 'pending');
        if (excludeRequestId) {
            pendingQuery = pendingQuery.neq('id', excludeRequestId);
        }
        const { data: pendingRequest } = await pendingQuery.maybeSingle();
        if (pendingRequest) {
            throw new ApiError(409, `A pending request for "${pendingRequest.proposed_name}" already exists. Choose a different name.`);
        }
    }
    async cooldownUntil(requesterId) {
        const { data: lastRejected } = await supabaseAdmin
            .from('club_requests')
            .select('reviewed_at')
            .eq('requester_id', requesterId)
            .eq('status', 'rejected')
            .order('reviewed_at', { ascending: false })
            .limit(1)
            .maybeSingle();
        const reviewedAt = lastRejected?.reviewed_at;
        if (!reviewedAt)
            return null;
        const rejectedAt = new Date(reviewedAt);
        const unlockAt = new Date(rejectedAt);
        unlockAt.setDate(unlockAt.getDate() + CLUB_REQUEST_COOLDOWN_DAYS);
        return unlockAt > new Date() ? unlockAt : null;
    }
}
export const clubRequestGuardsService = new ClubRequestGuardsService();
