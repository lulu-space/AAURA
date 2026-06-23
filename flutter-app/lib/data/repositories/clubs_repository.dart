import '../../core/network/api_client.dart';
import '../../models/club.dart';
import '../../models/club_server.dart';
import '../api_mappers.dart';
import '_repo_support.dart';

class ClubsRepository {
  ClubsRepository(this._api);

  final ApiClient _api;

  Future<List<Club>> list({Map<String, int>? memberCounts}) async {
    final data = await _api.get('/clubs');
    return asRows(data)
        .map((row) => ApiMappers.club(
              row,
              memberCount: memberCounts?[row['id']?.toString()] ?? 0,
            ))
        .toList();
  }

  Future<Club?> getById(String id, {int memberCount = 0}) async {
    final data = await _api.get('/clubs/$id');
    final row = asRow(data);
    return row == null ? null : ApiMappers.club(row, memberCount: memberCount);
  }

  Future<Club?> create({
    required String name,
    required String description,
  }) async {
    final result = await _api.post('/clubs', body: ApiMappers.clubToCreateBody(
      name: name,
      description: description,
    ));
    final row = asRow(result);
    return row == null ? null : ApiMappers.club(row, memberCount: 1);
  }

  Future<Club?> update(
    String id, {
    String? name,
    String? description,
    bool? isActive,
  }) async {
    final result = await _api.patch('/clubs/$id', body: ApiMappers.clubToUpdateBody(
      name: name,
      description: description,
      isActive: isActive,
    ));
    final row = asRow(result);
    return row == null ? null : ApiMappers.club(row);
  }

  Future<void> delete(String id) async {
    await _api.delete('/clubs/$id');
  }

  Future<List<ClubMember>> listMembers(String clubId) async {
    final data = await _api.get('/clubs/$clubId/members');
    return asRows(data).map(ApiMappers.clubMember).toList();
  }

  Future<List<Map<String, String>>> activityFeed({int limit = 20}) async {
    final data = await _api.get('/clubs/activity/feed', query: {
      'limit': limit,
    });
    return asRows(data).map(ApiMappers.clubActivityPost).toList();
  }
}
