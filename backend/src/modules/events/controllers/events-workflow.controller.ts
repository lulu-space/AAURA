import type { Request, Response } from 'express';
import { eventsWorkflowService } from '../services/events-workflow.service.js';

export class EventsWorkflowController {
  async analytics(req: Request, res: Response) {
    const data = await eventsWorkflowService.getEventAnalytics(
      req.params.id as string,
      req.authUser!.id,
      req.authUser?.role
    );
    res.json({ message: 'Event analytics fetched successfully.', data });
  }

  async organizerDashboard(req: Request, res: Response) {
    const data = await eventsWorkflowService.getOrganizerDashboard(req.authUser!.id);
    res.json({ message: 'Organizer dashboard fetched successfully.', data });
  }

  async predictSuccess(req: Request, res: Response) {
    const data = await eventsWorkflowService.predictSuccess(
      req.params.id as string,
      req.authUser!.id,
      req.authUser?.role,
      req.body
    );
    res.json({ message: 'Event success prediction completed.', data });
  }

  async predictDraft(req: Request, res: Response) {
    const data = await eventsWorkflowService.predictDraft(req.authUser?.role, req.body);
    res.json({ message: 'Draft event prediction completed.', data });
  }
}

export const eventsWorkflowController = new EventsWorkflowController();
