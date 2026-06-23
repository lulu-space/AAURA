import type { Request, Response } from 'express';
import { eventsReviewService } from '../services/events-review.service.js';

export class EventsReviewController {
  async listAll(_req: Request, res: Response) {
    const data = await eventsReviewService.listAll();
    res.json({ message: 'Event reviews fetched successfully.', data });
  }

  async listPending(_req: Request, res: Response) {
    const data = await eventsReviewService.listPending();
    res.json({ message: 'Pending event reviews fetched successfully.', data });
  }

  async approve(req: Request, res: Response) {
    const data = await eventsReviewService.approve(
      req.params.id as string,
      req.authUser!.id,
      req.body.approval_note
    );
    res.json({ message: 'Event approved successfully.', data });
  }

  async reject(req: Request, res: Response) {
    const data = await eventsReviewService.reject(
      req.params.id as string,
      req.authUser!.id,
      req.body.approval_note
    );
    res.json({ message: 'Event rejected successfully.', data });
  }

  async withdraw(req: Request, res: Response) {
    const data = await eventsReviewService.withdraw(
      req.params.id as string,
      req.authUser!.id,
      req.body.approval_note
    );
    res.json({ message: 'Event approval withdrawn successfully.', data });
  }
}

export const eventsReviewController = new EventsReviewController();
