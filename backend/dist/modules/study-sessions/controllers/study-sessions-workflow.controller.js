import { z } from 'zod';
import { studySessionsWorkflowService } from '../services/study-sessions-workflow.service.js';
const notifySchema = z.object({
    title: z.string().min(2),
    body: z.string().min(2),
    kind: z.enum(['updated', 'cancelled']).default('updated')
});
export class StudySessionsWorkflowController {
    async notifyMembers(req, res) {
        const { id } = req.params;
        const payload = notifySchema.parse(req.body);
        const result = await studySessionsWorkflowService.notifyMembers(id, req.authUser.id, payload);
        res.json({ message: 'Members notified.', data: result });
    }
}
export const studySessionsWorkflowController = new StudySessionsWorkflowController();
