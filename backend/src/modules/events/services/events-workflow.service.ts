import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
import { proxyToAi } from '../../ai/services/ai-proxy.service.js';
import {
  buildDraftEventFeatures,
  computeInterestMatch,
  computeSkillMatch,
  dominantValue,
  inferEventType,
  inferOrganizerType,
  normalizeDepartmentForMl,
  normalizeMajorForMl,
  strengthsToSkillNames,
  type EnrolleeProfile,
  type EventMlFeatures
} from '../utils/event-ml-features.js';

export class EventsWorkflowService {
  async getEventAnalytics(eventId: string, actorUserId: string, actorRole?: string) {
    const { data: event, error: eventError } = await supabaseAdmin
      .from('events')
      .select('*')
      .eq('id', eventId)
      .single();

    if (eventError || !event) {
      throw new ApiError(404, 'Event not found.', eventError);
    }

    if (actorRole !== 'admin' && event.organizer_id !== actorUserId) {
      throw new ApiError(403, 'Forbidden.');
    }

    const { data: reservations, error: resError } = await supabaseAdmin
      .from('event_reservation')
      .select('reservation_status')
      .eq('event_id', eventId);

    if (resError) throw new ApiError(500, 'Failed to load reservations.', resError);

    const totalReservations = reservations?.length ?? 0;
    const checkedIn =
      reservations?.filter((r) => r.reservation_status === 'checked_in').length ?? 0;
    const cancelled =
      reservations?.filter((r) => r.reservation_status === 'cancelled').length ?? 0;

    const { data: feedback, error: fbError } = await supabaseAdmin
      .from('event_feedback')
      .select('rating, comment')
      .eq('event_id', eventId);

    if (fbError) throw new ApiError(500, 'Failed to load feedback.', fbError);

    const ratings = feedback?.map((f) => f.rating) ?? [];
    const avgRating =
      ratings.length > 0 ? ratings.reduce((a, b) => a + b, 0) / ratings.length : null;

    const fillRate = event.capacity > 0 ? totalReservations / event.capacity : 0;
    const checkInRate = totalReservations > 0 ? checkedIn / totalReservations : 0;

    return {
      event: {
        id: event.id,
        title: event.title,
        capacity: event.capacity,
        status: event.status,
        starts_at: event.starts_at,
        ai_success_score: event.ai_success_score,
        ai_engagement_score: event.ai_engagement_score
      },
      attendance: {
        total_reservations: totalReservations,
        checked_in: checkedIn,
        cancelled,
        fill_rate: Number(fillRate.toFixed(3)),
        check_in_rate: Number(checkInRate.toFixed(3))
      },
      feedback: {
        count: ratings.length,
        average_rating: avgRating !== null ? Number(avgRating.toFixed(2)) : null,
        comments: (feedback ?? [])
          .filter((row) => typeof row.comment === 'string' && row.comment.trim().length > 0)
          .map((row) => ({
            rating: row.rating,
            comment: row.comment!.trim()
          }))
      }
    };
  }

  async getOrganizerDashboard(organizerId: string) {
    const { data: events, error } = await supabaseAdmin
      .from('events')
      .select('id, title, status, capacity, starts_at, ai_success_score, ai_engagement_score')
      .eq('organizer_id', organizerId)
      .order('starts_at', { ascending: false });

    if (error) throw new ApiError(500, 'Failed to load organizer events.', error);

    const summaries = await Promise.all(
      (events ?? []).map(async (event) => {
        const { count: reserved } = await supabaseAdmin
          .from('event_reservation')
          .select('id', { count: 'exact', head: true })
          .eq('event_id', event.id)
          .neq('reservation_status', 'cancelled');

        const { count: checkedIn } = await supabaseAdmin
          .from('event_reservation')
          .select('id', { count: 'exact', head: true })
          .eq('event_id', event.id)
          .eq('reservation_status', 'checked_in');

        return {
          ...event,
          reserved_count: reserved ?? 0,
          checked_in_count: checkedIn ?? 0
        };
      })
    );

    return {
      total_events: summaries.length,
      events: summaries
    };
  }

  private async loadEnrolleeProfiles(eventId: string): Promise<EnrolleeProfile[]> {
    const { data: reservations, error } = await supabaseAdmin
      .from('event_reservation')
      .select('user_id')
      .eq('event_id', eventId)
      .neq('reservation_status', 'cancelled');

    if (error) {
      throw new ApiError(500, 'Failed to load event reservations.', error);
    }

    const userIds = [...new Set((reservations ?? []).map((row) => row.user_id as string))];
    if (userIds.length === 0) return [];

    const [{ data: students }, { data: profiles }] = await Promise.all([
      supabaseAdmin.from('students').select('user_id, major, department').in('user_id', userIds),
      supabaseAdmin
        .from('student_profiles')
        .select('user_id, interests, strengths')
        .in('user_id', userIds)
    ]);

    const studentByUser = new Map((students ?? []).map((row) => [row.user_id as string, row]));
    const profileByUser = new Map((profiles ?? []).map((row) => [row.user_id as string, row]));

    return userIds.map((userId) => {
      const student = studentByUser.get(userId);
      const profile = profileByUser.get(userId);
      const rawInterests = profile?.interests;
      const interests = Array.isArray(rawInterests) ? rawInterests.map(String) : [];
      return {
        major: (student?.major as string | null | undefined) ?? null,
        department: (student?.department as string | null | undefined) ?? null,
        interests,
        skills: strengthsToSkillNames(profile?.strengths)
      };
    });
  }

  private async callAiPredict(features: EventMlFeatures) {
    const { status, body } = await proxyToAi('/api/predictions/event-success', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(features)
    });

    if (status >= 400) {
      throw new ApiError(502, 'AI prediction failed.', body);
    }

