import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
export class ConnectionsService {
    async connectedUserIds(userId) {
        const { data, error } = await supabaseAdmin
            .from('peer_connections')
            .select('requester_id, addressee_id')
            .eq('status', 'accepted')
            .or(`requester_id.eq.${userId},addressee_id.eq.${userId}`);
        if (error)
            throw new ApiError(500, 'Failed to fetch connections.', error);
        const ids = new Set();
        for (const row of data ?? []) {
            if (row.requester_id !== userId)
                ids.add(row.requester_id);
            if (row.addressee_id !== userId)
                ids.add(row.addressee_id);
        }
        return ids;
    }
    mapPeer(row) {
        const students = row.students;
        const profile = row.student_profiles;
        const email = row.email;
        return {
            user_id: row.id,
            full_name: row.full_name?.trim() || email.split('@')[0],
            email,
            major: students?.major ?? null,
            academic_year: students?.academic_year ?? null,
            interests: profile?.interests ?? []
        };
    }
    async listSuggestions(userId, limit = 24) {
        const connected = await this.connectedUserIds(userId);
        connected.add(userId);
        const { data, error } = await supabaseAdmin
            .from('users')
            .select('id, full_name, email, students(major, academic_year), student_profiles(interests)')
            .eq('role', 'student')
            .limit(Math.min(limit + connected.size, 60));
        if (error)
            throw new ApiError(500, 'Failed to fetch student suggestions.', error);
        return (data ?? [])
            .filter((row) => !connected.has(row.id))
            .slice(0, limit)
            .map((row) => this.mapPeer(row));
    }
    async listMine(userId) {
        const connected = await this.connectedUserIds(userId);
        if (connected.size === 0)
            return [];
        const { data, error } = await supabaseAdmin
            .from('users')
            .select('id, full_name, email, students(major, academic_year), student_profiles(interests)')
            .in('id', [...connected]);
        if (error)
            throw new ApiError(500, 'Failed to fetch connections.', error);
        return (data ?? []).map((row) => this.mapPeer(row));
    }
    async connect(userId, targetUserId) {
        if (userId === targetUserId) {
            throw new ApiError(400, 'Cannot connect with yourself.');
        }
        const { data: target, error: targetError } = await supabaseAdmin
            .from('users')
            .select('id')
            .eq('id', targetUserId)
            .single();
        if (targetError || !target) {
            throw new ApiError(404, 'User not found.', targetError);
        }
        const { data, error } = await supabaseAdmin
            .from('peer_connections')
            .upsert({
            requester_id: userId,
            addressee_id: targetUserId,
            status: 'accepted'
        }, { onConflict: 'requester_id,addressee_id' })
            .select('*')
            .single();
        if (error)
            throw new ApiError(500, 'Failed to create connection.', error);
        return data;
    }
    async disconnect(userId, targetUserId) {
        const { error } = await supabaseAdmin
            .from('peer_connections')
            .delete()
            .or(`and(requester_id.eq.${userId},addressee_id.eq.${targetUserId}),and(requester_id.eq.${targetUserId},addressee_id.eq.${userId})`);
        if (error)
            throw new ApiError(500, 'Failed to remove connection.', error);
        return { removed: true };
    }
}
export const connectionsService = new ConnectionsService();
