import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';

const DEFAULT_SETTINGS: Record<string, Record<string, unknown>> = {
  ai_settings: {
    recommendation_weight: 0.65,
    prediction_threshold: 0.55,
    interest_match_weight: 0.4
  },
  points_rules: {
    event_check_in_points: 10,
    volunteer_hour_points: 5,
    club_join_points: 3
  },
  event_categories: {
    categories: ['learn', 'serve', 'connect', 'explore']
  }
};

async function writeAuditLog(
  actorId: string,
  action: string,
  metadata: Record<string, unknown>,
  resource = 'admin',
  resourceId?: string
) {
  await supabaseAdmin.from('system_logs').insert({
    actor_user_id: actorId,
    action,
    resource,
    resource_id: resourceId ?? null,
    metadata
  });
}

export class AdminService {
  async getDashboard() {
    const [
      users,
      suspended,
      events,
      clubs,
      volunteering,
      pendingVolunteer,
      pendingEvents,
      pendingClubs
    ] = await Promise.all([
      supabaseAdmin.from('users').select('id', { count: 'exact', head: true }),
      supabaseAdmin
        .from('users')
        .select('id', { count: 'exact', head: true })
        .eq('is_suspended', true),
      supabaseAdmin.from('events').select('id', { count: 'exact', head: true }),
      supabaseAdmin.from('clubs').select('id', { count: 'exact', head: true }),
      supabaseAdmin.from('volunteering_records').select('id', { count: 'exact', head: true }),
      supabaseAdmin
        .from('volunteering_records')
        .select('id', { count: 'exact', head: true })
        .eq('status', 'pending'),
      supabaseAdmin
        .from('events')
        .select('id', { count: 'exact', head: true })
        .eq('is_approved', false)
        .neq('status', 'cancelled'),
      supabaseAdmin
        .from('club_requests')
        .select('id', { count: 'exact', head: true })
        .eq('status', 'pending')
    ]);

    return {
      users: users.count ?? 0,
      suspended_users: suspended.count ?? 0,
      events: events.count ?? 0,
      clubs: clubs.count ?? 0,
      volunteering_records: volunteering.count ?? 0,
      pending_volunteer_reviews: pendingVolunteer.count ?? 0,
      pending_event_reviews: pendingEvents.count ?? 0,
      pending_club_requests: pendingClubs.count ?? 0
    };
  }

  async listUsers() {
    const { data, error } = await supabaseAdmin
      .from('users')
      .select('id, email, full_name, role, is_suspended, assigned_faculty, created_at')
      .order('created_at', { ascending: false });

    if (error) throw new ApiError(500, 'Failed to fetch users.', error);
    return data;
  }

  async updateUser(
    actorId: string,
    userId: string,
    payload: {
      role?: string;
      is_suspended?: boolean;
      full_name?: string;
      assigned_faculty?: string | null;
    }
  ) {
    const { data, error } = await supabaseAdmin
      .from('users')
      .update(payload)
      .eq('id', userId)
      .select('id, email, full_name, role, is_suspended, assigned_faculty, created_at')
      .single();

    if (error) throw new ApiError(500, 'Failed to update user.', error);

    await writeAuditLog(actorId, 'admin.user.update', { user_id: userId, ...payload });
    return data;
  }

  async getContentOverview() {
    const eventSelect =
      'id, title, status, organizer_id, created_at, is_hidden';
    const clubSelect = 'id, name, is_active, organizer_id, created_at';
    const postSelect = 'id, club_id, title, body, is_hidden, created_at';
    const messageSelect =
      'id, club_id, channel_id, body, is_hidden, author_user_id, created_at';

    const [events, clubs, posts, messages, hiddenPosts, hiddenMessages] =
      await Promise.all([
        this.loadContentRows('events', eventSelect, 'created_at'),
        this.loadContentRows('clubs', clubSelect, 'created_at'),
        this.loadContentRows('club_activity_posts', postSelect, 'created_at'),
        this.loadContentRows('club_messages', messageSelect, 'created_at'),
        this.countHiddenRows('club_activity_posts'),
        this.countHiddenRows('club_messages')
      ]);

    return {
      events,
      clubs,
      posts,
      messages,
      hidden_posts: hiddenPosts,
      hidden_messages: hiddenMessages
    };
  }

