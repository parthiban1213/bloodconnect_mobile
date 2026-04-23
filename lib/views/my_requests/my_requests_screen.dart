import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/blood_requirement.dart';
import '../../viewmodels/my_requests_viewmodel.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';
import '../../widgets/app_widgets.dart';
import '../../widgets/blood_type_badge.dart';
import 'request_status_modal.dart';
import 'pledged_donors_modal.dart' as pdm;
import '../../widgets/ripple_badge.dart';

class MyRequestsScreen extends ConsumerStatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  ConsumerState<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends ConsumerState<MyRequestsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(myRequestsViewModelProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(myRequestsViewModelProvider.notifier).load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myRequestsViewModelProvider);
    final vm    = ref.read(myRequestsViewModelProvider.notifier);

    return Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: state.isLoading
              ? _buildShimmer()
              : state.error != null
                  ? ErrorView(
                      message: state.error!,
                      onRetry: () => vm.load(),
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SummaryRow(state: state),
                              const SizedBox(height: 10),
                              GestureDetector(
                                onTap: () async {
                                  await context.push('/add-requirement');
                                  vm.load();
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_rounded,
                                          size: 17, color: Colors.white),
                                      const SizedBox(width: 6),
                                      Text(
                                        AppConfig.myRequestsAddBtn,
                                        style: GoogleFonts.syne(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                        Expanded(
                          child: state.requests.isEmpty
                              ? const EmptyView(
                                  title: AppConfig.myRequestsEmptyTitle,
                                  subtitle: AppConfig.myRequestsEmptySubtitle,
                                  icon: Icons.bloodtype_outlined,
                                )
                              : RefreshIndicator(
                                  color: AppColors.primary,
                                  backgroundColor: AppColors.surface,
                                  onRefresh: () => vm.load(),
                                  child: _buildContent(state),
                                ),
                        ),
                      ],
                    ),
        ),
    );
  }

  Widget _buildContent(MyRequestsState state) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      children: [
        if (state.activeRequests.isNotEmpty) ...[
          _SectionHeader('Active', state.activeRequests.length, AppColors.primary),
          const SizedBox(height: 8),
          ...state.activeRequests.map((r) => _RequestCard(requirement: r)),
          const SizedBox(height: 12),
        ],
        if (state.fulfilledRequests.isNotEmpty) ...[
          _SectionHeader(AppConfig.myReqStatusFulfilled,
              state.fulfilledRequests.length, AppColors.secondary),
          const SizedBox(height: 8),
          ...state.fulfilledRequests.map((r) => _RequestCard(requirement: r)),
          const SizedBox(height: 12),
        ],
        if (state.cancelledRequests.isNotEmpty) ...[
          _SectionHeader(AppConfig.myReqStatusCancelled,
              state.cancelledRequests.length, AppColors.closedAccent),
          const SizedBox(height: 8),
          ...state.cancelledRequests.map((r) => _RequestCard(requirement: r)),
        ],
      ],
    );
  }

  Widget _buildShimmer() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        itemCount: 4,
        itemBuilder: (_, __) => const CardShimmer(),
      );
}

// ── Summary chips ─────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final MyRequestsState state;
  const _SummaryRow({required this.state});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Chip(count: state.activeRequests.length, label: 'Open',
            bg: AppColors.urgentBg, tc: AppColors.urgentText),
        const SizedBox(width: 8),
        _Chip(count: state.fulfilledRequests.length,
            label: AppConfig.myReqStatusFulfilled,
            bg: AppColors.secondaryLight, tc: AppColors.secondary),
        const SizedBox(width: 8),
        _Chip(count: state.cancelledRequests.length,
            label: AppConfig.myReqStatusCancelled,
            bg: AppColors.closedBg, tc: AppColors.closedText),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final int count;
  final String label;
  final Color bg;
  final Color tc;
  const _Chip({required this.count, required this.label,
      required this.bg, required this.tc});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Text('$count', style: GoogleFonts.syne(
            fontSize: 13, fontWeight: FontWeight.w700, color: tc)),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.syne(
            fontSize: 10, fontWeight: FontWeight.w600, color: tc)),
      ]),
    );
  }
}

// ── Section header ────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  final Color dotColor;
  const _SectionHeader(this.label, this.count, this.dotColor);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 5, height: 5,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
      const SizedBox(width: 7),
      Text('${label.toUpperCase()} · $count',
          style: GoogleFonts.syne(fontSize: 9, fontWeight: FontWeight.w700,
              color: AppColors.textMuted, letterSpacing: 0.9)),
    ]);
  }
}

// ── Individual request card ───────────────────────────────────
class _RequestCard extends ConsumerWidget {
  final BloodRequirement requirement;
  const _RequestCard({required this.requirement});

  Color get _statusBg {
    if (requirement.isFulfilled) return AppColors.secondaryLight;
    if (requirement.isCancelled) return AppColors.closedBg;
    return AppColors.urgentBg;
  }

  Color get _statusTc {
    if (requirement.isFulfilled) return AppColors.secondary;
    if (requirement.isCancelled) return AppColors.closedText;
    return AppColors.urgentText;
  }

