"""Shams profiling: NLP extraction from free-text student messages.

Pipeline (all graceful-degrading when NLTK data/resources are unavailable):
  1. Tokenize -> lowercase, strip punctuation, drop stopwords + short tokens.
  2. Lemmatize tokens (WordNet) so "coding"/"coded" -> "code".
  3. Extract personality *traits* via weighted regex cue patterns (capped).
  4. Map the text to canonical *interest* and *skill* vocabularies via lexicons.
  5. Rank salient *keywords* (unigrams + bigrams) by frequency.
  6. Build a human-readable summary + a calibrated confidence score.
"""
from __future__ import annotations

import re
from collections import Counter

# Light NLP: NLTK tokenization + stopwords + lemmatizer (download once on use).
try:
    import nltk
    from nltk.corpus import stopwords
    from nltk.stem import WordNetLemmatizer
    from nltk.tokenize import word_tokenize

    def _ensure_nltk_data() -> None:
        for resource, pkg in [
            ("tokenizers/punkt", "punkt"),
            ("tokenizers/punkt_tab", "punkt_tab"),
            ("corpora/stopwords", "stopwords"),
            ("corpora/wordnet", "wordnet"),
            ("corpora/omw-1.4", "omw-1.4"),
        ]:
            try:
                nltk.data.find(resource)
            except LookupError:
                nltk.download(pkg, quiet=True)

    _NLTK_AVAILABLE = True
    _LEMMATIZER = WordNetLemmatizer()
    _NLTK_PREPARED = False
except ImportError:
    _NLTK_AVAILABLE = False
    _LEMMATIZER = None
    _NLTK_PREPARED = False


def prepare_nltk() -> None:
    """Download/load NLTK resources once (call on AI service startup)."""
    global _NLTK_PREPARED
    if _NLTK_PREPARED or not _NLTK_AVAILABLE:
        return
    _ensure_nltk_data()
    _NLTK_PREPARED = True

MAX_TRAITS = 4
MAX_INTERESTS = 6
MAX_SKILLS = 6
MIN_TOKENS_FOR_PREVIEW = 12
SHORT_MESSAGE_CONFIDENCE_CAP = 0.55

# Substring-only hits for these words are ignored unless the lemma appears in tokens.
WEAK_LEXICON_WORDS = frozenset(
    {
        "help",
        "group",
        "new",
        "try",
        "play",
        "read",
        "write",
        "art",
        "design",
        "market",
        "found",
        "run",
        "video",
        "story",
        "learn",
    }
)

TRAIT_WEIGHTS: dict[str, int] = {
    "leadership": 4,
    "technical": 4,
    "community": 3,
    "communicator": 3,
    "business_minded": 3,
    "academic_focus": 3,
    "collaboration": 2,
    "active": 2,
    "creative": 2,
    "curious": 1,
}

# Personality / strength cues -> trait label. Matched against the raw lowercase
# text so multi-word cues ("help others") still work.
TRAIT_PATTERNS: list[tuple[str, str]] = [
    (r"\b(lead|leader|organiz|captain|president|head)\w*", "leadership"),
    (r"\b(team|group|collab|together|peer)\w*", "collaboration"),
    (r"\b(code|program|software|cs|computer|developer|hack|engineer)\w*", "technical"),
    (r"\b(volunteer|community|charity|outreach)\w*|help others", "community"),
    (r"\b(study|exam|learn|academic|homework|midterm|finals|research)\w*", "academic_focus"),
    (r"\b(sport|fitness|gym|football|basketball|athlet|run)\w*", "active"),
    (r"\b(art|design|creative|music|draw|paint|photo)\w*", "creative"),
    (r"\b(business|entrepreneur|startup|market|finance|found)\w*", "business_minded"),
    (r"\b(speak|debate|present|pitch|communicat)\w*", "communicator"),
    (r"\b(curious|explore|discover)\w*", "curious"),
]

