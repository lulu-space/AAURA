import '../../core/network/api_client.dart';
import '_repo_support.dart';

class StudentProfilesRepository {
  StudentProfilesRepository(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>?> mine() async {
    final data = await _api.get('/student-profiles');
    final rows = asRows(data);
    return rows.isNotEmpty ? rows.first : null;
  }

  /// Persists an updated interest list onto the student's profile row.
  /// Returns the updated row, or null if there is no profile to update yet.
  Future<Map<String, dynamic>?> updateInterests(List<String> interests) async {
    return upsertFields(interests: interests);
  }

  Future<Map<String, dynamic>?> updateGoals(List<String> goals) async {
    final current = await mine();
    final id = current?['id']?.toString();
    if (id == null || id.isEmpty) return null;
    final data = await _api.patch(
      '/student-profiles/$id',
      body: {'goals': goals},
    );
    return asRow(data);
  }

  Future<Map<String, dynamic>?> updateStrengths(List<dynamic> strengths) async {
    return upsertFields(strengths: strengths);
  }

  /// Creates or updates the signed-in student's profile row.
  Future<Map<String, dynamic>?> upsertFields({
    List<String>? interests,
    List<dynamic>? strengths,
    List<String>? goals,
    String? profileSummary,
    num? confidence,
  }) async {
    final body = <String, dynamic>{};
    if (interests != null) body['interests'] = interests;
    if (strengths != null) body['strengths'] = strengths;
    if (goals != null) body['goals'] = goals;
    if (profileSummary != null && profileSummary.trim().isNotEmpty) {
      body['profile_summary'] = profileSummary.trim();
    }
    if (confidence != null) body['confidence'] = confidence;
    if (body.isEmpty) return mine();

    final current = await mine();
    if (current != null) {
      final id = current['id']?.toString();
      if (id == null || id.isEmpty) return null;
      final data = await _api.patch('/student-profiles/$id', body: body);
      return asRow(data);
    }

    final data = await _api.post('/student-profiles', body: {
      ...body,
      'confidence': confidence ?? 50,
      'goals': goals ?? const [],
      'interests': interests ?? const [],
      'strengths': strengths ?? const [],
    });
    return asRow(data);
  }
}
