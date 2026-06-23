enum ChatRole { bot, user }

enum ChatInputMode {
  none,
  text,
  quickReplies,
  multiSelect,
  numeric,
  confirm,
}

class ChatMessage {
  final String id;
  final ChatRole role;
  final String text;
  final ChatInputMode inputMode;
  final List<String> quickReplies;
  final List<String> selections;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    this.inputMode = ChatInputMode.none,
    this.quickReplies = const [],
    this.selections = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
