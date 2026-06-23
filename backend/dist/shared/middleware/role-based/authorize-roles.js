import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
export const authorizeRoles = (...roles) => async (req, _res, next) => {
    if (!req.authUser?.id) {
        return next(new ApiError(401, 'Unauthorized.'));
    }
    const { data, error } = await supabaseAdmin
        .from('users')
        .select('role,is_suspended')
        .eq('id', req.authUser.id)
        .single();
    if (error || !data) {
        return next(new ApiError(403, 'Forbidden.'));
    }
    if (data.is_suspended) {
        return next(new ApiError(403, 'Account is suspended.'));
    }
    req.authUser.role = data.role;
    if (!roles.includes(data.role)) {
        return next(new ApiError(403, 'Forbidden.'));
    }
    next();
};
