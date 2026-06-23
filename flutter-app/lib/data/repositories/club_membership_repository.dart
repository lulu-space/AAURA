import '../../core/network/api_client.dart';
import '_repo_support.dart';

class ClubMembershipRepository {
  ClubMembershipRepository(this._api);

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> listMine() async {
    final data = await _api.get('/club-membership');
    return asRows(data);
  }

  Future<Map<String, dynamic>?> join(
    String clubId, {
    String role = 'member',
  }) async {
    final result = await _api.post('/club-membership', body: {
      'club_id': clubId,
      'role': role,
    });
    return asRow(result);
  }

  Future<void> leave(String membershipId) async {
    await _api.delete('/club-membership/$membershipId');
  }
}
