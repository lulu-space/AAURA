import type { Request, Response } from 'express';
import { volunteeringWorkflowService } from '../services/volunteering-workflow.service.js';

export class VolunteeringWorkflowController {
  async listPending(_req: Request, res: Response) {
    const data = await volunteeringWorkflowService.listPending();
    res.json({ message: 'Pending volunteering records fetched.', data });
  }

  async listAll(_req: Request, res: Response) {
    const data = await volunteeringWorkflowService.listAll();
    res.json({ message: 'Volunteering records fetched.', data });
  }

  async approve(req: Request, res: Response) {
    const role = req.authUser!.role;
    const emergency = (req.body as { emergency_override?: boolean }).emergency_override === true;
    if (role === 'admin' && !emergency) {
      res.status(403).json({
        message:
          'Volunteer hour approval is handled by Student Affairs. Pass emergency_override: true only for emergencies.'
      });
      return;
    }
    const { approval_note } = req.body as { approval_note?: string };
    const data = await volunteeringWorkflowService.approve(
      req.params.id as string,
      req.authUser!.id,
      approval_note
    );
    res.json({ message: 'Volunteering hours approved.', data });
  }

  async reject(req: Request, res: Response) {
    const role = req.authUser!.role;
    const emergency = (req.body as { emergency_override?: boolean }).emergency_override === true;
    if (role === 'admin' && !emergency) {
      res.status(403).json({
        message:
          'Volunteer hour rejection is handled by Student Affairs. Pass emergency_override: true only for emergencies.'
      });
      return;
    }
    const { approval_note } = req.body as { approval_note?: string };
    const data = await volunteeringWorkflowService.reject(
      req.params.id as string,
      req.authUser!.id,
      approval_note
    );
    res.json({ message: 'Volunteering hours rejected.', data });
  }

  async withdraw(req: Request, res: Response) {
    const data = await volunteeringWorkflowService.withdraw(
      req.params.id as string,
      req.authUser!.id
    );
    res.json({ message: 'Volunteering decision withdrawn.', data });
  }
}

export const volunteeringWorkflowController = new VolunteeringWorkflowController();
