/** Application roles (must match Supabase app_role enum). */
export const ROLES = {
    STUDENT: 'student',
    CLUB_ORGANIZER: 'club_organizer',
    STUDENT_AFFAIRS: 'student_affairs',
    DEAN_OF_FACULTY: 'dean_of_faculty',
    STAFF: 'staff',
    ADMIN: 'admin'
};
/** Student Affairs + Dean: events, predict success, volunteering opportunities only. */
export const FACULTY_OPS_ROLES = [
    ROLES.STUDENT_AFFAIRS,
    ROLES.DEAN_OF_FACULTY,
    ROLES.ADMIN
];
/** Club lead (also a student): student features + clubs/events/analytics/monthly report. */
export const CLUB_ORGANIZER_ROLES = [ROLES.CLUB_ORGANIZER, ROLES.ADMIN];
/** Anyone who can create/manage campus events. */
export const EVENT_MANAGER_ROLES = [
    ROLES.CLUB_ORGANIZER,
    ROLES.STUDENT_AFFAIRS,
    ROLES.DEAN_OF_FACULTY,
    ROLES.ADMIN
];
export const VOLUNTEERING_OPPORTUNITY_CREATOR_ROLES = [
    ROLES.STUDENT_AFFAIRS,
    ROLES.DEAN_OF_FACULTY,
    ROLES.ADMIN
];
export const STAFF_APPROVER_ROLES = [ROLES.STAFF, ROLES.ADMIN];
/** Roles that use student-facing features (Shams, reserve, join clubs, etc.). */
export const STUDENT_FEATURE_ROLES = [ROLES.STUDENT, ROLES.CLUB_ORGANIZER, ROLES.ADMIN];
/** Campus users with a student profile (student + club lead). */
export const STUDENT_LIKE_ROLES = [...STUDENT_FEATURE_ROLES];
export function roleInList(role, allowed) {
    return !!role && allowed.includes(role);
}
