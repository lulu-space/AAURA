import { profilingWorkflowService } from '../services/profiling-workflow.service.js';
export class ProfilingWorkflowController {
    async shamsChat(req, res) {
        const { message } = req.body;
        const data = await profilingWorkflowService.chatWithShams(req.authUser.id, message);
        res.json({ message: 'Shams draft updated. Review and confirm or regenerate.', data });
    }
    async getMyDraft(req, res) {
        const data = await profilingWorkflowService.getMyDraft(req.authUser.id);
        res.json({ message: 'Profile draft fetched.', data });
    }
    async confirmDraft(req, res) {
        const data = await profilingWorkflowService.confirmDraft(req.authUser.id);
        res.json({ message: 'Profile saved successfully.', data });
    }
    async regenerateDraft(req, res) {
        const data = await profilingWorkflowService.regenerateDraft(req.authUser.id);
        res.json(data);
    }
}
export const profilingWorkflowController = new ProfilingWorkflowController();
