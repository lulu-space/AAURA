const ML_MAJORS = [
  'Computer Science',
  'Engineering',
  'Business',
  'Arts',
  'Medicine',
  'Education',
  'Law',
  'Architecture'
] as const;

const ML_DEPARTMENTS = [
  'Engineering',
  'Business',
  'Arts',
  'Sciences',
  'Medicine',
  'Student Affairs',
  'Computer Science'
] as const;

const ML_ORGANIZER_TYPES = [
  'club_student',
  'club_event',
  'student_affairs',
  'dean_of_faculty'
] as const;

export type MlOrganizerType = (typeof ML_ORGANIZER_TYPES)[number];

export type EventMlFeatures = {
  student_major: string;
  event_type: string;
  department: string;
  organizer_type: MlOrganizerType;
  expected_attendance: number;
  interest_match_score: number;
  skill_match_score: number;
  target_major_count: number;
  target_interest_count: number;
};

export function normalizeMajorForMl(value?: string | null): string {
  const text = (value ?? '').toLowerCase();
  if (/computer|software|information tech|\bit\b/.test(text)) return 'Computer Science';
  if (/engineer/.test(text)) return 'Engineering';
  if (/business|finance|marketing/.test(text)) return 'Business';
  if (/art|design|media/.test(text)) return 'Arts';
  if (/medic|nurs|health/.test(text)) return 'Medicine';
  if (/education|teach/.test(text)) return 'Education';
  if (/law|legal/.test(text)) return 'Law';
  if (/architect/.test(text)) return 'Architecture';
  return ML_MAJORS.includes(value as (typeof ML_MAJORS)[number])
    ? (value as string)
    : 'Computer Science';
}

export function normalizeDepartmentForMl(value?: string | null): string {
  const text = (value ?? '').toLowerCase();
  if (/engineer/.test(text)) return 'Engineering';
  if (/business/.test(text)) return 'Business';
  if (/art/.test(text)) return 'Arts';
  if (/medic|health/.test(text)) return 'Medicine';
  if (/computer|software/.test(text)) return 'Computer Science';
  if (/science/.test(text)) return 'Sciences';
  if (/student affairs|campus life/.test(text)) return 'Student Affairs';
  return ML_DEPARTMENTS.includes(value as (typeof ML_DEPARTMENTS)[number])
    ? (value as string)
    : 'Student Affairs';
}

export function dominantValue(values: Array<string | null | undefined>, fallback: string): string {
  const counts = new Map<string, number>();
  for (const value of values) {
    if (!value) continue;
    counts.set(value, (counts.get(value) ?? 0) + 1);
  }
  if (counts.size === 0) return fallback;
  return [...counts.entries()].sort((a, b) => b[1] - a[1])[0][0];
}

export function listMatchScore(items: string[], eventText: string, emptyDefault = 0.2): number {
  const cleaned = items.map((item) => item.trim()).filter(Boolean);
  if (cleaned.length === 0) return emptyDefault;

  const text = eventText.toLowerCase();
  let hits = 0;
  for (const item of cleaned) {
    const normalized = item.toLowerCase();
    const tokens = normalized.split(/\W+/).filter((token) => token.length > 3);
    if (text.includes(normalized) || tokens.some((token) => text.includes(token))) {
      hits += 1;
    }
  }
  return Number(Math.min(1, hits / cleaned.length).toFixed(2));
}

export function inferOrganizerType(
  role?: string,
  clubId?: string | null
): MlOrganizerType {
  if (role === 'dean_of_faculty') return 'dean_of_faculty';
  if (role === 'student_affairs' || role === 'admin') return 'student_affairs';
  if (role === 'club_organizer') {
    return clubId ? 'club_student' : 'club_event';
  }
  return 'club_event';
}

