import { clubMessagesService } from '../services/club-messages.service.js';
export class ClubMessagesController {
    async list(req, res) {
        const clubId = req.query.club_id;
        const channelId = req.query.channel_id || 'general';
        const data = await clubMessagesService.list(clubId, channelId, req.authUser.id);
        res.json({ message: 'Club messages fetched.', data });
    }
    async send(req, res) {
        const { club_id, channel_id, body } = req.body;
        const data = await clubMessagesService.send(club_id, channel_id ?? 'general', req.authUser.id, body);
        res.status(201).json({ message: 'Message sent.', data });
    }
}
export const clubMessagesController = new ClubMessagesController();
