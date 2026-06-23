/** Roles that can see moderated / hidden campus content. */
export const CONTENT_MODERATOR_ROLES = new Set([
  'student_affairs',
  'dean_of_faculty',
  'admin'
]);

export function canViewModeratedContent(role?: string): boolean {
  return !!role && CONTENT_MODERATOR_ROLES.has(role);
}

/** Whether an event row should appear for this viewer. */
export function isEventVisibleToUser(
  row: Record<string, unknown>,
  userId: string,
  role?: string
): boolean {
  if (row.is_hidden === true) {
    if (canViewModeratedContent(role)) return true;
    if (row.organizer_id === userId) return true;
    return false;
  }
  return true;
}

/** Whether a club row should appear in public browse lists. */
export function isClubVisibleToUser(
  row: Record<string, unknown>,
  role?: string
): boolean {
  if (row.is_active === false && !canViewModeratedContent(role)) {
    return false;
  }
  return true;
}
