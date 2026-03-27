import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/blood_requirement.dart';
import '../services/requirements_service.dart';
import '../utils/api_exception.dart';
import 'auth_viewmodel.dart';

class RequirementsState {
  final bool isLoading;
  final List<BloodRequirement> requirements;
  final String? error;
  final String selectedFilter;
  final String userBloodType;
  final String searchQuery;
  final Set<String> donatingIds;
  final Set<String> declinedIds;
  /// IDs of requirements the current user has already donated to.
  /// Derived from server data (donations[].donorUsername) on every load —
  /// no local storage needed, survives logout/login automatically.
  final Set<String> donatedIds;

  const RequirementsState({
    this.isLoading      = false,
    this.requirements   = const [],
    this.error,
    this.selectedFilter = 'All',
    this.userBloodType  = '',
    this.searchQuery    = '',
    this.donatingIds    = const {},
    this.declinedIds    = const {},
    this.donatedIds     = const {},
  });

  RequirementsState copyWith({
    bool? isLoading,
    List<BloodRequirement>? requirements,
    String? error,
    String? selectedFilter,
    String? userBloodType,
    String? searchQuery,
    Set<String>? donatingIds,
    Set<String>? declinedIds,
    Set<String>? donatedIds,
    bool clearError = false,
  }) {
    return RequirementsState(
      isLoading:      isLoading ?? this.isLoading,
      requirements:   requirements ?? this.requirements,
      error:          clearError ? null : (error ?? this.error),
      selectedFilter: selectedFilter ?? this.selectedFilter,
      userBloodType:  userBloodType ?? this.userBloodType,
      searchQuery:    searchQuery ?? this.searchQuery,
      donatingIds:    donatingIds ?? this.donatingIds,
      declinedIds:    declinedIds ?? this.declinedIds,
      donatedIds:     donatedIds ?? this.donatedIds,
    );
  }

  List<BloodRequirement> get filtered {
    // Step 1: always exclude declined requests
    List<BloodRequirement> base = requirements
        .where((r) => !declinedIds.contains(r.id))
        .toList();

    // Step 2: when no filter is set, show all Open requests (all blood types)
    if (selectedFilter == 'All') {
      base = base.where((r) => r.isOpen).toList();
    }

    // Step 3: chip filter
    if (selectedFilter != 'All') {
      if (selectedFilter == 'Open') {
        base = base.where((r) => r.status == 'Open').toList();
      } else if (selectedFilter == 'Fulfilled') {
        base = base.where((r) => r.status == 'Fulfilled').toList();
      } else if (selectedFilter == 'Cancelled') {
        base = base.where((r) => r.status == 'Cancelled').toList();
      } else {
        const urgencyKeys = {'Critical', 'High', 'Medium', 'Low'};
        if (urgencyKeys.contains(selectedFilter)) {
          base = base.where((r) => r.urgency == selectedFilter && r.status == 'Open').toList();
        }
      }
    }

    // Step 4: search query
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      base = base.where((r) {
        return r.hospital.toLowerCase().contains(q) ||
               r.bloodType.toLowerCase().contains(q) ||
               r.patientName.toLowerCase().contains(q) ||
               r.location.toLowerCase().contains(q);
      }).toList();
    }

    return base;
  }

  bool isDonating(String id) => donatingIds.contains(id);
  bool isDeclined(String id) => declinedIds.contains(id);
  bool hasDonated(String id) => donatedIds.contains(id);
}

class RequirementsViewModel extends StateNotifier<RequirementsState> {
  final RequirementsService _service = RequirementsService();
  final Ref _ref;
  Timer? _autoRefreshTimer;

  RequirementsViewModel(this._ref, {String userBloodType = ''})
      : super(RequirementsState(userBloodType: userBloodType)) {
    load();
    _startAutoRefresh();
  }

