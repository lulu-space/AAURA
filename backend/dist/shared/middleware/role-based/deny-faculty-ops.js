import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
import { ROLES } from '../../constants/roles.js';
const FACULTY_ONLY_OPS_ROLES = [ROLES.STUDENT_AFFAIRS, ROLES.DEAN_OF_FACULTY];
/** Blocks Student Affairs / Dean from student-facing workflows (events, predict, volunteering opportunities only). */
export const denyFacultyOps = () => async (req, _res, next) => {
    if (!req.authUser?.id) {
        return next(new ApiError(401, 'Unauthorized.'));
    }
    const { data, error } = await supabaseAdmin
        .from('users')
        .select('role,is_suspended')
        .eq('id', req.authUser.id)
        .maybeSingle();
    if (error || !data) {
        return next(new ApiError(403, 'Application profile not ready yet. Sign out, sign back in, and try again.'));
    }
    req.authUser.role = data.role;
    if (FACULTY_ONLY_OPS_ROLES.includes(data.role)) {
        return next(new ApiError(403, 'This action is not available for your role.'));
    }
    next();
};