  private async loadContentRows(
    table: 'events' | 'clubs' | 'club_activity_posts' | 'club_messages',
    columns: string,
    orderColumn: string
  ) {
    const { data, error } = await supabaseAdmin
      .from(table)
      .select(columns)
      .order(orderColumn, { ascending: false })
      .limit(20);

    if (error) {
      const { data: fallback, error: fallbackError } = await supabaseAdmin
        .from(table)
        .select('*')
        .order(orderColumn, { ascending: false })
        .limit(20);

      if (fallbackError) {
        throw new ApiError(500, `Failed to load ${table}.`, fallbackError);
      }
      return fallback ?? [];
    }

    return data ?? [];
  }

  private async countHiddenRows(
    table: 'club_activity_posts' | 'club_messages'
  ): Promise<number> {
    const { count, error } = await supabaseAdmin
      .from(table)
      .select('id', { count: 'exact', head: true })
      .eq('is_hidden', true);

    if (error) return 0;
    return count ?? 0;
  }

  async moderateEvent(actorId: string, eventId: string, action: 'hide' | 'unhide' | 'cancel') {
    const patch =
      action === 'cancel'
        ? { status: 'cancelled', is_hidden: true }
        : { is_hidden: action === 'hide' };

    const { data, error } = await supabaseAdmin
      .from('events')
      .update(patch)
      .eq('id', eventId)
      .select('*')
      .single();

    if (error) throw new ApiError(500, 'Failed to moderate event.', error);
    await writeAuditLog(actorId, 'admin.content.event', { event_id: eventId, action });
    return data;
  }

  async moderateClub(actorId: string, clubId: string, action: 'deactivate' | 'reactivate' | 'hide_posts') {
    if (action === 'hide_posts') {
      await supabaseAdmin
        .from('club_activity_posts')
        .update({ is_hidden: true })
        .eq('club_id', clubId);
      await writeAuditLog(actorId, 'admin.content.club.hide_posts', { club_id: clubId });
      return { club_id: clubId, action };
    }

    const { data, error } = await supabaseAdmin
      .from('clubs')
      .update({ is_active: action === 'reactivate' })
      .eq('id', clubId)
      .select('*')
      .single();

    if (error) throw new ApiError(500, 'Failed to moderate club.', error);
    await writeAuditLog(actorId, 'admin.content.club', { club_id: clubId, action });
    return data;
  }

  async moderatePost(actorId: string, postId: string, hidden: boolean) {
    const { data, error } = await supabaseAdmin
      .from('club_activity_posts')
      .update({ is_hidden: hidden })
      .eq('id', postId)
      .select('*')
      .single();

    if (error) throw new ApiError(500, 'Failed to moderate post.', error);
    await writeAuditLog(actorId, 'admin.content.post', { post_id: postId, hidden });
    return data;
  }

  async moderateMessage(actorId: string, messageId: string, hidden: boolean) {
    const { data, error } = await supabaseAdmin
      .from('club_messages')
      .update({ is_hidden: hidden })
      .eq('id', messageId)
      .select('*')
      .single();

    if (error) throw new ApiError(500, 'Failed to moderate message.', error);
    await writeAuditLog(actorId, 'admin.content.message', { message_id: messageId, hidden });
    return data;
  }

