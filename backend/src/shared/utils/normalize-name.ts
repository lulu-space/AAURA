/**
 * Shared name normalization for clubs and events.
 * lowercase → trim → strip punctuation → collapse whitespace
 */
export function normalizeEntityName(name: string): string {
  return name
    .toLowerCase()
    .trim()
    .replace(/[^\w\s]/g, '')
    .replace(/\s+/g, ' ')
    .trim();
}

export const normalizeClubName = normalizeEntityName;
export const normalizeEventTitle = normalizeEntityName;
