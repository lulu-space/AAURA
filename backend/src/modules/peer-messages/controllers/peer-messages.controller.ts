import type { Request, Response } from 'express';
import { peerMessagesService } from '../services/peer-messages.service.js';

export class PeerMessagesController {
  async inbox(req: Request, res: Response) {
    const data = await peerMessagesService.listInbox(req.authUser!.id);
    res.json({ message: 'Inbox fetched.', data });
  }

  async list(req: Request, res: Response) {
    const otherUserId = req.query.user_id as string;
    const data = await peerMessagesService.listConversation(req.authUser!.id, otherUserId);
    res.json({ message: 'Messages fetched.', data });
  }

  async markRead(req: Request, res: Response) {
    const { user_id } = req.body as { user_id: string };
    const data = await peerMessagesService.markConversationRead(req.authUser!.id, user_id);
    res.json({ message: 'Conversation marked read.', data });
  }

  async send(req: Request, res: Response) {
    const { recipient_user_id, body } = req.body as {
      recipient_user_id: string;
      body: string;
    };
    const data = await peerMessagesService.send(req.authUser!.id, recipient_user_id, body);
    res.status(201).json({ message: 'Message sent.', data });
  }
}

export const peerMessagesController = new PeerMessagesController();
