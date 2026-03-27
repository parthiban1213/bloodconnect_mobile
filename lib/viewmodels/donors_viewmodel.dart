import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/donor_model.dart';
import '../services/donors_service.dart';

class DonorsState {
  final bool isLoading;
  final List<DonorModel> donors;
  final String? error;
  final String search;
  final String bloodTypeFilter; // '' = All
  final String availabilityFilter; // '' = All, 'true', 'false'

  const DonorsState({
    this.isLoading         = false,
    this.donors            = const [],
    this.error,
    this.search            = '',
    this.bloodTypeFilter   = '',
    this.availabilityFilter = '',
  });

  List<DonorModel> get filtered {
    return donors.where((d) {
      final q = search.toLowerCase();
      final matchSearch = q.isEmpty ||
          d.fullName.toLowerCase().contains(q) ||
          d.phone.contains(q) ||
          (d.address.toLowerCase().contains(q));
      final matchBlood = bloodTypeFilter.isEmpty ||
          d.bloodType == bloodTypeFilter;
      final matchAvail = availabilityFilter.isEmpty ||
          d.isAvailable.toString() == availabilityFilter;
      return matchSearch && matchBlood && matchAvail;
    }).toList();
  }

  DonorsState copyWith({
    bool? isLoading,
    List<DonorModel>? donors,
    String? error,
    bool clearError = false,
    String? search,
    String? bloodTypeFilter,
    String? availabilityFilter,
  }) {
    return DonorsState(
      isLoading:          isLoading ?? this.isLoading,
      donors:             donors ?? this.donors,
      error:              clearError ? null : (error ?? this.error),
      search:             search ?? this.search,
      bloodTypeFilter:    bloodTypeFilter ?? this.bloodTypeFilter,
      availabilityFilter: availabilityFilter ?? this.availabilityFilter,
    );
  }
}

class DonorsViewModel extends StateNotifier<DonorsState> {
  final DonorsService _service = DonorsService();

  DonorsViewModel() : super(const DonorsState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final donors = await _service.getDonors();
      state = state.copyWith(isLoading: false, donors: donors);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load donors. Please try again.',
      );
    }
  }

  void setSearch(String value) =>
      state = state.copyWith(search: value);

  void setBloodType(String value) =>
      state = state.copyWith(bloodTypeFilter: value);

  void setAvailability(String value) =>
      state = state.copyWith(availabilityFilter: value);
}

final donorsViewModelProvider =
    StateNotifierProvider<DonorsViewModel, DonorsState>(
        (_) => DonorsViewModel());
