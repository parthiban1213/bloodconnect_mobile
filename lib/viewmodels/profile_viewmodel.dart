import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stats_model.dart';
import '../services/stats_service.dart';
import '../utils/api_exception.dart';

class ProfileState {
  final bool isLoadingStats;
  final StatsModel? stats;
  final String? error;

  const ProfileState({
    this.isLoadingStats = false,
    this.stats,
    this.error,
  });

  ProfileState copyWith({
    bool? isLoadingStats,
    StatsModel? stats,
    String? error,
    bool clearError = false,
  }) {
    return ProfileState(
      isLoadingStats: isLoadingStats ?? this.isLoadingStats,
      stats: stats ?? this.stats,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ProfileViewModel extends StateNotifier<ProfileState> {
  final StatsService _statsService = StatsService();

  ProfileViewModel() : super(const ProfileState()) {
    loadStats();
  }

  Future<void> loadStats() async {
    state = state.copyWith(isLoadingStats: true, clearError: true);
    try {
      final stats = await _statsService.getStats();
      state = state.copyWith(isLoadingStats: false, stats: stats);
    } on ApiException catch (e) {
      state = state.copyWith(isLoadingStats: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isLoadingStats: false, error: 'Failed to load stats.');
    }
  }
}

final profileViewModelProvider =
    StateNotifierProvider<ProfileViewModel, ProfileState>((ref) {
  return ProfileViewModel();
});
