import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
import {
  FACULTY_OPTIONS,
  filterClubsForFaculty,
  filterEventsForFaculty,
  listStudentUserIdsInFaculty,
  majorsForFaculty,
  requireDeanFaculty
} from '../../../shared/utils/faculty-scope.js';

const EVENT_SELECT =
  '*, organizer:users!events_organizer_id_fkey(id, full_name, email, role)';

type ReportType = 'events' | 'clubs' | 'volunteering' | 'engagement';

export class DeanService {
  async getFaculties() {
    return FACULTY_OPTIONS;
  }

  async getDashboard(userId: string, role?: string) {
    const faculty = await requireDeanFaculty(userId, role);
    const studentIds = await listStudentUserIdsInFaculty(faculty);

    const { data: eventsRaw, error: eventsError } = await supabaseAdmin
      .from('events')
      .select(EVENT_SELECT)
      .neq('status', 'cancelled')
      .order('starts_at', { ascending: false });

    if (eventsError) {
      throw new ApiError(500, 'Failed to load faculty events.', eventsError);
    }

    const facultyEvents = await filterEventsForFaculty(
      (eventsRaw ?? []) as Record<string, unknown>[],
      faculty,
      userId
    );

    const { data: clubsRaw, error: clubsError } = await supabaseAdmin
      .from('clubs')
      .select('*')
      .order('name');

    if (clubsError) {
      throw new ApiError(500, 'Failed to load faculty clubs.', clubsError);
    }

    const facultyClubs = await filterClubsForFaculty(
      (clubsRaw ?? []) as Record<string, unknown>[],
      faculty
    );

    const { data: approvedVolunteerRows, error: hoursError } = await supabaseAdmin
      .from('volunteering_records')
      .select('hours')
      .eq('status', 'approved')
      .in('user_id', studentIds.length > 0 ? studentIds : ['00000000-0000-0000-0000-000000000000']);

    if (hoursError) {
      throw new ApiError(500, 'Failed to load volunteer stats.', hoursError);
    }

    const approvedVolunteerHours = (approvedVolunteerRows ?? []).reduce(
      (sum, row) => sum + Number(row.hours ?? 0),
      0
    );

    const { data: reservations, error: reservationError } = await supabaseAdmin
      .from('event_reservations')
      .select('id, event_id, reservation_status')
      .in(
        'event_id',
        facultyEvents.map((event) => event.id as string).filter(Boolean)
      );

    if (reservationError) {
      throw new ApiError(500, 'Failed to load engagement stats.', reservationError);
    }

    const checkedIn =
      reservations?.filter((row) => row.reservation_status === 'checked_in').length ?? 0;
    const enrolled =
      reservations?.filter((row) => row.reservation_status !== 'cancelled').length ?? 0;

    const pendingReviews = facultyEvents.filter(
      (event) => event.is_approved === false && event.status !== 'cancelled'
    ).length;

    const inactiveClubs = facultyClubs.filter((club) => club.is_active === false).length;

    return {
      faculty,
      student_count: studentIds.length,
      events: {
        total: facultyEvents.length,
        pending_reviews: pendingReviews,
        published: facultyEvents.filter((event) => event.status === 'published').length
      },
      clubs: {
        total: facultyClubs.length,
        active: facultyClubs.filter((club) => club.is_active !== false).length,
        inactive: inactiveClubs
      },
      volunteering: {
        approved_hours: approvedVolunteerHours,
        approved_records: approvedVolunteerRows?.length ?? 0
      },
      engagement: {
        event_enrollments: enrolled,
        event_check_ins: checkedIn
      }
    };
  }

  async listEvents(userId: string, role?: string) {
    const faculty = await requireDeanFaculty(userId, role);
    const { data, error } = await supabaseAdmin
      .from('events')
      .select(EVENT_SELECT)
      .order('starts_at', { ascending: false });

    if (error) throw new ApiError(500, 'Failed to load events.', error);
    return filterEventsForFaculty((data ?? []) as Record<string, unknown>[], faculty, userId);
  }

