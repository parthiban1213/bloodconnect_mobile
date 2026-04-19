import '../models/blood_requirement.dart';
import '../models/donation_history.dart';
import 'api_client.dart';

class PaginatedRequirements {
  final List<BloodRequirement> items;
  final int page;
  final int totalPages;
  final int total;

  const PaginatedRequirements({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.total,
  });
}

class RequirementsService {
  final ApiClient _client = ApiClient.instance;

  Future<PaginatedRequirements> getRequirements({
    String? status,
    String? urgency,
    String? bloodType,
    String? city,
    double? latitude,
    double? longitude,
    double? maxDistance,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null)      params['status']      = status;
    if (urgency != null)     params['urgency']      = urgency;
    if (bloodType != null)   params['bloodType']    = bloodType;
    if (city != null && city.isNotEmpty) params['city'] = city;
    if (latitude != null)    params['latitude']     = latitude.toString();
    if (longitude != null)   params['longitude']    = longitude.toString();
    if (maxDistance != null) params['maxDistance']  = maxDistance.toString();

    final res  = await _client.get('/requirements', queryParams: params);
    final data = res['data'] as List<dynamic>? ?? [];
    final pagination = res['pagination'] as Map<String, dynamic>?;

    final items = data
        .map((e) => BloodRequirement.fromJson(e as Map<String, dynamic>))
        .toList();

    return PaginatedRequirements(
      items:      items,
      page:       pagination?['page']       as int? ?? page,
      totalPages: pagination?['totalPages'] as int? ?? 1,
      total:      pagination?['total']      as int? ?? items.length,
    );
  }

  /// Legacy non-paginated fetch (used by silent refresh to get all).
  Future<List<BloodRequirement>> getAllRequirements({
    double? latitude,
    double? longitude,
    String? city,
    double? maxDistance,
  }) async {
    final params = <String, dynamic>{ 'limit': '500' };
    if (city != null && city.isNotEmpty) params['city']        = city;
    if (latitude != null)                params['latitude']    = latitude.toString();
    if (longitude != null)               params['longitude']   = longitude.toString();
    if (maxDistance != null)             params['maxDistance'] = maxDistance.toString();

    final res  = await _client.get('/requirements', queryParams: params);
    final data = res['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => BloodRequirement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<BloodRequirement>> getMyRequirements() async {
    final res  = await _client.get('/my-requirements');
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

  // ── Donate endpoint ──────────────────────────────────────
  /// Pledges to donate for [id]. After the pledge is created on the backend,
  /// a notification is sent to the requester via POST /requirements/:id/notify-pledge
  /// so they are immediately alerted that someone has responded.
  Future<BloodRequirement> donateToRequirement(
    String id, {
    required String scheduledDate,
    required String scheduledTime,
  }) async {
    // Step 1: create the pledge
    await _client.post('/requirements/$id/donate', data: {
      'scheduledDate':  scheduledDate,
      'scheduledTime':  scheduledTime,
      'donationStatus': 'Pending',
    });

    // Step 2: notify the requester (fire-and-forget — errors are non-fatal)
    _notifyRequesterOfPledge(id).catchError((_) {});

    // Step 3: return the refreshed requirement
    return getRequirement(id);
  }

  /// Sends a push notification to the requirement creator informing them
  /// that a donor has pledged. Uses a dedicated lightweight endpoint so the
  /// backend can look up the requester's FCM token and send the alert.
  Future<void> _notifyRequesterOfPledge(String requirementId) async {
    await _client.post('/requirements/$requirementId/notify-pledge');
  }

  // ── Decline endpoint ─────────────────────────────────────
  Future<void> declineRequirement(String id) async {
    await _client.post('/requirements/$id/decline');
  }

  // ── Donor list (requester / admin only) ──────────────────
  Future<List<DonorPledge>> getDonorPledges(String requirementId) async {
    final res  = await _client.get('/requirements/$requirementId/donors');
    final data = res['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => DonorPledge.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Update donation status (requester / admin only) ──────
  Future<Map<String, dynamic>> updateDonationStatus({
    required String requirementId,
    required String donorUsername,
    required String newStatus,
  }) async {
    final res = await _client.post(
      '/requirements/$requirementId/donations/${Uri.encodeComponent(donorUsername)}/status',
      data: {'donationStatus': newStatus},
    );
    return res as Map<String, dynamic>;
  }

  Future<List<DonationHistory>> getMyDonations() async {
    final res  = await _client.get('/my-donations');
    final data = res['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => DonationHistory.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
