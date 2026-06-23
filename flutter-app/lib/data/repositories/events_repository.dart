import '../../core/network/api_client.dart';
import '../../models/event.dart';
import '../api_mappers.dart';
import '_repo_support.dart';

class EventsRepository {
  EventsRepository(this._api);

  final ApiClient _api;

  Future<List<Event>> list() async {
    final data = await _api.get('/events');
    return asRows(data).map(ApiMappers.event).toList();
  }

  Future<Event?> getById(String id) async {
    final data = await _api.get('/events/$id');
    final row = asRow(data);
    return row == null ? null : ApiMappers.event(row);
  }

  Future<Map<String, dynamic>?> reserve(String eventId) async {
    final result = await _api.post('/event-reservations/reserve', body: {
      'event_id': eventId,
    });
    return asRow(result);
  }

  Future<Map<String, dynamic>?> reserveByJoinToken(String joinToken) async {
    final result = await _api.post('/event-reservations/join', body: {
      'join_token': joinToken,
    });
    return asRow(result);
  }

  Future<Map<String, dynamic>?> cancelReservation(String reservationId) async {
    final result = await _api.patch('/event-reservations/$reservationId', body: {
      'reservation_status': 'cancelled',
    });
    return asRow(result);
  }

  Future<Map<String, dynamic>?> getAnalytics(String eventId) async {
    final result = await _api.get('/events/$eventId/analytics');
    return asRow(result);
  }

  Future<List<Map<String, dynamic>>> myReservations() async {
    final data = await _api.get('/event-reservations/mine');
    return asRows(data);
  }

  Future<Map<String, dynamic>?> checkIn(String qrToken) async {
    final result = await _api.post('/event-reservations/check-in', body: {
      'qr_token': qrToken,
    });
    return asRow(result);
  }

  Future<Event?> create(Map<String, dynamic> body) async {
    final result = await _api.post('/events', body: body);
    final row = asRow(result);
    return row == null ? null : ApiMappers.event(row);
  }

  Future<Event?> update(String id, Map<String, dynamic> body) async {
    final result = await _api.patch('/events/$id', body: body);
    final row = asRow(result);
    return row == null ? null : ApiMappers.event(row);
  }

  Future<void> delete(String id) async {
    await _api.delete('/events/$id');
  }

  /// Calls backend AI pipeline: POST /events/:id/predict-success
  Future<Map<String, dynamic>?> predictSuccess(
    String eventId, {
    Map<String, dynamic>? overrides,
  }) async {
    final result = await _api.post(
      '/events/$eventId/predict-success',
      body: overrides ?? const {},
    );
    return asRow(result);
  }

  Future<List<Map<String, dynamic>>> listAttendees(String eventId) async {
    final data = await _api.get('/event-reservations/event/$eventId/attendees');
    return asRows(data);
  }

  /// Reviewers only — student-submitted events queue.
  Future<List<Event>> listReviewsAll() async {
    final data = await _api.get('/events/reviews/all');
    return asRows(data).map(ApiMappers.event).toList();
  }

  Future<void> approveReview(String id, {String? note}) =>
      _review(id, 'approve', note);

  Future<void> rejectReview(String id, {String? note}) =>
      _review(id, 'reject', note);

  Future<void> withdrawReview(String id, {String? note}) =>
      _review(id, 'withdraw-approval', note);

  Future<void> _review(String id, String action, String? note) async {
    await _api.patch('/events/$id/$action', body: {
      if (note != null && note.trim().isNotEmpty) 'approval_note': note.trim(),
    });
  }
}