    return body as {
      success_probability: number;
      success_label: number;
      engagement_score: number;
      features_used?: Record<string, unknown>;
      model_cv_accuracy?: number;
    };
  }

  private canRunPrediction(
    actorUserId: string,
    actorRole: string | undefined,
    organizerId: string
  ): boolean {
    if (actorRole === 'admin') return true;
    if (actorRole === 'student_affairs' || actorRole === 'dean_of_faculty') return true;
    return organizerId === actorUserId;
  }

  async predictSuccess(
    eventId: string,
    actorUserId: string,
    actorRole?: string,
    overrides: Partial<EventMlFeatures> = {}
  ) {
    const { data: event, error: eventError } = await supabaseAdmin
      .from('events')
      .select('*')
      .eq('id', eventId)
      .single();

    if (eventError || !event) {
      throw new ApiError(404, 'Event not found.', eventError);
    }

    if (!this.canRunPrediction(actorUserId, actorRole, event.organizer_id as string)) {
      throw new ApiError(403, 'Forbidden.');
    }

    const enrollees = await this.loadEnrolleeProfiles(eventId);

    const { data: organizerStudent } = await supabaseAdmin
      .from('students')
      .select('major, department')
      .eq('user_id', event.organizer_id)
      .maybeSingle();

    const reservationCount = enrollees.length;
    const organizerMajor = normalizeMajorForMl(organizerStudent?.major);
    const dominantEnrolleeMajor = normalizeMajorForMl(
      dominantValue(
        enrollees.map((profile) => profile.major),
        organizerMajor
      )
    );
    const dominantDepartment = normalizeDepartmentForMl(
      dominantValue(
        enrollees.map((profile) => profile.department),
        organizerStudent?.department ?? 'Student Affairs'
      )
    );

    const computedInterestMatch = computeInterestMatch(
      enrollees,
      event.title as string,
      event.description as string | null
    );
    const computedSkillMatch = computeSkillMatch(
      enrollees,
      event.title as string,
      event.description as string | null
    );
    const targetMajors = Array.isArray(event.target_majors)
      ? event.target_majors.map(String)
      : [];
    const targetInterests = Array.isArray(event.target_interests)
      ? event.target_interests.map(String)
      : [];

    const features: EventMlFeatures = {
      student_major:
        overrides.student_major ??
        (reservationCount > 0 ? dominantEnrolleeMajor : organizerMajor),
      event_type:
        overrides.event_type ??
        inferEventType(
          event.title as string,
          event.description as string,
          event.category as string | null
        ),
      department: overrides.department ?? dominantDepartment,
      organizer_type:
        overrides.organizer_type ??
        inferOrganizerType(actorRole, (event.club_id as string | null | undefined) ?? null),
      expected_attendance:
        overrides.expected_attendance ?? Math.max(1, reservationCount || 1),
      interest_match_score:
        overrides.interest_match_score ?? computedInterestMatch,
      skill_match_score: overrides.skill_match_score ?? computedSkillMatch,
      target_major_count: overrides.target_major_count ?? targetMajors.length,
      target_interest_count: overrides.target_interest_count ?? targetInterests.length
    };

    const prediction = await this.callAiPredict(features);

    const successScore = Number((prediction.success_probability * 100).toFixed(2));
    const engagementScore = prediction.engagement_score;

    const { data: updated, error: updateError } = await supabaseAdmin
      .from('events')
      .update({
        ai_success_score: successScore,
        ai_engagement_score: engagementScore
      })
      .eq('id', eventId)
      .select('*')
      .single();

    if (updateError) {
      throw new ApiError(500, 'Failed to save prediction scores.', updateError);
    }

    return {
      prediction,
      event: updated,
      features,
      enrollee_count: reservationCount
    };
  }

  async predictDraft(
    actorRole: string | undefined,
    input: {
      title: string;
      description?: string | null;
      category?: string | null;
      format?: string | null;
      capacity: number;
      promotion_level?: number;
      target_majors?: string[];
      target_interests?: string[];
      target_skills?: string[];
      tags?: string[];
      club_id?: string | null;
      department?: string | null;
    }
  ) {
    const features = buildDraftEventFeatures({
      title: input.title,
      description: input.description,
      category: input.category,
      format: input.format,
      capacity: input.capacity,
      promotionLevel: input.promotion_level,
      targetMajors: input.target_majors,
      targetInterests: input.target_interests,
      targetSkills: input.target_skills,
      tags: input.tags,
      organizerRole: actorRole,
      clubId: input.club_id,
      department: input.department
    });

    const prediction = await this.callAiPredict(features);

    const promotion = Math.max(1, Math.min(5, input.promotion_level ?? 3));
    const promotionFactor = 0.86 + promotion * 0.035;
    const adjustedProbability = Math.min(
      0.99,
      Math.max(0.05, prediction.success_probability * promotionFactor)
    );
    const adjustedPrediction = {
      ...prediction,
      success_probability: Number(adjustedProbability.toFixed(4)),
      success_label: adjustedProbability >= 0.5 ? 1 : 0,
      engagement_score: Number(
        Math.min(100, adjustedProbability * 55 + (features.interest_match_score ?? 0) * 25 + (features.skill_match_score ?? 0) * 20).toFixed(2)
      ),
      promotion_level_used: promotion
    };

    return {
      prediction: adjustedPrediction,
      features,
      input_summary: {
        majors: input.target_majors ?? [],
        interests: input.target_interests ?? [],
        skills: input.target_skills ?? [],
        tags: input.tags ?? [],
        organizer_type: features.organizer_type,
        capacity: input.capacity,
        promotion_level: promotion
      }
    };
  }
}

export const eventsWorkflowService = new EventsWorkflowService();