export function inferEventType(
  title: string,
  description?: string | null,
  category?: string | null,
  format?: string | null
): string {
  const text = `${title} ${description ?? ''} ${format ?? ''}`.toLowerCase();
  if (/hackathon|coding contest|programming contest/.test(text)) return 'hackathon';
  if (/career|internship|employer|job fair/.test(text)) return 'career';
  if (/volunteer|community service|charity/.test(text)) return 'volunteer';
  if (/sport|football|basketball|fitness/.test(text)) return 'sports';
  if (/cultural|music|art show|festival/.test(text)) return 'cultural';
  if (/social|networking|mixer/.test(text)) return 'social';
  if (/workshop|lab|hands-on|bootcamp/.test(text)) return 'workshop';
  if (/seminar|lecture|talk|panel/.test(text)) return 'seminar';

  switch ((category ?? '').toLowerCase()) {
    case 'serve':
      return 'volunteer';
    case 'connect':
      return 'social';
    case 'explore':
      return 'cultural';
    case 'learn':
      return 'workshop';
    default:
      return 'seminar';
  }
}

export function buildDraftEventFeatures(input: {
  title: string;
  description?: string | null;
  category?: string | null;
  format?: string | null;
  capacity: number;
  promotionLevel?: number;
  targetMajors?: string[];
  targetInterests?: string[];
  targetSkills?: string[];
  tags?: string[];
  organizerRole?: string;
  clubId?: string | null;
  department?: string | null;
}): EventMlFeatures {
  const targetMajors = input.targetMajors ?? [];
  const targetInterests = input.targetInterests ?? [];
  const targetSkills = input.targetSkills ?? [];
  const tags = input.tags ?? [];
  const eventText = `${input.title} ${input.description ?? ''} ${input.format ?? ''} ${tags.join(' ')}`;
  const dominantMajor = normalizeMajorForMl(
    dominantValue(targetMajors, targetMajors[0] ?? 'Computer Science')
  );
  const promotion = Math.max(1, Math.min(5, input.promotionLevel ?? 3));
  const expectedAttendance = Math.max(
    1,
    Math.round(input.capacity * (0.22 + promotion * 0.14))
  );

  return {
    student_major: dominantMajor,
    event_type: inferEventType(input.title, input.description, input.category, input.format),
    department: normalizeDepartmentForMl(input.department),
    organizer_type: inferOrganizerType(input.organizerRole, input.clubId),
    expected_attendance: expectedAttendance,
    interest_match_score: listMatchScore([...targetInterests, ...tags], eventText),
    skill_match_score: listMatchScore([...targetSkills, ...tags], eventText),
    target_major_count: targetMajors.length,
    target_interest_count: targetInterests.length
  };
}

export type EnrolleeProfile = {
  major: string | null;
  department: string | null;
  interests: string[];
  skills: string[];
};

export function scoreStudentInterest(profile: EnrolleeProfile, eventText: string): number {
  return listMatchScore([...profile.interests, ...profile.skills, profile.major ?? ''], eventText, 0.25);
}

export function computeInterestMatch(
  enrollees: EnrolleeProfile[],
  title: string,
  description?: string | null
): number {
  if (enrollees.length === 0) return 0.2;
  const eventText = `${title} ${description ?? ''}`;
  const scores = enrollees.map((profile) => scoreStudentInterest(profile, eventText));
  const average = scores.reduce((sum, score) => sum + score, 0) / scores.length;
  return Number(average.toFixed(2));
}

export function computeSkillMatch(
  enrollees: EnrolleeProfile[],
  title: string,
  description?: string | null
): number {
  if (enrollees.length === 0) return 0.2;
  const eventText = `${title} ${description ?? ''}`;
  const scores = enrollees.map((profile) => listMatchScore(profile.skills, eventText, 0.2));
  const average = scores.reduce((sum, score) => sum + score, 0) / scores.length;
  return Number(average.toFixed(2));
}

export function strengthsToSkillNames(strengths: unknown): string[] {
  if (!Array.isArray(strengths)) return [];
  return strengths
    .map((entry) => {
      if (typeof entry === 'string') return entry;
      if (entry && typeof entry === 'object' && 'name' in entry) {
        return String((entry as { name?: string }).name ?? '');
      }
      return '';
    })
    .filter(Boolean);
}
