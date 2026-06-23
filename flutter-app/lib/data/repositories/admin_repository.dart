import '../../core/network/api_client.dart';
import '_repo_support.dart';

class AdminRepository {
  AdminRepository(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>?> fetchDashboard() async {
    return asRow(await _api.get('/admin/dashboard'));
  }

  Future<List<Map<String, dynamic>>> fetchUsers() async {
    return asRows(await _api.get('/admin/users'));
  }

  Future<Map<String, dynamic>?> updateUser(
    String id, {
    String? role,
    bool? isSuspended,
    String? fullName,
  }) async {
    final body = <String, dynamic>{};
    if (role != null) body['role'] = role;
    if (isSuspended != null) body['is_suspended'] = isSuspended;
    if (fullName != null) body['full_name'] = fullName;
    return asRow(await _api.patch('/admin/users/$id', body: body));
  }

  Future<Map<String, dynamic>?> fetchContent() async {
    return asRow(await _api.get('/admin/content'));
  }

  Future<Map<String, dynamic>?> fetchAnalytics() async {
    return asRow(await _api.get('/admin/analytics'));
  }

  Future<List<Map<String, dynamic>>> fetchVolunteeringRecords() async {
    return asRows(await _api.get('/admin/volunteering'));
  }

  Future<Map<String, dynamic>?> fetchSettings() async {
    return asRow(await _api.get('/admin/settings'));
  }

  Future<Map<String, dynamic>?> updateSettings(
    String key,
    Map<String, dynamic> value,
  ) async {
    return asRow(await _api.patch('/admin/settings/$key', body: {'value': value}));
  }

  Future<List<Map<String, dynamic>>> fetchBadges() async {
    return asRows(await _api.get('/admin/badges'));
  }

  Future<List<Map<String, dynamic>>> fetchAuditLogs() async {
    return asRows(await _api.get('/admin/audit-logs'));
  }

  Future<int?> sendAnnouncement({
    required String title,
    required String body,
  }) async {
    final row = asRow(await _api.post('/admin/announcements', body: {
      'title': title,
      'body': body,
    }));
    final sent = row?['sent'];
    return sent is num ? sent.toInt() : null;
  }

  Future<bool> moderateEvent(String id, String action) async {
    await _api.patch('/admin/content/events/$id', body: {'action': action});
    return true;
  }

  Future<bool> moderateClub(String id, String action) async {
    await _api.patch('/admin/content/clubs/$id', body: {'action': action});
    return true;
  }

  Future<bool> moderatePost(String id, {required bool hidden}) async {
    await _api.patch('/admin/content/posts/$id', body: {'hidden': hidden});
    return true;
  }

  Future<bool> moderateMessage(String id, {required bool hidden}) async {
    await _api.patch('/admin/content/messages/$id', body: {'hidden': hidden});
    return true;
  }
}
