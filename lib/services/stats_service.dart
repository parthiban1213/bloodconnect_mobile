import '../models/stats_model.dart';
import 'api_client.dart';

class StatsService {
  final ApiClient _client = ApiClient.instance;

  Future<StatsModel> getStats() async {
    final res = await _client.get('/stats');
    return StatsModel.fromJson(res['data'] as Map<String, dynamic>);
  }
}