# Canonical interests must match the Flutter app's interest options so the
# extracted profile renders natively (pills, goals, event targeting).
INTEREST_LEXICON: dict[str, list[str]] = {
    "Programming": [
        "code",
        "coding",
        "program",
        "programming",
        "software",
        "developer",
        "python",
        "java",
        "javascript",
        "web",
        "hackathon",
        "hack",
        "algorithm",
        "computer",
        "cyber",
        "robotics",
    ],
    "Public Speaking": [
        "speak",
        "speaking",
        "debate",
        "presentation",
        "present",
        "pitch",
        "toastmaster",
        "rhetoric",
        "communication",
        "communicate",
    ],
    "Volunteering": [
        "volunteer",
        "community",
        "charity",
        "service",
        "outreach",
        "ngo",
        "donate",
        "nonprofit",
    ],
    "Study Groups": [
        "study",
        "studying",
        "tutor",
        "tutoring",
        "exam",
        "revision",
        "homework",
        "academic",
        "learning",
        "midterm",
        "finals",
    ],
    "Gaming": [
        "game",
        "gaming",
        "gamer",
        "esports",
        "console",
        "playstation",
        "xbox",
        "videogame",
    ],
    "Music": [
        "music",
        "sing",
        "singing",
        "guitar",
        "piano",
        "band",
        "concert",
        "instrument",
        "song",
        "dj",
    ],
    "Photography": [
        "photo",
        "photography",
        "camera",
        "photographer",
        "photoshoot",
        "picture",
        "filmmaking",
    ],
    "Sports": [
        "sport",
        "football",
        "basketball",
        "gym",
        "fitness",
        "soccer",
        "athletic",
        "running",
        "workout",
        "swim",
        "tennis",
    ],
    "Reading": [
        "reading",
        "book",
        "novel",
        "literature",
        "poetry",
        "blog",
    ],
    "Digital Art": [
        "illustration",
        "graphic",
        "animation",
        "ui",
        "ux",
        "figma",
    ],
    "Cultural Events": [
        "cultural",
        "culture",
        "heritage",
        "festival",
        "tradition",
        "language",
        "exchange",
        "diversity",
        "international",
    ],
    "Entrepreneurship": [
        "business",
        "entrepreneur",
        "startup",
        "marketing",
        "finance",
        "invest",
        "founder",
        "company",
        "innovation",
    ],
}

# Concrete skills (stored on profile strength rings), separate from broad traits.
SKILL_LEXICON: dict[str, list[str]] = {
    "Python": ["python"],
    "Java": ["java"],
    "JavaScript": ["javascript", "typescript"],
    "Web Development": ["html", "css", "react", "angular", "vue", "frontend", "backend", "fullstack"],
    "Mobile Development": ["android", "ios", "flutter", "swift", "kotlin", "mobile"],
    "UI/UX Design": ["figma", "wireframe", "prototype", "ux", "ui"],
    "Data Analysis": ["sql", "tableau", "analytics", "pandas", "statistics"],
    "Machine Learning": ["machine learning", "ml", "tensorflow", "pytorch", "model"],
    "Public Speaking": ["speaking", "debate", "presentation", "pitch"],
    "Leadership": ["leadership", "mentoring", "mentor", "organizing"],
    "Project Management": ["scrum", "agile", "project management", "kanban"],
    "Photography": ["photography", "photographer", "lightroom"],
    "Video Editing": ["premiere", "video editing", "after effects", "davinci"],
}

MAX_GOALS = 3

# Canonical majors aligned with Flutter MockData.majors.
MAJOR_ALIASES: dict[str, list[str]] = {
    "Computer Science": [
        "computer science",
        "comp sci",
        "computing",
        "cs student",
        "cs major",
    ],
    "Information Technology": ["information technology", "information systems", "it major"],
    "Software Engineering": ["software engineering", "software engineer"],
    "Business": ["business administration", "business major", "business student"],
    "Architecture": ["architecture", "architectural"],
    "Engineering": ["engineering student", "engineer major"],
    "English": ["english literature", "english major"],
}

YEAR_PATTERNS: list[tuple[re.Pattern[str], str, int]] = [
    (re.compile(r"\b(?:first|1st)[\s-]?year\b|\bfreshman\b|\byear\s*one\b|\byear\s*1\b", re.I), "1st Year", 1),
    (re.compile(r"\b(?:second|2nd)[\s-]?year\b|\bsophomore\b|\byear\s*two\b|\byear\s*2\b", re.I), "2nd Year", 2),
    (re.compile(r"\b(?:third|3rd)[\s-]?year\b|\bjunior\b|\byear\s*three\b|\byear\s*3\b", re.I), "3rd Year", 3),
    (re.compile(r"\b(?:fourth|4th)[\s-]?year\b|\bsenior\b|\byear\s*four\b|\byear\s*4\b", re.I), "4th Year", 4),
    (re.compile(r"\b(?:fifth|5th)[\s-]?year\b|\byear\s*five\b|\byear\s*5\b", re.I), "5th Year", 5),
]

