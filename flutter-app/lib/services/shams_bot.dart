// Shams - the AAURA onboarding chatbot.
//
// The real LLM-backed implementation will plug in behind [OnboardingBot].
// For now, [ShamsScriptedBot] runs a deterministic state machine that mirrors
// what the AI bot will eventually do: collect name, student ID, major, year
// and interests, then summarise and confirm.

import 'dart:async';
import 'dart:math';

import '../data/campus_form_options.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';

enum BotPhase {
  greeting,
  askName,
  askId,
  askMajor,
  askYear,
  askInterests,
  askSkills,
  confirm,
  nlpIntro,
  nlpConfirm,
  askStudentId,
  done,
}

class BotState {
  BotPhase phase;
  String? name;
  String? studentId;
  String? major;
  String? year;
  final List<String> interests;
  final List<String> skills;
  final List<String> goals;
  final String? profileSummary;
  final Map<String, String>? traits;
  final double? nlpConfidence;
  final bool usesBackendNlp;
  final bool isProfileUpdate;

  BotState({
    this.phase = BotPhase.greeting,
    this.name,
    this.studentId,
    this.major,
    this.year,
    List<String>? interests,
    List<String>? skills,
    List<String>? goals,
    this.profileSummary,
    this.traits,
    this.nlpConfidence,
    this.usesBackendNlp = false,
    this.isProfileUpdate = false,
  })  : interests = interests ?? <String>[],
        skills = skills ?? <String>[],
        goals = goals ?? <String>[];

  BotState copyWith({
    BotPhase? phase,
    String? name,
    String? studentId,
    String? major,
    String? year,
    List<String>? interests,
    List<String>? skills,
    List<String>? goals,
    String? profileSummary,
    Map<String, String>? traits,
    double? nlpConfidence,
    bool? usesBackendNlp,
    bool? isProfileUpdate,
  }) =>
      BotState(
        phase: phase ?? this.phase,
        name: name ?? this.name,
        studentId: studentId ?? this.studentId,
        major: major ?? this.major,
        year: year ?? this.year,
        interests: interests ?? this.interests,
        skills: skills ?? this.skills,
        goals: goals ?? this.goals,
        profileSummary: profileSummary ?? this.profileSummary,
        traits: traits ?? this.traits,
        nlpConfidence: nlpConfidence ?? this.nlpConfidence,
        usesBackendNlp: usesBackendNlp ?? this.usesBackendNlp,
        isProfileUpdate: isProfileUpdate ?? this.isProfileUpdate,
      );

  bool get isComplete =>
      usesBackendNlp
          ? profileSummary != null && interests.isNotEmpty
          : name != null &&
              studentId != null &&
              major != null &&
              year != null &&
              interests.isNotEmpty;

  UserProfile toProfile({String? email}) {
    if (usesBackendNlp) {
      final resolvedEmail =
          email ?? '${studentId ?? 'student'}@student.aaup.edu';
      final local = resolvedEmail.split('@').first;
      final displayName = name ??
          local
              .split(RegExp(r'[._-]'))
              .where((p) => p.isNotEmpty)
              .map((p) =>
                  '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
              .join(' ');
      return UserProfile(
        name: displayName.isEmpty ? 'AAURA Student' : displayName,
        studentId: studentId ?? '',
        major: major ?? 'Undeclared',
        year: year ?? '1st Year',
        interests: interests,
        quickTitle: traits?.keys.isNotEmpty == true
            ? traits!.keys.first.replaceAll('_', ' ')
            : 'Campus Explorer',
        email: resolvedEmail,
        bio: profileSummary,
        skills: skills.isNotEmpty
            ? skills
            : (traits?.keys.map((k) => k.replaceAll('_', ' ')).toList() ??
                const []),
      );
    }
    return UserProfile(
        name: name ?? '',
        studentId: studentId ?? '',
        major: major ?? '',
        year: year ?? '',
        interests: interests,
        skills: skills,
        quickTitle: 'New Student',
        email: email ?? '${studentId ?? ''}@student.aaup.edu',
      );
  }
}

class BotTurn {
  final BotState state;
  final List<ChatMessage> messages;

  const BotTurn(this.state, this.messages);
}

/// The seam where the real LLM-backed assistant will plug in later.
abstract class OnboardingBot {
  /// Initial bot intro turn.
  Future<BotTurn> start(BotState state);

  /// Process a user reply and return the next bot turn.
  Future<BotTurn> reply(BotState state, String text, List<String> selections);
}

class ShamsScriptedBot implements OnboardingBot {
  final Random _rng = Random();

  String _id() =>
      'm-${DateTime.now().microsecondsSinceEpoch}-${_rng.nextInt(99999)}';

  ChatMessage _bot(String text,
          {ChatInputMode input = ChatInputMode.none,
          List<String> quickReplies = const [],
          List<String> selections = const []}) =>
      ChatMessage(
        id: _id(),
        role: ChatRole.bot,
        text: text,
        inputMode: input,
        quickReplies: quickReplies,
        selections: selections,
      );

  @override
  Future<BotTurn> start(BotState state) async {
    final greeting = _bot(
      "Hi, I'm Shams - your AAURA assistant. I'll help you set up your profile in a minute.",
    );
    final ask = _bot(
      "First up - what should I call you?",
      input: ChatInputMode.text,
    );
    return BotTurn(
      state.copyWith(phase: BotPhase.askName),
      [greeting, ask],
    );
  }

