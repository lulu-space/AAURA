import { ApiError } from '../../core/errors/api-error.js';

/** Allowed campus email patterns (no other domains or subdomains). */
export const CAMPUS_EMAIL_INVALID_MESSAGE =
  'Use an AAUP campus email only: @student.aaup.edu (students), @staff.aaup.edu (Student Affairs), @aaup.edu (Dean of Faculty), or admin@aaup.edu (admin).';

export const ADMIN_CAMPUS_EMAIL = 'admin@aaup.edu';

const ALLOWED_DOMAINS = new Set(['student.aaup.edu', 'staff.aaup.edu', 'aaup.edu']);

export type CampusEmailRole =
  | 'student'
  | 'student_affairs'
  | 'dean_of_faculty'
  | 'admin';

export function normalizeCampusEmail(email: string): string {
  return email.trim().toLowerCase();
}

export function parseCampusEmail(email: string): { local: string; domain: string } | null {
  const normalized = normalizeCampusEmail(email);
  const at = normalized.lastIndexOf('@');
  if (at <= 0 || at === normalized.length - 1) return null;
  const local = normalized.slice(0, at);
  const domain = normalized.slice(at + 1);
  if (!local || !domain) return null;
  return { local, domain };
}

/** Returns null when the address is not an allowed AAUP campus email. */
export function validateCampusEmail(email: string): CampusEmailRole | null {
  const parsed = parseCampusEmail(email);
  if (!parsed) return null;
  if (!ALLOWED_DOMAINS.has(parsed.domain)) return null;

  if (parsed.domain === 'student.aaup.edu') return 'student';
  if (parsed.domain === 'staff.aaup.edu') return 'student_affairs';
  if (parsed.domain === 'aaup.edu') {
    return normalizeCampusEmail(email) === ADMIN_CAMPUS_EMAIL ? 'admin' : 'dean_of_faculty';
  }
  return null;
}

export function assertValidCampusEmail(email: string): CampusEmailRole {
  const role = validateCampusEmail(email);
  if (!role) {
    throw new ApiError(403, CAMPUS_EMAIL_INVALID_MESSAGE);
  }
  return role;
}

export function roleFromCampusEmail(email: string): CampusEmailRole {
  return assertValidCampusEmail(email);
}
