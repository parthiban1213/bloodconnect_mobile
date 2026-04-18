import '../models/donor_model.dart';
import 'api_client.dart';

class DonorsService {
  final ApiClient _client = ApiClient.instance;

  Future<List<DonorModel>> getDonors({
    String? bloodType,
    bool? isAvailable,
    String? search,
  }) async {
    final params = <String, dynamic>{};
    if (bloodType != null) params['bloodType'] = bloodType;
    if (isAvailable != null) params['available'] = isAvailable;
    if (search != null && search.isNotEmpty) params['search'] = search;

    final res = await _client.get('/donors', queryParams: params.isEmpty ? null : params);
    final data = res['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => DonorModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DonorModel> getDonor(String id) async {
    final res = await _client.get('/donors/$id');
    return DonorModel.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<DonorModel> createDonor(Map<String, dynamic> data) async {
    final res = await _client.post('/donors', data: data);
    return DonorModel.fromJson(res['data'] as Map<String, dynamic>);
  }
}
