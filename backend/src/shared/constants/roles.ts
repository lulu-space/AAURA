/** Application roles (must match Supabase app_role enum). */

export const ROLES = {

  STUDENT: 'student',

  CLUB_ORGANIZER: 'club_organizer',

  STUDENT_AFFAIRS: 'student_affairs',

  DEAN_OF_FACULTY: 'dean_of_faculty',

  STAFF: 'staff',

  ADMIN: 'admin'

} as const;



export type AppRole = (typeof ROLES)[keyof typeof ROLES];



/** Student Affairs + Dean: events, predict success, volunteering opportunities only. */

export const FACULTY_OPS_ROLES: AppRole[] = [

  ROLES.STUDENT_AFFAIRS,

  ROLES.DEAN_OF_FACULTY,

  ROLES.ADMIN

];



/** Club lead (also a student): student features + clubs/events/analytics/monthly report. */

export const CLUB_ORGANIZER_ROLES: AppRole[] = [ROLES.CLUB_ORGANIZER, ROLES.ADMIN];



/** Anyone who can create/manage campus events. */

export const EVENT_MANAGER_ROLES: AppRole[] = [

  ROLES.CLUB_ORGANIZER,

  ROLES.STUDENT_AFFAIRS,

  ROLES.DEAN_OF_FACULTY,

  ROLES.ADMIN

];



export const VOLUNTEERING_OPPORTUNITY_CREATOR_ROLES: AppRole[] = [

  ROLES.STUDENT_AFFAIRS,

  ROLES.DEAN_OF_FACULTY,

  ROLES.ADMIN

];



export const STAFF_APPROVER_ROLES: AppRole[] = [ROLES.STAFF, ROLES.ADMIN];

/** Student Affairs office + dean + admin (and legacy staff) can review volunteer hours. */
export const VOLUNTEER_REVIEWER_ROLES: AppRole[] = [
  ROLES.STUDENT_AFFAIRS,
  ROLES.STAFF,
  ROLES.DEAN_OF_FACULTY,
  ROLES.ADMIN
];



/** Roles that use student-facing features (Shams, reserve, join clubs, etc.). */

export const STUDENT_FEATURE_ROLES: AppRole[] = [ROLES.STUDENT, ROLES.CLUB_ORGANIZER, ROLES.ADMIN];



/** Campus users with a student profile (student + club lead). */

export const STUDENT_LIKE_ROLES: AppRole[] = [...STUDENT_FEATURE_ROLES];



export function roleInList(role: string | undefined, allowed: readonly string[]): boolean {

  return !!role && allowed.includes(role);

}