  async getAnalytics() {
    const [reservations, volunteerApproved, gamification, registrations] = await Promise.all([
      supabaseAdmin
        .from('event_reservations')
        .select('reservation_status'),
      supabaseAdmin
        .from('volunteering_records')
        .select('hours')
        .eq('status', 'approved'),
      supabaseAdmin.from('gamification').select('points'),
      supabaseAdmin.from('users').select('role')
    ]);

    const reservationRows = reservations.data ?? [];
    const checkIns = reservationRows.filter((r) => r.reservation_status === 'checked_in').length;
    const enrollments = reservationRows.filter((r) => r.reservation_status !== 'cancelled').length;
    const approvedHours = (volunteerApproved.data ?? []).reduce(
      (sum, row) => sum + Number(row.hours ?? 0),
      0
    );
    const totalPoints = (gamification.data ?? []).reduce(
      (sum, row) => sum + Number(row.points ?? 0),
      0
    );

    const roleCounts = new Map<string, number>();
    for (const row of registrations.data ?? []) {
      const role = String(row.role ?? 'unknown');
      roleCounts.set(role, (roleCounts.get(role) ?? 0) + 1);
    }

    return {
      engagement: {
        event_enrollments: enrollments,
        event_check_ins: checkIns
      },
      volunteering: {
        approved_hours: approvedHours,
        approved_records: volunteerApproved.data?.length ?? 0
      },
      gamification: {
        total_points_awarded: totalPoints,
        profiles: gamification.data?.length ?? 0
      },
      users_by_role: Object.fromEntries(roleCounts.entries())
    };
  }

  async listVolunteeringRecords() {
    const { data, error } = await supabaseAdmin
      .from('volunteering_records')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(100);

    if (error) throw new ApiError(500, 'Failed to fetch volunteering records.', error);
    return data;
  }

  async getSettings() {
    const { data, error } = await supabaseAdmin.from('platform_settings').select('key, value, updated_at');
    if (error) throw new ApiError(500, 'Failed to load settings.', error);

    const merged = { ...DEFAULT_SETTINGS };
    for (const row of data ?? []) {
      merged[row.key as string] = row.value as Record<string, unknown>;
    }
    return merged;
  }

  async updateSettings(actorId: string, key: string, value: Record<string, unknown>) {
    if (!DEFAULT_SETTINGS[key]) {
      throw new ApiError(400, 'Unknown settings key.');
    }

    const { data, error } = await supabaseAdmin
      .from('platform_settings')
      .upsert(
        { key, value, updated_at: new Date().toISOString(), updated_by: actorId },
        { onConflict: 'key' }
      )
      .select('key, value, updated_at')
      .single();

    if (error) throw new ApiError(500, 'Failed to update settings.', error);
    await writeAuditLog(actorId, 'admin.settings.update', { key, value });
    return data;
  }

  async listBadges() {
    const { data, error } = await supabaseAdmin
      .from('badge_definitions')
      .select('*')
      .order('sort_order');

    if (error) throw new ApiError(500, 'Failed to load badges.', error);
    return data;
  }

  async updateBadge(actorId: string, badgeId: string, payload: Record<string, unknown>) {
    const { data, error } = await supabaseAdmin
      .from('badge_definitions')
      .update(payload)
      .eq('id', badgeId)
      .select('*')
      .single();

    if (error) throw new ApiError(500, 'Failed to update badge.', error);
    await writeAuditLog(actorId, 'admin.badges.update', { badge_id: badgeId, ...payload });
    return data;
  }

  async listAuditLogs() {
    const { data, error } = await supabaseAdmin
      .from('system_logs')
      .select('*')
      .order('created_at', { ascending: false })
      .limit(100);

    if (error) throw new ApiError(500, 'Failed to load audit logs.', error);
    return data;
  }

  async sendAnnouncement(actorId: string, payload: { title: string; body: string }) {
    const { data: users, error } = await supabaseAdmin
      .from('users')
      .select('id')
      .eq('is_suspended', false);

    if (error) throw new ApiError(500, 'Failed to load users for announcement.', error);

    const rows = (users ?? []).map((user) => ({
      user_id: user.id,
      title: payload.title.trim(),
      body: payload.body.trim(),
      notification_type: 'announcement',
      payload: { sender_role: 'admin' }
    }));

    if (rows.length === 0) return { sent: 0 };

    const { error: insertError } = await supabaseAdmin.from('notifications').insert(rows);
    if (insertError) throw new ApiError(500, 'Failed to send announcement.', insertError);

    await writeAuditLog(actorId, 'admin.announcement', {
      title: payload.title,
      recipients: rows.length
    });

    return { sent: rows.length };
  }
}

export const adminService = new AdminService();
