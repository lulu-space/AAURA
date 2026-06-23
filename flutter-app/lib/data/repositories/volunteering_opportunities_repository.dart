import '../../core/network/api_client.dart';
import '../../models/volunteer_opportunity.dart';
import '../../models/volunteer_request.dart';
import '../api_mappers.dart';
import '_repo_support.dart';

class VolunteeringOpportunitiesRepository {
  VolunteeringOpportunitiesRepository(this._api);

  final ApiClient _api;

  Future<List<VolunteerOpportunity>> listOpen() async {
    final data = await _api.get('/volunteering-opportunities');
    return asRows(data)
        .where((row) => row['status'] != 'closed')
        .map(ApiMappers.volunteerOpportunity)
        .toList();
  }

  Future<List<VolunteerOpportunity>> listAll() async {
    final data = await _api.get('/volunteering-opportunities');
    return asRows(data).map(ApiMappers.volunteerOpportunity).toList();
  }

  Future<VolunteerOpportunity?> fetchByJoinToken(String token) async {
    final result = await _api.get('/volunteering-opportunities/join/$token');
    final row = asRow(result);
    return row == null ? null : ApiMappers.volunteerOpportunity(row);
  }

  Future<VolunteerRequest?> applyByJoinToken(String joinToken) async {
    final result = await _api.post(
      '/volunteering-opportunities/join',
      body: {'join_token': joinToken},
    );
    final row = asRow(result);
    return row == null ? null : ApiMappers.volunteerRequest(row);
  }

  Future<VolunteerOpportunity?> create(Map<String, dynamic> body) async {
    final result = await _api.post('/volunteering-opportunities', body: body);
    final row = asRow(result);
    return row == null ? null : ApiMappers.volunteerOpportunity(row);
  }

  Future<VolunteerOpportunity?> update(String id, Map<String, dynamic> body) async {
    final result = await _api.patch('/volunteering-opportunities/$id', body: body);
    final row = asRow(result);
    return row == null ? null : ApiMappers.volunteerOpportunity(row);
  }
}
