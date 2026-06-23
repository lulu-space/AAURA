import { studySessionMembershipWorkflowService } from '../services/study-session-membership.service.js';
export class StudySessionMembershipWorkflowController {
    async join(req, res) {
        const { study_session_id } = req.body;
        const data = await studySessionMembershipWorkflowService.join(study_session_id, req.authUser.id);
        res.status(201).json({ message: 'Joined study session.', data });
    }
    async listMembers(req, res) {
        const data = await studySessionMembershipWorkflowService.listSessionMembers(req.params.sessionId, req.authUser.id, req.authUser?.role);
        res.json({ message: 'Study session members fetched.', data });
    }
}
export const studySessionMembershipWorkflowController = new StudySessionMembershipWorkflowController();
