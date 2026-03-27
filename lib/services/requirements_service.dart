import '../models/blood_requirement.dart';
import '../models/donation_history.dart';
import 'api_client.dart';

class RequirementsService {
  final ApiClient _client = ApiClient.instance;

  Future<List<BloodRequirement>> getRequirements({
    String? status,
    String? urgency,
    String? bloodType,
  }) async {
    final params = <String, dynamic>{};
    if (status != null) params['status'] = status;
    if (urgency != null) params['urgency'] = urgency;
    if (bloodType != null) params['bloodType'] = bloodType;

    final res = await _client.get('/requirements',
        queryParams: params.isEmpty ? null : params);
    final data = res['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => BloodRequirement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Correct endpoint: /my-requirements (not /requirements/my) ──
  Future<List<BloodRequirement>> getMyRequirements() async {
    final res = await _client.get('/my-requirements');
    final data = res['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => BloodRequirement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<BloodRequirement> getRequirement(String id) async {
    final res = await _client.get('/requirements/$id');
    return BloodRequirement.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<BloodRequirement> createRequirement(Map<String, dynamic> data) async {
    final res = await _client.post('/requirements', data: data);
    return BloodRequirement.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<BloodRequirement> updateRequirement(
      String id, Map<String, dynamic> data) async {
    final res = await _client.put('/requirements/$id', data: data);
    return BloodRequirement.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> deleteRequirement(String id) async {
    await _client.delete('/requirements/$id');
  }

  Future<BloodRequirement> fulfillRequirement(String id) async {
    return updateRequirement(id, {'status': 'Fulfilled'});
  }

  Future<BloodRequirement> cancelRequirement(String id) async {
    return updateRequirement(id, {'status': 'Cancelled'});
  }

  // ── Donate endpoint ─────────────────────────────────────────
  // Backend POST /requirements/:id/donate returns:
  //   { success, message, data: { remainingUnits, status } }
  // NOT a full BloodRequirement object.
  // We call donate, then fetch the fresh requirement separately.
  Future<BloodRequirement> donateToRequirement(String id) async {
    // Step 1: record donation on server
    // Backend handles: decrement remainingUnits, auto-fulfill, SMS via Twilio
    await _client.post('/requirements/$id/donate');

    // Step 2: fetch the updated full requirement
    return getRequirement(id);
  }

  // ── Decline endpoint ────────────────────────────────────────
  Future<void> declineRequirement(String id) async {
    await _client.post('/requirements/$id/decline');
  }

  // ── Correct endpoint: /my-donations (not /donations/my) ────
  Future<List<DonationHistory>> getMyDonations() async {
    final res = await _client.get('/my-donations');
    final data = res['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => DonationHistory.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
