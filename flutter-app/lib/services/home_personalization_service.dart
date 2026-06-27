import '../models/club.dart';
import '../models/event.dart';
import '../models/study_session.dart';

/// Ranks campus events and clubs against a student's interests, skills, and major.
class HomePersonalizationService {
  const HomePersonalizationService._();

  /// Minimum score to appear on the personalized home feed (not the full catalog).
  static const double minSuggestionScore = 0.12;

  static List<Event> rankEvents(
    List<Event> events, {
    required List<String> interests,
    required List<String> skills,
    String? major,
    int limit = 8,
  }) {
    if (events.isEmpty) return const [];
    if (interests.isEmpty && skills.isEmpty && (major == null || major.isEmpty)) {
      return events.take(limit).toList(growable: false);
    }

    final scored = events
        .map(
          (event) => (
            event: event,
            score: _scoreEvent(
              event,
              interests: interests,
              skills: skills,
              major: major,
            ),
          ),
        )
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored
        .where((row) => row.score >= minSuggestionScore)
        .map((row) => row.event)
        .take(limit)
        .toList(growable: false);
  }

  static List<Club> rankClubs(
    List<Club> clubs, {
    required List<String> interests,
    required List<String> skills,
    String? major,
    int limit = 8,
  }) {
    final active = clubs.where((c) => c.isActive).toList(growable: false);
    if (active.isEmpty) return const [];
    if (interests.isEmpty && skills.isEmpty && (major == null || major.isEmpty)) {
      return active.take(limit).toList(growable: false);
    }

    final scored = active
        .map(
          (club) => (
            club: club,
            score: _scoreClub(
              club,
              interests: interests,
              skills: skills,
              major: major,
            ),
          ),
        )
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored
        .where((row) => row.score >= minSuggestionScore)
        .map((row) => row.club)
        .take(limit)
        .toList(growable: false);
  }

  static List<StudySession> rankStudySessions(
    List<StudySession> sessions, {
    required List<String> interests,
    required List<String> skills,
    String? major,
    Set<String> hostSessionIds = const {},
    Set<String> joinedSessionIds = const {},
    int limit = 12,
  }) {
    if (sessions.isEmpty) return const [];

    final alwaysInclude = sessions.where(
      (s) => hostSessionIds.contains(s.id) || joinedSessionIds.contains(s.id),
    );

    if (interests.isEmpty &&
        skills.isEmpty &&
        (major == null || major.isEmpty || major == 'Undeclared')) {
      return sessions.take(limit).toList(growable: false);
    }

    final scored = sessions
        .map(
          (session) => (
            session: session,
            score: _scoreStudySession(
              session,
              interests: interests,
              skills: skills,
              major: major,
            ),
          ),
        )
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    final ranked = scored
        .where((row) => row.score > 0.01)
        .map((row) => row.session)
        .toList(growable: false);

    final merged = <String, StudySession>{};
    for (final session in [...alwaysInclude, ...ranked]) {
      merged[session.id] = session;
    }
    return merged.values.take(limit).toList(growable: false);
  }

  static double _scoreStudySession(
    StudySession session, {
    required List<String> interests,
    required List<String> skills,
    String? major,
  }) {
    final text =
        '${session.course} ${session.details} ${session.type.label} ${session.host}';

    if (_isExcludedTopic(text, interests: interests, skills: skills, major: major)) {
      return 0;
    }

    var score = 0.0;
    score += _listMatchScore(interests, text) * 0.5;
    score += _listMatchScore(skills, text) * 0.35;

    final normalizedMajor = major?.trim();
    if (normalizedMajor != null &&
        normalizedMajor.isNotEmpty &&
        normalizedMajor != 'Undeclared') {
      score += _listMatchScore([normalizedMajor], text) * 0.15;
    }

    return score;
  }

