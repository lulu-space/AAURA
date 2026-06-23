import { ApiError } from '../../../core/errors/api-error.js';
import { supabaseAdmin } from '../../../config/supabase.js';
import { proxyToAi } from '../../ai/services/ai-proxy.service.js';
import { strengthsFromTraits, mergeStrengths, strengthsFromSkillNames } from '../../student-profiles/services/skill-progress.service.js';

type ShamsExtraction = {
  reply: string;
  traits: Record<string, string>;
  interests: string[];
  skills?: string[];
  keywords: string[];
  major?: string | null;
  year?: string | null;
  academic_year?: number | null;
  goals?: string[];
  profile_summary: string;
  profile_text: string;
  confidence: number;
  needs_detail?: boolean;
};

function mergeGoals(
  extracted: string[],
  interests: string[],
  strengths: Array<string | { name?: string }>
): string[] {
  const merged = [...extracted];
  const seen = new Set(merged.map((goal) => goal.toLowerCase()));
  for (const starter of buildStarterGoals(interests, strengths)) {
    if (merged.length >= 5) break;
    const key = starter.toLowerCase();
    if (seen.has(key)) continue;
    merged.push(starter);
    seen.add(key);
  }
  return merged.slice(0, 5);
}

function mergeUniqueStrings(existing: unknown, incoming: string[]): string[] {
  const merged = [...(Array.isArray(existing) ? existing.map(String) : []), ...incoming];
  const seen = new Set<string>();
  const result: string[] = [];
  for (const value of merged) {
    const trimmed = value.trim();
    if (!trimmed) continue;
    const key = trimmed.toLowerCase();
    if (seen.has(key)) continue;
    seen.add(key);
    result.push(trimmed);
  }
  return result;
}

/**
 * Turn raw interests/strengths into a few readable, actionable starter goals
 * rather than dumping the raw interest list (which read like tags, not goals).
 */
function buildStarterGoals(
  interests: string[],
  strengths: Array<string | { name?: string }>
): string[] {
  const goals: string[] = [];
  for (const interest of interests.slice(0, 2)) {
    goals.push(`Get involved in ${interest.toLowerCase()} on campus`);
  }
  if (strengths.length > 0) {
    const first = strengths[0] as string | { name?: string };
    const label =
      typeof first === 'string' ? first : first.name ?? 'campus skills';
    goals.push(`Grow your ${label.toLowerCase()} skills`);
  }
  goals.push('Attend 3 campus events this semester');
  goals.push('Earn your first badge');
  return Array.from(new Set(goals)).slice(0, 4);
}

