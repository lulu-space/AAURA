import { authService } from '../services/auth.service.js';
export class AuthController {
    async provision(req, res) {
        const data = await authService.provisionUser(req.authUser.id, req.authUser?.email, req.body);
        res.status(201).json({
            message: 'Application user provisioned successfully.',
            data
        });
    }
}
export const authController = new AuthController();
