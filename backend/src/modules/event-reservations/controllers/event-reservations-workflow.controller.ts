import type { Request, Response } from 'express';
import { eventReservationsWorkflowService } from '../services/event-reservations-workflow.service.js';

export class EventReservationsWorkflowController {
  async reserve(req: Request, res: Response) {
    const { event_id } = req.body as { event_id: string };
    const data = await eventReservationsWorkflowService.reserve(event_id, req.authUser!.id);
    res.status(201).json({ message: 'Event reserved successfully.', data });
  }

  async join(req: Request, res: Response) {
    const { join_token } = req.body as { join_token: string };
    const data = await eventReservationsWorkflowService.reserveByJoinToken(
      join_token,
      req.authUser!.id
    );
    res.status(201).json({ message: 'Event reserved successfully.', data });
  }

  async previewJoin(req: Request, res: Response) {
    const data = await eventReservationsWorkflowService.findEventByJoinToken(
      req.params.token as string
    );
    res.json({ message: 'Event fetched.', data });
  }

  async checkIn(req: Request, res: Response) {
    const { qr_token } = req.body as { qr_token: string };
    const data = await eventReservationsWorkflowService.checkInByQrToken(
      qr_token,
      req.authUser!.id,
      req.authUser?.role
    );
    res.json({ message: 'Checked in successfully.', data });
  }

  async listMine(req: Request, res: Response) {
    const data = await eventReservationsWorkflowService.listMine(req.authUser!.id);
    res.json({ message: 'Reservations fetched successfully.', data });
  }

  async listAttendees(req: Request, res: Response) {
    const data = await eventReservationsWorkflowService.listEventAttendees(
      req.params.eventId as string,
      req.authUser!.id,
      req.authUser?.role
    );
    res.json({ message: 'Event attendees fetched successfully.', data });
  }
}

export const eventReservationsWorkflowController = new EventReservationsWorkflowController();
