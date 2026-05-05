import 'package:flutter/material.dart';
import '../../utils/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/gamification_model.dart';
import '../../viewmodels/gamification_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';

class RewardsScreen extends ConsumerStatefulWidget {
  const RewardsScreen({super.key});

  @override
  ConsumerState<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends ConsumerState<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gamificationViewModelProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(gamificationViewModelProvider);
    final user  = ref.watch(authViewModelProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Tab bar — sits directly below the shell AppBar ────
          Container(
            color: AppColors.navBg,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 2,
              labelStyle: GoogleFonts.syne(
                  fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: GoogleFonts.syne(fontSize: 13),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withOpacity(0.5),
              tabs: const [
                Tab(text: AppConfig.gamificationLeaderboard),
                Tab(text: AppConfig.gamificationChallenges),
                Tab(text: AppConfig.gamificationBadges),
              ],
            ),
          ),
          // ── Tab content ───────────────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : state.data == null
                    ? _ErrorState(
                        onRetry: () => ref
                            .read(gamificationViewModelProvider.notifier)
                            .load())
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _LeaderboardTab(data: state.data!, state: state),
                          _ChallengesTab(data: state.data!),
                          _BadgesTab(data: state.data!),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Leaderboard Tab
// ─────────────────────────────────────────────────────────────
class _LeaderboardTab extends ConsumerWidget {
  final GamificationData data;
  final GamificationState state;
  const _LeaderboardTab({required this.data, required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vm      = ref.read(gamificationViewModelProvider.notifier);
    final entries = state.currentLeaderboard;
    final me      = entries.firstWhere((e) => e.isCurrentUser,
        orElse: () => LeaderboardEntry(
          username: '', displayName: 'You', bloodType: '',
          tier: data.tier.name, donationCount: data.donationCount,
          xp: data.xp, rank: data.cityRank,
        ));

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(gamificationViewModelProvider.notifier).load(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
        children: [
          // ── Your rank hero ────────────────────────────────
          _YourRankHero(entry: me, data: data),
          const SizedBox(height: 14),

          // ── Scope selector ────────────────────────────────
          Row(
            children: [
              _ScopePill(
                label: AppConfig.gamificationMyCity,
                active: state.selectedScope == LeaderboardScope.city,
                onTap: () => vm.setScope(LeaderboardScope.city),
              ),
              const SizedBox(width: 8),
              _ScopePill(
                label: AppConfig.gamificationAll,
                active: state.selectedScope == LeaderboardScope.all,
                onTap: () => vm.setScope(LeaderboardScope.all),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Column headers ────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(children: [
              SizedBox(
                width: 28,
                child: Text(AppConfig.gamificationXp.substring(0,1),
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: AppColors.textMuted)),
              ),
              const SizedBox(width: 8),
              const SizedBox(width: 32),
              Expanded(
                child: Text(AppConfig.gamificationDonor,
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: AppColors.textMuted)),
              ),
              SizedBox(
                width: 52,
                child: Text(AppConfig.gamificationDonations,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: AppColors.textMuted)),
              ),
              SizedBox(
                width: 44,
                child: Text(AppConfig.gamificationXp,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: AppColors.textMuted)),
              ),
            ]),
          ),
          const SizedBox(height: 6),

          // ── Rows ──────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: entries.asMap().entries.map((e) {
                final idx   = e.key;
                final entry = e.value;
                return _LeaderboardRow(
                  entry: entry,
                  showDivider: idx < entries.length - 1,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────
//  Scope pill button
// ─────────────────────────────────────────────────────────────
class _ScopePill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ScopePill({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
              color: active ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: GoogleFonts.syne(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _YourRankHero extends StatelessWidget {
  final LeaderboardEntry entry;
  final GamificationData data;
  const _YourRankHero({required this.entry, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.urgentBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '#${entry.rank > 0 ? entry.rank : data.cityRank}',
              style: GoogleFonts.syne(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _Avatar(initials: entry.initials, isCurrentUser: true),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(
                  child: Text(
                    entry.displayName,
                    style: GoogleFonts.syne(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                _YouTag(),
              ]),
              Text(
                '${data.tier.name} · ${entry.bloodType}',
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Text(
          '${data.xp} XP',
          style: GoogleFonts.syne(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
      ]),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool showDivider;
  const _LeaderboardRow({required this.entry, required this.showDivider});

  Color _rankColor() {
    switch (entry.rank) {
      case 1: return const Color(0xFFF9A825);
      case 2: return const Color(0xFF757575);
      case 3: return const Color(0xFFBF6B3D);
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: entry.isCurrentUser
              ? BoxDecoration(
                  color: AppColors.urgentBg,
                  borderRadius: BorderRadius.circular(
                      showDivider ? 0 : 16),
                )
              : null,
          child: Row(children: [
            SizedBox(
              width: 28,
              child: Text(
                '${entry.rank}',
                textAlign: TextAlign.center,
                style: GoogleFonts.syne(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _rankColor(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            _Avatar(initials: entry.initials, isCurrentUser: entry.isCurrentUser),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(
                        entry.displayName,
                        style: GoogleFonts.syne(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: entry.isCurrentUser
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (entry.isCurrentUser) ...[ const SizedBox(width: 4), _YouTag() ],
                  ]),
                  Text(
                    '${entry.bloodType} · ${entry.tier}',
                    style: GoogleFonts.dmSans(
                        fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 52,
              child: Text(
                '${entry.donationCount}',
                textAlign: TextAlign.center,
                style: GoogleFonts.syne(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
            ),
            SizedBox(
              width: 44,
              child: Text(
                '${entry.xp}',
                textAlign: TextAlign.right,
                style: GoogleFonts.syne(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
              ),
            ),
          ]),
        ),
        if (showDivider)
          const Divider(height: 1, thickness: 1, color: AppColors.borderSoft,
              indent: 12),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Challenges Tab
// ─────────────────────────────────────────────────────────────
class _ChallengesTab extends StatefulWidget {
  final GamificationData data;
  const _ChallengesTab({required this.data});

  @override
  State<_ChallengesTab> createState() => _ChallengesTabState();
}

class _ChallengesTabState extends State<_ChallengesTab> {
  String _filter = 'All'; // All | Active | Completed

  List<ChallengeModel> get _filtered {
    switch (_filter) {
      case 'Active':    return widget.data.activeChallenges;
      case 'Completed': return widget.data.completedChallenges;
      default:          return widget.data.challenges;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
      children: [

        // ── Filter pills ──────────────────────────────────
        Row(
          children: [AppConfig.gamificationAll, AppConfig.gamificationActive, AppConfig.gamificationCompleted].map((f) {
            final active = _filter == f;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _filter = f),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: active
                        ? AppColors.textPrimary
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                        color: active
                            ? AppColors.textPrimary
                            : AppColors.border),
                  ),
                  child: Text(
                    f,
                    style: GoogleFonts.syne(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),

        // ── Challenge cards ───────────────────────────────
        ..._filtered.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ChallengeCard(challenge: c),
            )),
      ],
    );
  }
}


class _ChallengeCard extends StatelessWidget {
  final ChallengeModel challenge;
  const _ChallengeCard({required this.challenge});

  IconData get _icon {
    switch (challenge.icon) {
      case ChallengeIcon.heart:   return Icons.favorite_rounded;
      case ChallengeIcon.shield:  return Icons.shield_rounded;
      case ChallengeIcon.people:  return Icons.people_rounded;
      case ChallengeIcon.bolt:    return Icons.bolt_rounded;
      default:                    return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = challenge.isCompleted;
    final bgColor     = done ? AppColors.secondaryLight : AppColors.surface;
    final borderColor = done ? AppColors.secondary.withOpacity(0.4) : AppColors.border;
    final iconBg      = done ? AppColors.secondary.withOpacity(0.15) : AppColors.urgentBg;
    final iconColor   = done ? AppColors.secondary : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(_icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                challenge.title,
                style: GoogleFonts.syne(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: done ? AppColors.secondary : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: done
                    ? AppColors.secondary.withOpacity(0.15)
                    : AppColors.plannedBg,
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '+${challenge.xpReward} XP',
                style: GoogleFonts.syne(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: done ? AppColors.secondary : AppColors.plannedText,
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          Text(
            challenge.description,
            style: GoogleFonts.dmSans(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: challenge.progressFraction,
              minHeight: 6,
              backgroundColor: AppColors.border,
              color: done ? AppColors.secondary : AppColors.primary,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                done
                    ? 'Completed${challenge.completedAt != null ? ' · ${DateFormat("d MMM").format(challenge.completedAt!)}' : ''}'
                    : '${challenge.progressCurrent} of ${challenge.progressTotal} done',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: done ? AppColors.secondary : AppColors.textSecondary,
                ),
              ),
              Text(
                done
                    ? '+${challenge.xpReward} XP earned'
                    : challenge.deadline != null
                        ? 'Ends ${DateFormat("d MMM").format(challenge.deadline!)}'
                        : AppConfig.gamificationOngoing,
                style: GoogleFonts.dmSans(
                    fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Badges Tab
// ─────────────────────────────────────────────────────────────
class _BadgesTab extends StatelessWidget {
  final GamificationData data;
  const _BadgesTab({required this.data});

  IconData _badgeIcon(BadgeIcon icon) {
    switch (icon) {
      case BadgeIcon.heart:  return Icons.favorite_rounded;
      case BadgeIcon.bolt:   return Icons.bolt_rounded;
      case BadgeIcon.clock:  return Icons.access_time_rounded;
      case BadgeIcon.shield: return Icons.shield_rounded;
      case BadgeIcon.people: return Icons.people_rounded;
      case BadgeIcon.lock:   return Icons.lock_outline_rounded;
      case BadgeIcon.trophy: return Icons.emoji_events_rounded;
      default:               return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final earned = data.earnedBadges.length;
    final total  = data.badges.length;
    final locked = data.badges.where((b) => !b.isEarned).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 100),
      children: [
        // ── Summary ───────────────────────────────────────────
        Text(
          '$earned of $total badges earned',
          style: GoogleFonts.dmSans(
              fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 16),

        // ── Earned section ────────────────────────────────────
        if (data.earnedBadges.isNotEmpty) ...[
          _BadgeSectionHeader(
            label: AppConfig.gamificationEarned,
            count: earned,
            color: AppColors.secondary,
          ),
          const SizedBox(height: 8),
          _BadgeList(badges: data.earnedBadges, badgeIcon: _badgeIcon),
          const SizedBox(height: 20),
        ],

        // ── Locked section ────────────────────────────────────
        if (locked.isNotEmpty) ...[
          _BadgeSectionHeader(
            label: AppConfig.gamificationLocked,
            count: locked.length,
            color: AppColors.textMuted,
          ),
          const SizedBox(height: 8),
          _BadgeList(badges: locked, badgeIcon: _badgeIcon),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Badge section header
// ─────────────────────────────────────────────────────────────
class _BadgeSectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _BadgeSectionHeader(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(
        label,
        style: GoogleFonts.syne(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.05,
        ),
      ),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          '$count',
          style: GoogleFonts.syne(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────
//  Badge list card
// ─────────────────────────────────────────────────────────────
class _BadgeList extends StatelessWidget {
  final List<BadgeModel> badges;
  final IconData Function(BadgeIcon) badgeIcon;
  const _BadgeList({required this.badges, required this.badgeIcon});

  @override
  Widget build(BuildContext context) {
    final locked = badges.isNotEmpty && !badges.first.isEarned;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: badges.asMap().entries.map((e) {
          final idx   = e.key;
          final badge = e.value;
          return Column(
            children: [
              Opacity(
                opacity: locked ? 0.45 : 1.0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: locked
                            ? AppColors.background
                            : AppColors.urgentBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        badgeIcon(badge.icon),
                        size: 20,
                        color: locked
                            ? AppColors.textMuted
                            : AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            badge.name,
                            style: GoogleFonts.syne(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            locked
                                ? badge.earnedDescription
                                : badge.description,
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.textSecondary),
                          ),
                          if (badge.isEarned && badge.earnedAt != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Earned ${DateFormat("d MMM yyyy").format(badge.earnedAt!)}',
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                color: AppColors.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: locked
                            ? AppColors.background
                            : AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        locked
                            ? AppConfig.gamificationLocked
                            : AppConfig.gamificationEarned,
                        style: GoogleFonts.syne(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: locked
                              ? AppColors.textMuted
                              : AppColors.secondary,
                        ),
                      ),
                    ),
                  ]),
                ),
              ),
              if (idx < badges.length - 1)
                const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.borderSoft,
                    indent: 14),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Shared small widgets
// ─────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String initials;
  final bool isCurrentUser;
  const _Avatar({required this.initials, required this.isCurrentUser});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.urgentBg : AppColors.background3,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.syne(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isCurrentUser
                ? AppColors.primary
                : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _YouTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        AppConfig.gamificationYouTag,
        style: GoogleFonts.syne(
            fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.wifi_off_rounded, size: 32, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(AppConfig.gamificationFailedLoad,
              style: GoogleFonts.syne(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(AppConfig.gamificationTryAgain,
                  style: GoogleFonts.syne(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