GOAL_PATTERNS: list[re.Pattern[str]] = [
    re.compile(r"\bhope to\s+([^\.!\n;]+)", re.I),
    re.compile(r"\b(?:want|plan|aim|looking) to\s+([^\.!\n;]+)", re.I),
    re.compile(r"\bmy goal is to\s+([^\.!\n;]+)", re.I),
    re.compile(r"\bgoal is to\s+([^\.!\n;]+)", re.I),
]

_BUILTIN_STOPWORDS = {
    "a", "an", "the", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with",
    "is", "am", "are", "was", "were", "be", "been", "being", "have", "has", "had",
    "do", "does", "did", "will", "would", "could", "should", "may", "might", "must",
    "i", "me", "my", "we", "our", "you", "your", "they", "them", "their", "it", "its",
    "this", "that", "these", "those", "as", "from", "by", "about", "into", "through",
    "during", "before", "after", "above", "below", "between", "so", "than", "too", "very",
    "can", "just", "like", "really", "also", "when", "what", "which", "who", "how", "why",
    "want", "love", "enjoy", "interested", "interest", "lot", "lots", "much", "more",
}


def _stopword_set() -> set[str]:
    if _NLTK_AVAILABLE:
        try:
            if not _NLTK_PREPARED:
                prepare_nltk()
            return set(stopwords.words("english")) | _BUILTIN_STOPWORDS
        except Exception:
            return _BUILTIN_STOPWORDS
    return _BUILTIN_STOPWORDS


def _lemmatize(token: str) -> str:
    if _LEMMATIZER is None:
        return token
    try:
        verb = _LEMMATIZER.lemmatize(token, pos="v")
        return _LEMMATIZER.lemmatize(verb, pos="n")
    except Exception:
        return token


def _tokenize(text: str) -> list[str]:
    """Cleaned, human-readable tokens (used for keyword display)."""
    text = text.lower().strip()
    stop = _stopword_set()
    if _NLTK_AVAILABLE:
        try:
            if not _NLTK_PREPARED:
                prepare_nltk()
            raw = word_tokenize(text)
        except Exception:
            raw = re.findall(r"[a-z]{3,}", text)
    else:
        raw = re.findall(r"[a-z]{3,}", text)
    return [t for t in raw if t.isalpha() and len(t) > 2 and t not in stop]


def _lemma_set(tokens: list[str]) -> set[str]:
    lemmas: set[str] = set()
    for t in tokens:
        lemmas.add(t)
        lemmas.add(_lemmatize(t))
    return lemmas


def _word_boundary_match(word: str, text: str) -> bool:
    if len(word) <= 2:
        return False
    return re.search(rf"\b{re.escape(word)}\b", text, flags=re.IGNORECASE) is not None


def _score_lexicon(words: list[str], token_set: set[str], text: str) -> int:
    """Score a lexicon entry using lemma hits (+2) and whole-word hits (+1)."""
    lower = text.lower()
    score = 0
    for word in words:
        lemma = _lemmatize(word)
        lemma_hit = word in token_set or lemma in token_set
        if lemma_hit:
            score += 2
            continue
        if word in WEAK_LEXICON_WORDS:
            continue
        if _word_boundary_match(word, lower):
            score += 1
    return score


def _extract_major(text: str) -> str | None:
    lower = text.lower()
    best_label: str | None = None
    best_score = 0
    for label, aliases in MAJOR_ALIASES.items():
        score = 0
        if _word_boundary_match(label.lower(), lower):
            score += 3
        for alias in aliases:
            if alias in lower or _word_boundary_match(alias, lower):
                score += 2
        if score > best_score:
            best_score = score
            best_label = label
    return best_label if best_score > 0 else None


def _extract_year(text: str) -> tuple[str | None, int | None]:
    for pattern, label, numeric in YEAR_PATTERNS:
        if pattern.search(text):
            return label, numeric
    return None, None


def _normalize_goal(clause: str) -> str:
    cleaned = clause.strip().strip(",").strip()
    if not cleaned:
        return ""
    cleaned = cleaned[0].upper() + cleaned[1:]
    if len(cleaned) > 140:
        cleaned = f"{cleaned[:137].rstrip()}..."
    return cleaned


