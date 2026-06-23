import { eventsReviewService } from '../services/events-review.service.js';
export class EventsReviewController {
    async listAll(_req, res) {
        const data = await eventsReviewService.listAll();
        res.json({ message: 'Event reviews fetched successfully.', data });
    }
    async listPending(_req, res) {
        const data = await eventsReviewService.listPending();
        res.json({ message: 'Pending event reviews fetched successfully.', data });
    }
    async approve(req, res) {
        const data = await eventsReviewService.approve(req.params.id, req.authUser.id, req.body.approval_note);
        res.json({ message: 'Event approved successfully.', data });
    }
    async reject(req, res) {
        const data = await eventsReviewService.reject(req.params.id, req.authUser.id, req.body.approval_note);
        res.json({ message: 'Event rejected successfully.', data });
    }
    async withdraw(req, res) {
        const data = await eventsReviewService.withdraw(req.params.id, req.authUser.id, req.body.approval_note);
        res.json({ message: 'Event approval withdrawn successfully.', data });
    }
}
export const eventsReviewController = new EventsReviewController();
