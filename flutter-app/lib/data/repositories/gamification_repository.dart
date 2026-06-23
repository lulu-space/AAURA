import '../../core/network/api_client.dart';
import '_repo_support.dart';

class GamificationRepository {
  GamificationRepository(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>?> forUser(String userId) async {
    final data = await _api.get('/gamification');
    final rows = asRows(data);
    for (final row in rows) {
      if (row['user_id']?.toString() == userId) return row;
    }
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Creates a gamification row starting at 0 points for [userId].
  Future<Map<String, dynamic>?> ensureProfile(String userId) async {
    final existing = await forUser(userId);
    if (existing != null) return existing;
    final result = await _api.post('/gamification', body: {
      'user_id': userId,
      'points': 0,
      'level': 1,
      'badges': [],
      'streak_days': 0,
    });
    return asRow(result);
  }

  Future<Map<String, dynamic>?> addPoints(String rowId, int delta) async {
    final current = await _api.get('/gamification/$rowId');
    final row = asRow(current);
    if (row == null) return null;
    final points = (row['points'] as num?)?.toInt() ?? 0;
    final next = (points + delta).clamp(0, 999999);
    final result = await _api.patch('/gamification/$rowId', body: {
      'points': next,
    });
    return asRow(result);
  }

  Future<List<Map<String, dynamic>>> leaderboard({int limit = 10}) async {
    final data = await _api.get('/gamification/leaderboard', query: {
      'limit': limit,
    });
    return asRows(data);
  }
}
