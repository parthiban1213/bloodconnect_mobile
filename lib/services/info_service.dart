import '../models/info_entry.dart';
import 'api_client.dart';

class InfoService {
  final ApiClient _client = ApiClient.instance;

  Future<List<InfoEntry>> getEntries({String? category, String? search}) async {
    final params = <String, dynamic>{};
    if (category != null) params['category'] = category;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final res = await _client.get('/info', queryParams: params.isEmpty ? null : params);
    final data = res['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => InfoEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<InfoEntry> getEntry(String id) async {
    final res = await _client.get('/info/$id');
    return InfoEntry.fromJson(res['data'] as Map<String, dynamic>);
  }
}
