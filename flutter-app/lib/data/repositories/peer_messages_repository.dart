import '../../core/network/api_client.dart';
import '../../models/peer_conversation.dart';
import '../../models/peer_message.dart';
import '../api_mappers.dart';
import '_repo_support.dart';

class PeerMessagesRepository {
  PeerMessagesRepository(this._api);

  final ApiClient _api;

  Future<List<PeerConversation>> listInbox({required String currentUserId}) async {
    final data = await _api.get('/peer-messages/inbox');
    return asRows(data)
        .map(
          (row) => ApiMappers.peerConversation(
            row,
            currentUserId: currentUserId,
          ),
        )
        .toList();
  }

  Future<List<PeerMessage>> listConversation(String userId) async {
    final data = await _api.get('/peer-messages', query: {'user_id': userId});
    return asRows(data).map(_fromRow).toList();
  }

  Future<void> markConversationRead(String userId) async {
    await _api.post('/peer-messages/read', body: {'user_id': userId});
  }

  Future<PeerMessage?> send({
    required String recipientUserId,
    required String body,
  }) async {
    final result = await _api.post('/peer-messages', body: {
      'recipient_user_id': recipientUserId,
      'body': body,
    });
    final row = asRow(result);
    return row == null ? null : _fromRow(row);
  }

  PeerMessage _fromRow(Map<String, dynamic> row) {
    return PeerMessage(
      id: row['id']?.toString() ?? '',
      senderUserId: row['sender_user_id']?.toString() ?? '',
      recipientUserId: row['recipient_user_id']?.toString() ?? '',
      body: row['body']?.toString() ?? '',
      createdAt: DateTime.tryParse(row['created_at']?.toString() ?? ''),
    );
  }
}