  async listClubs(userId: string, role?: string) {
    const faculty = await requireDeanFaculty(userId, role);
    const { data, error } = await supabaseAdmin.from('clubs').select('*').order('name');
    if (error) throw new ApiError(500, 'Failed to load clubs.', error);
    return filterClubsForFaculty((data ?? []) as Record<string, unknown>[], faculty);
  }

  async getInsights(userId: string, role?: string) {
    const faculty = await requireDeanFaculty(userId, role);
    const studentIds = await listStudentUserIdsInFaculty(faculty);
    const events = await this.listEvents(userId, role);
    const clubs = await this.listClubs(userId, role);

    const engagementPredictions = events
      .map((event) => ({
        event_id: event.id,
        title: event.title,
        predicted_success: event.ai_success_score ?? null,
        expected_attendance: event.expected_attendance ?? null,
        status: event.status
      }))
      .filter((row) => row.predicted_success != null)
      .sort(
        (a, b) => (Number(b.predicted_success) || 0) - (Number(a.predicted_success) || 0)
      )
      .slice(0, 8);

    const inactiveClubs = clubs
      .filter((club) => club.is_active === false)
      .map((club) => ({
        id: club.id,
        name: club.name,
        last_activity_at: club.last_activity_at ?? null
      }));

    let topInterests: Array<{ interest: string; count: number }> = [];
    if (studentIds.length > 0) {
      const { data: profiles, error } = await supabaseAdmin
        .from('student_profiles')
        .select('interests')
        .in('user_id', studentIds);

      if (error) throw new ApiError(500, 'Failed to load student interests.', error);

      const counts = new Map<string, number>();
      for (const profile of profiles ?? []) {
        const interests = profile.interests;
        if (!Array.isArray(interests)) continue;
        for (const interest of interests) {
          const key = String(interest).trim();
          if (!key) continue;
          counts.set(key, (counts.get(key) ?? 0) + 1);
        }
      }

      topInterests = [...counts.entries()]
        .map(([interest, count]) => ({ interest, count }))
        .sort((a, b) => b.count - a.count)
        .slice(0, 10);
    }

    return {
      faculty,
      engagement_predictions: engagementPredictions,
      inactive_clubs: inactiveClubs,
      top_student_interests: topInterests
    };
  }

