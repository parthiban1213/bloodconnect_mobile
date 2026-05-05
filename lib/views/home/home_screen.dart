import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/requirements_viewmodel.dart';
import '../../viewmodels/my_requests_viewmodel.dart';
import '../../viewmodels/gamification_viewmodel.dart';
import '../../models/user_model.dart';
import '../../models/blood_requirement.dart';
import '../../models/gamification_model.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/password_prompt_dialog.dart';
import '../../widgets/app_update_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
{


  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bloodType = ref.read(authViewModelProvider).user?.bloodType ?? '';
      ref.read(requirementsViewModelProvider.notifier).setUserBloodType(bloodType);
      ref.read(requirementsViewModelProvider.notifier).load();
      ref.read(myRequestsViewModelProvider.notifier).load();
      ref.read(gamificationViewModelProvider.notifier).load();
      if (mounted) await PasswordPromptDialog.showIfNeeded(context);
      if (mounted) await AppUpdateDialog.showIfNeeded(context);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return AppConfig.homeGreetingMorning;
    if (h < 17) return AppConfig.homeGreetingAfternoon;
    return AppConfig.homeGreetingEvening;
  }

  @override
  Widget build(BuildContext context) {
    final authState   = ref.watch(authViewModelProvider);
    final myReqState  = ref.watch(myRequestsViewModelProvider);
    final urgentAsync = ref.watch(homeUrgentRequirementsProvider);
    final gamState    = ref.watch(gamificationViewModelProvider);
    final user        = authState.user;

    final donationCount  = user?.donationCount ?? 0;
    final activeRequests = myReqState.activeRequests;
    final pendingCount   = activeRequests.fold<int>(0, (s, r) => s + r.pendingCount);
    final images         = AppConfig.carouselImages;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(
              child: _HomeHeader(
                greeting: _greeting(),
                user: user,
                donationCount: donationCount,
                activeRequestCount: activeRequests.length,
                pendingCount: pendingCount,
              ),
            ),
          ],
          body: RefreshIndicator(
            color: AppColors.primary,
            backgroundColor: AppColors.surface,
            onRefresh: () async {
              ref.invalidate(homeUrgentRequirementsProvider);
              ref.read(myRequestsViewModelProvider.notifier).load();
              ref.read(authViewModelProvider.notifier).refreshProfile();
              ref.read(gamificationViewModelProvider.notifier).load();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
              children: [
                // ── Pending pledge alert ───────────────────────────
                if (pendingCount > 0) ...[
                  const SizedBox(height: 12),
                  _PendingAlert(
                    count: pendingCount,
                    onTap: () => context.go('/my-requests'),
                  ),
                ],

                // ── Image carousel ────────────────────────────────
                if (images.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _ImageCarousel(images: images),
                ],

                // ── Rewards inline card ───────────────────────────
                if (gamState.data != null) ...[
                  const SizedBox(height: 12),
                  _HomeRewardsCard(
                    data: gamState.data!,
                    onTap: () => context.go('/rewards'),
                  ),
                ],

                // ── Urgent near you ───────────────────────────────
                const SizedBox(height: 14),
                _SectionHeader(
                  title: AppConfig.homeUrgentSectionTitle,
                  onSeeAll: () => context.go('/feed'),
                ),
                const SizedBox(height: 8),
                urgentAsync.when(
                  loading: () => const CardShimmer(),
                  error:   (_, __) => const _EmptyUrgent(),
                  data: (urgentItems) => urgentItems.isEmpty
                      ? const _EmptyUrgent()
                      : Column(
                    children: urgentItems.map(
                          (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _UrgentCard(requirement: r),
                      ),
                    ).toList(),
                  ),
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Header — Option D (light background, white stat cards)
// ─────────────────────────────────────────────────────────────
class _HomeHeader extends StatelessWidget {
  final String greeting;
  final UserModel? user;
  final int donationCount;
  final int activeRequestCount;
  final int pendingCount;
  const _HomeHeader({
    required this.greeting,
    required this.user,
    required this.donationCount,
    required this.activeRequestCount,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: greeting / name / actions ──────────────
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.firstName?.toUpperCase() ?? user?.displayName.toUpperCase() ?? AppConfig.homeRewardsWelcome,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Blood type badge
                  if (user?.bloodType.isNotEmpty == true)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 11, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        user!.bloodType,
                        style: GoogleFonts.syne(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 14),

              // ── Stat cards row ───────────────────────────────────
              Row(
                children: [
                  _StatCard(
                    label: AppConfig.homeStatDonated,
                    value: '$donationCount',
                    valueColor: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: AppConfig.homeStatRequests,
                    value: '$activeRequestCount',
                    valueColor: AppColors.primaryLight,
                  ),
                  const SizedBox(width: 10),
                  _StatCard(
                    label: AppConfig.homeStatPending,
                    value: '$pendingCount',
                    valueColor: pendingCount > 0
                        ? AppColors.primary
                        : AppColors.primaryLight,
                  ),
                ],
              ),

              const SizedBox(height: 4),
            ],
          ),
        ),

      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.textPrimary,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.syne(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: valueColor,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.syne(
                fontSize: 8,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.08,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Image carousel (unchanged)
// ─────────────────────────────────────────────────────────────
class _ImageCarousel extends StatefulWidget {
  final List<String> images;
  const _ImageCarousel({required this.images});

  @override
  State<_ImageCarousel> createState() => _ImageCarouselState();
}

class _ImageCarouselState extends State<_ImageCarousel> {
  late final PageController _ctrl;
  late int _currentPage;
  Timer? _timer;

  static const _autoScrollInterval = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    _currentPage = widget.images.length * 500;
    _ctrl = PageController(
      viewportFraction: 1.0,
      initialPage: _currentPage,
    );
    _startAutoScroll();
  }

  void _startAutoScroll() {
    if (widget.images.length <= 1) return;
    _timer = Timer.periodic(_autoScrollInterval, (_) {
      if (!_ctrl.hasClients) return;
      _ctrl.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  int get _dotIndex => _currentPage % widget.images.length;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 1200 / 600,
          child: PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemCount: widget.images.length * 1000,
            itemBuilder: (context, index) {
              final assetPath = widget.images[index % widget.images.length];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    assetPath,
                    fit: BoxFit.fill,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: BoxDecoration(
                        color: AppColors.navBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 36,
                          color: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.images.length, (i) {
              final active = i == _dotIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width:  active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Pending pledge alert banner (unchanged)
// ─────────────────────────────────────────────────────────────
class _PendingAlert extends StatelessWidget {
  final int count;
  final VoidCallback onTap;

  const _PendingAlert({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.urgentBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.urgentBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '$count ${count == 1 ? AppConfig.homePendingAlertSingle : AppConfig.homePendingAlertPlural}',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.urgentText,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Section header (unchanged)
// ─────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback onSeeAll;

  const _SectionHeader({required this.title, required this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.syne(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Text(
            AppConfig.homeUrgentSeeAll,
            style: GoogleFonts.syne(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Urgent requirement card (unchanged)
// ─────────────────────────────────────────────────────────────
class _UrgentCard extends StatelessWidget {
  final BloodRequirement requirement;
  const _UrgentCard({required this.requirement});

  Color get _urgencyColor {
    switch (requirement.urgency.toLowerCase()) {
      case 'critical':
      case 'urgent':
        return AppColors.primary;
      case 'moderate':
        return AppColors.moderateAccent;
      default:
        return AppColors.plannedAccent;
    }
  }

  Color get _urgencyBg {
    switch (requirement.urgency.toLowerCase()) {
      case 'critical':
      case 'urgent':
        return AppColors.urgentBg;
      case 'moderate':
        return AppColors.moderateBg;
      default:
        return AppColors.plannedBg;
    }
  }

  Color get _urgencyBorder {
    switch (requirement.urgency.toLowerCase()) {
      case 'critical':
      case 'urgent':
        return AppColors.urgentBorder;
      case 'moderate':
        return AppColors.moderateBorder;
      default:
        return AppColors.plannedBorder;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        '/requirement/${requirement.id}',
        extra: {'requirement': requirement},
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _urgencyBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _urgencyBorder),
              ),
              child: Center(
                child: Text(
                  requirement.bloodType,
                  style: GoogleFonts.syne(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: _urgencyColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    requirement.hospital,
                    style: GoogleFonts.syne(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${requirement.remainingUnits} unit${requirement.remainingUnits != 1 ? 's' : ''} needed'
                        '${requirement.location.isNotEmpty ? ' · ${requirement.location}' : ''}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _urgencyBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _urgencyBorder),
              ),
              child: Text(
                requirement.urgency,
                style: GoogleFonts.syne(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: _urgencyColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Empty urgent state (unchanged)
// ─────────────────────────────────────────────────────────────
class _EmptyUrgent extends StatelessWidget {
  const _EmptyUrgent();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.bloodtype_outlined,
              size: 28, color: AppColors.textMuted),
          const SizedBox(height: 8),
          Text(
            AppConfig.homeUrgentEmpty,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Gamification widgets for Rewards tab on Home screen
// ─────────────────────────────────────────────────────────────


// ─────────────────────────────────────────────────────────────
//  Inline rewards card — sits between carousel and urgent section
// ─────────────────────────────────────────────────────────────
class _HomeRewardsCard extends StatelessWidget {
  final GamificationData data;
  final VoidCallback onTap;
  const _HomeRewardsCard({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final nextTier   = data.nextTier;
    final xpForNext  = data.xpForNextTier;
    final progress   = xpForNext > 0
        ? (data.xp / xpForNext).clamp(0.0, 1.0)
        : 1.0;
    final cityRankStr = data.cityRank > 0 ? '#${data.cityRank}' : '—';
    final cityLabel   = data.cityName.isNotEmpty
        ? data.cityName
        : AppConfig.homeRewardsCityLb;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.navBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: tier + rank ──────────────────────────
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${data.tier.name} ${AppConfig.gamificationDonor}',
                        style: GoogleFonts.syne(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '$cityRankStr in $cityLabel',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: AppColors.navInactive,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${data.xp} ${AppConfig.gamificationXp}',
                  style: GoogleFonts.syne(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.navInactive,
                ),
              ],
            ),

            // ── XP progress bar ───────────────────────────────
            if (nextTier != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: Colors.white.withOpacity(0.1),
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${(xpForNext - data.xp).clamp(0, xpForNext)} ${AppConfig.gamificationXp} to ${nextTier.name}',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: AppColors.navInactive,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HomeXpCard extends StatelessWidget {
  final GamificationData data;
  const _HomeXpCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final nextTier  = data.nextTier;
    final xpForNext = data.xpForNextTier;
    final progress  = xpForNext > 0
        ? (data.xp / xpForNext).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                nextTier != null
                    ? '${data.tier.name} → ${nextTier.name}'
                    : data.tier.name,
                style: GoogleFonts.syne(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              Text(
                xpForNext > 0
                    ? '${data.xp} / $xpForNext XP'
                    : '${data.xp} XP',
                style: GoogleFonts.dmSans(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: AppColors.border,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            nextTier != null
                ? '${(xpForNext - data.xp).clamp(0, xpForNext)} XP to ${nextTier.name} · ${data.donationCount} donations'
                : AppConfig.homeRewardsLegendReached,
            style: GoogleFonts.dmSans(
                fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _HomeLeaderboardCard extends StatelessWidget {
  final GamificationData data;
  const _HomeLeaderboardCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final lb  = data.cityLeaderboard;
    final me  = lb.firstWhere((e) => e.isCurrentUser,
        orElse: () => LeaderboardEntry(
          username: '', displayName: 'You', bloodType: '',
          tier: data.tier.name, donationCount: data.donationCount,
          xp: data.xp, rank: data.cityRank, isCurrentUser: true,
        ));
    final top3 = lb.where((e) => !e.isCurrentUser).take(3).toList();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Your row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              color: AppColors.urgentBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.urgentBorder),
            ),
            child: Row(children: [
              Text(
                '#${me.rank > 0 ? me.rank : data.cityRank}',
                style: GoogleFonts.syne(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              _MiniAvatar(initials: me.initials, isMe: true),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppConfig.homeRewardsYou,
                        style: GoogleFonts.syne(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                    Text('${data.tier.name} · ${data.xp} XP',
                        style: GoogleFonts.dmSans(
                            fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text('${data.xp}',
                  style: GoogleFonts.syne(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
            ]),
          ),
          const SizedBox(height: 8),
          ...top3.asMap().entries.map((e) {
            final rank  = e.key + 1;
            final entry = e.value;
            final rankColor = rank == 1
                ? const Color(0xFFF9A825)
                : rank == 2
                ? const Color(0xFF757575)
                : const Color(0xFFBF6B3D);
            return Padding(
              padding: EdgeInsets.only(top: e.key == 0 ? 0 : 4),
              child: Row(children: [
                SizedBox(
                  width: 20,
                  child: Text('$rank',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.syne(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: rankColor)),
                ),
                const SizedBox(width: 8),
                _MiniAvatar(initials: entry.initials, isMe: false),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(entry.displayName,
                      style: GoogleFonts.dmSans(
                          fontSize: 12, color: AppColors.textPrimary)),
                ),
                Text('${entry.xp} XP',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textSecondary)),
              ]),
            );
          }),
        ],
      ),
    );
  }
}

class _MiniAvatar extends StatelessWidget {
  final String initials;
  final bool isMe;
  const _MiniAvatar({required this.initials, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: isMe ? AppColors.urgentBg : AppColors.background,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: Text(
          initials,
          style: GoogleFonts.syne(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: isMe ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _HomeChallengesCard extends StatelessWidget {
  final GamificationData data;
  const _HomeChallengesCard({required this.data});

  IconData _icon(ChallengeIcon icon) {
    switch (icon) {
      case ChallengeIcon.heart:  return Icons.favorite_rounded;
      case ChallengeIcon.shield: return Icons.shield_rounded;
      case ChallengeIcon.people: return Icons.people_rounded;
      case ChallengeIcon.bolt:   return Icons.bolt_rounded;
      default:                   return Icons.star_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = data.activeChallenges.take(3).toList();
    if (active.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: active.asMap().entries.map((e) {
          final idx = e.key;
          final c   = e.value;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 13, vertical: 11),
                child: Row(children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppColors.urgentBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(_icon(c.icon), size: 14, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.title,
                            style: GoogleFonts.syne(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Row(children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: c.progressFraction,
                                minHeight: 4,
                                backgroundColor: AppColors.border,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text('${c.progressPercent}%',
                              style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: AppColors.textSecondary)),
                        ]),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.plannedBg,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text('+${c.xpReward} XP',
                        style: GoogleFonts.syne(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.plannedText)),
                  ),
                ]),
              ),
              if (idx < active.length - 1)
                const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.borderSoft,
                    indent: 13),
            ],
          );
        }).toList(),
      ),
    );
  }
}