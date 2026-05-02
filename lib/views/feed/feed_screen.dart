import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/requirements_viewmodel.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';
import '../../widgets/app_widgets.dart';
import '../../services/reminder_service.dart';
import 'requirement_card.dart';
import 'feed_map_view.dart';
import '../../widgets/password_prompt_dialog.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _searchCtrl  = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollController = ScrollController();
  bool _showMap = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bloodType = ref.read(authViewModelProvider).user?.bloodType ?? '';
      ref.read(requirementsViewModelProvider.notifier).setUserBloodType(bloodType);
      // Initial load is triggered by the viewmodel constructor + _initLocation
      // Show the one-time post-registration password prompt if flagged.
      if (mounted) await PasswordPromptDialog.showIfNeeded(context);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(requirementsViewModelProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ── Filter popup (urgency/status filters) ───────────────────────
  void _showFilterPopup(BuildContext context, RequirementsState reqState,
      RequirementsViewModel reqVm) {
    final filters = AppConfig.feedFilters;
    String selected = reqState.selectedFilter;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (ctx, setPopState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppConfig.feedFilterTitle,
                          style: GoogleFonts.syne(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          )),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: filters.map((f) {
                      final key    = f['key']!;
                      final label  = f['label']!;
                      final active = selected == key;
                      return GestureDetector(
                        onTap: () => setPopState(() => selected = key),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 130),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? AppColors.navBg : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active ? AppColors.navBg : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            label,
                            style: GoogleFonts.syne(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: active
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(children: [
                    if (selected != 'All')
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            reqVm.setFilter('All');
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Center(
                              child: Text(AppConfig.feedFilterClear,
                                  style: GoogleFonts.syne(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  )),
                            ),
                          ),
                        ),
                      ),
                    if (selected != 'All') const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: () {
                          reqVm.setFilter(selected);
                          Navigator.pop(ctx);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.navBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(AppConfig.feedFilterApply,
                                style: GoogleFonts.syne(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                )),
                          ),
                        ),
                      ),
                    ),
                  ]),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── Location filter popup ─────────────────────────────────────
  void _showLocationFilterPopup(BuildContext context, RequirementsState reqState,
      RequirementsViewModel reqVm) {
    LocationFilterRadius selected = reqState.locationFilter;
    final hasGps = reqState.hasGpsLocation;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (ctx, setPopState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppConfig.feedLocationFilter,
                          style: GoogleFonts.syne(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          )),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.close_rounded,
                              size: 16, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),

                  if (!hasGps) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.location_off_rounded,
                            size: 14, color: Color(0xFF92400E)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Location access not granted. Distance-based filters use your profile city.',
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: const Color(0xFF92400E)),
                          ),
                        ),
                      ]),
                    ),
                  ],

                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: LocationFilterRadius.values.map((f) {
                      final active = selected == f;
                      // Disable distance-based filters when no GPS
                      final isDistanceFilter =
                          f != LocationFilterRadius.sameCity &&
                              f != LocationFilterRadius.allLocations;
                      final disabled = isDistanceFilter && !hasGps;

                      return GestureDetector(
                        onTap: disabled
                            ? null
                            : () => setPopState(() => selected = f),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 130),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: active
                                ? AppColors.navBg
                                : disabled
                                ? AppColors.border.withOpacity(0.3)
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active ? AppColors.navBg : AppColors.border,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            f.label,
                            style: GoogleFonts.syne(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: active
                                  ? Colors.white
                                  : disabled
                                  ? AppColors.textMuted.withOpacity(0.5)
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: GestureDetector(
                      onTap: () {
                        reqVm.setLocationFilter(selected);
                        Navigator.pop(ctx);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.navBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(AppConfig.feedFilterApply,
                              style: GoogleFonts.syne(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              )),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    ref.listen<AuthState>(authViewModelProvider, (prev, next) {
      final newBt = next.user?.bloodType ?? '';
      final oldBt = prev?.user?.bloodType ?? '';
      if (newBt != oldBt && newBt.isNotEmpty) {
        ref.read(requirementsViewModelProvider.notifier).setUserBloodType(newBt);
        ref.read(requirementsViewModelProvider.notifier).load();
      }
    });
    final reqState  = ref.watch(requirementsViewModelProvider);
    final reqVm     = ref.read(requirementsViewModelProvider.notifier);
    final user      = authState.user;

    final bloodType = user?.bloodType ?? '';
    if (reqState.userBloodType != bloodType && bloodType.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        reqVm.setUserBloodType(bloodType);
      });
    }

    final activeFilter = reqState.selectedFilter;
    final isFiltered   = activeFilter != 'All';
    final locationFilter = reqState.locationFilter;
    final isLocationFiltered = locationFilter != LocationFilterRadius.allLocations;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/home');
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: AppColors.background,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Greeting row with inline open count ───────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting().toUpperCase(),
                              style: GoogleFonts.syne(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textMuted,
                                letterSpacing: 0.9,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  user?.firstName ?? user?.displayName ?? 'Welcome',
                                  style: GoogleFonts.cormorantGaramond(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                // Inline open request count pill
                                if (!reqState.isLoading && reqState.error == null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryLight,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: AppColors.urgentBorder, width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 5, height: 5,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${reqState.filtered.where((r) => r.isOpen).length}',
                                          style: GoogleFonts.syne(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          'open',
                                          style: GoogleFonts.syne(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primaryDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        // Blood type badge
                        if (user?.bloodType.isNotEmpty == true)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.urgentBorder, width: 1),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 6, height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  user!.bloodType,
                                  style: GoogleFonts.syne(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Center(
                              child: Text(
                                user?.initials ?? '?',
                                style: GoogleFonts.syne(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // ── Unified search + filter card ───────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          // Search input row
                          Row(children: [
                            Container(
                              width: 30, height: 30,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.search_rounded,
                                  size: 15, color: AppColors.primary),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                focusNode: _searchFocus,
                                style: GoogleFonts.dmSans(
                                    fontSize: 12, color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: AppConfig.feedSearchHint,
                                  hintStyle: GoogleFonts.dmSans(
                                      fontSize: 12, color: AppColors.textMuted),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding:
                                  const EdgeInsets.symmetric(vertical: 8),
                                ),
                                onChanged: (v) => ref
                                    .read(requirementsViewModelProvider.notifier)
                                    .setSearchQuery(v),
                              ),
                            ),
                            if (reqState.searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchCtrl.clear();
                                  _searchFocus.unfocus();
                                  ref.read(requirementsViewModelProvider.notifier)
                                      .setSearchQuery('');
                                },
                                child: const Icon(Icons.close_rounded,
                                    size: 15, color: AppColors.textMuted),
                              ),
                          ]),

                          // Divider
                          Container(
                            height: 1,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            color: AppColors.borderSoft,
                          ),

                          // Filter row
                          Row(children: [
                            // Location filter chip
                            GestureDetector(
                              onTap: () => _showLocationFilterPopup(
                                  context, reqState, reqVm),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isLocationFiltered
                                      ? AppColors.primaryLight
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isLocationFiltered
                                        ? AppColors.urgentBorder
                                        : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.near_me_rounded,
                                      size: 11,
                                      color: isLocationFiltered
                                          ? AppColors.primary
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      isLocationFiltered
                                          ? locationFilter.label
                                          : 'Nearby',
                                      style: GoogleFonts.syne(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isLocationFiltered
                                            ? AppColors.primary
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    if (isLocationFiltered) ...[
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => reqVm.setLocationFilter(
                                            LocationFilterRadius.allLocations),
                                        child: const Icon(Icons.close_rounded,
                                            size: 10, color: AppColors.primary),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(width: 6),

                            // Urgency/status filter chip
                            GestureDetector(
                              onTap: () =>
                                  _showFilterPopup(context, reqState, reqVm),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isFiltered
                                      ? AppColors.navBg
                                      : AppColors.background,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isFiltered
                                        ? AppColors.navBg
                                        : AppColors.border,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 11,
                                      color: isFiltered
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      isFiltered ? activeFilter : 'All',
                                      style: GoogleFonts.syne(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isFiltered
                                            ? Colors.white
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                    if (isFiltered) ...[
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                        onTap: () => reqVm.setFilter('All'),
                                        child: const Icon(Icons.close_rounded,
                                            size: 10, color: Colors.white),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            const Spacer(),

                            // List / Map toggle
                            _ViewTogglePill(
                              showMap: _showMap,
                              onToggle: (v) => setState(() => _showMap = v),
                            ),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Cooldown / unavailable banners ────────────────────────────
              Builder(builder: (context) {
                final lastDonation  = authState.user?.lastDonationDate;
                final isInCooldown  = !ReminderService.isEligible(lastDonation);
                final isUnavailable = authState.user?.isAvailable == false;
                final nextDate      = ReminderService.nextEligibleDate(lastDonation);
                final daysLeft      = ReminderService.daysUntilEligible(lastDonation);

                if (!isInCooldown && !isUnavailable) return const SizedBox.shrink();
                return Column(children: [
                  if (isInCooldown && nextDate != null)
                    _FeedBanner(
                      icon: Icons.hourglass_top_rounded,
                      color: const Color(0xFF92400E),
                      bgColor: const Color(0xFFFEF3C7),
                      borderColor: const Color(0xFFFCD34D),
                      message:
                      '${AppConfig.cooldownBannerTitle} — '
                          '${AppConfig.cooldownBannerPrefix}'
                          '${nextDate.day} ${_monthAbbr(nextDate.month)} ${nextDate.year}'
                          ' ($daysLeft day${daysLeft != 1 ? 's' : ''}'
                          '${AppConfig.cooldownBannerSuffix})',
                    ),
                ]);
              }),

              // ── Feed list / map ─────────────────────────────────────────
              Expanded(
                child: reqState.isLoading
                    ? _buildShimmer()
                    : reqState.error != null
                    ? ErrorView(
                    message: reqState.error!,
                    onRetry: () => reqVm.load())
                    : _showMap
                // ── MAP VIEW ──────────────────────────────
                    ? const FeedMapView()
                // ── LIST VIEW ─────────────────────────────
                    : reqState.filtered.isEmpty
                    ? RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: () => reqVm.load(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverFillRemaining(
                        child: EmptyView(
                          title: reqState.searchQuery.isNotEmpty
                              ? 'No results'
                              : bloodType.isNotEmpty
                              ? 'No $bloodType requests'
                              : 'No requests found',
                          subtitle: reqState.searchQuery.isNotEmpty
                              ? 'Try a different hospital name or blood type.'
                              : isLocationFiltered
                              ? 'No requests nearby. Try expanding the location filter.'
                              : bloodType.isNotEmpty
                              ? 'No open requests for $bloodType right now.'
                              : 'No open blood requests right now.',
                          icon: Icons.bloodtype_outlined,
                        ),
                      ),
                    ],
                  ),
                )
                    : RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  onRefresh: () => reqVm.load(),
                  child: _buildList(reqState),
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  static String _monthAbbr(int month) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'];
    return months[(month - 1).clamp(0, 11)];
  }

  /// Flat list — no urgency section headers. Sorted by distance when location available.
  Widget _buildList(RequirementsState state) {
    final items = state.filtered;

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
      itemCount: items.length + (state.isLoadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          // Loading more indicator
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return RequirementCard(
          requirement: items[index],
          showDistance: state.hasGpsLocation,
        );
      },
    );
  }

  Widget _buildShimmer() => ListView.builder(
    padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
    itemCount: 4,
    itemBuilder: (_, __) => const CardShimmer(),
  );
}

// ════════════════════════════════════════════════════════════
//  LIST / MAP SEGMENTED TOGGLE PILL
// ════════════════════════════════════════════════════════════

class _ViewTogglePill extends StatelessWidget {
  final bool showMap;
  final ValueChanged<bool> onToggle;

  const _ViewTogglePill({required this.showMap, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Segment(
            icon: Icons.view_list_rounded,
            label: AppConfig.feedViewList,
            active: !showMap,
            onTap: () => onToggle(false),
          ),
          _Segment(
            icon: Icons.map_rounded,
            label: AppConfig.feedViewMap,
            active: showMap,
            onTap: () => onToggle(true),
          ),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _Segment({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13,
                color: active ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.syne(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Banner widget shown above the feed for cooldown / unavailable ─────────────
class _FeedBanner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color borderColor;
  final String message;

  const _FeedBanner({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Row(children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ]),
    );
  }
}