  async generateReport(userId: string, role: string | undefined, type: ReportType) {
    const faculty = await requireDeanFaculty(userId, role);
    const generatedAt = new Date().toISOString();
    const studentIds = await listStudentUserIdsInFaculty(faculty);

    switch (type) {
      case 'events': {
        const events = await this.listEvents(userId, role);
        return {
          faculty,
          type,
          generated_at: generatedAt,
          summary: {
            total_events: events.length,
            published: events.filter((event) => event.status === 'published').length,
            pending_review: events.filter(
              (event) => event.is_approved === false && event.status !== 'cancelled'
            ).length
          },
          rows: events.map((event) => ({
            id: event.id,
            title: event.title,
            status: event.status,
            starts_at: event.starts_at,
            target_majors: event.target_majors,
            ai_success_score: event.ai_success_score ?? null
          }))
        };
      }
      case 'clubs': {
        const clubs = await this.listClubs(userId, role);
        return {
          faculty,
          type,
          generated_at: generatedAt,
          summary: {
            total_clubs: clubs.length,
            active: clubs.filter((club) => club.is_active !== false).length,
            inactive: clubs.filter((club) => club.is_active === false).length
          },
          rows: clubs.map((club) => ({
            id: club.id,
            name: club.name,
            is_active: club.is_active,
            last_activity_at: club.last_activity_at ?? null
          }))
        };
      }
      case 'volunteering': {
        const majors = majorsForFaculty(faculty);
        const { data: records, error } = await supabaseAdmin
          .from('volunteering_records')
          .select('id, title, hours, status, occurred_at, user_id, opportunity_id')
          .in('user_id', studentIds.length > 0 ? studentIds : ['00000000-0000-0000-0000-000000000000'])
          .order('occurred_at', { ascending: false });

        if (error) throw new ApiError(500, 'Failed to load volunteering report.', error);

        const approvedHours = (records ?? [])
          .filter((row) => row.status === 'approved')
          .reduce((sum, row) => sum + Number(row.hours ?? 0), 0);

        return {
          faculty,
          type,
          generated_at: generatedAt,
          summary: {
            total_records: records?.length ?? 0,
            approved_hours: approvedHours,
            faculty_majors: majors
          },
          rows: records ?? []
        };
      }
      case 'engagement': {
        const events = await this.listEvents(userId, role);
        const eventIds = events.map((event) => event.id as string).filter(Boolean);
        const { data: reservations, error } = await supabaseAdmin
          .from('event_reservations')
          .select('event_id, reservation_status, user_id')
          .in('event_id', eventIds.length > 0 ? eventIds : ['00000000-0000-0000-0000-000000000000']);

        if (error) throw new ApiError(500, 'Failed to load engagement report.', error);

        const byEvent = new Map<
          string,
          { enrollments: number; check_ins: number; title: string }
        >();
        for (const event of events) {
          byEvent.set(event.id as string, {
            enrollments: 0,
            check_ins: 0,
            title: String(event.title ?? 'Event')
          });
        }
        for (const row of reservations ?? []) {
          const bucket = byEvent.get(row.event_id as string);
          if (!bucket) continue;
          if (row.reservation_status !== 'cancelled') bucket.enrollments += 1;
          if (row.reservation_status === 'checked_in') bucket.check_ins += 1;
        }

        return {
          faculty,
          type,
          generated_at: generatedAt,
          summary: {
            faculty_students: studentIds.length,
            total_enrollments: reservations?.filter((row) => row.reservation_status !== 'cancelled')
              .length ?? 0,
            total_check_ins:
              reservations?.filter((row) => row.reservation_status === 'checked_in').length ?? 0
          },
          rows: [...byEvent.entries()].map(([eventId, stats]) => ({
            event_id: eventId,
            title: stats.title,
            enrollments: stats.enrollments,
            check_ins: stats.check_ins
          }))
        };
      }
      default:
        throw new ApiError(400, 'Invalid report type.');
    }
  }

  async listAnnouncements(userId: string, role?: string) {
    await requireDeanFaculty(userId, role);
    const { data, error } = await supabaseAdmin
      .from('faculty_announcements')
      .select('*')
      .eq('dean_user_id', userId)
      .order('created_at', { ascending: false })
      .limit(30);

    if (error) throw new ApiError(500, 'Failed to load announcements.', error);
    return data ?? [];
  }

  async sendAnnouncement(
    userId: string,
    role: string | undefined,
    payload: { title: string; body: string }
  ) {
    const faculty = await requireDeanFaculty(userId, role);
    const studentIds = await listStudentUserIdsInFaculty(faculty);
    const title = payload.title.trim();
    const body = payload.body.trim();

    let sent = 0;
    if (studentIds.length > 0) {
      const rows = studentIds.map((studentId) => ({
        user_id: studentId,
        title,
        body,
        notification_type: 'announcement',
        payload: { faculty, sender_role: 'dean_of_faculty', dean_user_id: userId }
      }));

      const { error } = await supabaseAdmin.from('notifications').insert(rows);
      if (error) throw new ApiError(500, 'Failed to send announcement.', error);
      sent = rows.length;
    }

    const { data: record, error: historyError } = await supabaseAdmin
      .from('faculty_announcements')
      .insert({
        dean_user_id: userId,
        faculty,
        title,
        body,
        sent_count: sent
      })
      .select('*')
      .single();

    if (historyError) {
      throw new ApiError(500, 'Failed to record announcement.', historyError);
    }

    return { faculty, sent, announcement: record };
  }
}

export const deanService = new DeanService();
