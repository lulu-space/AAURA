import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
export class PeerMessagesService {
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
    async assertConnected(userId, otherUserId) {
        if (userId === otherUserId) {
            throw new ApiError(400, 'Cannot message yourself.');
        }
        const connected = await this.connectedUserIds(userId);
        if (!connected.has(otherUserId)) {
            throw new ApiError(403, 'You can only message students you are connected with.');
        }
    }
    async senderDisplayName(userId) {
        const { data, error } = await supabaseAdmin
            .from('users')
            .select('full_name, email')
            .eq('id', userId)
            .maybeSingle();
        if (error)
            throw new ApiError(500, 'Failed to resolve sender name.', error);
        const fullName = data?.full_name?.trim();
        if (fullName)
            return fullName;
        const email = data?.email ?? '';
        return email.split('@')[0] || 'A student';
    }
    peerIdFor(userId, message) {
        return message.sender_user_id === userId
            ? message.recipient_user_id
            : message.sender_user_id;
    }
    async listInbox(userId) {
        const connectedIds = await this.connectedUserIds(userId);
        if (connectedIds.size === 0)
            return [];
        const { data: messages, error } = await supabaseAdmin
            .from('peer_direct_messages')
            .select('id, sender_user_id, recipient_user_id, body, created_at')
            .or(`sender_user_id.eq.${userId},recipient_user_id.eq.${userId}`)
            .order('created_at', { ascending: true })
            .limit(1000);
        if (error)
            throw new ApiError(500, 'Failed to fetch inbox.', error);
        const { data: reads, error: readsError } = await supabaseAdmin
            .from('peer_direct_message_reads')
            .select('peer_user_id, last_read_at')
            .eq('user_id', userId);
        if (readsError)
            throw new ApiError(500, 'Failed to fetch read state.', readsError);
        const readMap = new Map();
        for (const row of reads ?? []) {
            readMap.set(row.peer_user_id, row.last_read_at);
        }
        const grouped = new Map();
        for (const row of (messages ?? [])) {
            const peerId = this.peerIdFor(userId, row);
            if (!connectedIds.has(peerId))
                continue;
            const list = grouped.get(peerId) ?? [];
            list.push(row);
            grouped.set(peerId, list);
        }
        if (grouped.size === 0)
            return [];
        const peerIds = [...grouped.keys()];
        const { data: peers, error: peersError } = await supabaseAdmin
            .from('users')
            .select('id, full_name, email, students(major, academic_year)')
            .in('id', peerIds);
        if (peersError)
            throw new ApiError(500, 'Failed to fetch peer profiles.', peersError);
        const peerMap = new Map();
        for (const peer of peers ?? []) {
            peerMap.set(peer.id, peer);
        }
        const inbox = peerIds.map((peerId) => {
            const thread = grouped.get(peerId) ?? [];
            const last = thread[thread.length - 1];
            const lastReadAt = readMap.get(peerId);
            const lastReadMs = lastReadAt ? Date.parse(lastReadAt) : 0;
            const unreadCount = thread.filter((message) => message.recipient_user_id === userId &&
                Date.parse(message.created_at) > lastReadMs).length;
            const peer = peerMap.get(peerId);
            const students = peer?.students;
            const email = peer?.email ?? '';
            const fullName = peer?.full_name?.trim();
            return {
                peer_user_id: peerId,
                full_name: fullName || email.split('@')[0] || 'Student',
                major: students?.major ?? null,
                academic_year: students?.academic_year ?? null,
                last_message_id: last.id,
                last_message_body: last.body,
                last_message_at: last.created_at,
                last_sender_user_id: last.sender_user_id,
                unread_count: unreadCount
            };
        });
        inbox.sort((a, b) => Date.parse(b.last_message_at) - Date.parse(a.last_message_at));
        return inbox;
    }
    async listConversation(userId, otherUserId) {
        await this.assertConnected(userId, otherUserId);
        const { data, error } = await supabaseAdmin
            .from('peer_direct_messages')
            .select('id, sender_user_id, recipient_user_id, body, created_at')
            .or(`and(sender_user_id.eq.${userId},recipient_user_id.eq.${otherUserId}),and(sender_user_id.eq.${otherUserId},recipient_user_id.eq.${userId})`)
            .order('created_at', { ascending: true })
            .limit(200);
        if (error)
            throw new ApiError(500, 'Failed to fetch messages.', error);
        return data ?? [];
    }
    async markConversationRead(userId, otherUserId) {
        await this.assertConnected(userId, otherUserId);
        const now = new Date().toISOString();
        const { error } = await supabaseAdmin.from('peer_direct_message_reads').upsert({
            user_id: userId,
            peer_user_id: otherUserId,
            last_read_at: now
        }, { onConflict: 'user_id,peer_user_id' });
        if (error)
            throw new ApiError(500, 'Failed to mark conversation read.', error);
        const { error: notifyError } = await supabaseAdmin
            .from('notifications')
            .update({ is_read: true })
            .eq('user_id', userId)
            .eq('notification_type', 'message')
            .filter('payload->>peer_user_id', 'eq', otherUserId);
        if (notifyError) {
            throw new ApiError(500, 'Failed to mark message notifications read.', notifyError);
        }
        return { peer_user_id: otherUserId, last_read_at: now };
    }
    async send(userId, recipientUserId, body) {
        await this.assertConnected(userId, recipientUserId);
        const trimmed = body.trim();
        const { data, error } = await supabaseAdmin
            .from('peer_direct_messages')
            .insert({
            sender_user_id: userId,
            recipient_user_id: recipientUserId,
            body: trimmed
        })
            .select('id, sender_user_id, recipient_user_id, body, created_at')
            .single();
        if (error)
            throw new ApiError(500, 'Failed to send message.', error);
        const senderName = await this.senderDisplayName(userId);
        const preview = trimmed.length > 120 ? `${trimmed.slice(0, 117).trimEnd()}…` : trimmed;
        const { error: notifyError } = await supabaseAdmin.from('notifications').insert({
            user_id: recipientUserId,
            title: `New message from ${senderName}`,
            body: preview,
            notification_type: 'message',
            is_read: false,
            payload: {
                peer_user_id: userId,
                message_id: data.id
            }
        });
        if (notifyError) {
            console.warn('Message sent but notification failed:', notifyError.message);
        }
        return data;
    }
}
export const peerMessagesService = new PeerMessagesService();
