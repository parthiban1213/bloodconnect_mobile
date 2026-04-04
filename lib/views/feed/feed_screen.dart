import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/requirements_viewmodel.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';
import '../../widgets/app_widgets.dart';
import 'requirement_card.dart';
import '../../widgets/password_prompt_dialog.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  final _searchCtrl  = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final bloodType = ref.read(authViewModelProvider).user?.bloodType ?? '';
      ref.read(requirementsViewModelProvider.notifier).setUserBloodType(bloodType);
      ref.read(requirementsViewModelProvider.notifier).load();
      // Show the one-time post-registration password prompt if flagged.
      if (mounted) await PasswordPromptDialog.showIfNeeded(context);
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // Fix #3: Show filter popup for feed
  void _showFilterPopup(BuildContext context, RequirementsState reqState,
      RequirementsViewModel reqVm) {
    final filters = AppConfig.feedFilters;
    // selected must live OUTSIDE the builder so setPopState doesn't reset it
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

    // Fix #3: active filter label for the indicator chip
    final activeFilter = reqState.selectedFilter;
    final isFiltered   = activeFilter != 'All';

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

                  // ── Search bar + filter button row ─────────────────────────
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
                    // Fix #3: filter icon button
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

                  // Fix #3: show selected filter chip + clear option below search
                  if (isFiltered) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.navBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Text(
                            activeFilter,
                            style: GoogleFonts.syne(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => reqVm.setFilter('All'),
                            child: const Icon(Icons.close_rounded,
                                size: 12, color: Colors.white),
                          ),
                        ]),
                      ),
                    ]),
                  ],

                  const SizedBox(height: 14),
                ],
              ),
            ),

            // ── Feed list ─────────────────────────────────────────────────
            Expanded(
              child: reqState.isLoading
                  ? _buildShimmer()
                  : reqState.error != null
                      ? ErrorView(
                          message: reqState.error!,
                          onRetry: () => reqVm.load())
                      : reqState.filtered.isEmpty
                          // Fix #4: RefreshIndicator wraps EmptyView too via CustomScrollView
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

  Widget _buildList(RequirementsState state) {
    final items     = state.filtered;
    final critical  = items.where((r) => r.urgency == 'Critical' && r.isOpen).toList();
    final high      = items.where((r) => r.urgency == 'High'     && r.isOpen).toList();
    final medium    = items.where((r) => r.urgency == 'Medium'   && r.isOpen).toList();
    final low       = items.where((r) => r.urgency == 'Low'      && r.isOpen).toList();
    final fulfilled = items.where((r) => r.isFulfilled).toList();
    final cancelled = items.where((r) => r.isCancelled).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
      children: [
        if (critical.isNotEmpty)  ...[_SectionLabel('Critical',  AppColors.primary),       ...critical.map((r)  => RequirementCard(requirement: r))],
        if (high.isNotEmpty)      ...[_SectionLabel('High',      AppColors.moderateAccent), ...high.map((r)      => RequirementCard(requirement: r))],
        if (medium.isNotEmpty)    ...[_SectionLabel('Medium',    AppColors.plannedAccent),  ...medium.map((r)    => RequirementCard(requirement: r))],
        if (low.isNotEmpty)       ...[_SectionLabel('Low',       AppColors.plannedBorder),  ...low.map((r)       => RequirementCard(requirement: r))],
        if (fulfilled.isNotEmpty) ...[_SectionLabel('Fulfilled', AppColors.secondary),      ...fulfilled.map((r) => RequirementCard(requirement: r))],
        if (cancelled.isNotEmpty) ...[_SectionLabel('Cancelled', AppColors.closedAccent),   ...cancelled.map((r) => RequirementCard(requirement: r))],
      ],
    );
  }

  Widget _buildShimmer() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 110),
        itemCount: 4,
        itemBuilder: (_, __) => const CardShimmer(),
      );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color dotColor;
  const _SectionLabel(this.label, this.dotColor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(children: [
        Container(
            width: 5, height: 5,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.syne(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.9,
          ),
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