  @override
  Future<BotTurn> reply(
    BotState state,
    String text,
    List<String> selections,
  ) async {
    switch (state.phase) {
      case BotPhase.greeting:
      case BotPhase.askName:
        final name = text.trim();
        if (name.isEmpty) {
          return BotTurn(state, [
            _bot("I didn't catch a name - could you type it again?",
                input: ChatInputMode.text),
          ]);
        }
        final firstName = name.split(' ').first;
        return BotTurn(
          state.copyWith(phase: BotPhase.askId, name: name),
          [
            _bot("Nice to meet you, $firstName."),
            _bot(
              "What's your AAUP student ID? (digits only)",
              input: ChatInputMode.numeric,
            ),
          ],
        );

      case BotPhase.askId:
      case BotPhase.askStudentId:
        final id = text.trim();
        final valid = RegExp(r'^[0-9]{6,}$').hasMatch(id);
        if (!valid) {
          return BotTurn(state, [
            _bot(
              "Hmm, that doesn't look like a valid ID. It should be at least 6 digits.",
              input: ChatInputMode.numeric,
            ),
          ]);
        }
        return BotTurn(
          state.copyWith(phase: BotPhase.askMajor, studentId: id),
          [
            _bot("Got it - that ID is saved."),
            _bot(
              "Which major are you in? Pick the closest one.",
              input: ChatInputMode.quickReplies,
              quickReplies: CampusFormOptions.majors,
            ),
          ],
        );

      case BotPhase.askMajor:
        final major = text.trim();
        if (!CampusFormOptions.majors.contains(major)) {
          return BotTurn(state, [
            _bot(
              "Tap one of the chips below to pick your major.",
              input: ChatInputMode.quickReplies,
              quickReplies: CampusFormOptions.majors,
            ),
          ]);
        }
        return BotTurn(
          state.copyWith(phase: BotPhase.askYear, major: major),
          [
            _bot("$major - sounds great."),
            _bot(
              "And what year are you in?",
              input: ChatInputMode.quickReplies,
              quickReplies: CampusFormOptions.years,
            ),
          ],
        );

      case BotPhase.askYear:
        final year = text.trim();
        if (!CampusFormOptions.years.contains(year)) {
          return BotTurn(state, [
            _bot(
              "Pick your year from the chips below.",
              input: ChatInputMode.quickReplies,
              quickReplies: CampusFormOptions.years,
            ),
          ]);
        }
        return BotTurn(
          state.copyWith(phase: BotPhase.askInterests, year: year),
          [
            _bot("Perfect."),
            _bot(
              "Last bit - what are you into? Pick as many as you like (at least one).",
              input: ChatInputMode.multiSelect,
              quickReplies: CampusFormOptions.interestOptions,
              selections: state.interests,
            ),
          ],
        );

      case BotPhase.askInterests:
        if (selections.isEmpty) {
          return BotTurn(state, [
            _bot(
              "Pick at least one interest so I can suggest events you'll like.",
              input: ChatInputMode.multiSelect,
              quickReplies: CampusFormOptions.interestOptions,
              selections: state.interests,
            ),
          ]);
        }
        final next = state.copyWith(
          phase: BotPhase.askSkills,
          interests: List.of(selections),
        );
        return BotTurn(next, [
          _bot("Awesome."),
          _bot(
            "What skills are you building? List a few, comma-separated.",
            input: ChatInputMode.text,
          ),
        ]);

      case BotPhase.askSkills:
        final skills = text
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
        if (skills.isEmpty) {
          return BotTurn(state, [
            _bot(
              "Add at least one skill, or type a few separated by commas.",
              input: ChatInputMode.text,
            ),
          ]);
        }
        final next = state.copyWith(
          phase: BotPhase.confirm,
          skills: skills,
        );
        return BotTurn(next, [
          _bot("Here's your AAURA setup:"),
          _bot(_summary(next)),
          _bot(
            "Looks good?",
            input: ChatInputMode.confirm,
            quickReplies: const ['Looks good', 'Edit interests', 'Start over'],
          ),
        ]);

      case BotPhase.confirm:
        final choice = text.trim().toLowerCase();
        if (choice.startsWith('looks')) {
          return BotTurn(state.copyWith(phase: BotPhase.done), [
            _bot("All set - taking you in."),
          ]);
        } else if (choice.startsWith('edit')) {
          return BotTurn(
            state.copyWith(phase: BotPhase.askInterests, interests: state.interests),
            [
              _bot(
                "Sure - update your interests below.",
                input: ChatInputMode.multiSelect,
                quickReplies: CampusFormOptions.interestOptions,
                selections: state.interests,
              ),
            ],
          );
        } else {
          return BotTurn(BotState(), [
            _bot("No problem, let's start fresh - what should I call you?",
                input: ChatInputMode.text),
          ]);
        }

      case BotPhase.done:
        return BotTurn(state, const []);

      case BotPhase.nlpIntro:
      case BotPhase.nlpConfirm:
        return start(state);
    }
  }

  String _summary(BotState s) =>
      'Name: ${s.name}\nID: ${s.studentId}\nMajor: ${s.major}\nYear: ${s.year}\n'
      'Interests: ${s.interests.join(', ')}\n'
      'Skills: ${s.skills.join(', ')}';
}
