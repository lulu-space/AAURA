import '../../core/network/api_client.dart';
import '../../models/club.dart';
import '../../models/event.dart';
import '../api_mappers.dart';
import '_repo_support.dart';

class DeanRepository {
  DeanRepository(this._api);

  final ApiClient _api;

  Future<Map<String, dynamic>?> fetchDashboard() async {
    final result = await _api.get('/dean/dashboard');
    return asRow(result);
  }

  Future<List<Map<String, dynamic>>> fetchEvents() async {
    final result = await _api.get('/dean/events');
    return asRows(result);
  }

  Future<List<Map<String, dynamic>>> fetchClubs() async {
    final result = await _api.get('/dean/clubs');
    return asRows(result);
  }

  Future<Map<String, dynamic>?> fetchInsights() async {
    final result = await _api.get('/dean/insights');
    return asRow(result);
  }

  Future<Map<String, dynamic>?> fetchReport(String type) async {
    final result = await _api.get('/dean/reports/$type');
    return asRow(result);
  }

  Future<int?> sendAnnouncement({
    required String title,
    required String body,
  }) async {
    final result = await _api.post('/dean/announcements', body: {
      'title': title,
      'body': body,
    });
    final row = asRow(result);
    final sent = row?['sent'];
    return sent is num ? sent.toInt() : null;
  }

  Future<List<Map<String, dynamic>>> fetchAnnouncements() async {
    final result = await _api.get('/dean/announcements');
    return asRows(result);
  }

  Future<List<Event>> fetchFacultyEvents() async {
    final rows = await fetchEvents();
    return rows.map(ApiMappers.event).toList();
  }

  Future<List<Club>> fetchFacultyClubs() async {
    final rows = await fetchClubs();
    return rows.map(ApiMappers.club).toList();
  }
}
