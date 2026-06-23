import { usersService } from '../services/users.service.js';
export class UsersController {
    async me(req, res) {
        const data = await usersService.getMe(req.authUser.id);
        res.json({ message: 'User fetched successfully.', data });
    }
    async updateMe(req, res) {
        const data = await usersService.updateMe(req.authUser.id, req.body, req.authUser.role);
        res.json({ message: 'User updated successfully.', data });
    }
    async adminList(_req, res) {
        const data = await usersService.adminList();
        res.json({ message: 'Users fetched successfully.', data });
    }
    async adminGetById(req, res) {
        const data = await usersService.adminGetById(req.params.id);
        res.json({ message: 'User fetched successfully.', data });
    }
    async adminUpdate(req, res) {
        const data = await usersService.adminUpdate(req.params.id, req.body);
        res.json({ message: 'User updated successfully.', data });
    }
}
export const usersController = new UsersController();
