import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
export const MAX_SKILL_PROGRESS = 0.9;
function normalizeProgress(value, fallback) {
    if (typeof value !== 'number' || Number.isNaN(value))
        return fallback;
    let progress = value;
    if (progress > 1)
        progress = progress / 100;
    return Math.min(MAX_SKILL_PROGRESS, Math.max(0, progress));
}
function baselineProgress(confidence) {
    const normalized = confidence > 1 ? confidence / 100 : confidence;
    return Math.min(0.45, Math.max(0.12, normalized * 0.55));
}
export function normalizeStrengths(raw, confidence = 0.5) {
    if (!Array.isArray(raw))
        return [];
    const base = baselineProgress(confidence);
    return raw
        .map((entry) => {
        if (typeof entry === 'string' && entry.trim().length > 0) {
            return {
                name: entry.replace(/_/g, ' '),
                progress: base,
                note: 'From your Shams profile',
                change: ''
            };
        }
        if (entry && typeof entry === 'object') {
            const row = entry;
            const name = String(row.name ?? 'Skill').trim();
            if (!name)
                return null;
            const progress = typeof row.progress === 'number'
                ? normalizeProgress(row.progress, base)
                : base;
            return {
                name,
                progress,
                note: String(row.note ?? ''),
                change: String(row.change ?? '')
            };
        }
        return null;
    })
        .filter((entry) => entry != null);
}
export function strengthsFromTraits(traitMap, confidence) {
    const base = baselineProgress(confidence);
    return Object.entries(traitMap).map(([name, note]) => ({
        name: name.replace(/_/g, ' '),
        progress: base,
        note: typeof note === 'string' && note.trim().length > 0 ? note : 'From your Shams profile',
        change: 'Profile created'
    }));
}
export function strengthsFromSkillNames(skillNames, confidence) {
    const base = baselineProgress(confidence);
    return skillNames
        .map((name) => name.trim())
        .filter((name) => name.length > 0)
        .map((name) => ({
        name,
        progress: base,
        note: 'From your Shams profile',
        change: 'Profile created'
    }));
}
/** Keep manually added or progressed skills when Shams confirms a new draft. */
export function mergeStrengths(existing, incoming, confidence = 0.5) {
    const prior = normalizeStrengths(existing, confidence);
    const byName = new Map();
    const keyOf = (name) => name.trim().toLowerCase().replace(/\s+/g, ' ');
    for (const skill of prior) {
        byName.set(keyOf(skill.name), skill);
    }
    for (const skill of incoming) {
        const key = keyOf(skill.name);
        const current = byName.get(key);
        if (!current) {
            byName.set(key, skill);
            continue;
        }
        byName.set(key, {
            ...current,
            progress: Math.max(current.progress, skill.progress),
            note: skill.note.trim().length > 0 ? skill.note : current.note,
            change: skill.change || current.change
        });
    }
    return [...byName.values()];
}
export function bumpStrengths(strengths, delta, changeLabel) {
    if (strengths.length === 0 || delta <= 0)
        return strengths;
    return strengths.map((skill) => ({
        ...skill,
        progress: Math.min(MAX_SKILL_PROGRESS, Math.round((skill.progress + delta) * 1000) / 1000),
        change: changeLabel
    }));
}
export async function bumpStudentSkillProgress(userId, delta, changeLabel) {
    if (delta <= 0)
        return null;
    const { data: profile, error } = await supabaseAdmin
        .from('student_profiles')
        .select('id, strengths, confidence')
        .eq('user_id', userId)
        .maybeSingle();
    if (error)
        throw new ApiError(500, 'Failed to load student profile.', error);
    if (!profile)
        return null;
    const confidence = typeof profile.confidence === 'number' ? profile.confidence : 0.5;
    const normalized = normalizeStrengths(profile.strengths, confidence);
    if (normalized.length === 0)
        return null;
    const next = bumpStrengths(normalized, delta, changeLabel);
    const { data: updated, error: updateError } = await supabaseAdmin
        .from('student_profiles')
        .update({ strengths: next })
        .eq('id', profile.id)
        .select('*')
        .single();
    if (updateError)
        throw new ApiError(500, 'Failed to update skill progress.', updateError);
    return updated;
}
