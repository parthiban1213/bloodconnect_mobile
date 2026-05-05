// ─────────────────────────────────────────────────────────────
//  GamificationService — real API-backed implementation.
//
//  Backend endpoints (added to server.js):
//    GET  /api/gamification/me            → user XP, badges, challenges
//    GET  /api/gamification/leaderboard   → ranked donor list by XP
//    POST /api/gamification/award-xp      → award bonus XP
//
//  Falls back to locally-derived data if server is unreachable.
// ─────────────────────────────────────────────────────────────

import '../utils/app_config.dart';
import '../models/gamification_model.dart';
import '../utils/api_exception.dart';
import 'api_client.dart';

class GamificationService {
  final ApiClient _client = ApiClient.instance;

  // ── Full gamification profile for the current user ─────────
  Future<GamificationData> getMyGamification(int donationCount) async {
    try {
      final res  = await _client.get('/gamification/me');
      final data = (res['data'] as Map<String, dynamic>?) ?? res;
      return _parseGamificationData(data, donationCount);
    } on ApiException {
      return _localFallback(donationCount);
    } catch (_) {
      return _localFallback(donationCount);
    }
  }

  // ── Leaderboard — live from server ─────────────────────────
  Future<List<LeaderboardEntry>> getLeaderboard({
    LeaderboardScope scope = LeaderboardScope.city,
    int limit = 20,
  }) async {
    final scopeParam = scope == LeaderboardScope.city ? 'city' : 'all';
    try {
      final res  = await _client.get(
        '/gamification/leaderboard',
        queryParams: {'scope': scopeParam, 'limit': limit.toString()},
      );
      final list = res['data'] as List<dynamic>? ?? [];
      return list
          .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      return _mockLeaderboard(scope);
    } catch (_) {
      return _mockLeaderboard(scope);
    }
  }

  // ── Award bonus XP ─────────────────────────────────────────
  Future<void> awardXp({required String reason, required int amount}) async {
    try {
      await _client.post('/gamification/award-xp',
          data: {'reason': reason, 'amount': amount});
    } catch (_) {
      // Best-effort — never block the donation flow
    }
  }

  // ─────────────────────────────────────────────────────────
  //  Parsers
  // ─────────────────────────────────────────────────────────

  GamificationData _parseGamificationData(
      Map<String, dynamic> res, int donationCount) {
    final dc   = (res['donationCount'] as num?)?.toInt() ?? donationCount;
    final xp   = (res['xp']           as num?)?.toInt() ?? XpConfig.estimatedXp(dc);
    final tier = DonorTier.forDonationCount(dc);

    // Parse earned badges from server response
    final earnedBadgeList = (res['badges'] as List<dynamic>? ?? [])
        .map((b) => _parseBadge(b as Map<String, dynamic>))
        .whereType<BadgeModel>()
        .toList();

    // Merge earned badges with ALL badge templates so locked ones always show.
    // Build a map of earned badges by id for quick lookup.
    final earnedMap = {for (final b in earnedBadgeList) b.id: b};
    final allBadges = BadgeModel.defaults().map((template) {
      // If the user earned this badge, use the server version (has earnedAt)
      return earnedMap[template.id] ?? template;
    }).toList();

    final challengeList = (res['challenges'] as List<dynamic>? ?? [])
        .map((c) => _parseChallenge(c as Map<String, dynamic>))
        .toList();

    return GamificationData(
      xp:             xp,
      donationCount:  dc,
      tier:           tier,
      cityRank:       (res['cityRank']     as num?)?.toInt() ?? 0,
      cityName:       res['cityName']?.toString() ?? '',
      badges:         allBadges,
      challenges:     challengeList.isEmpty ? _defaultChallenges(dc) : challengeList,
    );
  }

  BadgeModel? _parseBadge(Map<String, dynamic> json) {
    final id       = json['id']?.toString() ?? '';
    final defaults = BadgeModel.defaults();
    final template = defaults.where((b) => b.id == id).firstOrNull;
    if (template == null) return null;
    DateTime? earnedAt;
    if (json['earnedAt'] != null) {
      earnedAt = DateTime.tryParse(json['earnedAt'].toString());
    }
    return template.copyWith(earnedAt: earnedAt);
  }

  ChallengeModel _parseChallenge(Map<String, dynamic> json) {
    DateTime? deadline;
    if (json['deadline'] != null) {
      deadline = DateTime.tryParse(json['deadline'].toString());
    }
    DateTime? completedAt;
    if (json['completedAt'] != null) {
      completedAt = DateTime.tryParse(json['completedAt'].toString());
    }

    ChallengeIcon icon = ChallengeIcon.star;
    switch (json['id']?.toString()) {
      case 'blood_type_hero':
      case 'life_saver':       icon = ChallengeIcon.heart;  break;
      case 'rapid_pledge':     icon = ChallengeIcon.bolt;   break;
      case 'emergency_responder': icon = ChallengeIcon.shield; break;
    }

    return ChallengeModel(
      id:              json['id']?.toString() ?? '',
      title:           json['title']?.toString() ?? '',
      description:     json['description']?.toString() ?? '',
      xpReward:        (json['xpReward']        as num?)?.toInt() ?? 0,
      progressCurrent: (json['progressCurrent'] as num?)?.toInt() ?? 0,
      progressTotal:   (json['progressTotal']   as num?)?.toInt() ?? 1,
      deadline:        deadline,
      isCompleted:     json['isCompleted'] == true,
      completedAt:     completedAt,
      icon:            icon,
    );
  }

