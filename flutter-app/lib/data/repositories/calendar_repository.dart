import '../../core/network/api_client.dart';

import '_repo_support.dart';

class CalendarRepository {
  CalendarRepository(this._api);

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> listMine() async {
    final data = await _api.get('/calendar');
    return asRows(data);
  }

  Future<Map<String, dynamic>?> create({
    required String title,
    required String itemType,
    required DateTime startsAt,
    DateTime? endsAt,
  }) async {
    final result = await _api.post('/calendar', body: {
      'title': title,
      'item_type': itemType,
      'starts_at': startsAt.toUtc().toIso8601String(),
      if (endsAt != null) 'ends_at': endsAt.toUtc().toIso8601String(),
    });
    return asRow(result);
  }

  Future<Map<String, dynamic>?> update(
    String id, {
    String? title,
    DateTime? startsAt,
    DateTime? endsAt,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (startsAt != null) {
      body['starts_at'] = startsAt.toUtc().toIso8601String();
    }
    if (endsAt != null) body['ends_at'] = endsAt.toUtc().toIso8601String();
    final result = await _api.patch('/calendar/$id', body: body);
    return asRow(result);
  }

  Future<void> delete(String id) async {
    await _api.delete('/calendar/$id');
  }
}
