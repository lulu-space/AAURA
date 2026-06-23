class PeerConversation {
  final String peerUserId;
  final String name;
  final String major;
  final String year;
  final String lastMessageBody;
  final DateTime? lastMessageAt;
  final bool lastMessageIsMine;
  final int unreadCount;

  const PeerConversation({
    required this.peerUserId,
    required this.name,
    required this.major,
    required this.year,
    required this.lastMessageBody,
    this.lastMessageAt,
    this.lastMessageIsMine = false,
    this.unreadCount = 0,
  });

  String get initial => name.isEmpty ? '?' : name[0].toUpperCase();

  bool get hasUnread => unreadCount > 0;
}
