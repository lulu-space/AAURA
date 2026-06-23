import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
export class ClubMessagesService {
    async assertMember(clubId, userId) {
        const { data, error } = await supabaseAdmin
            .from('club_membership')
            .select('id')
            .eq('club_id', clubId)
            .eq('user_id', userId)
            .maybeSingle();
        if (error)
            throw new ApiError(500, 'Failed to verify club membership.', error);
        if (!data)
            throw new ApiError(403, 'Join the club to access this channel.');
    }
    async list(clubId, channelId, userId) {
        await this.assertMember(clubId, userId);
        const { data, error } = await supabaseAdmin
            .from('club_messages')
            .select('*, users(full_name, role)')
            .eq('club_id', clubId)
            .eq('channel_id', channelId)
            .order('created_at', { ascending: true })
            .limit(200);
        if (error)
            throw new ApiError(500, 'Failed to fetch club messages.', error);
        return data;
    }
    async send(clubId, channelId, userId, body) {
        await this.assertMember(clubId, userId);
        const { data, error } = await supabaseAdmin
            .from('club_messages')
            .insert({
            club_id: clubId,
            channel_id: channelId,
            author_user_id: userId,
            body: body.trim()
        })
            .select('*, users(full_name, role)')
            .single();
        if (error)
            throw new ApiError(500, 'Failed to send message.', error);
        return data;
    }
}
export const clubMessagesService = new ClubMessagesService();
