// ─────────────────────────────────────────────────────────────
//  GamificationViewModel — Riverpod state for gamification
// ─────────────────────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_config.dart';
import '../models/gamification_model.dart';
import '../services/gamification_service.dart';
import 'auth_viewmodel.dart';

class GamificationState {
  final bool isLoading;
  final GamificationData? data;
  final String? error;
  final LeaderboardScope selectedScope;

  const GamificationState({
    this.isLoading     = false,
    this.data,
    this.error,
    this.selectedScope = LeaderboardScope.city,
  });

  GamificationState copyWith({
    bool? isLoading,
    GamificationData? data,
    String? error,
    bool clearError = false,
    LeaderboardScope? selectedScope,
  }) =>
      GamificationState(
        isLoading:     isLoading ?? this.isLoading,
        data:          data ?? this.data,
        error:         clearError ? null : (error ?? this.error),
        selectedScope: selectedScope ?? this.selectedScope,
      );

  // ── Convenience getters ─────────────────────────────────────
  List<LeaderboardEntry> get currentLeaderboard {
    if (data == null) return [];
    switch (selectedScope) {
      case LeaderboardScope.city: return data!.cityLeaderboard;
      case LeaderboardScope.all:  return data!.allLeaderboard;
    }
  }
}

class GamificationViewModel extends StateNotifier<GamificationState> {
  final GamificationService _service = GamificationService();
  final Ref _ref;

  GamificationViewModel(this._ref) : super(const GamificationState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final donationCount =
          _ref.read(authViewModelProvider).user?.donationCount ?? 0;
      final username =
          _ref.read(authViewModelProvider).user?.username ?? '';
      final city =
          _ref.read(authViewModelProvider).user?.city ?? '';

      var data = await _service.getMyGamification(donationCount);

      // Fetch all three leaderboard scopes in parallel
      final results = await Future.wait([
        _service.getLeaderboard(scope: LeaderboardScope.city),
        _service.getLeaderboard(scope: LeaderboardScope.all),
      ]);

      final cityLb = _injectCurrentUser(results[0], username, donationCount, data, city);
      final allLb  = _injectCurrentUser(results[1], username, donationCount, data, city);

      // Compute city rank from leaderboard
      final cityRank = cityLb.indexWhere((e) => e.isCurrentUser);

      data = data.copyWith(
        cityLeaderboard: cityLb,
        allLeaderboard:  allLb,
        cityRank:            cityRank >= 0 ? cityRank + 1 : data.cityRank,
        cityName:            city,
      );

      state = state.copyWith(isLoading: false, data: data);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error:     AppConfig.gamificationFailedLoadVM,
      );
    }
  }

  void setScope(LeaderboardScope scope) {
    state = state.copyWith(selectedScope: scope);
  }

  // ── Refresh after a donation is completed ──────────────────
  Future<void> refreshAfterDonation() => load();

  // ─────────────────────────────────────────────────────────
  //  Helpers
  // ─────────────────────────────────────────────────────────

  List<LeaderboardEntry> _injectCurrentUser(
    List<LeaderboardEntry> list,
    String username,
    int donationCount,
    GamificationData data,
    String city,
  ) {
    if (username.isEmpty) return list;

    // Remove any existing entry for this user
    final filtered = list.where((e) => e.username != username).toList();

    final userEntry = LeaderboardEntry(
      username:      username,
      displayName:   _ref.read(authViewModelProvider).user?.displayName ?? username,
      bloodType:     _ref.read(authViewModelProvider).user?.bloodType ?? '',
      tier:          data.tier.name,
      donationCount: donationCount,
      xp:            data.xp,
      rank:          0,
      isCurrentUser: true,
    );

    // Insert in correct position by XP
    final inserted = [...filtered, userEntry];
    inserted.sort((a, b) => b.xp.compareTo(a.xp));

    // Re-assign ranks
    return inserted.asMap().entries.map((e) {
      final entry = e.value;
      return LeaderboardEntry(
        username:      entry.username,
        displayName:   entry.displayName,
        bloodType:     entry.bloodType,
        tier:          entry.tier,
        donationCount: entry.donationCount,
        xp:            entry.xp,
        rank:          e.key + 1,
        isCurrentUser: entry.isCurrentUser,
      );
    }).toList();
  }
}

final gamificationViewModelProvider =
    StateNotifierProvider<GamificationViewModel, GamificationState>((ref) {
  return GamificationViewModel(ref);
});
