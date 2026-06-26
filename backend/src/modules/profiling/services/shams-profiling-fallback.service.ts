/**
 * Local Shams profiling when the Python AI service is unreachable (e.g. Render deploy
 * without a separate AI container). Mirrors ai/app/services/shams_profiling.py.
 */

type ShamsExtraction = {
  reply: string;
  traits: Record<string, string>;
  interests: string[];
  skills: string[];
  keywords: string[];
  major: string | null;
  year: string | null;
  academic_year: number | null;
  goals: string[];
  profile_summary: string;
  profile_text: string;
  confidence: number;
  needs_detail: boolean;
};

const STOPWORDS = new Set([
  'a', 'an', 'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'of', 'with',
  'is', 'am', 'are', 'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had',
  'do', 'does', 'did', 'will', 'would', 'could', 'should', 'may', 'might', 'must',
  'i', 'me', 'my', 'we', 'our', 'you', 'your', 'they', 'them', 'their', 'it', 'its',
  'this', 'that', 'these', 'those', 'as', 'from', 'by', 'about', 'into', 'through',
  'during', 'before', 'after', 'above', 'below', 'between', 'so', 'than', 'too', 'very',
  'can', 'just', 'like', 'really', 'also', 'when', 'what', 'which', 'who', 'how', 'why',
  'want', 'love', 'enjoy', 'interested', 'interest', 'lot', 'lots', 'much', 'more'
]);

const TRAIT_PATTERNS: Array<{ pattern: RegExp; trait: string; weight: number }> = [
  { pattern: /\b(lead|leader|organiz|captain|president|head)\w*/i, trait: 'leadership', weight: 4 },
  { pattern: /\b(team|group|collab|together|peer)\w*/i, trait: 'collaboration', weight: 2 },
  { pattern: /\b(code|program|software|cs|computer|developer|hack|engineer)\w*/i, trait: 'technical', weight: 4 },
  { pattern: /\b(volunteer|community|charity|outreach)\w*|help others/i, trait: 'community', weight: 3 },
  { pattern: /\b(study|exam|learn|academic|homework|midterm|finals|research)\w*/i, trait: 'academic_focus', weight: 3 },
  { pattern: /\b(sport|fitness|gym|football|basketball|athlet|run)\w*/i, trait: 'active', weight: 2 },
  { pattern: /\b(art|design|creative|music|draw|paint|photo)\w*/i, trait: 'creative', weight: 2 },
  { pattern: /\b(business|entrepreneur|startup|market|finance|found)\w*/i, trait: 'business_minded', weight: 3 },
  { pattern: /\b(speak|debate|present|pitch|communicat)\w*/i, trait: 'communicator', weight: 3 }
];

const INTEREST_LEXICON: Record<string, string[]> = {
  Programming: ['code', 'coding', 'program', 'programming', 'software', 'developer', 'python', 'java', 'javascript', 'web', 'hackathon', 'hack', 'computer'],
  'Public Speaking': ['speak', 'speaking', 'debate', 'presentation', 'present', 'pitch', 'communication'],
  Volunteering: ['volunteer', 'community', 'charity', 'service', 'outreach'],
  'Study Groups': ['study', 'studying', 'tutor', 'exam', 'homework', 'academic', 'learning', 'midterm', 'finals'],
  Gaming: ['game', 'gaming', 'gamer', 'esports'],
  Music: ['music', 'sing', 'guitar', 'piano', 'band', 'concert'],
  Photography: ['photo', 'photography', 'camera', 'photographer'],
  Sports: ['sport', 'football', 'basketball', 'gym', 'fitness', 'soccer', 'athletic', 'workout'],
  Reading: ['reading', 'book', 'novel', 'literature'],
  'Digital Art': ['illustration', 'graphic', 'animation', 'ui', 'ux', 'figma', 'paint', 'painting'],
  'Cultural Events': ['cultural', 'culture', 'heritage', 'festival', 'tradition'],
  Entrepreneurship: ['business', 'entrepreneur', 'startup', 'marketing', 'finance', 'founder', 'innovation']
};

const SKILL_LEXICON: Record<string, string[]> = {
  Python: ['python'],
  Java: ['java'],
  JavaScript: ['javascript', 'typescript'],
  'Web Development': ['html', 'css', 'react', 'frontend', 'backend', 'fullstack', 'web development'],
  'Mobile Development': ['android', 'ios', 'flutter', 'swift', 'kotlin', 'mobile'],
  'UI/UX Design': ['figma', 'wireframe', 'prototype', 'ux', 'ui'],
  'Data Analysis': ['sql', 'tableau', 'analytics', 'pandas', 'statistics'],
  'Machine Learning': ['machine learning', 'ml', 'tensorflow', 'pytorch'],
  'Public Speaking': ['speaking', 'debate', 'presentation', 'pitch'],
  Leadership: ['leadership', 'mentoring', 'mentor', 'organizing'],
  'Project Management': ['scrum', 'agile', 'project management', 'kanban']
};

const GOAL_PATTERNS = [
  /\bhope to\s+([^\.!\n;]+)/gi,
  /\b(?:want|plan|aim|looking) to\s+([^\.!\n;]+)/gi,
  /\bmy goals? are to\s+([^\.!\n;]+)/gi,
  /\bmy goal is to\s+([^\.!\n;]+)/gi,
  /\bgoal is to\s+([^\.!\n;]+)/gi
];

function tokenize(text: string): string[] {
  const raw = text.toLowerCase().match(/[a-z]{3,}/g) ?? [];
  return raw.filter((t) => !STOPWORDS.has(t));
}

function wordBoundaryMatch(word: string, text: string): boolean {
  if (word.length <= 2) return false;
  return new RegExp(`\\b${word.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\b`, 'i').test(text);
}