  // ── Auto-refresh ──────────────────────────────────────────────────────────

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _silentRefresh(),
    );
  }

  Future<void> _silentRefresh() async {
    try {
      final reqs = await _service.getRequirements();
      _sortRequirements(reqs);
      final donated = _deriveDonatedIds(reqs);
      state = state.copyWith(requirements: reqs, donatedIds: donated);
    } catch (_) {
      // Silent — never surface auto-refresh errors
    }
  }

  // ── Derive donated IDs from server data ───────────────────────────────────

  /// Scans the freshly-loaded requirements list and returns IDs of all
  /// requirements where the currently logged-in user appears in the
  /// donations array.  Because this data comes from MongoDB, it persists
  /// across app restarts, logouts, and device changes automatically.
  Set<String> _deriveDonatedIds(List<BloodRequirement> reqs) {
    final username = _ref.read(authViewModelProvider).user?.username ?? '';
    if (username.isEmpty) return state.donatedIds; // keep existing if not logged in yet
    return reqs
        .where((r) => r.hasDonatedBy(username))
        .map((r) => r.id)
        .toSet();
  }

  // ── Public API ────────────────────────────────────────────────────────────

  void setUserBloodType(String bloodType) {
    if (state.userBloodType != bloodType) {
      state = state.copyWith(userBloodType: bloodType);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setFilter(String filter) =>
      state = state.copyWith(selectedFilter: filter);

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final reqs = await _service.getRequirements();
      _sortRequirements(reqs);
      final donated = _deriveDonatedIds(reqs);
      state = state.copyWith(isLoading: false, requirements: reqs, donatedIds: donated);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Failed to load requirements.');
    }
  }

  void _sortRequirements(List<BloodRequirement> reqs) {
    const order = {'Critical': 0, 'High': 1, 'Medium': 2, 'Low': 3};
    reqs.sort((a, b) {
      if (a.status == 'Open' && b.status != 'Open') return -1;
      if (a.status != 'Open' && b.status == 'Open') return 1;
      return (order[a.urgency] ?? 4).compareTo(order[b.urgency] ?? 4);
    });
  }

  Future<BloodRequirement?> getDetail(String id) async {
    try { return await _service.getRequirement(id); } catch (_) { return null; }
  }

  Future<BloodRequirement?> donate(String id) async {
    final donating = Set<String>.from(state.donatingIds)..add(id);
    state = state.copyWith(donatingIds: donating, clearError: true);
    try {
      final updated = await _service.donateToRequirement(id);
      final updatedList = state.requirements.map((r) => r.id == id ? updated : r).toList();
      // Mark as donated immediately (optimistic) — will also be confirmed on next load
      // since the username is now in the donations array on the server.
      final donated = Set<String>.from(state.donatedIds)..add(id);
      state = state.copyWith(
        requirements: updatedList,
        donatingIds:  Set<String>.from(state.donatingIds)..remove(id),
        donatedIds:   donated,
      );
      _ref.read(authViewModelProvider.notifier).refreshProfile();
      load();
      return updated;
    } on ApiException catch (e) {
      state = state.copyWith(
        error:       e.message,
        donatingIds: Set<String>.from(state.donatingIds)..remove(id),
      );
      return null;
    } catch (_) {
      state = state.copyWith(
        error:       'Donation action failed. Please try again.',
        donatingIds: Set<String>.from(state.donatingIds)..remove(id),
      );
      return null;
    }
  }

  Future<bool> confirmDonation(String id) async {
    try {
      await _service.fulfillRequirement(id);
      await load();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    }
  }

  Future<bool> declineDonation(String id) async {
    // Immediately hide card from feed (optimistic update)
    final hidden = Set<String>.from(state.declinedIds)..add(id);
    state = state.copyWith(declinedIds: hidden);
    // Inform backend in background
    _service.declineRequirement(id).catchError((_) {});
    return true;
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}

final requirementsViewModelProvider =
    StateNotifierProvider<RequirementsViewModel, RequirementsState>((ref) {
  return RequirementsViewModel(ref);
});
