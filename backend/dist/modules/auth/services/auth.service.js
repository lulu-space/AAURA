import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
import { assertValidCampusEmail, roleFromCampusEmail } from '../../../shared/utils/campus-email.js';
function normalizeProvisionRpcRow(data) {
    if (data == null) {
        throw new ApiError(500, 'Provision returned no user row.', {
            hint: 'Confirm migration 0003 ran and GRANT EXECUTE on provision_application_user for service_role (see 0004_grant_provision_execute.sql).'
        });
    }
    if (Array.isArray(data)) {
        if (data.length === 0) {
            throw new ApiError(500, 'Provision returned an empty row set.', null);
        }
        return data[0];
    }
    if (typeof data === 'object') {
        return data;
    }
    throw new ApiError(500, 'Unexpected provision response shape.', { data });
}
function roleFromEmail(email) {
    return roleFromCampusEmail(email);
}
export class AuthService {
    async deriveFullName(authUserId, payloadFullName) {
        const trimmed = payloadFullName?.trim();
        if (trimmed && trimmed.length >= 3)
            return trimmed;
        const { data: authData, error: authErr } = await supabaseAdmin.auth.admin.getUserById(authUserId);
        if (authErr || !authData?.user) {
            throw new ApiError(400, 'Could not load auth user to derive fullName.', authErr);
        }
        const meta = authData.user.user_metadata;
        const fromMeta = typeof meta?.full_name === 'string'
            ? meta.full_name
            : typeof meta?.name === 'string'
                ? meta.name
                : undefined;
        return (fromMeta?.trim() ||
            authData.user.email?.split('@')[0]?.trim() ||
            'Unnamed User');
    }
    async attachStudentPayload(authUserId, payload, userRow) {
        if (payload.universityId) {
            const { error: studentError } = await supabaseAdmin.from('students').upsert({
                user_id: authUserId,
                university_id: payload.universityId,
                major: payload.major ?? null,
                department: payload.department ?? null,
                academic_year: payload.academicYear ?? null
            }, { onConflict: 'user_id' });
            if (studentError) {
                throw new ApiError(500, 'Failed to upsert student row.', studentError);
            }
        }
        const { data: student } = await supabaseAdmin
            .from('students')
            .select('university_id,major,department,academic_year')
            .eq('user_id', authUserId)
            .maybeSingle();
        return {
            ...userRow,
            student: student
                ? {
                    universityId: student.university_id,
                    major: student.major,
                    department: student.department,
                    academicYear: student.academic_year
                }
                : null
        };
    }
    /** Fallback when the provision RPC is missing or not granted on Supabase. */
    async provisionUserDirect(authUserId, authEmail, payload) {
        const fullName = await this.deriveFullName(authUserId, payload.fullName);
        const role = roleFromEmail(authEmail);
        const { data, error } = await supabaseAdmin
            .from('users')
            .upsert({
            id: authUserId,
            email: authEmail,
            full_name: fullName,
            role,
            is_suspended: false
        }, { onConflict: 'id' })
            .select('*')
            .single();
        if (error || !data) {
            throw new ApiError(500, 'Failed to provision application user (direct upsert).', error);
        }
        return this.attachStudentPayload(authUserId, payload, data);
    }
    async provisionUser(authUserId, authEmail, payload) {
        if (!authEmail) {
            throw new ApiError(400, 'Authenticated email is required.');
        }
        assertValidCampusEmail(authEmail);
        const fullName = await this.deriveFullName(authUserId, payload.fullName);
        const { data, error } = await supabaseAdmin.rpc('provision_application_user', {
            p_user_id: authUserId,
            p_email: authEmail,
            p_full_name: fullName,
            p_university_id: payload.universityId ?? null,
            p_major: payload.major ?? null,
            p_department: payload.department ?? null,
            p_academic_year: payload.academicYear ?? null
        });
        if (error) {
            console.warn('[auth] provision_application_user RPC failed; using direct upsert:', error.message);
            return this.provisionUserDirect(authUserId, authEmail, payload);
        }
        const userRow = normalizeProvisionRpcRow(data);
        return this.attachStudentPayload(authUserId, payload, userRow);
    }
    /** Ensures a JWT-authenticated user has a row in public.users (idempotent). */
    async ensureApplicationUser(authUserId, authEmail) {
        const { data: existing, error: loadError } = await supabaseAdmin
            .from('users')
            .select('role,is_suspended')
            .eq('id', authUserId)
            .maybeSingle();
        if (loadError) {
            throw new ApiError(500, 'Failed to load application user.', loadError);
        }
        if (existing)
            return existing;
        assertValidCampusEmail(authEmail ?? '');
        await this.provisionUser(authUserId, authEmail, {});
        const { data: created, error: reloadError } = await supabaseAdmin
            .from('users')
            .select('role,is_suspended')
            .eq('id', authUserId)
            .maybeSingle();
        if (reloadError || !created) {
            throw new ApiError(500, 'Application user was not created.', reloadError);
        }
        return created;
    }
}
export const authService = new AuthService();