  // ─────────────────────────────────────────────────────────
  //  Local fallback
  // ─────────────────────────────────────────────────────────

  GamificationData _localFallback(int donationCount) {
    final tier = DonorTier.forDonationCount(donationCount);
    final xp   = XpConfig.estimatedXp(donationCount);
    return GamificationData(
      xp:             xp,
      donationCount:  donationCount,
      tier:           tier,
      cityRank:       0,
      cityName:       '',
      badges:         _defaultBadges(donationCount),
      challenges:     _defaultChallenges(donationCount),
      cityLeaderboard: _mockLeaderboard(LeaderboardScope.city),
      allLeaderboard:  _mockLeaderboard(LeaderboardScope.all),
    );
  }

  List<BadgeModel> _defaultBadges(int donationCount) {
    final now      = DateTime.now();
    final defaults = BadgeModel.defaults();
    return defaults.map((b) {
      DateTime? earned;
      switch (b.id) {
        case 'first_drop':
          if (donationCount >= 1)  earned = now.subtract(const Duration(days: 60));
        case 'life_saver':
          if (donationCount >= 3)  earned = now.subtract(const Duration(days: 30));
        case 'on_time':
          if (donationCount >= 2)  earned = now.subtract(const Duration(days: 5));
        case 'platinum':
          if (donationCount >= 15) earned = now;
        case 'legend':
          if (donationCount >= 25) earned = now;
      }
      return b.copyWith(earnedAt: earned);
    }).toList();
  }

  List<ChallengeModel> _defaultChallenges(int donationCount) {
    final endOfMonth = _endOfCurrentMonth();
    return [
      ChallengeModel(
        id: 'first_drop', title: AppConfig.challengeFirstPledgeTitle,
        description: AppConfig.challengeFirstPledgeDesc, xpReward: 50,
        progressCurrent: donationCount >= 1 ? 1 : 0, progressTotal: 1,
        isCompleted: donationCount >= 1,
        completedAt: donationCount >= 1
            ? DateTime.now().subtract(const Duration(days: 60)) : null,
        icon: ChallengeIcon.star,
      ),
      ChallengeModel(
        id: 'blood_type_hero', title: AppConfig.challengeBloodTypeHeroTitle,
        description: AppConfig.challengeBloodTypeHeroDesc, xpReward: 150,
        progressCurrent: donationCount >= 2 ? 2 : (donationCount >= 1 ? 1 : 0),
        progressTotal: 3, deadline: endOfMonth, isCompleted: false,
        icon: ChallengeIcon.heart,
      ),
      ChallengeModel(
        id: 'rapid_pledge', title: AppConfig.challengeRapidPledgeTitle,
        description: AppConfig.challengeRapidPledgeDesc, xpReward: 100,
        progressCurrent: donationCount >= 1 ? 1 : 0, progressTotal: 1,
        isCompleted: donationCount >= 1,
        completedAt: donationCount >= 1
            ? DateTime.now().subtract(const Duration(days: 6)) : null,
        icon: ChallengeIcon.bolt,
      ),
      ChallengeModel(
        id: 'life_saver', title: AppConfig.challengeLifeSaverTitle,
        description: AppConfig.challengeLifeSaverDesc, xpReward: 200,
        progressCurrent: donationCount.clamp(0, 3), progressTotal: 3,
        isCompleted: donationCount >= 3, icon: ChallengeIcon.heart,
      ),
      ChallengeModel(
        id: 'emergency_responder', title: AppConfig.challengeEmergencyTitle,
        description: AppConfig.challengeEmergencyDesc, xpReward: 200,
        progressCurrent: 0, progressTotal: 1, isCompleted: false,
        icon: ChallengeIcon.shield,
      ),
    ];
  }

  List<LeaderboardEntry> _mockLeaderboard(LeaderboardScope scope) => [
    LeaderboardEntry(username: 'rameshk',  displayName: 'Ramesh K',  bloodType: 'B+', tier: AppConfig.tierGold,   donationCount: 12, xp: 2140, rank: 1),
    LeaderboardEntry(username: 'priyam',   displayName: 'Priya M',   bloodType: 'O+', tier: AppConfig.tierGold,   donationCount: 10, xp: 1870, rank: 2),
    LeaderboardEntry(username: 'senthilk', displayName: 'Senthil K', bloodType: 'A-', tier: AppConfig.tierGold,   donationCount: 9,  xp: 1640, rank: 3),
    LeaderboardEntry(username: 'meenav',   displayName: 'Meena V',   bloodType: 'O-', tier: AppConfig.tierSilver, donationCount: 7,  xp: 1180, rank: 4),
    LeaderboardEntry(username: 'babur',    displayName: 'Babu R',    bloodType: 'AB+',tier: AppConfig.tierSilver, donationCount: 6,  xp: 1020, rank: 5),
    LeaderboardEntry(username: 'janakilm', displayName: 'Janaki L',  bloodType: 'B-', tier: AppConfig.tierSilver, donationCount: 5,  xp:  870,  rank: 6),
    LeaderboardEntry(username: 'tamilp',   displayName: 'Tamil P',   bloodType: 'A+', tier: AppConfig.tierSilver, donationCount: 4,  xp:  720,  rank: 7),
  ];

  DateTime _endOfCurrentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0, 23, 59, 59);
  }
}