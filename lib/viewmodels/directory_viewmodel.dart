import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/info_entry.dart';
import '../services/info_service.dart';
import '../utils/api_exception.dart';

class DirectoryState {
  final bool isLoading;
  final List<InfoEntry> entries;
  final String? error;
  final String selectedCategory; // 'All', 'Hospital', 'Blood Bank', 'Ambulance'
  final String searchQuery;
  final String availabilityFilter; // '' = all, 'true' = 24h only, 'false' = non-24h

  const DirectoryState({
    this.isLoading = false,
    this.entries = const [],
    this.error,
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.availabilityFilter = '',
  });

  DirectoryState copyWith({
    bool? isLoading,
    List<InfoEntry>? entries,
    String? error,
    String? selectedCategory,
    String? searchQuery,
    String? availabilityFilter,
    bool clearError = false,
  }) {
    return DirectoryState(
      isLoading: isLoading ?? this.isLoading,
      entries: entries ?? this.entries,
      error: clearError ? null : (error ?? this.error),
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      availabilityFilter: availabilityFilter ?? this.availabilityFilter,
    );
  }

  bool get hasActiveFilter =>
      selectedCategory != 'All' || availabilityFilter.isNotEmpty;

  List<InfoEntry> get filtered {
    var result = entries;

    if (selectedCategory != 'All') {
      result = result.where((e) => e.category == selectedCategory).toList();
    }

    if (availabilityFilter == 'true') {
      result = result.where((e) => e.available24h).toList();
    } else if (availabilityFilter == 'false') {
      result = result.where((e) => !e.available24h).toList();
    }

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      result = result
          .where((e) =>
      e.name.toLowerCase().contains(q) ||
          e.area.toLowerCase().contains(q) ||
          e.address.toLowerCase().contains(q))
          .toList();
    }

    return result;
  }
}

class DirectoryViewModel extends StateNotifier<DirectoryState> {
  final InfoService _service = InfoService();

  DirectoryViewModel() : super(const DirectoryState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final entries = await _service.getEntries();
      state = state.copyWith(isLoading: false, entries: entries);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to load directory.');
    }
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setAvailability(String value) {
    state = state.copyWith(availabilityFilter: value);
  }

  void clearFilters() {
    state = state.copyWith(
      selectedCategory: 'All',
      availabilityFilter: '',
    );
  }
}

final directoryViewModelProvider =
StateNotifierProvider<DirectoryViewModel, DirectoryState>((ref) {
  return DirectoryViewModel();
});