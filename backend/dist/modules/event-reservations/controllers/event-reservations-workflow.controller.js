import { eventReservationsWorkflowService } from '../services/event-reservations-workflow.service.js';
export class EventReservationsWorkflowController {
    async reserve(req, res) {
        const { event_id } = req.body;
        const data = await eventReservationsWorkflowService.reserve(event_id, req.authUser.id);
        res.status(201).json({ message: 'Event reserved successfully.', data });
    }
    async checkIn(req, res) {
        const { qr_token } = req.body;
        const data = await eventReservationsWorkflowService.checkInByQrToken(qr_token, req.authUser.id, req.authUser?.role);
        res.json({ message: 'Checked in successfully.', data });
    }
    async listMine(req, res) {
        const data = await eventReservationsWorkflowService.listMine(req.authUser.id);
        res.json({ message: 'Reservations fetched successfully.', data });
    }
    async listAttendees(req, res) {
        const data = await eventReservationsWorkflowService.listEventAttendees(req.params.eventId, req.authUser.id, req.authUser?.role);
        res.json({ message: 'Event attendees fetched successfully.', data });
    }
}
export const eventReservationsWorkflowController = new EventReservationsWorkflowController();
