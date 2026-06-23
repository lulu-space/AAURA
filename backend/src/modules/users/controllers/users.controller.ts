import type { Request, Response } from 'express';
import { usersService } from '../services/users.service.js';

export class UsersController {
  async me(req: Request, res: Response) {
    const data = await usersService.getMe(req.authUser!.id);
    res.json({ message: 'User fetched successfully.', data });
  }

  async updateMe(req: Request, res: Response) {
    const data = await usersService.updateMe(
      req.authUser!.id,
      req.body,
      req.authUser!.role
    );
    res.json({ message: 'User updated successfully.', data });
  }

  async adminList(_req: Request, res: Response) {
    const data = await usersService.adminList();
    res.json({ message: 'Users fetched successfully.', data });
  }

  async adminGetById(req: Request, res: Response) {
    const data = await usersService.adminGetById(req.params.id as string);
    res.json({ message: 'User fetched successfully.', data });
  }

  async adminUpdate(req: Request, res: Response) {
    const data = await usersService.adminUpdate(req.params.id as string, req.body);
    res.json({ message: 'User updated successfully.', data });
  }
}

export const usersController = new UsersController();

