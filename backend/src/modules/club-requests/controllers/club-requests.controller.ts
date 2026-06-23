import type { Request, Response } from 'express';
import { clubRequestsService } from '../services/club-requests.service.js';

export class ClubRequestsController {
  async eligibility(req: Request, res: Response) {
    const data = await clubRequestsService.checkEligibility(req.authUser!.id);
    res.json({ message: 'Club request eligibility checked.', data });
  }

  async create(req: Request, res: Response) {
    const data = await clubRequestsService.create(req.authUser!.id, req.body);
    res.status(201).json({ message: 'Club request submitted.', data });
  }

  async listMine(req: Request, res: Response) {
    const data = await clubRequestsService.listMine(req.authUser!.id);
    res.json({ message: 'Your club requests fetched.', data });
  }

  async listPending(_req: Request, res: Response) {
    const data = await clubRequestsService.listPending();
    res.json({ message: 'Pending club requests fetched.', data });
  }

  async listAll(_req: Request, res: Response) {
    const data = await clubRequestsService.listAll();
    res.json({ message: 'Club requests fetched.', data });
  }

  async approve(req: Request, res: Response) {
    const { review_note } = req.body as { review_note?: string };
    const data = await clubRequestsService.approve(
      req.params.id as string,
      req.authUser!.id,
      review_note
    );
    res.json({ message: 'Club request approved.', data });
  }

  async reject(req: Request, res: Response) {
    const { review_note } = req.body as { review_note?: string };
    const data = await clubRequestsService.reject(
      req.params.id as string,
      req.authUser!.id,
      review_note
    );
    res.json({ message: 'Club request rejected.', data });
  }

  async revoke(req: Request, res: Response) {
    const { review_note } = req.body as { review_note?: string };
    const data = await clubRequestsService.revoke(
      req.params.id as string,
      req.authUser!.id,
      review_note
    );
    res.json({ message: 'Club access revoked.', data });
  }
}

export const clubRequestsController = new ClubRequestsController();
