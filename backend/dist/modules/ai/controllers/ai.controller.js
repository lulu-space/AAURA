import { proxyToAi } from '../services/ai-proxy.service.js';
function sendProxy(res, status, body) {
    return res.status(status).json(body);
}
export class AiController {
    async health(_req, res) {
        const { status, body } = await proxyToAi('/api/health');
        return sendProxy(res, status, body);
    }
    async predictEventSuccess(req, res) {
        const { status, body } = await proxyToAi('/api/predictions/event-success', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(req.body)
        });
        return sendProxy(res, status, body);
    }
    async shamsChat(req, res) {
        const { status, body } = await proxyToAi('/api/profiling/shams/chat', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(req.body)
        });
        return sendProxy(res, status, body);
    }
    async generateRecommendations(req, res) {
        const { status, body } = await proxyToAi('/api/recommendations/generate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(req.body)
        });
        return sendProxy(res, status, body);
    }
    async generateStudyPlan(req, res) {
        const { status, body } = await proxyToAi('/api/study-plans/generate', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(req.body)
        });
        return sendProxy(res, status, body);
    }
}
export const aiController = new AiController();