  String get _statusLabel {
    if (requirement.isFulfilled) return AppConfig.myReqStatusFulfilled;
    if (requirement.isCancelled) return AppConfig.myReqStatusCancelled;
    return 'Open';
  }

  Future<void> _confirmClose(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppConfig.myRequestsCloseTitle,
            style: GoogleFonts.syne(
                fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        content: Text(AppConfig.myRequestsCloseBody,
            style: GoogleFonts.dmSans(
                fontSize: 13, color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppConfig.myReqCancelAction,
                style: GoogleFonts.dmSans(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(AppConfig.myRequestsCloseConfirm,
                style: GoogleFonts.dmSans(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      final ok = await ref
          .read(myRequestsViewModelProvider.notifier)
          .closeRequest(requirement.id);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppConfig.myRequestsCloseError,
              style: GoogleFonts.dmSans(fontSize: 13)),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasPending = requirement.pendingCount > 0 && requirement.isOpen;

    return PendingPledgeAnimation(
      active: hasPending,
      child: GestureDetector(
        onTap: () => showRequestStatusModal(
          context, requirement, isRequester: true),
        child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasPending ? const Color(0xFFFCD34D) : AppColors.border,
            width: hasPending ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BloodTypeBadge(
                  bloodType: requirement.bloodType,
                  urgency: requirement.urgency,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(requirement.hospital,
                          style: GoogleFonts.syne(fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                      if (requirement.patientName.isNotEmpty)
                        Text(requirement.patientName,
                            style: GoogleFonts.dmSans(fontSize: 11,
                                color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _statusBg,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(_statusLabel,
                      style: GoogleFonts.syne(fontSize: 9,
                          fontWeight: FontWeight.w700, color: _statusTc)),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Progress ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${requirement.unitsFulfilled}/${requirement.unitsRequired} units',
                      style: GoogleFonts.dmSans(fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary),
                    ),
                    if (requirement.pendingCount > 0 && requirement.isOpen)
                      Text(
                        '+${requirement.pendingCount}${AppConfig.pendingCountSuffix}',
                        style: GoogleFonts.dmSans(fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF92400E)),
                      ),
                  ],
                ),
                Text(
                  '${requirement.donorCount} donor${requirement.donorCount != 1 ? 's' : ''}',
                  style: GoogleFonts.dmSans(fontSize: 10, color: AppColors.textMuted),
                ),
              ],
            ),
            const SizedBox(height: 5),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: requirement.fulfillmentProgress,
                backgroundColor: AppColors.border,
                color: requirement.isFulfilled
                    ? AppColors.secondary : AppColors.primary,
                minHeight: 6,
              ),
            ),

            // ── Action buttons ────────────────────────────────────
            if (requirement.isOpen) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  // Pledged Donors — wide, bounces when pending
                  Expanded(
                    child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                      onTap: () => pdm.showPledgedDonorsModal(context, requirement),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: hasPending
                                  ? AppColors.primary.withOpacity(0.5)
                                  : AppColors.urgentBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people_outline_rounded,
                                  size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Text('Pledged Donors',
                                  style: GoogleFonts.syne(fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary)),
                              if (requirement.donationsCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text('${requirement.donationsCount}',
                                      style: GoogleFonts.syne(fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ),
                              ],
                            ],
                          ),
                        ),  // Container
                      ),    // GestureDetector
                  ),        // Expanded
                  const SizedBox(width: 8),
                  // Edit icon button
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      await context.push('/add-requirement',
                          extra: {'existing': requirement});
                      ref.read(myRequestsViewModelProvider.notifier).load();
                    },
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.plannedBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.plannedBorder),
                      ),
                      child: const Center(
                        child: Icon(Icons.edit_outlined,
                            size: 16, color: AppColors.plannedText),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Close icon button
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _confirmClose(context, ref),
                    child: Container(
                      width: 38, height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.closedBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.closedBorder),
                      ),
                      child: const Center(
                        child: Icon(Icons.cancel_outlined,
                            size: 16, color: AppColors.closedText),
                      ),
                    ),
                  ),
                ],
              ),  // Row
            ] else ...[
              // Fulfilled or Cancelled — View Status only
              const SizedBox(height: 12),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => showRequestStatusModal(
                  context, requirement, isRequester: true),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: requirement.isFulfilled
                        ? AppColors.secondaryLight : AppColors.closedBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: requirement.isFulfilled
                          ? const Color(0xFF9FE1CB) : AppColors.closedBorder,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        requirement.isFulfilled
                            ? Icons.check_circle_outline_rounded
                            : Icons.info_outline_rounded,
                        size: 13,
                        color: requirement.isFulfilled
                            ? const Color(0xFF085041) : AppColors.closedText,
                      ),
                      const SizedBox(width: 6),
                      Text(AppConfig.myRequestsViewStatus,
                          style: GoogleFonts.syne(fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: requirement.isFulfilled
                                  ? const Color(0xFF085041)
                                  : AppColors.closedText)),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),   // Container
      ), // GestureDetector
    );
  }
}
