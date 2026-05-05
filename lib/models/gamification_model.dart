import '../utils/app_config.dart';
// ─────────────────────────────────────────────────────────────
//  GamificationModel — donor XP, tiers, badges, challenges
// ─────────────────────────────────────────────────────────────

class DonorTier {
  final String name;
  final int minDonations;
  final int maxDonations; // -1 = unlimited
  final int xpPerDonation;

  const DonorTier({
    required this.name,
    required this.minDonations,
    required this.maxDonations,
    required this.xpPerDonation,
  });

  static const List<DonorTier> tiers = [
    DonorTier(name: AppConfig.tierBronze,   minDonations: 0,  maxDonations: 3,  xpPerDonation: 100),
    DonorTier(name: AppConfig.tierSilver,   minDonations: 4,  maxDonations: 6,  xpPerDonation: 100),
    DonorTier(name: AppConfig.tierGold,     minDonations: 7,  maxDonations: 14, xpPerDonation: 100),
    DonorTier(name: AppConfig.tierPlatinum, minDonations: 15, maxDonations: 24, xpPerDonation: 100),
    DonorTier(name: AppConfig.tierLegend,   minDonations: 25, maxDonations: -1, xpPerDonation: 100),
  ];

  static DonorTier forDonationCount(int count) {
    for (final tier in tiers.reversed) {
      if (count >= tier.minDonations) return tier;
    }
    return tiers.first;
  }

  static DonorTier? nextTier(String currentName) {
    final idx = tiers.indexWhere((t) => t.name == currentName);
    if (idx == -1 || idx >= tiers.length - 1) return null;
    return tiers[idx + 1];
  }
}

// ── XP thresholds (cumulative) ────────────────────────────────
// Each completed donation = +100 XP base
// Critical pledge = +50 XP bonus
// On-time fulfillment = +30 XP bonus
// Monthly streak = +20 XP bonus
// Challenges award their own XP on top.
class XpConfig {
  static const int perDonation     = 100;
  static const int criticalBonus   = 50;
  static const int onTimeBonus     = 30;

  // XP needed to reach the next tier (based on donation count thresholds * xpPerDonation)
  static int xpForTier(DonorTier tier) => tier.minDonations * perDonation;

  static int xpForNextTier(int donationCount) {
    final current = DonorTier.forDonationCount(donationCount);
    final next    = DonorTier.nextTier(current.name);
    if (next == null) return -1; // already Legend
    return next.minDonations * perDonation;
  }

  static int estimatedXp(int donationCount) => donationCount * perDonation;
}

// ── Badge model ───────────────────────────────────────────────
class BadgeModel {
  final String id;
  final String name;
  final String description;
  final String earnedDescription; // shown when locked: what to do to earn it
  final DateTime? earnedAt;       // null = locked
  final BadgeIcon icon;

  const BadgeModel({
    required this.id,
    required this.name,
    required this.description,
    required this.earnedDescription,
    this.earnedAt,
    required this.icon,
  });

  bool get isEarned => earnedAt != null;

  static List<BadgeModel> defaults() => [
    const BadgeModel(
      id: 'first_drop',
      name: AppConfig.badgeFirstDropName,
      description: AppConfig.badgeFirstDropDesc,
      earnedDescription: AppConfig.badgeFirstDropEarn,
      icon: BadgeIcon.star,
    ),
    const BadgeModel(
      id: 'life_saver',
      name: AppConfig.badgeLifeSaverName,
      description: AppConfig.badgeLifeSaverDesc,
      earnedDescription: AppConfig.badgeLifeSaverEarn,
      icon: BadgeIcon.heart,
    ),
    const BadgeModel(
      id: 'on_time',
      name: AppConfig.badgeOnTimeName,
      description: AppConfig.badgeOnTimeDesc,
      earnedDescription: AppConfig.badgeOnTimeEarn,
      icon: BadgeIcon.clock,
    ),
    const BadgeModel(
      id: 'rapid_responder',
      name: AppConfig.badgeRapidName,
      description: AppConfig.badgeRapidDesc,
      earnedDescription: AppConfig.badgeRapidEarn,
      icon: BadgeIcon.shield,
    ),
    const BadgeModel(
      id: 'platinum',
      name: AppConfig.tierPlatinum,
      description: AppConfig.badgePlatinumDesc,
      earnedDescription: AppConfig.badgePlatinumEarn,
      icon: BadgeIcon.lock,
    ),
    const BadgeModel(
      id: 'legend',
      name: AppConfig.tierLegend,
      description: AppConfig.badgeLegendDesc,
      earnedDescription: AppConfig.badgeLegendEarn,
      icon: BadgeIcon.trophy,
    ),
  ];