function scoreLexicon(words: string[], tokenSet: Set<string>, text: string): number {
  const lower = text.toLowerCase();
  let score = 0;
  for (const word of words) {
    if (tokenSet.has(word)) {
      score += 2;
      continue;
    }
    if (wordBoundaryMatch(word, lower)) score += 1;
  }
  return score;
}

function extractFromLexicon(
  lexicon: Record<string, string[]>,
  tokenSet: Set<string>,
  text: string,
  limit: number
): string[] {
  const scored: Array<[string, number]> = [];
  for (const [label, words] of Object.entries(lexicon)) {
    const score = scoreLexicon(words, tokenSet, text);
    if (score > 0) scored.push([label, score]);
  }
  scored.sort((a, b) => b[1] - a[1]);
  return scored.slice(0, limit).map(([label]) => label);
}

function extractTraits(text: string): Record<string, string> {
  const traits: Record<string, string> = {};
  const matched = TRAIT_PATTERNS.filter(({ pattern }) => pattern.test(text))
    .sort((a, b) => b.weight - a.weight);
  for (const { trait } of matched) {
    if (traits[trait]) continue;
    traits[trait] = 'detected';
    if (Object.keys(traits).length >= 4) break;
  }
  return traits;
}

function extractGoals(text: string): string[] {
  const found: string[] = [];
  const seen = new Set<string>();
  for (const pattern of GOAL_PATTERNS) {
    for (const match of text.matchAll(pattern)) {
      let goal = (match[1] ?? '').trim().replace(/,$/, '');
      if (!goal) continue;
      goal = goal[0].toUpperCase() + goal.slice(1);
      const key = goal.toLowerCase();
      if (seen.has(key)) continue;
      seen.add(key);
      found.push(goal.length > 140 ? `${goal.slice(0, 137).trim()}...` : goal);
      if (found.length >= 3) return found;
    }
  }
  return found;
}

function topKeywords(tokens: string[], limit = 8): string[] {
  if (!tokens.length) return [];
  const counts = new Map<string, number>();
  for (const t of tokens) counts.set(t, (counts.get(t) ?? 0) + 1);
  return [...counts.entries()]
    .sort((a, b) => b[1] - a[1])
    .slice(0, limit)
    .map(([word]) => word);
}

function buildSummary(
  traits: Record<string, string>,
  interests: string[],
  skills: string[],
  keywords: string[]
): string {
  const traitNames = Object.keys(traits).join(', ') || 'general campus engagement';
  const interestNames = interests.join(', ') || 'exploring campus opportunities';
  const skillNames = skills.join(', ') || 'building campus-ready skills';
  const keywordNames = keywords.slice(0, 5).join(', ') || 'varied topics';
  return (
    `Profile highlights strengths in ${traitNames}. ` +
    `Interests include ${interestNames}. ` +
    `Skills to grow: ${skillNames}. ` +
    `Key themes: ${keywordNames}.`
  );
}

function computeConfidence(
  traits: Record<string, string>,
  interests: string[],
  skills: string[],
  keywords: string[],
  tokenCount: number
): number {
  let confidence = Math.min(
    0.95,
    0.4 + 0.08 * Object.keys(traits).length + 0.05 * interests.length +
      0.04 * skills.length + 0.015 * keywords.length
  );
  if (tokenCount < 12 && Object.keys(traits).length + interests.length + skills.length < 3) {
    confidence = Math.min(confidence, 0.55);
  }
  return Math.round(confidence * 100) / 100;
}

export function analyzeShamsMessageFallback(message: string): ShamsExtraction {
  const text = message.trim();
  const tokens = tokenize(text);
  const tokenSet = new Set(tokens);
  const traits = extractTraits(text);
  const interests = extractFromLexicon(INTEREST_LEXICON, tokenSet, text, 6);
  const skills = extractFromLexicon(SKILL_LEXICON, tokenSet, text, 6);
  const keywords = topKeywords(tokens);
  const goals = extractGoals(text);
  const needsDetail = interests.length === 0 && skills.length === 0;

  if (needsDetail) {
    return {
      reply:
        'Thanks for sharing! To build a useful profile, tell me a bit more — mention 2–3 things you enjoy on campus (for example programming, sports, volunteering, music, or public speaking).',
      traits: {},
      interests: [],
      skills: [],
      keywords,
      major: null,
      year: null,
      academic_year: null,
      goals,
      profile_summary: '',
      profile_text: text,
      confidence: computeConfidence({}, [], [], keywords, tokens.length),
      needs_detail: true
    };
  }

  if (!Object.keys(traits).length) traits.exploratory = 'open_to_discovery';

  const profileSummary = buildSummary(traits, interests, skills, keywords);
  const confidence = computeConfidence(traits, interests, skills, keywords, tokens.length);
  const traitList = Object.keys(traits).join(', ');
  const interestHint = interests.length ? ` and interests in ${interests.slice(0, 3).join(', ')}` : '';
  const skillHint = skills.length ? ` Skills spotted: ${skills.slice(0, 3).join(', ')}.` : '';
  const goalHint = goals.length ? ` Goals: ${goals.slice(0, 2).join('; ')}.` : '';
  const reply =
    `Thanks for sharing. From your message I picked up themes around ${traitList}${interestHint}.${skillHint}${goalHint} ` +
    `I drafted a profile preview (confidence ${Math.round(confidence * 100)}%). ` +
    'Review it and choose **Keep** to save or **Re-enter** to try again.';

  return {
    reply,
    traits,
    interests,
    skills,
    keywords,
    major: null,
    year: null,
    academic_year: null,
    goals,
    profile_summary: profileSummary,
    profile_text: text,
    confidence,
    needs_detail: false
  };
}
