import '../../core/network/api_client.dart';
import '_repo_support.dart';

class StudySessionMembershipRepository {
  StudySessionMembershipRepository(this._api);

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> listMine() async {
    final data = await _api.get('/study-session-membership');
    return asRows(data);
  }

  Future<Map<String, dynamic>?> join(String studySessionId) async {
    final result = await _api.post('/study-session-membership/join', body: {
      'study_session_id': studySessionId,
    });
    return asRow(result);
  }

  Future<void> leave(String membershipId) async {
    await _api.delete('/study-session-membership/$membershipId');
  }

  Future<List<Map<String, dynamic>>> listMembers(String studySessionId) async {
    final data =
        await _api.get('/study-session-membership/session/$studySessionId/members');
    return asRows(data);
  }
}
