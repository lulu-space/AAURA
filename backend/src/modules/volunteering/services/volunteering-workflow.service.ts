import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
import { bumpStudentSkillProgress } from '../../student-profiles/services/skill-progress.service.js';
const SELECT_WITH_STUDENT =
  '*, student:users!volunteering_records_user_id_fkey(full_name)';

type RecordRow = Record<string, unknown> & {
  student?: { full_name?: string | null } | null;
  user_id?: string;
};

function nameFromJoin(row: RecordRow) {
  const joined = row.student?.full_name?.trim();
  return joined ? joined : null;
}

async function attachStudentNames(rows: RecordRow[]) {
  const withJoin = rows.map((row) => {
    const { student, ...rest } = row;
    return { ...rest, student_name: nameFromJoin(row) };
  });

  const missingIds = [
    ...new Set(
      withJoin
        .filter((row) => !row.student_name && row.user_id)
        .map((row) => row.user_id as string)
    )
  ];
  if (missingIds.length === 0) return withJoin;

  const { data: users, error } = await supabaseAdmin
    .from('users')
    .select('id, full_name')
    .in('id', missingIds);

  if (error || !users) return withJoin;

  const byId = new Map(users.map((user) => [user.id, user.full_name?.trim() ?? null]));
  return withJoin.map((row) =>
    row.student_name
      ? row
      : { ...row, student_name: byId.get(row.user_id as string) ?? null }
  );
}

export class VolunteeringWorkflowService {
  async listPending() {
    const { data, error } = await supabaseAdmin
      .from('volunteering_records')
      .select(SELECT_WITH_STUDENT)
      .eq('status', 'pending')
      .order('created_at', { ascending: false });

    if (error) throw new ApiError(500, 'Failed to fetch pending records.', error);
    return attachStudentNames((data as RecordRow[] | null) ?? []);
  }

  /** All records (any status) for staff dashboards + office-wide hour totals. */
  async listAll() {
    const { data, error } = await supabaseAdmin
      .from('volunteering_records')
      .select(SELECT_WITH_STUDENT)
      .order('created_at', { ascending: false });

    if (error) throw new ApiError(500, 'Failed to fetch volunteering records.', error);
    return attachStudentNames((data as RecordRow[] | null) ?? []);
  }

  async approve(recordId: string, staffUserId: string, approvalNote?: string) {
    return this.setStatus(recordId, staffUserId, 'approved', approvalNote);
  }

  async reject(recordId: string, staffUserId: string, approvalNote?: string) {
    return this.setStatus(recordId, staffUserId, 'rejected', approvalNote);
  }

  async withdraw(recordId: string, staffUserId: string) {
    const { data: existing, error: fetchError } = await supabaseAdmin
      .from('volunteering_records')
      .select('id, status, user_id, hours, title')
      .eq('id', recordId)
      .single();

    if (fetchError || !existing) {
      throw new ApiError(404, 'Volunteering record not found.', fetchError);
    }

    if (existing.status === 'pending') {
      throw new ApiError(400, 'Record is already pending review.');
    }

    const { data, error } = await supabaseAdmin
      .from('volunteering_records')
      .update({
        status: 'pending',
        approved_by_staff_id: null,
        approval_note: null
      })
      .eq('id', recordId)
      .select(SELECT_WITH_STUDENT)
      .single();

    if (error) throw new ApiError(500, 'Failed to withdraw volunteering decision.', error);

    const [withName] = await attachStudentNames([data as RecordRow]);

    if (data.user_id) {
      const hours = Number(data.hours ?? 0);
      const title = String(data.title ?? 'Volunteer activity');
      await supabaseAdmin.from('notifications').insert({
        user_id: data.user_id,
        title: 'Volunteer hours under review again',
        body: `Your ${hours} h for "${title}" were sent back to pending review.`,
        notification_type: 'system',
        payload: { volunteering_record_id: recordId, status: 'pending' }
      });
    }

    return withName ?? data;
  }

  private async setStatus(
    recordId: string,
    staffUserId: string,
    status: 'approved' | 'rejected',
    approvalNote?: string
  ) {
    const { data: existing, error: fetchError } = await supabaseAdmin
      .from('volunteering_records')
      .select('id, status, user_id, hours, title')
      .eq('id', recordId)
      .single();

    if (fetchError || !existing) {
      throw new ApiError(404, 'Volunteering record not found.', fetchError);
    }

    if (existing.status !== 'pending') {
      throw new ApiError(400, `Record is already ${existing.status}.`);
    }

    const { data, error } = await supabaseAdmin
      .from('volunteering_records')
      .update({
        status,
        approved_by_staff_id: staffUserId,
        approval_note: approvalNote ?? null
      })
      .eq('id', recordId)
      .select(SELECT_WITH_STUDENT)
      .single();

    if (error) throw new ApiError(500, 'Failed to update volunteering record.', error);

    const [withName] = await attachStudentNames([data as RecordRow]);

    if (status === 'approved') {
      const hours = Number(data.hours ?? 0);
      const title = String(data.title ?? '');
      const isEnrollment =
        hours === 0 || title.toLowerCase().startsWith('enrollment:');
      if (!isEnrollment && hours > 0 && data.user_id) {
        const delta = Math.min(0.2, hours * 0.02);
        await bumpStudentSkillProgress(
          data.user_id as string,
          delta,
          `+${Math.round(delta * 100)}% from volunteer hours`
        ).catch(() => null);
      }
    }

    if (data.user_id) {
      const hours = Number(data.hours ?? 0);
      const title = String(data.title ?? 'Volunteer activity');
      const approved = status === 'approved';
      const note = approvalNote?.trim();
      await supabaseAdmin.from('notifications').insert({
        user_id: data.user_id,
        title: approved ? 'Volunteer hours approved' : 'Volunteer hours declined',
        body: approved
          ? note
            ? `Your ${hours} h for "${title}" were approved: ${note}`
            : `Your ${hours} h for "${title}" were approved.`
          : note
            ? `Your ${hours} h for "${title}" were declined: ${note}`
            : `Your ${hours} h for "${title}" were declined.`,
        notification_type: 'system',
        payload: { volunteering_record_id: recordId, status }
      });
    }

    return withName ?? data;
  }
}

export const volunteeringWorkflowService = new VolunteeringWorkflowService();
