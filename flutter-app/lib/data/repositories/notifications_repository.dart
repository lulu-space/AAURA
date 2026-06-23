import '../../core/network/api_client.dart';

import '../../models/app_notification.dart';

import '../api_mappers.dart';

import '_repo_support.dart';



class NotificationsRepository {

  NotificationsRepository(this._api);



  final ApiClient _api;



  Future<List<AppNotification>> listMine() async {

    final data = await _api.get('/notifications');

    return asRows(data).map(ApiMappers.notification).toList();

  }



  Future<AppNotification?> markRead(String id) async {

    final result = await _api.patch('/notifications/$id', body: {'is_read': true});

    final row = asRow(result);

    return row == null ? null : ApiMappers.notification(row);

  }

}


