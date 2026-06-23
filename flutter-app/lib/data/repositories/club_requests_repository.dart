import '../../core/network/api_client.dart';
import '../../models/club_request.dart';
import '../../models/club_request_eligibility.dart';
import '../api_mappers.dart';
import '_repo_support.dart';

class ClubRequestsRepository {
  ClubRequestsRepository(this._api);

  final ApiClient _api;

  Future<ClubRequestEligibility> fetchEligibility() async {
    final data = await _api.get('/club-requests/eligibility');
    final row = asRow(data);
    if (row == null) {
      return const ClubRequestEligibility(eligible: false, reasons: ['Unable to check eligibility.']);
    }
    final cooldownRaw = row['cooldown_until'] as String?;
    return ClubRequestEligibility(
      eligible: row['eligible'] as bool? ?? false,
      reasons: (row['reasons'] as List?)
              ?.map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList() ??
          const [],
      cooldownUntil:
          cooldownRaw == null ? null : DateTime.tryParse(cooldownRaw),
    );
  }

  Future<ClubRequest?> submit({
    required String proposedName,
    required String description,
    required String category,
    required String advisorEmail,
    List<String> coFounderNames = const [],
  }) async {
    final result = await _api.post('/club-requests', body: {
      'proposed_name': proposedName,
      'description': description.trim(),
      'category': category,
      'advisor_email': advisorEmail.trim(),
      'co_founder_names': coFounderNames
          .map((n) => n.trim())
          .where((n) => n.length >= 2)
          .toList(),
    });
    final row = asRow(result);
    return row == null ? null : ApiMappers.clubRequest(row);
  }

  Future<List<ClubRequest>> listMine() async {
    final data = await _api.get('/club-requests/mine');
    return asRows(data).map(ApiMappers.clubRequest).toList();
  }

  Future<List<ClubRequest>> listAll() async {
    final data = await _api.get('/club-requests/all');
    return asRows(data).map(ApiMappers.clubRequest).toList();
  }

  Future<void> approve(String id, {String? note}) =>
      _review(id, 'approve', note);

  Future<void> reject(String id, {String? note}) => _review(id, 'reject', note);

  Future<void> revoke(String id, {String? note}) => _review(id, 'revoke', note);

  Future<void> _review(String id, String action, String? note) async {
    await _api.patch('/club-requests/$id/$action', body: {
      if (note != null && note.trim().isNotEmpty) 'review_note': note.trim(),
    });
  }
}
