import { clubsWorkflowService } from '../services/clubs-workflow.service.js';
export class ClubsWorkflowController {
    async detectInactive(_req, res) {
        const data = await clubsWorkflowService.detectInactiveClubs();
        res.json({ message: 'Dead club detection completed.', data });
    }
    async reactivate(req, res) {
        const data = await clubsWorkflowService.reactivateClub(req.params.id, req.authUser.id, req.authUser?.role);
        res.json({ message: 'Club reactivated.', data });
    }
    async monthlyReport(req, res) {
        const year = parseInt(String(req.query.year ?? new Date().getUTCFullYear()), 10);
        const month = parseInt(String(req.query.month ?? new Date().getUTCMonth() + 1), 10);
        const data = await clubsWorkflowService.getMonthlyReport(req.authUser.id, year, month);
        res.json({ message: 'Monthly club activity report.', data });
    }
    async listWithCounts(_req, res) {
        const data = await clubsWorkflowService.listWithCounts();
        res.json({ message: 'Clubs fetched.', data });
    }
    async listMembers(req, res) {
        const data = await clubsWorkflowService.listMembers(req.params.id, req.authUser.id);
        res.json({ message: 'Club members fetched.', data });
    }
    async activityFeed(req, res) {
        const limit = parseInt(String(req.query.limit ?? 20), 10);
        const data = await clubsWorkflowService.listActivityFeed(req.authUser.id, limit);
        res.json({ message: 'Club activity feed fetched.', data });
    }
}
export const clubsWorkflowController = new ClubsWorkflowController();
