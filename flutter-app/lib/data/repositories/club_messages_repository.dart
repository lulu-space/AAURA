import '../../core/network/api_client.dart';
import '../../models/club_server.dart';
import '../api_mappers.dart';
import '_repo_support.dart';

class ClubMessagesRepository {
  ClubMessagesRepository(this._api);

  final ApiClient _api;

  Future<List<ClubMessage>> list({
    required String clubId,
    required String channelId,
    required String currentUserId,
  }) async {
    final data = await _api.get('/club-messages', query: {
      'club_id': clubId,
      'channel_id': channelId,
    });
    return asRows(data)
        .map((row) => ApiMappers.clubMessage(row, currentUserId: currentUserId))
        .toList();
  }

  Future<ClubMessage?> send({
    required String clubId,
    required String channelId,
    required String body,
    required String currentUserId,
  }) async {
    final result = await _api.post('/club-messages', body: {
      'club_id': clubId,
      'channel_id': channelId,
      'body': body,
    });
    final row = asRow(result);
    return row == null
        ? null
        : ApiMappers.clubMessage(row, currentUserId: currentUserId);
  }
}
