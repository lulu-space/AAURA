import type { Request, Response } from 'express';
import { adminService } from '../services/admin.service.js';

export class AdminController {
  async dashboard(_req: Request, res: Response) {
    const data = await adminService.getDashboard();
    res.json({ message: 'Admin dashboard fetched successfully.', data });
  }

  async users(_req: Request, res: Response) {
    const data = await adminService.listUsers();
    res.json({ message: 'Users fetched successfully.', data });
  }

  async updateUser(req: Request, res: Response) {
    const data = await adminService.updateUser(
      req.authUser!.id,
      req.params.id as string,
      req.body
    );
    res.json({ message: 'User updated successfully.', data });
  }

  async content(_req: Request, res: Response) {
    const data = await adminService.getContentOverview();
    res.json({ message: 'Content overview fetched successfully.', data });
  }

  async moderateEvent(req: Request, res: Response) {
    const data = await adminService.moderateEvent(
      req.authUser!.id,
      req.params.id as string,
      req.body.action
    );
    res.json({ message: 'Event moderated successfully.', data });
  }

  async moderateClub(req: Request, res: Response) {
    const data = await adminService.moderateClub(
      req.authUser!.id,
      req.params.id as string,
      req.body.action
    );
    res.json({ message: 'Club moderated successfully.', data });
  }

  async moderatePost(req: Request, res: Response) {
    const data = await adminService.moderatePost(
      req.authUser!.id,
      req.params.id as string,
      req.body.hidden
    );
    res.json({ message: 'Post moderated successfully.', data });
  }

  async moderateMessage(req: Request, res: Response) {
    const data = await adminService.moderateMessage(
      req.authUser!.id,
      req.params.id as string,
      req.body.hidden
    );
    res.json({ message: 'Message moderated successfully.', data });
  }

  async analytics(_req: Request, res: Response) {
    const data = await adminService.getAnalytics();
    res.json({ message: 'System analytics fetched successfully.', data });
  }

  async volunteering(_req: Request, res: Response) {
    const data = await adminService.listVolunteeringRecords();
    res.json({ message: 'Volunteering records fetched successfully.', data });
  }

  async settings(_req: Request, res: Response) {
    const data = await adminService.getSettings();
    res.json({ message: 'Settings fetched successfully.', data });
  }

  async updateSettings(req: Request, res: Response) {
    const data = await adminService.updateSettings(
      req.authUser!.id,
      req.params.key as string,
      req.body.value
    );
    res.json({ message: 'Settings updated successfully.', data });
  }

  async badges(_req: Request, res: Response) {
    const data = await adminService.listBadges();
    res.json({ message: 'Badges fetched successfully.', data });
  }

  async updateBadge(req: Request, res: Response) {
    const data = await adminService.updateBadge(
      req.authUser!.id,
      req.params.id as string,
      req.body
    );
    res.json({ message: 'Badge updated successfully.', data });
  }

  async auditLogs(_req: Request, res: Response) {
    const data = await adminService.listAuditLogs();
    res.json({ message: 'Audit logs fetched successfully.', data });
  }

  async announce(req: Request, res: Response) {
    const data = await adminService.sendAnnouncement(req.authUser!.id, req.body);
    res.json({ message: 'System announcement sent successfully.', data });
  }
}

export const adminController = new AdminController();
