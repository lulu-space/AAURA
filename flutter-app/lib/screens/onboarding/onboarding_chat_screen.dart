import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/chat_message.dart';
import '../../services/shams_bot.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/transitions.dart';
import '../../widgets/bird_avatar.dart';
import '../../widgets/dawn_scene.dart';
import '../shell/main_shell.dart';
import 'onboarding_form_fallback.dart';

// Sunbird palette — matches auth flow.
const Color _dawnLow = AppPalette.dawnLow;
const Color _ink = AppPalette.ink;

class OnboardingChatScreen extends StatefulWidget {
  final bool isProfileUpdate;
  const OnboardingChatScreen({super.key, this.isProfileUpdate = false});

  @override
  State<OnboardingChatScreen> createState() => _OnboardingChatScreenState();
}

class _OnboardingChatScreenState extends State<OnboardingChatScreen> {
  final _scroll = ScrollController();
  final _input = TextEditingController();
  final _focus = FocusNode();
  final List<ChatMessage> _messages = [];
  final Set<String> _multiSelections = {};

  late final OnboardingBot _bot;
  late BotState _state;
  ChatMessage? _activePrompt; // last bot message that expects user input
  bool _typing = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _bot = context.read<OnboardingBot>();
    final appState = context.read<AppState>();
    final profile = appState.profile;
    _state = BotState(
      name: profile?.name,
      studentId: profile?.studentId,
      major: profile?.major,
      year: profile?.year,
      interests: profile?.interests ?? const [],
      skills: widget.isProfileUpdate
          ? appState.personalizationSkillNames
          : const [],
      profileSummary: profile?.bio,
      isProfileUpdate: widget.isProfileUpdate,
    );
    _kickoff();
  }

  Future<void> _kickoff() async {
    setState(() => _typing = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final turn = await _bot.start(_state);
    if (!mounted) return;
    _applyTurn(turn);
  }

  void _applyTurn(BotTurn turn) {
    setState(() {
      _typing = false;
      _state = turn.state;
      for (final msg in turn.messages) {
        _messages.add(msg);
      }
      _activePrompt =
          turn.messages.isNotEmpty ? turn.messages.last : _activePrompt;
      if (_activePrompt?.inputMode == ChatInputMode.multiSelect) {
        _multiSelections
          ..clear()
          ..addAll(_state.interests);
      }
    });
    _scrollToBottom();

    if (_state.phase == BotPhase.done) {
      _finishOnboarding();
    }
  }

  Future<void> _send(String text, {List<String>? selections}) async {
    if (_busy) return;
    final trimmed = text.trim();
    if (trimmed.isEmpty && (selections == null || selections.isEmpty)) return;
    setState(() {
      _busy = true;
      _messages.add(ChatMessage(
        id: 'u-${DateTime.now().microsecondsSinceEpoch}',
        role: ChatRole.user,
        text: trimmed.isEmpty
            ? (selections ?? const []).join(', ')
            : trimmed,
      ));
      _input.clear();
      _activePrompt = null;
      _typing = true;
    });
    _scrollToBottom();

    await Future<void>.delayed(const Duration(milliseconds: 600));

    final turn =
        await _bot.reply(_state, trimmed, selections ?? const <String>[]);
    if (!mounted) return;
    _applyTurn(turn);
    setState(() => _busy = false);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 240,
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _finishOnboarding() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;
    final appState = context.read<AppState>();
    final email = appState.profile?.email ??
        Supabase.instance.client.auth.currentUser?.email;
    var profile = _state.toProfile(email: email);

    if (widget.isProfileUpdate) {
      final current = appState.profile;
      if (current != null) {
        profile = profile.copyWith(
          email: current.email,
          role: current.role,
          studentId: profile.studentId.isNotEmpty
              ? profile.studentId
              : current.studentId,
          name: profile.name.isNotEmpty ? profile.name : current.name,
          major: profile.major.isNotEmpty && profile.major != 'Undeclared'
              ? profile.major
              : current.major,
          year: profile.year.isNotEmpty ? profile.year : current.year,
        );
      }

      String? error;
      if (_state.usesBackendNlp) {
        error = await appState.completeShamsProfileUpdate(profile);
      } else {
        await appState.saveManualProfileUpdate(profile);
      }
      if (!mounted) return;
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        setState(() => _busy = false);
        return;
      }
      Navigator.of(context).pop();
      return;
    }

    String? error;
    if (_state.usesBackendNlp) {
      error = await appState.completeShamsOnboarding(profile);
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        setState(() => _busy = false);
        return;
      }
    } else {
      await appState.completeOnboarding(profile);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      FadeSlidePageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const DawnScene(reveal: 1.0),
            SafeArea(
              child: Column(
                children: [
                  _Header(
                    isProfileUpdate: widget.isProfileUpdate,
                    onSkip: () async {
                      final saved = await Navigator.of(context).push<bool>(
                        FadeSlidePageRoute(
                          builder: (_) => OnboardingFormFallback(
                            isProfileUpdate: widget.isProfileUpdate,
                          ),
                        ),
                      );
                      if (!mounted) return;
                      if (widget.isProfileUpdate && saved == true) {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                          AppSpacing.lg, AppSpacing.lg, AppSpacing.md),
                      itemCount: _messages.length + (_typing ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (_typing && i == _messages.length) {
                          return const _TypingBubble();
                        }
                        final m = _messages[i];
                        return _Bubble(message: m);
                      },
                    ),
                  ),
                  _InputArea(
                    prompt: _activePrompt,
                    controller: _input,
                    focus: _focus,
                    busy: _busy,
                    multiSelections: _multiSelections,
                    onSend: _send,
                    onToggleMulti: (val) {
                      setState(() {
                        if (!_multiSelections.add(val)) {
                          _multiSelections.remove(val);
                        }
                      });
                    },
                    onSubmitMulti: () {
                      _send('Selected: ${_multiSelections.length}',
                          selections: _multiSelections.toList());
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final VoidCallback onSkip;
  final bool isProfileUpdate;
  const _Header({required this.onSkip, this.isProfileUpdate = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Row(
        children: [
          if (isProfileUpdate)
            IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              color: _ink,
              tooltip: 'Back',
            ),
          const BirdAvatar(size: 44)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1, end: 1.06, duration: 1600.ms),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shams',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _ink,
                        )),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isProfileUpdate
                          ? 'Update your profile'
                          : 'AAURA Assistant · placeholder',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: _ink.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onSkip,
            style: TextButton.styleFrom(foregroundColor: _ink),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Form'),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  const _Bubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final isBot = message.role == ChatRole.bot;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(AppRadii.lg),
      topRight: const Radius.circular(AppRadii.lg),
      bottomLeft: Radius.circular(isBot ? 4 : AppRadii.lg),
      bottomRight: Radius.circular(isBot ? AppRadii.lg : 4),
    );
    final bubble = ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isBot
                ? Colors.white.withValues(alpha: 0.34)
                : _ink.withValues(alpha: 0.82),
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: _dawnLow.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: isBot
                  ? Colors.white.withValues(alpha: 0.55)
                  : Colors.white.withValues(alpha: 0.18),
            ),
          ),
          child: Text(
            message.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isBot ? _ink : Colors.white,
                  height: 1.35,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment:
            isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isBot)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: BirdAvatar(size: 28),
            ),
          Flexible(child: bubble),
        ],
      )
          .animate()
          .fadeIn(duration: 220.ms)
          .slideY(begin: 0.2, end: 0, duration: 240.ms, curve: Curves.easeOut),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    const radius = BorderRadius.only(
      topLeft: Radius.circular(AppRadii.lg),
      topRight: Radius.circular(AppRadii.lg),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(AppRadii.lg),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: BirdAvatar(size: 28),
          ),
          ClipRRect(
            borderRadius: radius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.34),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.55)),
                  borderRadius: radius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _dawnLow.withValues(alpha: 0.85),
                          ),
                        )
                            .animate(
                              onPlay: (c) => c.repeat(reverse: true),
                              delay: (i * 140).ms,
                            )
                            .fadeIn(duration: 320.ms)
                            .scaleXY(begin: 0.6, end: 1.2, duration: 320.ms),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  final ChatMessage? prompt;
  final TextEditingController controller;
  final FocusNode focus;
  final bool busy;
  final Set<String> multiSelections;
  final void Function(String text, {List<String>? selections}) onSend;
  final ValueChanged<String> onToggleMulti;
  final VoidCallback onSubmitMulti;

  const _InputArea({
    required this.prompt,
    required this.controller,
    required this.focus,
    required this.busy,
    required this.multiSelections,
    required this.onSend,
    required this.onToggleMulti,
    required this.onSubmitMulti,
  });

  @override
  Widget build(BuildContext context) {
    final mode = prompt?.inputMode ?? ChatInputMode.text;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.28),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
            ),
            boxShadow: [
              BoxShadow(
                color: _dawnLow.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
              child: switch (mode) {
            ChatInputMode.quickReplies => _QuickRepliesRow(
                replies: prompt!.quickReplies,
                onSelect: (v) => onSend(v),
              ),
            ChatInputMode.multiSelect => _MultiSelectRow(
                options: prompt!.quickReplies,
                selections: multiSelections,
                onToggle: onToggleMulti,
                onSubmit: onSubmitMulti,
              ),
            ChatInputMode.confirm => _QuickRepliesRow(
                replies: prompt!.quickReplies,
                onSelect: (v) => onSend(v),
              ),
            ChatInputMode.numeric => _TextRow(
                controller: controller,
                focus: focus,
                hint: 'Type your student ID',
                keyboard: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSend: () => onSend(controller.text),
                busy: busy,
              ),
            _ => _TextRow(
                controller: controller,
                focus: focus,
                hint: 'Type your reply...',
                keyboard: TextInputType.text,
                inputFormatters: const [],
                onSend: () => onSend(controller.text),
                busy: busy,
              ),
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _TextRow extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focus;
  final String hint;
  final TextInputType keyboard;
  final List<TextInputFormatter> inputFormatters;
  final VoidCallback onSend;
  final bool busy;
  const _TextRow({
    required this.controller,
    required this.focus,
    required this.hint,
    required this.keyboard,
    required this.inputFormatters,
    required this.onSend,
    required this.busy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            focusNode: focus,
            keyboardType: keyboard,
            inputFormatters: inputFormatters,
            onSubmitted: (_) => onSend(),
            style: const TextStyle(color: _ink),
            cursorColor: _ink,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: _ink.withValues(alpha: 0.45)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.45),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                borderSide:
                    BorderSide(color: Colors.white.withValues(alpha: 0.6)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadii.pill),
                borderSide: const BorderSide(color: _ink, width: 1.4),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filled(
          onPressed: busy ? null : onSend,
          style: IconButton.styleFrom(
            backgroundColor: _ink,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.all(14),
          ),
          icon: const Icon(Icons.send_rounded),
        ),
      ],
    );
  }
}