def _extract_goals(text: str) -> list[str]:
    found: list[str] = []
    seen: set[str] = set()
    for pattern in GOAL_PATTERNS:
        for match in pattern.finditer(text):
            goal = _normalize_goal(match.group(1))
            key = goal.lower()
            if not goal or key in seen:
                continue
            seen.add(key)
            found.append(goal)
            if len(found) >= MAX_GOALS:
                return found
    return found


def _extract_traits(text: str) -> dict[str, str]:
    lower = text.lower()
    matched: list[tuple[int, str]] = []
    for pattern, trait in TRAIT_PATTERNS:
        if re.search(pattern, lower):
            matched.append((TRAIT_WEIGHTS.get(trait, 1), trait))
    matched.sort(key=lambda row: row[0], reverse=True)

    traits: dict[str, str] = {}
    for _, trait in matched:
        if trait in traits:
            continue
        traits[trait] = "detected"
        if len(traits) >= MAX_TRAITS:
            break
    return traits


def _extract_from_lexicon(
    lexicon: dict[str, list[str]],
    token_set: set[str],
    text: str,
    *,
    limit: int,
) -> list[str]:
    scored: list[tuple[str, int]] = []
    for label, words in lexicon.items():
        score = _score_lexicon(words, token_set, text)
        if score > 0:
            scored.append((label, score))
    scored.sort(key=lambda row: row[1], reverse=True)
    return [label for label, _ in scored[:limit]]


def _extract_freeform_interests(text: str, known: list[str]) -> list[str]:
    known_lower = {label.lower() for label in known}
    extras: list[str] = []
    for chunk in re.split(r"[,;\n]+", text):
        cleaned = chunk.strip()
        if len(cleaned) < 3 or len(cleaned) > 48:
            continue
        if cleaned.lower() in known_lower:
            continue
        if not re.match(r"^[a-zA-Z0-9\s&'-]+$", cleaned):
            continue
        title = cleaned[0].upper() + cleaned[1:] if len(cleaned) > 1 else cleaned.upper()
        if title.lower() in known_lower:
            continue
        extras.append(title)
        known_lower.add(title.lower())
    return extras[:4]


def _extract_interests(token_set: set[str], text: str) -> list[str]:
    interests = _extract_from_lexicon(
        INTEREST_LEXICON,
        token_set,
        text,
        limit=MAX_INTERESTS,
    )
    return _merge_unique_strings(interests + _extract_freeform_interests(text, interests))


def _merge_unique_strings(values: list[str]) -> list[str]:
    seen: set[str] = set()
    merged: list[str] = []
    for value in values:
        key = value.strip().lower()
        if not key or key in seen:
            continue
        seen.add(key)
        merged.append(value.strip())
    return merged


def _extract_skills(token_set: set[str], text: str) -> list[str]:
    return _extract_from_lexicon(
        SKILL_LEXICON,
        token_set,
        text,
        limit=MAX_SKILLS,
    )


