import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/requirements_viewmodel.dart';
import '../../viewmodels/my_requests_viewmodel.dart';
import '../../models/user_model.dart';
import '../../models/blood_requirement.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/password_prompt_dialog.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bloodType = ref.read(authViewModelProvider).user?.bloodType ?? '';
      ref.read(requirementsViewModelProvider.notifier).setUserBloodType(bloodType);
      ref.read(requirementsViewModelProvider.notifier).load();
      ref.read(myRequestsViewModelProvider.notifier).load();
      if (mounted) await PasswordPromptDialog.showIfNeeded(context);
    });
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final authState   = ref.watch(authViewModelProvider);
    final myReqState  = ref.watch(myRequestsViewModelProvider);
    // Use the dedicated home provider so the feed's locationFilter never
    // contaminates the "Urgent near you" list.
    final urgentAsync = ref.watch(homeUrgentRequirementsProvider);
    final user        = authState.user;

    final donationCount  = user?.donationCount ?? 0;
    final activeRequests = myReqState.activeRequests;
    final pendingCount   = activeRequests.fold<int>(0, (s, r) => s + r.pendingCount);
    final images         = AppConfig.carouselImages;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.surface,
          onRefresh: () async {
            ref.invalidate(homeUrgentRequirementsProvider);
            ref.read(myRequestsViewModelProvider.notifier).load();
            ref.read(authViewModelProvider.notifier).refreshProfile();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 110),
            children: [
              // ── Hero dark card ────────────────────────────────────────
              _HeroCard(
                greeting: _greeting(),
                user: user,
                donationCount: donationCount,
                activeRequestCount: activeRequests.length,
                pendingCount: pendingCount,
              ),

              const SizedBox(height: 10),

              // ── Image carousel ────────────────────────────────────────
              if (images.isNotEmpty) ...[
                _ImageCarousel(images: images),
                const SizedBox(height: 10),
              ],

              // ── Pending pledge alert ───────────────────────────────────
              if (pendingCount > 0) ...[
                _PendingAlert(
                  count: pendingCount,
                  onTap: () => context.go('/my-requests'),
                ),
                const SizedBox(height: 10),
              ],

              // ── Urgent near you ───────────────────────────────────────
              _SectionHeader(
                title: 'Urgent near you',
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
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Hero dark card  (Concept A)
// ─────────────────────────────────────────────────────────────
class _HeroCard extends StatelessWidget {
  final String greeting;
  final UserModel? user;
  final int donationCount;
  final int activeRequestCount;
  final int pendingCount;

  const _HeroCard({
    required this.greeting,
    required this.user,
    required this.donationCount,
    required this.activeRequestCount,
    required this.pendingCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Top row: greeting + blood type badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting.toUpperCase(),
                      style: GoogleFonts.syne(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.45),
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user?.displayName ?? 'Welcome',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (user?.bloodType.isNotEmpty == true)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.32),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    user!.bloodType,
                    style: GoogleFonts.syne(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.urgentAccent,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),
          Container(height: 1, color: Colors.white.withOpacity(0.08)),
          const SizedBox(height: 12),

          // Stat trio
          Row(
            children: [
              _StatItem(
                label: 'DONATED',
                value: '$donationCount',
                alignment: CrossAxisAlignment.start,
              ),
              _VerticalDivider(),
              _StatItem(
                label: 'REQUESTS',
                value: '$activeRequestCount',
                alignment: CrossAxisAlignment.center,
              ),
              _VerticalDivider(),
              _StatItem(
                label: 'PENDING',
                value: '$pendingCount',
                valueColor: pendingCount > 0
                    ? AppColors.primary
                    : Colors.white,
                alignment: CrossAxisAlignment.end,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final CrossAxisAlignment alignment;

  const _StatItem({
    required this.label,
    required this.value,
    this.valueColor,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Text(
            label,
            style: GoogleFonts.syne(
              fontSize: 7,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.45),
              letterSpacing: 0.05,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.syne(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: valueColor ?? Colors.white,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 36,
    margin: const EdgeInsets.symmetric(horizontal: 12),
    color: Colors.white.withOpacity(0.08),
  );
}

// ─────────────────────────────────────────────────────────────
//  Image carousel
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

  // Auto-scroll interval — change here to adjust speed
  static const _autoScrollInterval = Duration(seconds: 4);

  @override
  void initState() {
    super.initState();
    // Start at a large offset so infinite-style scrolling works in both directions
    _currentPage = widget.images.length * 500;
    _ctrl = PageController(
      viewportFraction: 0.88,
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
        // Slide area — AspectRatio matches the banner dimensions exactly
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

        // Dot indicators — only when more than one image
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
//  Pending pledge alert banner
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
                '$count pending pledge${count == 1 ? '' : 's'} on your requests — tap to review',
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
//  Section header
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
            'See all →',
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
//  Lightweight urgent requirement card (no donate button / progress bar)
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
            // Blood type circle
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
            // Hospital + meta
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
            // Urgency badge
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
            'No urgent requests near you',
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