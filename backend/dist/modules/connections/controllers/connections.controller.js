import { connectionsService } from '../services/connections.service.js';
export class ConnectionsController {
    async suggestions(req, res) {
        const data = await connectionsService.listSuggestions(req.authUser.id);
        res.json({ message: 'Connection suggestions fetched.', data });
    }
    async listMine(req, res) {
        const data = await connectionsService.listMine(req.authUser.id);
        res.json({ message: 'Connections fetched.', data });
    }
    async connect(req, res) {
        const { user_id } = req.body;
        const data = await connectionsService.connect(req.authUser.id, user_id);
        res.status(201).json({ message: 'Connected.', data });
    }
    async disconnect(req, res) {
        const targetUserId = req.params.userId;
        const data = await connectionsService.disconnect(req.authUser.id, targetUserId);
        res.json({ message: 'Connection removed.', data });
    }
}
export const connectionsController = new ConnectionsController();
