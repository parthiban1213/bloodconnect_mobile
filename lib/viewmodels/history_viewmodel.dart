import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/donation_history.dart';
import '../models/blood_requirement.dart';
import '../services/requirements_service.dart';
import 'auth_viewmodel.dart';

class HistoryState {
  final bool isLoading;
  final List<DonationHistory> myDonations;
  final List<BloodRequirement> completedRequests; // all fulfilled/cancelled from feed
  final String? error;

  const HistoryState({
    this.isLoading          = false,
    this.myDonations        = const [],
    this.completedRequests  = const [],
    this.error,
  });

  int get completedCount => completedRequests.length;

  HistoryState copyWith({
    bool? isLoading,
    List<DonationHistory>? myDonations,
    List<BloodRequirement>? completedRequests,
    String? error,
    bool clearError = false,
  }) {
    return HistoryState(
      isLoading:         isLoading ?? this.isLoading,
      myDonations:       myDonations ?? this.myDonations,
      completedRequests: completedRequests ?? this.completedRequests,
      error:             clearError ? null : (error ?? this.error),
    );
  }
}

class HistoryViewModel extends StateNotifier<HistoryState> {
  final RequirementsService _service = RequirementsService();

  HistoryViewModel() : super(const HistoryState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      // Run both requests in parallel
      final results = await Future.wait([
        _service.getMyDonations(),    // GET /api/my-donations  (donor tab)
        _service.getMyRequirements(), // GET /api/my-requirements (completed tab)
      ]);

      final donations = results[0] as List<DonationHistory>;
      final myReqs    = results[1] as List<BloodRequirement>;

      // Completed tab = only the current user's OWN requests that are
      // Fulfilled or Cancelled. Sorted newest-updated first.
      final completed = myReqs
          .where((r) => r.isFulfilled || r.isCancelled)
          .toList()
        ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      donations.sort((a, b) => b.donatedAt.compareTo(a.donatedAt));

      state = state.copyWith(
        isLoading:         false,
        myDonations:       donations,
        completedRequests: completed,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error:     'Failed to load history. Please try again.',
      );
    }
  }
}

final historyViewModelProvider =
    StateNotifierProvider<HistoryViewModel, HistoryState>(
        (_) => HistoryViewModel());