export class ProfilingWorkflowService {
  async chatWithShams(userId: string, message: string) {
    const { status, body } = await proxyToAi('/api/profiling/shams/chat', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message })
    });

    if (status >= 400) {
      throw new ApiError(502, 'Shams profiling failed.', body);
    }

    const extraction = body as ShamsExtraction;

    if (extraction.needs_detail) {
      return {
        reply: extraction.reply,
        draft: null,
        preview: {
          profile_summary: extraction.profile_summary,
          traits: extraction.traits,
          interests: extraction.interests,
          skills: extraction.skills ?? [],
          keywords: extraction.keywords,
          confidence: extraction.confidence,
          needs_detail: true
        }
      };
    }

    const traitsPayload = {
      traits: extraction.traits,
      interests: extraction.interests,
      skills: extraction.skills ?? [],
      keywords: extraction.keywords,
      profile_summary: extraction.profile_summary,
      major: extraction.major ?? null,
      year: extraction.year ?? null,
      academic_year: extraction.academic_year ?? null,
      goals: extraction.goals ?? []
    };

    const { data: draft, error } = await supabaseAdmin
      .from('student_profile_drafts')
      .upsert(
        {
          user_id: userId,
          profile_text: extraction.profile_text,
          traits: traitsPayload,
          confidence: extraction.confidence,
          source: 'ai'
        },
        { onConflict: 'user_id' }
      )
      .select('*')
      .single();

    if (error) {
      throw new ApiError(500, 'Failed to save profile draft.', error);
    }

    return {
      reply: extraction.reply,
      draft,
      preview: {
        profile_summary: extraction.profile_summary,
        traits: extraction.traits,
        interests: extraction.interests,
        skills: extraction.skills ?? [],
        keywords: extraction.keywords,
        major: extraction.major ?? null,
        year: extraction.year ?? null,
        academic_year: extraction.academic_year ?? null,
        goals: extraction.goals ?? [],
        confidence: extraction.confidence,
        needs_detail: false
      }
    };
  }

  async getMyDraft(userId: string) {
    const { data, error } = await supabaseAdmin
      .from('student_profile_drafts')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle();

    if (error) throw new ApiError(500, 'Failed to fetch profile draft.', error);
    return data;
  }

  async confirmDraft(userId: string) {
    const { data: draft, error: draftError } = await supabaseAdmin
      .from('student_profile_drafts')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle();

    if (draftError) throw new ApiError(500, 'Failed to load profile draft.', draftError);
    if (!draft) throw new ApiError(404, 'No profile draft to confirm. Chat with Shams first.');

    const traitsObj = (draft.traits ?? {}) as {
      traits?: Record<string, string>;
      interests?: string[];
      skills?: string[];
      keywords?: string[];
      profile_summary?: string;
      major?: string | null;
      year?: string | null;
      academic_year?: number | null;
      goals?: string[];
    };
    const traitMap = traitsObj.traits ?? {};
    const interests = traitsObj.interests ?? [];
    const extractedSkills = traitsObj.skills ?? [];
    const extractedGoals = traitsObj.goals ?? [];
    const confidence = (draft.confidence as number | undefined) ?? 0.5;
    const traitStrengths = strengthsFromTraits(traitMap, confidence);
    const namedSkillStrengths = strengthsFromSkillNames(extractedSkills, confidence);
    const shamsStrengths = mergeStrengths([], traitStrengths, confidence);
    const mergedShamsStrengths = mergeStrengths(shamsStrengths, namedSkillStrengths, confidence);

    const { data: existingProfile } = await supabaseAdmin
      .from('student_profiles')
      .select('strengths, confidence, interests')
      .eq('user_id', userId)
      .maybeSingle();

    const strengths = mergeStrengths(
      existingProfile?.strengths,
      mergedShamsStrengths,
      (existingProfile?.confidence as number | undefined) ?? confidence
    );
    const mergedInterests = mergeUniqueStrings(existingProfile?.interests, interests);
    const profileSummary =
      traitsObj.profile_summary ??
      `AI profile based on: ${strengths.map((s) => s.name).join(', ') || 'campus interests'}.`;
    const goals = mergeGoals(extractedGoals, interests, strengths);

    const { data: profile, error: profileError } = await supabaseAdmin
      .from('student_profiles')
      .upsert(
        {
          user_id: userId,
          profile_summary: profileSummary,
          strengths,
          goals,
          interests: mergedInterests,
          confidence: draft.confidence,
          last_ai_refresh_at: new Date().toISOString()
        },
        { onConflict: 'user_id' }
      )
      .select('*')
      .single();

    if (profileError) {
      throw new ApiError(500, 'Failed to save student profile.', profileError);
    }

    const major = traitsObj.major?.trim();
    const academicYear =
      typeof traitsObj.academic_year === 'number'
        ? traitsObj.academic_year
        : null;
    if (major || academicYear) {
      const studentPatch: Record<string, unknown> = {};
      if (major) studentPatch.major = major;
      if (academicYear) studentPatch.academic_year = academicYear;

      const { data: existingStudent } = await supabaseAdmin
        .from('students')
        .select('user_id')
        .eq('user_id', userId)
        .maybeSingle();

      if (existingStudent) {
        await supabaseAdmin.from('students').update(studentPatch).eq('user_id', userId);
      }
    }

    // Draft has been promoted to a real profile; clear it so the user is not
    // re-prompted to confirm an already-applied preview.
    await supabaseAdmin
      .from('student_profile_drafts')
      .delete()
      .eq('user_id', userId);

    return { profile, draft };
  }

  async regenerateDraft(userId: string) {
    const { error } = await supabaseAdmin
      .from('student_profile_drafts')
      .delete()
      .eq('user_id', userId);

    if (error) throw new ApiError(500, 'Failed to clear profile draft.', error);

    return {
      message: 'Draft cleared. Send a new message to Shams to generate a fresh profile preview.'
    };
  }
}

export const profilingWorkflowService = new ProfilingWorkflowService();
