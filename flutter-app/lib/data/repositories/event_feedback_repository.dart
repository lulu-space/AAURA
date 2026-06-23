import '../../core/network/api_client.dart';
import '_repo_support.dart';

class EventFeedbackRepository {
  EventFeedbackRepository(this._api);

  final ApiClient _api;

  Future<List<Map<String, dynamic>>> listMine() async {
    final data = await _api.get('/event-feedback');
    return asRows(data);
  }

  Future<Map<String, dynamic>?> submit({
    required String eventId,
    required int rating,
    String? comment,
  }) async {
    final body = <String, dynamic>{
      'event_id': eventId,
      'rating': rating,
    };
    if (comment != null && comment.trim().isNotEmpty) {
      body['comment'] = comment.trim();
    }
    final result = await _api.post('/event-feedback', body: body);
    return asRow(result);
  }
}
