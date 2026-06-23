import { deanService } from '../services/dean.service.js';
export class DeanController {
    async faculties(_req, res) {
        const data = await deanService.getFaculties();
        res.json({ message: 'Faculties fetched successfully.', data });
    }
    async dashboard(req, res) {
        const data = await deanService.getDashboard(req.authUser.id, req.authUser.role);
        res.json({ message: 'Dean dashboard fetched successfully.', data });
    }
    async events(req, res) {
        const data = await deanService.listEvents(req.authUser.id, req.authUser.role);
        res.json({ message: 'Faculty events fetched successfully.', data });
    }
    async clubs(req, res) {
        const data = await deanService.listClubs(req.authUser.id, req.authUser.role);
        res.json({ message: 'Faculty clubs fetched successfully.', data });
    }
    async insights(req, res) {
        const data = await deanService.getInsights(req.authUser.id, req.authUser.role);
        res.json({ message: 'Faculty insights fetched successfully.', data });
    }
    async report(req, res) {
        const type = req.params.type;
        const data = await deanService.generateReport(req.authUser.id, req.authUser.role, type);
        res.json({ message: 'Faculty report generated successfully.', data });
    }
    async announce(req, res) {
        const data = await deanService.sendAnnouncement(req.authUser.id, req.authUser.role, req.body);
        res.json({ message: 'Announcement sent successfully.', data });
    }
    async announcements(req, res) {
        const data = await deanService.listAnnouncements(req.authUser.id, req.authUser.role);
        res.json({ message: 'Announcements fetched successfully.', data });
    }
}
export const deanController = new DeanController();
