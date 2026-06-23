import type { Request, Response } from 'express';
import { CrudController } from '../../../shared/utils/crud-controller.js';
import { eventsMutationService } from '../services/events-mutation.service.js';
import { eventsService } from '../services/events.service.js';

export class EventsController extends CrudController {
  constructor() {
    super(eventsService, 'Events');
  }

  async list(req: Request, res: Response) {
    const data = await eventsMutationService.listForUser(
      req.authUser!.id,
      req.authUser?.role
    );
    res.json({ message: 'Events fetched successfully.', data });
  }

  async getById(req: Request, res: Response) {
    const data = await eventsMutationService.getByIdForUser(
      req.params.id as string,
      req.authUser!.id,
      req.authUser?.role
    );
    res.json({ message: 'Events fetched successfully.', data });
  }

  async create(req: Request, res: Response) {
    const data = await eventsMutationService.create(
      req.authUser!.id,
      req.authUser?.role,
      req.body
    );
    res.status(201).json({ message: 'Events created successfully.', data });
  }

  async update(req: Request, res: Response) {
    const data = await eventsMutationService.update(
      req.params.id as string,
      req.authUser!.id,
      req.authUser?.role,
      req.body
    );
    res.json({ message: 'Events updated successfully.', data });
  }
}

export const eventsController = new EventsController();
