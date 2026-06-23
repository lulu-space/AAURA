import { eventsWorkflowService } from '../services/events-workflow.service.js';
export class EventsWorkflowController {
    async analytics(req, res) {
        const data = await eventsWorkflowService.getEventAnalytics(req.params.id, req.authUser.id, req.authUser?.role);
        res.json({ message: 'Event analytics fetched successfully.', data });
    }
    async organizerDashboard(req, res) {
        const data = await eventsWorkflowService.getOrganizerDashboard(req.authUser.id);
        res.json({ message: 'Organizer dashboard fetched successfully.', data });
    }
    async predictSuccess(req, res) {
        const data = await eventsWorkflowService.predictSuccess(req.params.id, req.authUser.id, req.authUser?.role, req.body);
        res.json({ message: 'Event success prediction completed.', data });
    }
    async predictDraft(req, res) {
        const data = await eventsWorkflowService.predictDraft(req.authUser?.role, req.body);
        res.json({ message: 'Draft event prediction completed.', data });
    }
}
export const eventsWorkflowController = new EventsWorkflowController();
