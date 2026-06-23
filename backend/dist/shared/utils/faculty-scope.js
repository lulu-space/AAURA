import { ApiError } from '../../core/errors/api-error.js';
import { supabaseAdmin } from '../../config/supabase.js';
export const FACULTY_OPTIONS = [
    'Engineering',
    'Business',
    'Arts',
    'Sciences',
    'Medicine',
    'Computer Science'
];
const FACULTY_MAJORS = {
    Engineering: ['Engineering', 'Architecture', 'Software Engineering'],
    'Computer Science': ['Computer Science', 'Information Technology', 'Software Engineering'],
    Business: ['Business'],
    Arts: ['English'],
    Sciences: ['Information Technology'],
    Medicine: ['Medicine']
};
export function majorsForFaculty(faculty) {
    return [...(FACULTY_MAJORS[faculty] ?? [faculty])];
}
export function isValidFaculty(value) {
    return FACULTY_OPTIONS.includes(value);
}
export async function requireDeanFaculty(userId, role) {
    if (role !== 'dean_of_faculty') {
        throw new ApiError(403, 'Dean access only.');
    }
    const { data, error } = await supabaseAdmin
        .from('users')
        .select('assigned_faculty')
        .eq('id', userId)
        .single();
    if (error || !data) {
        throw new ApiError(404, 'User not found.', error);
    }
    const faculty = data.assigned_faculty?.trim();
    if (!faculty || !isValidFaculty(faculty)) {
        throw new ApiError(400, 'Set your assigned faculty on your profile first.');
    }
    return faculty;
}
export async function listStudentUserIdsInFaculty(faculty) {
    const majors = majorsForFaculty(faculty);
    const ids = new Set();
    const { data: byDepartment, error: deptError } = await supabaseAdmin
        .from('students')
        .select('user_id')
        .eq('department', faculty);
    if (deptError) {
        throw new ApiError(500, 'Failed to load faculty students.', deptError);
    }
    for (const row of byDepartment ?? []) {
        if (row.user_id)
            ids.add(row.user_id);
    }
    if (majors.length > 0) {
        const { data: byMajor, error: majorError } = await supabaseAdmin
            .from('students')
            .select('user_id')
            .in('major', majors);
        if (majorError) {
            throw new ApiError(500, 'Failed to load faculty students.', majorError);
        }
        for (const row of byMajor ?? []) {
            if (row.user_id)
                ids.add(row.user_id);
        }
    }
    return [...ids];
}
export function eventTargetsFaculty(event, faculty) {
    const majors = majorsForFaculty(faculty);
    const targets = event.target_majors;
    if (!Array.isArray(targets) || targets.length === 0)
        return false;
    return targets.some((target) => majors.includes(String(target)));
}
export function eventOrganizerInFaculty(event, facultyStudentIds) {
    const organizerId = event.organizer_id;
    return organizerId != null && facultyStudentIds.has(organizerId);
}
export async function filterEventsForFaculty(events, faculty, deanUserId) {
    const facultyStudentIds = new Set(await listStudentUserIdsInFaculty(faculty));
    return events.filter((event) => {
        if (deanUserId && event.organizer_id === deanUserId)
            return true;
        return (eventTargetsFaculty(event, faculty) || eventOrganizerInFaculty(event, facultyStudentIds));
    });
}
export async function filterClubsForFaculty(clubs, faculty) {
    const facultyStudentIds = new Set(await listStudentUserIdsInFaculty(faculty));
    if (facultyStudentIds.size === 0)
        return [];
    const clubIds = clubs.map((club) => club.id).filter(Boolean);
    if (clubIds.length === 0)
        return [];
    const { data: memberships, error } = await supabaseAdmin
        .from('club_membership')
        .select('club_id, user_id')
        .in('club_id', clubIds);
    if (error) {
        throw new ApiError(500, 'Failed to load club memberships.', error);
    }
    const clubMembers = new Map();
    for (const row of memberships ?? []) {
        const clubId = row.club_id;
        const userId = row.user_id;
        if (!clubMembers.has(clubId))
            clubMembers.set(clubId, new Set());
        clubMembers.get(clubId).add(userId);
    }
    return clubs.filter((club) => {
        const organizerId = club.organizer_id;
        if (organizerId && facultyStudentIds.has(organizerId))
            return true;
        const members = clubMembers.get(club.id);
        if (!members)
            return false;
        for (const memberId of members) {
            if (facultyStudentIds.has(memberId))
                return true;
        }
        return false;
    });
}