  BadgeModel copyWith({DateTime? earnedAt}) => BadgeModel(
    id:                 id,
    name:               name,
    description:        description,
    earnedDescription:  earnedDescription,
    earnedAt:           earnedAt ?? this.earnedAt,
    icon:               icon,
  );
}

enum BadgeIcon { star, heart, bolt, clock, shield, people, lock, trophy }

// ── Challenge model ───────────────────────────────────────────
class ChallengeModel {
  final String id;
  final String title;
  final String description;
  final int xpReward;
  final int progressCurrent;
  final int progressTotal;
  final DateTime? deadline;
  final bool isCompleted;
  final DateTime? completedAt;
  final ChallengeIcon icon;

  const ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.progressCurrent,
    required this.progressTotal,
    this.deadline,
    this.isCompleted = false,
    this.completedAt,
    required this.icon,
  });

  double get progressFraction =>
      progressTotal > 0 ? (progressCurrent / progressTotal).clamp(0.0, 1.0) : 0;

  int get progressPercent => (progressFraction * 100).round();

  ChallengeModel copyWith({
    int? progressCurrent,
    bool? isCompleted,
    DateTime? completedAt,
  }) =>
      ChallengeModel(
        id:              id,
        title:           title,
        description:     description,
        xpReward:        xpReward,
        progressCurrent: progressCurrent ?? this.progressCurrent,
        progressTotal:   progressTotal,
        deadline:        deadline,
        isCompleted:     isCompleted ?? this.isCompleted,
        completedAt:     completedAt ?? this.completedAt,
        icon:            icon,
      );
}

enum ChallengeIcon { star, heart, shield, people, bolt }

// ── Leaderboard entry ─────────────────────────────────────────
class LeaderboardEntry {
  final String username;
  final String displayName;
  final String bloodType;
  final String tier;
  final int donationCount;
  final int xp;
  final int rank;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.username,
    required this.displayName,
    required this.bloodType,
    required this.tier,
    required this.donationCount,
    required this.xp,
    required this.rank,
    this.isCurrentUser = false,
  });

  String get initials {
    final parts = displayName.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return username.isNotEmpty ? username[0].toUpperCase() : '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json, {bool isCurrentUser = false}) {
    return LeaderboardEntry(
      username:      json['username']?.toString() ?? '',
      displayName:   json['displayName']?.toString() ?? json['username']?.toString() ?? '',
      bloodType:     json['bloodType']?.toString() ?? '',
      tier:          json['tier']?.toString() ?? 'Bronze',
      donationCount: (json['donationCount'] as num?)?.toInt() ?? 0,
      xp:            (json['xp'] as num?)?.toInt() ?? 0,
      rank:          (json['rank'] as num?)?.toInt() ?? 0,
      isCurrentUser: isCurrentUser,
    );
  }
}

enum LeaderboardScope { city, all }

// ── Gamification state (top-level aggregate) ──────────────────
class GamificationData {
  final int xp;
  final int donationCount;
  final DonorTier tier;
  final int cityRank;
  final String cityName;
  final List<BadgeModel> badges;
  final List<ChallengeModel> challenges;
  final List<LeaderboardEntry> cityLeaderboard;
  final List<LeaderboardEntry> allLeaderboard;

  const GamificationData({
    this.xp              = 0,
    this.donationCount   = 0,
    required this.tier,
    this.cityRank        = 0,
    this.cityName        = '',
    this.badges          = const [],
    this.challenges      = const [],
    this.cityLeaderboard = const [],
    this.allLeaderboard  = const [],
  });

  DonorTier? get nextTier => DonorTier.nextTier(tier.name);

  int get xpForNextTier => XpConfig.xpForNextTier(donationCount);

  List<BadgeModel> get earnedBadges => badges.where((b) => b.isEarned).toList();
  List<ChallengeModel> get activeChallenges =>
      challenges.where((c) => !c.isCompleted).toList();
  List<ChallengeModel> get completedChallenges =>
      challenges.where((c) => c.isCompleted).toList();


  GamificationData copyWith({
    int? xp,
    int? donationCount,
    DonorTier? tier,
    int? cityRank,
    String? cityName,
    List<BadgeModel>? badges,
    List<ChallengeModel>? challenges,
    List<LeaderboardEntry>? cityLeaderboard,
    List<LeaderboardEntry>? allLeaderboard,
  }) =>
      GamificationData(
        xp:                  xp ?? this.xp,
        donationCount:       donationCount ?? this.donationCount,
        tier:                tier ?? this.tier,
        cityRank:            cityRank ?? this.cityRank,
        cityName:            cityName ?? this.cityName,
        badges:              badges ?? this.badges,
        challenges:          challenges ?? this.challenges,
        cityLeaderboard: cityLeaderboard ?? this.cityLeaderboard,
        allLeaderboard:  allLeaderboard  ?? this.allLeaderboard,
      );
}