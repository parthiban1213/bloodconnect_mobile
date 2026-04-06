import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/blood_requirement.dart';
import '../services/requirements_service.dart';
import '../utils/api_exception.dart';

class MyRequestsState {
  final bool isLoading;
  final List<BloodRequirement> requests;
  final String? error;

  const MyRequestsState({
    this.isLoading = false,
    this.requests  = const [],
    this.error,
  });

  MyRequestsState copyWith({
    bool? isLoading,
    List<BloodRequirement>? requests,
    String? error,
    bool clearError = false,
  }) =>
      MyRequestsState(
        isLoading: isLoading ?? this.isLoading,
        requests:  requests  ?? this.requests,
        error:     clearError ? null : (error ?? this.error),
      );

  List<BloodRequirement> get activeRequests    =>
      requests.where((r) => r.isOpen).toList();
  List<BloodRequirement> get fulfilledRequests =>
      requests.where((r) => r.isFulfilled).toList();
  List<BloodRequirement> get cancelledRequests =>
      requests.where((r) => r.isCancelled).toList();
}

class MyRequestsViewModel extends StateNotifier<MyRequestsState> {
  final RequirementsService _service = RequirementsService();
  Timer? _refreshTimer;

  MyRequestsViewModel() : super(const MyRequestsState()) {
    load();
    _startAutoRefresh();
  }

  // Auto-refresh every 30 seconds while the provider is alive
  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _silentRefresh(),
    );
  }

  // Background refresh — no loading spinner
  Future<void> _silentRefresh() async {
    try {
      final reqs = await _service.getMyRequirements();
      _sort(reqs);
      state = state.copyWith(requests: reqs);
    } catch (_) {
      // Silent — never surface auto-refresh errors
    }
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final reqs = await _service.getMyRequirements();
      _sort(reqs);
      state = state.copyWith(isLoading: false, requests: reqs);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to load your requests.');
    }
  }

  void _sort(List<BloodRequirement> reqs) {
    reqs.sort((a, b) {
      if (a.isOpen && !b.isOpen) return -1;
      if (!a.isOpen && b.isOpen) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
  }

  Future<bool> updateRequest(String id, Map<String, dynamic> data) async {
    try {
      final updated = await _service.updateRequirement(id, data);
      final newList = state.requests.map((r) => r.id == id ? updated : r).toList();
      _sort(newList);
      state = state.copyWith(requests: newList);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Failed to update request.');
      return false;
    }
  }

  /// Fetches the full donor pledge list for a given requirement.
  /// Used by the status modal to show who has pledged and their status.
  /// Only works if the current user is the requirement creator or admin.
  Future<List<DonorPledge>> fetchDonorPledges(String requirementId) async {
    try {
      return await _service.getDonorPledges(requirementId);
    } catch (_) {
      return [];
    }
  }

  Future<bool> closeRequest(String id) async {
    try {
      final updated = await _service.cancelRequirement(id);
      final newList = state.requests.map((r) => r.id == id ? updated : r).toList();
      _sort(newList);
      state = state.copyWith(requests: newList);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Failed to close request.');
      return false;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

final myRequestsViewModelProvider =
    StateNotifierProvider<MyRequestsViewModel, MyRequestsState>(
        (_) => MyRequestsViewModel());