  static bool _isExcludedTopic(
    String text, {
    required List<String> interests,
    required List<String> skills,
    String? major,
  }) {
    const topicKeywords = <String, List<String>>{
      'art': [
        'art',
        'artist',
        'painting',
        'drawing',
        'gallery',
        'sculpture',
        'illustration',
        'visual arts',
      ],
      'music': ['music', 'orchestra', 'choir', 'band', 'concert', 'singing'],
      'sports': [
        'sport',
        'football',
        'basketball',
        'soccer',
        'athletic',
        'fitness',
        'volleyball',
      ],
      'drama': ['drama', 'theatre', 'theater', 'acting', 'performance'],
      'business': [
        'business',
        'entrepreneur',
        'marketing',
        'finance',
        'accounting',
        'mba',
        'commerce',
      ],
      'medicine': ['medicine', 'nursing', 'pharmacy', 'clinical', 'medical'],
      'law': ['law', 'legal', 'juris'],
      'engineering': ['engineering', 'robotics', 'mechanical', 'electrical'],
    };

    final profileBlob =
        '${interests.join(' ')} ${skills.join(' ')} ${major ?? ''}'.toLowerCase();
    final lower = text.toLowerCase();

    for (final entry in topicKeywords.entries) {
      final hitsTopic = entry.value.any((kw) => _textMentionsKeyword(lower, kw));
      if (!hitsTopic) continue;

      final profileMatch = _listMatchScore(
            [entry.key, ...entry.value],
            profileBlob,
          ) >
          0.01;
      final interestMatch = _listMatchScore(interests, lower) > 0.01;
      if (!profileMatch && !interestMatch) {
        return true;
      }
    }
    return false;
  }

  /// Avoid substring false positives (e.g. "art" inside "smart").
  static bool _textMentionsKeyword(String lowerText, String keyword) {
    final normalized = keyword.trim().toLowerCase();
    if (normalized.isEmpty) return false;
    if (normalized.length <= 4) {
      return RegExp('\\b${RegExp.escape(normalized)}\\b').hasMatch(lowerText);
    }
    return lowerText.contains(normalized);
  }

  static double _scoreEvent(
    Event event, {
    required List<String> interests,
    required List<String> skills,
    String? major,
  }) {
    final text =
        '${event.title} ${event.about} ${event.format} ${event.tags.join(' ')} '
        '${event.targetInterests.join(' ')} ${event.category.label}';

    if (_isExcludedTopic(text, interests: interests, skills: skills, major: major)) {
      return 0;
    }

    final interestMatch = _listMatchScore(interests, text);
    final skillMatch = _listMatchScore(skills, text);
    final targetInterestMatch = event.targetInterests.isEmpty
        ? 0.0
        : _listMatchScore(interests, event.targetInterests.join(' '));

    if (interestMatch <= 0 && skillMatch <= 0 && targetInterestMatch <= 0) {
      return 0;
    }

    var score = 0.0;
    score += interestMatch * 0.42;
    score += skillMatch * 0.38;
    score += targetInterestMatch * 0.12;

    final normalizedMajor = major?.trim();
    if (normalizedMajor != null &&
        normalizedMajor.isNotEmpty &&
        normalizedMajor != 'Undeclared') {
      score += _listMatchScore([normalizedMajor], text) * 0.08;
      if (event.targetMajors.isNotEmpty &&
          event.targetMajors.any(
            (m) => m.toLowerCase() == normalizedMajor.toLowerCase(),
          )) {
        score += 0.05;
      }
    }

    return score;
  }

  static double _scoreClub(
    Club club, {
    required List<String> interests,
    required List<String> skills,
    String? major,
  }) {
    final text =
        '${club.name} ${club.description} ${club.focus} ${club.category.label} '
        '${club.roles.join(' ')}';

    if (_isExcludedTopic(text, interests: interests, skills: skills, major: major)) {
      return 0;
    }

    final interestMatch = _listMatchScore(interests, text);
    final skillMatch = _listMatchScore(skills, text);
    if (interestMatch <= 0 && skillMatch <= 0) {
      return 0;
    }

    var score = 0.0;
    score += interestMatch * 0.48;
    score += skillMatch * 0.37;

    final normalizedMajor = major?.trim();
    if (normalizedMajor != null &&
        normalizedMajor.isNotEmpty &&
        normalizedMajor != 'Undeclared') {
      score += _listMatchScore([normalizedMajor], text) * 0.15;
    }

    return score;
  }

  /// Overlap between profile tokens and searchable text (mirrors backend match logic).
  static double _listMatchScore(
    List<String> items,
    String text, {
    double emptyDefault = 0,
  }) {
    final cleaned = items.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (cleaned.isEmpty) return emptyDefault;

    final lower = text.toLowerCase();
    var hits = 0;
    for (final item in cleaned) {
      final normalized = item.toLowerCase();
      final tokens = normalized
          .split(RegExp(r'\W+'))
          .where((token) => token.length > 3);
      if (lower.contains(normalized) || tokens.any((token) => lower.contains(token))) {
        hits++;
      }
    }
    return (hits / cleaned.length).clamp(0.0, 1.0);
  }
}
