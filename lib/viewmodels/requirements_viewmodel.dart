import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/blood_requirement.dart';
import '../services/requirements_service.dart';
import '../services/location_service.dart';
import '../utils/api_exception.dart';
import 'auth_viewmodel.dart';

/// Distance filter options for the feed
enum LocationFilterRadius {
  nearby5km,
  nearby10km,
  nearby25km,
  nearby50km,
  sameCity,
  allLocations,
}

extension LocationFilterRadiusExt on LocationFilterRadius {
  String get label {
    switch (this) {
      case LocationFilterRadius.nearby5km:    return '5 km';
      case LocationFilterRadius.nearby10km:   return '10 km';
      case LocationFilterRadius.nearby25km:   return '25 km';
      case LocationFilterRadius.nearby50km:   return '50 km';
      case LocationFilterRadius.sameCity:     return 'My City';
      case LocationFilterRadius.allLocations: return 'All Locations';
    }
  }

  double? get distanceKm {
    switch (this) {
      case LocationFilterRadius.nearby5km:    return 5;
      case LocationFilterRadius.nearby10km:   return 10;
      case LocationFilterRadius.nearby25km:   return 25;
      case LocationFilterRadius.nearby50km:   return 50;
      case LocationFilterRadius.sameCity:     return null;
      case LocationFilterRadius.allLocations: return null;
    }
  }
}

class RequirementsState {
  final bool isLoading;
  final List<BloodRequirement> requirements;
  final String? error;
  final String selectedFilter;
  final String userBloodType;
  final String searchQuery;
  final Set<String> donatingIds;
  final Set<String> declinedIds;
  final Set<String> donatedIds;

  // ── Pagination ────────────────────────────────────────────────
  final int currentPage;
  final int totalPages;
  final int totalItems;
  final bool isLoadingMore;

  // ── Location ──────────────────────────────────────────────────
  final UserLocation? userLocation;
  final bool locationLoading;
  final LocationFilterRadius locationFilter;