def _top_keywords(tokens: list[str], limit: int = 8) -> list[str]:
    if not tokens:
        return []
    unigrams = Counter(tokens)
    bigrams = Counter(
        f"{tokens[i]} {tokens[i + 1]}" for i in range(len(tokens) - 1)
    )
    phrases = [phrase for phrase, count in bigrams.most_common() if count > 1]
    keywords = phrases[: limit // 2]
    for word, _ in unigrams.most_common(limit):
        if word not in " ".join(keywords) and word not in keywords:
            keywords.append(word)
        if len(keywords) >= limit:
            break
    return keywords[:limit]


def _build_summary(
    traits: dict[str, str],
    interests: list[str],
    skills: list[str],
    keywords: list[str],
) -> str:
    trait_names = ", ".join(traits.keys()) if traits else "general campus engagement"
    interest_names = ", ".join(interests) if interests else "exploring campus opportunities"
    skill_names = ", ".join(skills) if skills else "building campus-ready skills"
    keyword_names = ", ".join(keywords[:5]) if keywords else "varied topics"
    return (
        f"Profile highlights strengths in {trait_names}. "
        f"Interests include {interest_names}. "
        f"Skills to grow: {skill_names}. "
        f"Key themes: {keyword_names}."
    )


def _compute_confidence(
    traits: dict[str, str],
    interests: list[str],
    skills: list[str],
    keywords: list[str],
    *,
    token_count: int,
) -> float:
    confidence = min(
        0.95,
        0.40
        + 0.08 * len(traits)
        + 0.05 * len(interests)
        + 0.04 * len(skills)
        + 0.015 * len(keywords),
    )
    if token_count < MIN_TOKENS_FOR_PREVIEW and (
        len(traits) + len(interests) + len(skills) < 3
    ):
        confidence = min(confidence, SHORT_MESSAGE_CONFIDENCE_CAP)
    return round(confidence, 2)


def _filter_profile_fields_from_interests(
    interests: list[str],
    text: str,
    major: str | None,
    year_label: str | None,
) -> list[str]:
    blocked: set[str] = set()
    if major:
        blocked.add(major.strip().lower())
    if year_label:
        blocked.add(year_label.strip().lower())
    for pattern, label, _numeric in YEAR_PATTERNS:
        if pattern.search(text):
            blocked.add(label.strip().lower())
    name_match = re.search(
        r"\b(?:i am|i'm|im|my name is|name is)\s+([A-Za-z][A-Za-z'-]{1,23})\b",
        text,
        re.I,
    )
    if name_match:
        blocked.add(name_match.group(1).strip().lower())

    filtered: list[str] = []
    for interest in interests:
        key = interest.strip().lower()
        if not key or key in blocked:
            continue
        if re.fullmatch(
            r"(year\s*\d|first year|second year|third year|fourth year|"
            r"1st year|2nd year|3rd year|4th year|fifth year)",
            key,
        ):
            continue
        if key.isdigit():
            continue
        filtered.append(interest.strip())
    return filtered


def analyze_message(message: str) -> dict[str, object]:
    text = message.strip()
    tokens = _tokenize(text)
    token_set = _lemma_set(tokens)
    traits = _extract_traits(text)
    major = _extract_major(text)
    year_label, academic_year = _extract_year(text)
    interests = _extract_interests(token_set, text)
    interests = _filter_profile_fields_from_interests(
        interests,
        text,
        major,
        year_label,
    )
    skills = _extract_skills(token_set, text)
    keywords = _top_keywords(tokens)
    goals = _extract_goals(text)

    needs_detail = len(interests) == 0 and len(skills) == 0

    if needs_detail:
        reply = (
            "Thanks for sharing! To build a useful profile, tell me a bit more — "
            "mention 2–3 things you enjoy on campus (for example programming, sports, "
            "volunteering, music, or public speaking)."
        )
        return {
            "reply": reply,
            "traits": {},
            "interests": [],
            "skills": [],
            "keywords": keywords,
            "major": major,
            "year": year_label,
            "academic_year": academic_year,
            "goals": goals,
            "profile_summary": "",
            "profile_text": text,
            "confidence": _compute_confidence(
                {},
                [],
                [],
                keywords,
                token_count=len(tokens),
            ),
            "needs_detail": True,
        }

    if not traits:
        traits["exploratory"] = "open_to_discovery"

    profile_summary = _build_summary(traits, interests, skills, keywords)
    confidence = _compute_confidence(
        traits,
        interests,
        skills,
        keywords,
        token_count=len(tokens),
    )

    trait_list = ", ".join(traits.keys())
    interest_hint = (
        f" and interests in {', '.join(interests[:3])}" if interests else ""
    )
    skill_hint = f" Skills spotted: {', '.join(skills[:3])}." if skills else ""
    major_hint = f" Major: {major}." if major else ""
    year_hint = f" Year: {year_label}." if year_label else ""
    goal_hint = f" Goals: {'; '.join(goals[:2])}." if goals else ""
    reply = (
        f"Thanks for sharing. From your message I picked up themes around {trait_list}"
        f"{interest_hint}.{skill_hint}{major_hint}{year_hint}{goal_hint} "
        f"I drafted a profile preview (confidence {confidence:.0%}). "
        "Review it and choose **Keep** to save or **Re-enter** to try again."
    )

    return {
        "reply": reply,
        "traits": traits,
        "interests": interests,
        "skills": skills,
        "keywords": keywords,
        "major": major,
        "year": year_label,
        "academic_year": academic_year,
        "goals": goals,
        "profile_summary": profile_summary,
        "profile_text": text,
        "confidence": confidence,
        "needs_detail": False,
    }
