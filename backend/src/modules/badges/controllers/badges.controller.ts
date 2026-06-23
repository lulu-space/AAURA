import type { Request, Response } from 'express';
import { badgesService } from '../services/badges.service.js';

export class BadgesController {
  async listDefinitions(_req: Request, res: Response) {
    const data = await badgesService.listDefinitions();
    res.json({ message: 'Badge catalog fetched.', data });
  }
}

export const badgesController = new BadgesController();
