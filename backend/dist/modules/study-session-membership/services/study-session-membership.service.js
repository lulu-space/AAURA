import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
import { SupabaseCrudService } from '../../../shared/utils/supabase-crud.service.js';
export const studySessionMembershipService = new SupabaseCrudService('study_session_membership', '*', {
    ownerColumn: 'user_id',
    createRoles: ['student', 'club_organizer', 'admin'],
    restrictListToOwner: true,
    restrictGetToOwner: true
});
export class StudySessionMembershipWorkflowService {
    async join(studySessionId, userId) {
        const { data: session, error: sessionError } = await supabaseAdmin
            .from('study_sessions')
            .select('id, capacity')
            .eq('id', studySessionId)
            .single();
        if (sessionError || !session) {
            throw new ApiError(404, 'Study session not found.', sessionError);
        }
        const { count, error: countError } = await supabaseAdmin
            .from('study_session_membership')
            .select('id', { count: 'exact', head: true })
            .eq('study_session_id', studySessionId);
        if (countError) {
            throw new ApiError(500, 'Failed to check session capacity.', countError);
        }
        if ((count ?? 0) >= session.capacity) {
            throw new ApiError(409, 'Study session is full.');
        }
        const { data, error } = await supabaseAdmin
            .from('study_session_membership')
            .insert({
            study_session_id: studySessionId,
            user_id: userId
        })
            .select('*')
            .single();
        if (error) {
            if (error.code === '23505') {
                throw new ApiError(409, 'You already joined this study session.');
            }
            throw new ApiError(500, 'Failed to join study session.', error);
        }
        return data;
    }
    async listSessionMembers(studySessionId, actorUserId, actorRole) {
        const { data: session, error: sessionError } = await supabaseAdmin
            .from('study_sessions')
            .select('id, host_user_id')
            .eq('id', studySessionId)
            .single();
        if (sessionError || !session) {
            throw new ApiError(404, 'Study session not found.', sessionError);
        }
        const isHost = session.host_user_id === actorUserId;
        const isAdmin = actorRole === 'admin';
        if (!isHost && !isAdmin) {
            const { data: mine, error: mineError } = await supabaseAdmin
                .from('study_session_membership')
                .select('id')
                .eq('study_session_id', studySessionId)
                .eq('user_id', actorUserId)
                .maybeSingle();
            if (mineError)
                throw new ApiError(500, 'Failed to verify membership.', mineError);
            if (!mine) {
                throw new ApiError(403, 'Join this session to see who is attending.');
            }
        }
        const { data, error } = await supabaseAdmin
            .from('study_session_membership')
            .select('joined_at, users(id, full_name, email, students(major, academic_year))')
            .eq('study_session_id', studySessionId)
            .order('joined_at', { ascending: true });
        if (error)
            throw new ApiError(500, 'Failed to fetch session members.', error);
        return (data ?? []).map((row) => {
            const users = row.users;
            const student = Array.isArray(users?.students)
                ? users?.students[0]
                : users?.students;
            const email = users?.email ?? '';
            const userId = users?.id ?? '';
            return {
                user_id: userId,
                full_name: users?.full_name?.trim() || email.split('@')[0] || 'Student',
                major: student?.major ?? null,
                academic_year: student?.academic_year ?? null,
                is_host: userId === session.host_user_id,
                joined_at: row.joined_at
            };
        });
    }
}
export const studySessionMembershipWorkflowService = new StudySessionMembershipWorkflowService();
