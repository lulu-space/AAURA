class PeerMessage {
  final String id;
  final String senderUserId;
  final String recipientUserId;
  final String body;
  final DateTime? createdAt;

  const PeerMessage({
    required this.id,
    required this.senderUserId,
    required this.recipientUserId,
    required this.body,
    this.createdAt,
  });

  bool isMine(String currentUserId) => senderUserId == currentUserId;
}