  const RequirementsState({
    this.isLoading       = false,
    this.requirements    = const [],
    this.error,
    this.selectedFilter  = 'All',
    this.userBloodType   = '',
    this.searchQuery     = '',
    this.donatingIds     = const {},
    this.declinedIds     = const {},
    this.donatedIds      = const {},
    this.currentPage     = 1,
    this.totalPages      = 1,
    this.totalItems      = 0,
    this.isLoadingMore   = false,
    this.userLocation,
    this.locationLoading = false,
    this.locationFilter  = LocationFilterRadius.allLocations,
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
    int? currentPage,
    int? totalPages,
    int? totalItems,
    bool? isLoadingMore,
    UserLocation? userLocation,
    bool? locationLoading,
    LocationFilterRadius? locationFilter,
    bool clearError = false,
    bool clearLocation = false,
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
      currentPage:    currentPage ?? this.currentPage,
      totalPages:     totalPages ?? this.totalPages,
      totalItems:     totalItems ?? this.totalItems,
      isLoadingMore:  isLoadingMore ?? this.isLoadingMore,
      userLocation:   clearLocation ? null : (userLocation ?? this.userLocation),
      locationLoading: locationLoading ?? this.locationLoading,
      locationFilter: locationFilter ?? this.locationFilter,
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
            r.location.toLowerCase().contains(q) ||
            r.city.toLowerCase().contains(q);
      }).toList();
    }

    return base;
  }

  bool get hasGpsLocation => userLocation?.isGps == true;
  bool get hasMorePages   => currentPage < totalPages;

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
    _initLocation();
    _startAutoRefresh();
  }

  // ── Location initialization ─────────────────────────────────────
  Future<void> _initLocation() async {
    state = state.copyWith(locationLoading: true);

    // Try GPS first
    final gpsLocation = await LocationService.instance.requestGpsLocation();
    if (gpsLocation != null) {
      state = state.copyWith(
        userLocation: gpsLocation,
        locationLoading: false,
        locationFilter: LocationFilterRadius.nearby25km,
      );
      load();
      return;
    }

    // Fallback to profile city
    final userCity = _ref.read(authViewModelProvider).user?.city ?? '';
    if (userCity.isNotEmpty) {
      final coords = CityCoordinates.lookup(userCity);
      if (coords != null) {
        LocationService.instance.setFallbackLocation(coords['lat']!, coords['lng']!);
        state = state.copyWith(
          userLocation: LocationService.instance.currentLocation,
          locationLoading: false,
          locationFilter: LocationFilterRadius.sameCity,
        );
      } else {
        // City not in lookup table — use city name filter on the server
        state = state.copyWith(locationLoading: false,
            locationFilter: LocationFilterRadius.sameCity);
      }
    } else {
      state = state.copyWith(locationLoading: false);
    }

    load();
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
      final reqs = await _service.getAllRequirements(
        latitude:    state.userLocation?.latitude,
        longitude:   state.userLocation?.longitude,
        city:        _getCityFilter(),
        maxDistance: _getMaxDistance(),
      );
      _sortRequirements(reqs);
      final donated = _deriveDonatedIds(reqs);
      state = state.copyWith(requirements: reqs, donatedIds: donated);
    } catch (_) {
      // Silent — never surface auto-refresh errors
    }
  }

  // ── Derive donated IDs from server data ───────────────────────────────────

  Set<String> _deriveDonatedIds(List<BloodRequirement> reqs) {
    final username = _ref.read(authViewModelProvider).user?.username ?? '';
    if (username.isEmpty) return state.donatedIds;
    return reqs
        .where((r) => r.hasDonatedBy(username))
        .map((r) => r.id)
        .toSet();
  }

  // ── Location filter helpers ───────────────────────────────────────────────

  String? _getCityFilter() {
    if (state.locationFilter == LocationFilterRadius.sameCity) {
      return _ref.read(authViewModelProvider).user?.city;
    }
    return null;
  }

  double? _getMaxDistance() {
    if (state.userLocation != null) {
      return state.locationFilter.distanceKm;
    }
    return null;
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

  void setLocationFilter(LocationFilterRadius filter) {
    state = state.copyWith(locationFilter: filter, currentPage: 1);
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true, currentPage: 1);
    try {
      final result = await _service.getRequirements(
        latitude:    state.userLocation?.latitude,
        longitude:   state.userLocation?.longitude,
        city:        _getCityFilter(),
        maxDistance:  _getMaxDistance(),
        page:        1,
        limit:       20,
      );
      _sortRequirements(result.items);
      final donated = _deriveDonatedIds(result.items);
      state = state.copyWith(
        isLoading: false,
        requirements: result.items,
        donatedIds: donated,
        currentPage: result.page,
        totalPages: result.totalPages,
        totalItems: result.total,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Failed to load requirements.');
    }
  }

  /// Load next page (pagination)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMorePages) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      final nextPage = state.currentPage + 1;
      final result = await _service.getRequirements(
        latitude:    state.userLocation?.latitude,
        longitude:   state.userLocation?.longitude,
        city:        _getCityFilter(),
        maxDistance:  _getMaxDistance(),
        page:        nextPage,
        limit:       20,
      );
      final combined = [...state.requirements, ...result.items];
      _sortRequirements(combined);
      final donated = _deriveDonatedIds(combined);
      state = state.copyWith(
        isLoadingMore: false,
        requirements: combined,
        donatedIds: donated,
        currentPage: result.page,
        totalPages: result.totalPages,
        totalItems: result.total,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void _sortRequirements(List<BloodRequirement> reqs) {
    // When user has location, sort primarily by distance (already done by server),
    // otherwise fall back to urgency-based sorting.
    if (state.userLocation == null) {
      const order = {'Critical': 0, 'High': 1, 'Medium': 2, 'Low': 3};
      reqs.sort((a, b) {
        if (a.status == 'Open' && b.status != 'Open') return -1;
        if (a.status != 'Open' && b.status == 'Open') return 1;
        return (order[a.urgency] ?? 4).compareTo(order[b.urgency] ?? 4);
      });
    }
    // When location is available, server already sorted by distance
  }

  Future<BloodRequirement?> getDetail(String id) async {
    try { return await _service.getRequirement(id); } catch (_) { return null; }
  }

  Future<BloodRequirement?> donate(
      String id, {
        required String scheduledDate,
        required String scheduledTime,
      }) async {
    final donating = Set<String>.from(state.donatingIds)..add(id);
    state = state.copyWith(donatingIds: donating, clearError: true);
    try {
      final updated = await _service.donateToRequirement(
        id,
        scheduledDate: scheduledDate,
        scheduledTime: scheduledTime,
      );
      final updatedList = state.requirements.map((r) => r.id == id ? updated : r).toList();
      final donated = Set<String>.from(state.donatedIds)..add(id);
      state = state.copyWith(
        requirements: updatedList,
        donatingIds:  Set<String>.from(state.donatingIds)..remove(id),
        donatedIds:   donated,
      );
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
    final hidden = Set<String>.from(state.declinedIds)..add(id);
    state = state.copyWith(declinedIds: hidden);
    _service.declineRequirement(id).catchError((_) {});
    return true;
  }

  Future<bool> updateDonationStatus({
    required String requirementId,
    required String donorUsername,
    required String newStatus,
  }) async {
    try {
      await _service.updateDonationStatus(
        requirementId: requirementId,
        donorUsername: donorUsername,
        newStatus:     newStatus,
      );
      await load();
      if (newStatus == 'Completed') {
        _ref.read(authViewModelProvider.notifier).refreshProfile();
      }
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Failed to update donation status.');
      return false;
    }
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

/// Fetches the top urgent open requirements for the home screen, independent
/// of the feed's location filter.
///
/// Priority:
///   1. GPS available → fetch within 25 km of the user's coordinates.
///   2. GPS not available → fetch by the user's profile city.
///
/// This provider never reads [RequirementsState.locationFilter], so changing
/// the location filter in the feed screen has no effect on the home screen.
final homeUrgentRequirementsProvider =
FutureProvider.autoDispose<List<BloodRequirement>>((ref) async {
  final service  = RequirementsService();
  final userCity = ref.watch(authViewModelProvider).user?.city ?? '';

  // Reuse the GPS location that _initLocation() already resolved, if any.
  final cachedGps = LocationService.instance.currentLocation;
  final hasGps    = cachedGps?.isGps == true;

  double? latitude, longitude, maxDistance;
  String? city;

  if (hasGps) {
    latitude    = cachedGps!.latitude;
    longitude   = cachedGps.longitude;
    maxDistance = 25; // always 25 km for the home screen
  } else if (userCity.isNotEmpty) {
    city = userCity;
  }

  final result = await service.getRequirements(
    latitude:    latitude,
    longitude:   longitude,
    maxDistance: maxDistance,
    city:        city,
    page:        1,
    limit:       20,
  );

  return result.items
      .where((r) => r.isOpen)
      .take(3)
      .toList();
});