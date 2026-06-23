import '../../core/network/api_client.dart';

import '_repo_support.dart';

class StudyPlansRepository {
  StudyPlansRepository(this._api);

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> listMine() async {
    final data = await _api.get('/study-plans');
    return asRows(data);
  }

  Future<Map<String, dynamic>?> create({
    required String title,
    List<dynamic> goals = const [],
    List<dynamic> schedule = const [],
    String source = 'manual',
  }) async {
    final result = await _api.post('/study-plans', body: {
      'title': title,
      'goals': goals,
      'schedule': schedule,
      'source': source,
    });
    return asRow(result);
  }

  Future<Map<String, dynamic>?> update(
    String id, {
    List<dynamic>? schedule,
    List<dynamic>? goals,
    String? title,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (goals != null) body['goals'] = goals;
    if (schedule != null) body['schedule'] = schedule;
    final result = await _api.patch('/study-plans/$id', body: body);
    return asRow(result);
  }
}
