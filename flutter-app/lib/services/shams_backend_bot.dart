import 'dart:math';

import '../core/network/api_exception.dart';
import '../data/repositories/profiling_repository.dart';
import '../models/chat_message.dart';
import '../utils/university_id.dart';
import 'shams_bot.dart';

/// Shams powered by backend NLP: POST /profiling/shams/chat → draft preview.
class ShamsBackendBot implements OnboardingBot {
  ShamsBackendBot(this._repo);

  final ProfilingRepository _repo;
  final Random _rng = Random();

  String _id() =>
      'm-${DateTime.now().microsecondsSinceEpoch}-${_rng.nextInt(99999)}';

  ChatMessage _bot(
    String text, {
    ChatInputMode input = ChatInputMode.none,
    List<String> quickReplies = const [],
  }) =>
      ChatMessage(
        id: _id(),
        role: ChatRole.bot,
        text: text,
        inputMode: input,
        quickReplies: quickReplies,
      );

  @override
  Future<BotTurn> start(BotState state) async {
    if (state.isProfileUpdate) {
      return _profileUpdateStart(state);
    }

    try {
      final draft = await _repo.myDraft();
      if (draft != null) {
        return _confirmTurn(_stateFromDraft(state, draft));
      }
    } catch (_) {}

    return BotTurn(
      state.copyWith(phase: BotPhase.nlpIntro, usesBackendNlp: true),
      [
        _bot(
          "Hi, I'm Shams — your AAURA assistant. I'll build your campus profile from a short conversation.",
        ),
        _bot(
          'Tell me about yourself: interests, goals, clubs, or what you enjoy on campus. A few sentences is perfect.',
          input: ChatInputMode.text,
        ),
      ],
    );
  }

  BotTurn _profileUpdateStart(BotState state) {
    final interestHint = state.interests.isEmpty
        ? ''
        : '\n\nCurrent interests: ${state.interests.join(', ')}.';
    final skillHint = state.skills.isEmpty
        ? ''
        : '\nCurrent skills: ${state.skills.join(', ')}.';
    return BotTurn(
      state.copyWith(phase: BotPhase.nlpIntro, usesBackendNlp: true),
      [
        _bot(
          "Welcome back! Tell me what's new — interests, skills, or goals you want to add.$interestHint$skillHint",
        ),
        _bot(
          'Share only the updates you want saved. I will merge them with your existing profile.',
          input: ChatInputMode.text,
        ),
      ],
    );
  }

  @override
  Future<BotTurn> reply(
    BotState state,
    String text,
    List<String> selections,
  ) async {
    switch (state.phase) {
      case BotPhase.nlpIntro:
        return _handleIntroMessage(state, text);
      case BotPhase.nlpConfirm:
        return _handleConfirmChoice(state, text);
      case BotPhase.askStudentId:
        return _handleStudentId(state, text);
      default:
        return start(state);
    }
  }

  bool _hasValidStudentId(String? value) => UniversityId.isValid(value);

  Future<BotTurn> _handleStudentId(BotState state, String text) async {
    final id = text.trim();
    if (!_hasValidStudentId(id)) {
      return BotTurn(state, [
        _bot(
          "That doesn't look like a valid AAUP student ID. Enter at least 6 digits.",
          input: ChatInputMode.numeric,
        ),
      ]);
    }
    return BotTurn(
      state.copyWith(phase: BotPhase.done, studentId: id),
      [_bot('Got it — saving your profile now.')],
    );
  }

