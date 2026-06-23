import { clubRequestsService } from '../services/club-requests.service.js';
export class ClubRequestsController {
    async eligibility(req, res) {
        const data = await clubRequestsService.checkEligibility(req.authUser.id);
        res.json({ message: 'Club request eligibility checked.', data });
    }
    async create(req, res) {
        const data = await clubRequestsService.create(req.authUser.id, req.body);
        res.status(201).json({ message: 'Club request submitted.', data });
    }
    async listMine(req, res) {
        const data = await clubRequestsService.listMine(req.authUser.id);
        res.json({ message: 'Your club requests fetched.', data });
    }
    async listPending(_req, res) {
        const data = await clubRequestsService.listPending();
        res.json({ message: 'Pending club requests fetched.', data });
    }
    async listAll(_req, res) {
        const data = await clubRequestsService.listAll();
        res.json({ message: 'Club requests fetched.', data });
    }
    async approve(req, res) {
        const { review_note } = req.body;
        const data = await clubRequestsService.approve(req.params.id, req.authUser.id, review_note);
        res.json({ message: 'Club request approved.', data });
    }
    async reject(req, res) {
        const { review_note } = req.body;
        const data = await clubRequestsService.reject(req.params.id, req.authUser.id, review_note);
        res.json({ message: 'Club request rejected.', data });
    }
    async revoke(req, res) {
        const { review_note } = req.body;
        const data = await clubRequestsService.revoke(req.params.id, req.authUser.id, review_note);
        res.json({ message: 'Club access revoked.', data });
    }
}
export const clubRequestsController = new ClubRequestsController();
