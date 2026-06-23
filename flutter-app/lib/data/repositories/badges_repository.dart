import '../../core/network/api_client.dart';
import '../../models/badge.dart';
import '../api_mappers.dart';
import '_repo_support.dart';

class BadgesRepository {
  BadgesRepository(this._api);

  final ApiClient _api;

  Future<List<AppBadge>> listDefinitions() async {
    final data = await _api.get('/badges');
    return asRows(data).map(ApiMappers.badgeDefinition).toList();
  }
}