  Future<BotTurn> _handleIntroMessage(BotState state, String text) async {
    final message = text.trim();
    if (message.isEmpty) {
      return BotTurn(state, [
        _bot(
          'Share a little about yourself so I can draft your profile.',
          input: ChatInputMode.text,
        ),
      ]);
    }

    try {
      final data = await _repo.chat(message);
      final preview = data['preview'];
      if (preview is! Map<String, dynamic>) {
        throw StateError('Missing preview');
      }
      if (preview['needs_detail'] == true) {
        final reply =
            (data['reply'] as String?) ?? 'Tell me a bit more about yourself.';
        return BotTurn(
          state.copyWith(
            phase: BotPhase.nlpIntro,
            interests: const [],
            skills: const [],
            goals: const [],
            profileSummary: null,
            traits: null,
            nlpConfidence: null,
          ),
          [
            _bot(reply),
            _bot(
              'What are you into at AAUP?',
              input: ChatInputMode.text,
            ),
          ],
        );
      }
      final reply = (data['reply'] as String?) ?? 'Here is your profile preview.';
      final next = _stateFromPreview(state, preview, profileText: message);
      return BotTurn(next, [
        _bot(reply),
        _bot(_formatPreview(preview)),
        _bot(
          'Save this profile to AAURA?',
          input: ChatInputMode.confirm,
          quickReplies: const ['Keep', 'Re-enter'],
        ),
      ]);
    } on ApiException catch (e) {
      final detail = e.message.trim();
      final hint = e.statusCode == 0
          ? 'The request timed out. Please wait a moment and try again.'
          : e.statusCode == 403
              ? 'Your campus account may still be setting up — wait a moment, then try again.'
              : e.statusCode == 502 || e.statusCode == 503
                  ? 'Shams is temporarily unavailable. Try again in a moment, or tap Form to fill your profile manually.'
                  : e.statusCode >= 500
                      ? 'Tap **Form** above to complete your profile manually, or try again in a moment.'
                      : 'Something went wrong. Try again, or use the Form option above.';
      return BotTurn(state, [
        _bot(
          detail.isNotEmpty ? '$detail $hint' : hint,
          input: ChatInputMode.text,
        ),
      ]);
    } catch (_) {
      return BotTurn(state, [
        _bot(
          "I couldn't reach the profiling service right now. Try again, or tap Form to complete your profile manually.",
          input: ChatInputMode.text,
        ),
      ]);
    }
  }

  Future<BotTurn> _handleConfirmChoice(BotState state, String text) async {
    final choice = text.trim().toLowerCase();
    if (choice.startsWith('keep') || choice.startsWith('looks')) {
      if (!_hasValidStudentId(state.studentId)) {
        return BotTurn(
          state.copyWith(phase: BotPhase.askStudentId),
          [
            _bot('Almost done — I still need your AAUP student ID.'),
            _bot(
              'What is your student ID? (digits only)',
              input: ChatInputMode.numeric,
            ),
          ],
        );
      }
      return BotTurn(state.copyWith(phase: BotPhase.done), [
        _bot('Perfect — saving your profile now.'),
      ]);
    }
    if (choice.startsWith('re-enter') ||
        choice.startsWith('re enter') ||
        choice.startsWith('regen') ||
        choice.startsWith('start')) {
      return BotTurn(
        state.copyWith(phase: BotPhase.nlpIntro),
        [
          _bot(
            "Let's continue where you left off — tell me what to add or change.",
          ),
          _bot(
            state.interests.isNotEmpty || state.skills.isNotEmpty
                ? 'Update your interests, skills, or goals. I will merge them with what you already shared.'
                : 'What would you like to update?',
            input: ChatInputMode.text,
          ),
        ],
      );
    }
    return BotTurn(state, [
      _bot(
        'Tap **Keep** to save or **Re-enter** to start over.',
        input: ChatInputMode.confirm,
        quickReplies: const ['Keep', 'Re-enter'],
      ),
    ]);
  }

