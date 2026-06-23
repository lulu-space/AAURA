import type { Request, Response } from 'express';
import { connectionsService } from '../services/connections.service.js';

export class ConnectionsController {
  async suggestions(req: Request, res: Response) {
    const data = await connectionsService.listSuggestions(req.authUser!.id);
    res.json({ message: 'Connection suggestions fetched.', data });
  }

  async listMine(req: Request, res: Response) {
    const data = await connectionsService.listMine(req.authUser!.id);
    res.json({ message: 'Connections fetched.', data });
  }

  async connect(req: Request, res: Response) {
    const { user_id } = req.body as { user_id: string };
    const data = await connectionsService.connect(req.authUser!.id, user_id);
    res.status(201).json({ message: 'Connected.', data });
  }

  async disconnect(req: Request, res: Response) {
    const targetUserId = req.params.userId as string;
    const data = await connectionsService.disconnect(req.authUser!.id, targetUserId);
    res.json({ message: 'Connection removed.', data });
  }
}

export const connectionsController = new ConnectionsController();
