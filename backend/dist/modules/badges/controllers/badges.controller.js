import { badgesService } from '../services/badges.service.js';
export class BadgesController {
    async listDefinitions(_req, res) {
        const data = await badgesService.listDefinitions();
        res.json({ message: 'Badge catalog fetched.', data });
    }
}
export const badgesController = new BadgesController();