class _QuickRepliesRow extends StatelessWidget {
  final List<String> replies;
  final ValueChanged<String> onSelect;
  const _QuickRepliesRow({required this.replies, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: replies.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final r = replies[i];
          return ActionChip(
            label: Text(r),
            labelStyle: const TextStyle(
              color: _ink,
              fontWeight: FontWeight.w600,
            ),
            elevation: 0,
            pressElevation: 0,
            surfaceTintColor: Colors.transparent,
            shadowColor: Colors.transparent,
            backgroundColor: const Color(0xFFFBE4D8).withValues(alpha: 0.55),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.pill),
              side: BorderSide(color: _dawnLow.withValues(alpha: 0.45)),
            ),
            onPressed: () => onSelect(r),
          );
        },
      ),
    );
  }
}

class _MultiSelectRow extends StatelessWidget {
  final List<String> options;
  final Set<String> selections;
  final ValueChanged<String> onToggle;
  final VoidCallback onSubmit;
  const _MultiSelectRow({
    required this.options,
    required this.selections,
    required this.onToggle,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 96,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final o in options)
                  FilterChip(
                    label: Text(o),
                    selected: selections.contains(o),
                    onSelected: (_) => onToggle(o),
                    selectedColor: _ink,
                    elevation: 0,
                    pressElevation: 0,
                    surfaceTintColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    labelStyle: TextStyle(
                      color: selections.contains(o) ? Colors.white : _ink,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor:
                        const Color(0xFFFBE4D8).withValues(alpha: 0.55),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.pill),
                      side: BorderSide(
                        color: selections.contains(o)
                            ? _ink
                            : _dawnLow.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 44,
          child: ElevatedButton.icon(
            onPressed: selections.isEmpty ? null : onSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: _ink,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.check_rounded),
            label: Text('Continue with ${selections.length}'),
          ),
        ),
      ],
    );
  }
}
