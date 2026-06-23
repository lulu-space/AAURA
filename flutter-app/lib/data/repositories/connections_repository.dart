import '../../core/network/api_client.dart';
import '../../models/connection.dart';
import '../api_mappers.dart';
import '_repo_support.dart';

class ConnectionsRepository {
  ConnectionsRepository(this._api);

  final ApiClient _api;

  Future<List<Connection>> suggestions() async {
    final data = await _api.get('/connections/suggestions');
    return asRows(data).map(ApiMappers.connection).toList();
  }

  Future<List<Connection>> listMine() async {
    final data = await _api.get('/connections/mine');
    return asRows(data).map(ApiMappers.connection).toList();
  }

  Future<void> connect(String userId) async {
    await _api.post('/connections/connect', body: {'user_id': userId});
  }

  Future<void> disconnect(String userId) async {
    await _api.delete('/connections/$userId');
  }
}
