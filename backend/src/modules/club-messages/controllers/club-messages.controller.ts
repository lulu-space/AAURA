import type { Request, Response } from 'express';
import { clubMessagesService } from '../services/club-messages.service.js';

export class ClubMessagesController {
  async list(req: Request, res: Response) {
    const clubId = req.query.club_id as string;
    const channelId = (req.query.channel_id as string) || 'general';
    const data = await clubMessagesService.list(clubId, channelId, req.authUser!.id);
    res.json({ message: 'Club messages fetched.', data });
  }

  async send(req: Request, res: Response) {
    const { club_id, channel_id, body } = req.body as {
      club_id: string;
      channel_id?: string;
      body: string;
    };
    const data = await clubMessagesService.send(
      club_id,
      channel_id ?? 'general',
      req.authUser!.id,
      body
    );
    res.status(201).json({ message: 'Message sent.', data });
  }
}

export const clubMessagesController = new ClubMessagesController();