  BotTurn _confirmTurn(BotState state) {
    final preview = <String, dynamic>{
      'profile_summary': state.profileSummary ?? 'Your saved draft',
      'traits': state.traits ?? const {},
      'interests': state.interests,
      'skills': state.skills,
      'goals': state.goals,
      'major': state.major,
      'year': state.year,
      'confidence': state.nlpConfidence ?? 0.5,
    };
    return BotTurn(
      state.copyWith(phase: BotPhase.nlpConfirm, usesBackendNlp: true),
      [
        _bot('Welcome back — you already have a profile draft.'),
        _bot(_formatPreview(preview)),
        _bot(
          'Save this profile to AAURA?',
          input: ChatInputMode.confirm,
          quickReplies: const ['Keep', 'Re-enter'],
        ),
      ],
    );
  }

  BotState _stateFromDraft(BotState base, Map<String, dynamic> draft) {
    final traitsObj = draft['traits'];
    Map<String, String>? traitsMap;
    List<String> interests = [];
    List<String> skills = [];
    List<String> goals = [];
    String? summary;
    String? major;
    String? year;

    if (traitsObj is Map<String, dynamic>) {
      final inner = traitsObj['traits'];
      if (inner is Map) {
        traitsMap = inner.map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        );
      }
      final list = traitsObj['interests'];
      if (list is List) interests = list.map((e) => e.toString()).toList();
      final skillList = traitsObj['skills'];
      if (skillList is List) {
        skills = skillList.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      final goalList = traitsObj['goals'];
      if (goalList is List) {
        goals = goalList.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
      }
      summary = traitsObj['profile_summary'] as String?;
      major = traitsObj['major'] as String?;
      year = traitsObj['year'] as String?;
    }

    return base.copyWith(
      phase: BotPhase.nlpConfirm,
      usesBackendNlp: true,
      interests: interests,
      skills: skills,
      goals: goals,
      major: major,
      year: year,
      profileSummary: summary ?? draft['profile_text'] as String?,
      traits: traitsMap,
      nlpConfidence: (draft['confidence'] as num?)?.toDouble(),
    );
  }

  BotState _stateFromPreview(
    BotState base,
    Map<String, dynamic> preview, {
    required String profileText,
  }) {
    final traitsRaw = preview['traits'];
    Map<String, String>? traitsMap;
    if (traitsRaw is Map) {
      traitsMap = traitsRaw.map(
        (k, v) => MapEntry(k.toString(), v.toString()),
      );
    }
    final interests = (preview['interests'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        const <String>[];
    final skills = (preview['skills'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    final goals = (preview['goals'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList() ??
        const <String>[];
    final major = preview['major'] as String?;
    final year = preview['year'] as String?;

    return base.copyWith(
      phase: BotPhase.nlpConfirm,
      usesBackendNlp: true,
      interests: interests,
      skills: skills,
      goals: goals,
      major: major,
      year: year,
      profileSummary: preview['profile_summary'] as String? ?? profileText,
      traits: traitsMap,
      nlpConfidence: (preview['confidence'] as num?)?.toDouble(),
    );
  }

  String _formatPreview(Map<String, dynamic> preview) {
    final summary =
        (preview['profile_summary'] as String?)?.trim() ?? 'Profile preview';
    final traits = preview['traits'];
    final interests = preview['interests'];
    final skills = preview['skills'];
    final goals = preview['goals'];
    final major = preview['major'];
    final year = preview['year'];
    final confidence = preview['confidence'];

    final lines = <String>[summary];
    if (major is String && major.isNotEmpty) {
      lines.add('Major: $major');
    }
    if (year is String && year.isNotEmpty) {
      lines.add('Year: $year');
    }
    if (traits is Map && traits.isNotEmpty) {
      lines.add('Strengths: ${traits.keys.join(', ')}');
    }
    if (interests is List && interests.isNotEmpty) {
      lines.add('Interests: ${interests.join(', ')}');
    }
    if (skills is List && skills.isNotEmpty) {
      lines.add('Skills: ${skills.join(', ')}');
    }
    if (goals is List && goals.isNotEmpty) {
      lines.add('Goals: ${goals.join('; ')}');
    }
    if (confidence is num) {
      lines.add('Confidence: ${(confidence * 100).round()}%');
    }
    return lines.join('\n');
  }
}
