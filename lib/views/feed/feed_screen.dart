import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                      Text('Location Filter',
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
      canPop: true,
      child: Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Greeting + blood type badge ────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          const SizedBox(height: 3),
                          Text(
                            user?.displayName ?? 'Welcome',
                            style: GoogleFonts.cormorantGaramond(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
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

                  const SizedBox(height: 12),

                  // ── Open request count ────────────────────────────────────
                  if (!reqState.isLoading && reqState.error == null)
                    _OpenRequestCount(count: reqState.filtered.where((r) => r.isOpen).length),

                  const SizedBox(height: 12),

                  // ── Search bar + filter buttons row ─────────────────────────
                  Row(children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 1),
                        ),
                        child: Row(children: [
                          const Icon(Icons.search_rounded,
                              size: 15, color: AppColors.textMuted),
                          const SizedBox(width: 9),
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
                                    const EdgeInsets.symmetric(vertical: 10),
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
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Location filter button
                    GestureDetector(
                      onTap: () => _showLocationFilterPopup(context, reqState, reqVm),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isLocationFiltered ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isLocationFiltered ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: isLocationFiltered ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Map / List toggle button
                    GestureDetector(
                      onTap: () => setState(() => _showMap = !_showMap),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _showMap ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _showMap ? AppColors.primary : AppColors.border,
                          ),
                        ),
                        child: Icon(
                          _showMap ? Icons.view_list_rounded : Icons.map_rounded,
                          size: 18,
                          color: _showMap ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Status/urgency filter button
                    GestureDetector(
                      onTap: () => _showFilterPopup(context, reqState, reqVm),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isFiltered ? AppColors.navBg : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFiltered ? AppColors.navBg : AppColors.border,
                          ),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: isFiltered ? Colors.white : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ]),

                  // Active filter chips
                  if (isFiltered || isLocationFiltered) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      if (isLocationFiltered)
                        _FilterChip(
                          label: locationFilter.label,
                          icon: Icons.location_on_rounded,
                          onClear: () => reqVm.setLocationFilter(LocationFilterRadius.allLocations),
                        ),
                      if (isLocationFiltered && isFiltered)
                        const SizedBox(width: 6),
                      if (isFiltered)
                        _FilterChip(
                          label: activeFilter,
                          icon: Icons.tune_rounded,
                          onClear: () => reqVm.setFilter('All'),
                        ),
                    ]),
                  ],

                  const SizedBox(height: 14),
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

// ── Filter chip widget ────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onClear;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.navBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: Colors.white),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.syne(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onClear,
          child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
        ),
      ]),
    );
  }
}

// ════════════════════════════════════════════════════════════
//  OPEN REQUEST COUNT
// ════════════════════════════════════════════════════════════

class _OpenRequestCount extends StatelessWidget {
  final int count;
  const _OpenRequestCount({required this.count});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(Icons.bloodtype_outlined, size: 16, color: AppColors.primary),
            const SizedBox(width: 10),
            Text(
              '$count',
              style: GoogleFonts.syne(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              AppConfig.feedOpenRequests,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
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
