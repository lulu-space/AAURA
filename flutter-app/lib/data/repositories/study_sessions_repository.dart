import '../../core/network/api_client.dart';

import '../../models/study_session.dart';

import '../api_mappers.dart';

import '_repo_support.dart';

class StudySessionsRepository {
  StudySessionsRepository(this._api);

  final ApiClient _api;

  Future<List<StudySession>> list() async {
    final data = await _api.get('/study-sessions');
    return asRows(data).map(ApiMappers.studySession).toList();
  }

  Future<StudySession?> create({
    required String title,
    required String topic,
    required DateTime startsAt,
    required DateTime endsAt,
    required int capacity,
    String? location,
  }) async {
    final result = await _api.post(
      '/study-sessions',
      body: ApiMappers.studySessionToCreateBody(
        title: title,
        topic: topic,
        startsAt: startsAt,
        endsAt: endsAt,
        capacity: capacity,
        location: location,
      ),
    );
    final row = asRow(result);
    return row == null ? null : ApiMappers.studySession(row);
  }

  Future<StudySession?> update({
    required String id,
    String? title,
    String? topic,
    DateTime? startsAt,
    DateTime? endsAt,
    int? capacity,
    String? location,
  }) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (topic != null) body['topic'] = topic;
    if (startsAt != null) body['starts_at'] = startsAt.toUtc().toIso8601String();
    if (endsAt != null) body['ends_at'] = endsAt.toUtc().toIso8601String();
    if (capacity != null) body['capacity'] = capacity;
    if (location != null) body['location'] = location;
    final result = await _api.patch('/study-sessions/$id', body: body);
    final row = asRow(result);
    return row == null ? null : ApiMappers.studySession(row);
  }

  Future<void> delete(String id) async {
    await _api.delete('/study-sessions/$id');
  }

  Future<int> notifyMembers({
    required String id,
    required String title,
    required String body,
    String kind = 'updated',
  }) async {
    final data = await _api.post('/study-sessions/$id/notify-members', body: {
      'title': title,
      'body': body,
      'kind': kind,
    });
    if (data is Map && data['notified'] is num) {
      return (data['notified'] as num).toInt();
    }
    return 0;
  }
}
