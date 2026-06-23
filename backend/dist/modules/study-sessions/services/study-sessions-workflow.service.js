import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
export class StudySessionsWorkflowService {
    /** Notify every enrolled member (except the host) about a schedule change. */
    async notifyMembers(sessionId, hostUserId, payload) {
        const { data: session, error: sessionError } = await supabaseAdmin
            .from('study_sessions')
            .select('id, host_user_id, title')
            .eq('id', sessionId)
            .maybeSingle();
        if (sessionError)
            throw new ApiError(500, sessionError.message);
        if (!session)
            throw new ApiError(404, 'Study session not found.');
        if (session.host_user_id !== hostUserId) {
            throw new ApiError(403, 'Only the session host can notify members.');
        }
        const { data: memberships, error: membershipError } = await supabaseAdmin
            .from('study_session_membership')
            .select('user_id')
            .eq('study_session_id', sessionId);
        if (membershipError)
            throw new ApiError(500, membershipError.message);
        const recipients = (memberships ?? [])
            .map((row) => row.user_id)
            .filter((userId) => userId !== hostUserId);
        if (recipients.length === 0) {
            return { notified: 0 };
        }
        const rows = recipients.map((userId) => ({
            user_id: userId,
            title: payload.title,
            body: payload.body,
            notification_type: 'study',
            is_read: false,
            payload: {
                study_session_id: sessionId,
                kind: payload.kind
            }
        }));
        const { error: notifyError } = await supabaseAdmin.from('notifications').insert(rows);
        if (notifyError)
            throw new ApiError(500, notifyError.message);
        return { notified: recipients.length };
    }
}
export const studySessionsWorkflowService = new StudySessionsWorkflowService();
