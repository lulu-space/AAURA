import '../../core/network/api_client.dart';

import '_repo_support.dart';



class RecommendationsRepository {

  RecommendationsRepository(this._api);



  final ApiClient _api;



  Future<List<Map<String, dynamic>>> listMine() async {

    final data = await _api.get('/recommendations');

    return asRows(data);

  }

}


