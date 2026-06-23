import type { Request, Response } from 'express';
import { clubsWorkflowService } from '../services/clubs-workflow.service.js';

export class ClubsWorkflowController {
  async detectInactive(_req: Request, res: Response) {
    const data = await clubsWorkflowService.detectInactiveClubs();
    res.json({ message: 'Dead club detection completed.', data });
  }

  async reactivate(req: Request, res: Response) {
    const data = await clubsWorkflowService.reactivateClub(
      req.params.id as string,
      req.authUser!.id,
      req.authUser?.role
    );
    res.json({ message: 'Club reactivated.', data });
  }

  async monthlyReport(req: Request, res: Response) {
    const year = parseInt(String(req.query.year ?? new Date().getUTCFullYear()), 10);
    const month = parseInt(String(req.query.month ?? new Date().getUTCMonth() + 1), 10);
    const data = await clubsWorkflowService.getMonthlyReport(req.authUser!.id, year, month);
    res.json({ message: 'Monthly club activity report.', data });
  }

  async listWithCounts(req: Request, res: Response) {
    const data = await clubsWorkflowService.listWithCounts(
      req.authUser!.id,
      req.authUser?.role
    );
    res.json({ message: 'Clubs fetched.', data });
  }

  async listMembers(req: Request, res: Response) {
    const data = await clubsWorkflowService.listMembers(
      req.params.id as string,
      req.authUser!.id
    );
    res.json({ message: 'Club members fetched.', data });
  }

  async activityFeed(req: Request, res: Response) {
    const limit = parseInt(String(req.query.limit ?? 20), 10);
    const data = await clubsWorkflowService.listActivityFeed(
      req.authUser!.id,
      limit,
      req.authUser?.role
    );
    res.json({ message: 'Club activity feed fetched.', data });
  }
}

export const clubsWorkflowController = new ClubsWorkflowController();
