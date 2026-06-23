import '../../core/network/api_client.dart';

import '../../models/volunteer_request.dart';

import '../api_mappers.dart';

import '_repo_support.dart';



class VolunteeringRepository {

  VolunteeringRepository(this._api);



  final ApiClient _api;



  Future<List<VolunteerRequest>> listMine() async {

    final data = await _api.get('/volunteering');

    return asRows(data).map(ApiMappers.volunteerRequest).toList();

  }



  Future<List<VolunteerRequest>> listPending() async {

    final data = await _api.get('/volunteering/pending');

    return asRows(data).map(ApiMappers.volunteerRequest).toList();

  }



  /// Staff/admin: every record (any status) for the office dashboard.

  Future<List<VolunteerRequest>> listAll() async {

    final data = await _api.get('/volunteering/all');

    return asRows(data).map(ApiMappers.volunteerRequest).toList();

  }



  Future<VolunteerRequest?> create({

    required String title,

    required double hours,

    required DateTime occurredAt,

    String? opportunityId,

  }) async {

    final body = <String, dynamic>{

      'title': title,

      'hours': hours,

      'occurred_at': occurredAt.toUtc().toIso8601String(),

    };

    if (opportunityId != null) body['opportunity_id'] = opportunityId;

    final result = await _api.post('/volunteering', body: body);

    final row = asRow(result);

    return row == null ? null : ApiMappers.volunteerRequest(row);

  }



  Future<VolunteerRequest?> approve(String id, {String? approvalNote}) async {

    final result = await _api.patch('/volunteering/$id/approve', body: {

      if (approvalNote != null && approvalNote.isNotEmpty)

        'approval_note': approvalNote,

    });

    final row = asRow(result);

    return row == null ? null : ApiMappers.volunteerRequest(row);

  }



  Future<VolunteerRequest?> reject(String id, {String? approvalNote}) async {

    final result = await _api.patch('/volunteering/$id/reject', body: {

      if (approvalNote != null && approvalNote.isNotEmpty)

        'approval_note': approvalNote,

    });

    final row = asRow(result);

    return row == null ? null : ApiMappers.volunteerRequest(row);

  }



  Future<VolunteerRequest?> withdraw(String id) async {

    final result = await _api.patch('/volunteering/$id/withdraw', body: {});

    final row = asRow(result);

    return row == null ? null : ApiMappers.volunteerRequest(row);

  }

}


