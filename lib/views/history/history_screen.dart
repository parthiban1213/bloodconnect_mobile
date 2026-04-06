import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../models/donation_history.dart';
import '../../models/blood_requirement.dart';
import '../../viewmodels/history_viewmodel.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';
import '../../widgets/app_widgets.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyViewModelProvider);
    final vm    = ref.read(historyViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Tab bar ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      const Border.fromBorderSide(BorderSide(color: AppColors.border)),
                ),
                child: TabBar(
                  controller: _tabController,
                  labelStyle: GoogleFonts.dmSans(
                      fontSize: 12, fontWeight: FontWeight.w600),
                  unselectedLabelStyle:
                      GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w500),
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMuted,
                  indicator: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  padding: const EdgeInsets.all(4),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.volunteer_activism_outlined, size: 14),
                          const SizedBox(width: 6),
                          const Text(AppConfig.historyMyDonations),
                          if (state.myDonations.isNotEmpty) ...[
                            const SizedBox(width: 5),
                            _CountBadge(state.myDonations.length),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded, size: 14),
                          const SizedBox(width: 6),
                          const Text(AppConfig.historyCompleted),
                          if (state.completedCount > 0) ...[
                            const SizedBox(width: 5),
                            _CountBadge(state.completedRequests.length),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Tab content ───────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? _buildShimmer()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 1: My Donations
                        _DonationsTab(
                          donations: state.myDonations,
                          onRefresh: () => vm.load(),
                        ),
                        // Tab 2: Completed — the current user's own Fulfilled/Cancelled requests
                        _CompletedTab(
                          requests: state.completedRequests,
                          onRefresh: () => vm.load(),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() => ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: 5,
        itemBuilder: (_, __) => const CardShimmer(),
      );
}

// ── Donations Tab ─────────────────────────────────────────────
class _DonationsTab extends StatelessWidget {
  final List<DonationHistory> donations;
  final Future<void> Function() onRefresh;

  const _DonationsTab({required this.donations, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (donations.isEmpty) {
      return const EmptyView(
        title: AppConfig.historyNoDonations,
        subtitle: AppConfig.historyNoDonationsSubtitle,
        icon: Icons.volunteer_activism_outlined,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: Colors.white,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: donations.length,
        itemBuilder: (_, i) => _DonationCard(donation: donations[i]),
      ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  final DonationHistory donation;
  const _DonationCard({required this.donation});

  @override
  Widget build(BuildContext context) {
    final isCompleted = donation.isCompleted;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF86EFAC)
              : const Color(0xFFFCD34D),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    donation.bloodType,
                    style: GoogleFonts.dmSans(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: Colors.white,
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
                      donation.hospital.isNotEmpty
                          ? donation.hospital
                          : 'Blood Donation',
                      style: GoogleFonts.dmSans(
                        fontSize: 14, fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (donation.patientName.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(donation.patientName,
                          style: GoogleFonts.dmSans(
                            fontSize: 11, color: AppColors.textSecondary,
                          )),
                    ],
                    if (donation.location.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 11, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Text(donation.location,
                            style: GoogleFonts.dmSans(
                              fontSize: 10, color: AppColors.textMuted,
                            )),
                      ]),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      _formatDateTime(donation.donatedAt),
                      style: GoogleFonts.dmSans(
                        fontSize: 10, color: AppColors.textVeryMuted,
                      ),
                    ),
                  ],
                ),
              ),
              // Donation status badge
              _DonationStatusBadge(isCompleted: isCompleted),
            ],
          ),

          // Scheduled date + time
          if (donation.scheduledDate.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: AppColors.borderSoft),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.calendar_today_rounded,
                  size: 12, color: AppColors.plannedAccent),
              const SizedBox(width: 6),
              Text(
                '${AppConfig.donorScheduledPrefix}${_formatSchedule(donation.scheduledDate, donation.scheduledTime)}',
                style: GoogleFonts.dmSans(
                  fontSize: 11, fontWeight: FontWeight.w500,
                  color: AppColors.plannedText,
                ),
              ),
            ]),
          ],

          // Request status
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.local_hospital_outlined,
                size: 12, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text('Request: ',
                style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.textMuted)),
            _ReqStatusChip(status: donation.status),
          ]),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return 'Today · ${DateFormat('h:mm a').format(dt)}';
    if (diff.inDays == 1) return 'Yesterday · ${DateFormat('h:mm a').format(dt)}';
    if (diff.inDays < 7)  return '${diff.inDays} days ago · ${DateFormat('h:mm a').format(dt)}';
    return DateFormat('d MMM yyyy · h:mm a').format(dt);
  }

  String _formatSchedule(String date, String time) {
    try {
      final d    = DateTime.parse(date);
      final fmtd = DateFormat('d MMM yyyy').format(d);
      return time.isNotEmpty ? '$fmtd  🕐 $time' : fmtd;
    } catch (_) {
      return time.isNotEmpty ? '$date  $time' : date;
    }
  }
}

class _DonationStatusBadge extends StatelessWidget {
  final bool isCompleted;
  const _DonationStatusBadge({required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isCompleted
            ? const Color(0xFFDCFCE7)
            : const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCompleted
              ? const Color(0xFF86EFAC)
              : const Color(0xFFFCD34D),
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          isCompleted
              ? Icons.check_circle_outline_rounded
              : Icons.hourglass_top_rounded,
          size: 10,
          color: isCompleted
              ? const Color(0xFF15803D)
              : const Color(0xFF92400E),
        ),
        const SizedBox(width: 4),
        Text(
          isCompleted
              ? AppConfig.donationStatusCompleted
              : AppConfig.donationStatusPending,
          style: GoogleFonts.dmSans(
            fontSize: 9, fontWeight: FontWeight.w600,
            color: isCompleted
                ? const Color(0xFF15803D)
                : const Color(0xFF92400E),
          ),
        ),
      ]),
    );
  }
}

class _ReqStatusChip extends StatelessWidget {
  final String status;
  const _ReqStatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    if (status == 'Fulfilled')      color = AppColors.secondary;
    else if (status == 'Cancelled') color = AppColors.closedAccent;
    else                            color = AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(status,
          style: GoogleFonts.dmSans(
            fontSize: 9, fontWeight: FontWeight.w600, color: color,
          )),
    );
  }
}

// ── Completed Tab ─────────────────────────────────────────────
// Shows the current user's OWN blood requests that are Fulfilled or Cancelled.
// Uses /my-requirements, so only requests they created are shown.
class _CompletedTab extends StatelessWidget {
  final List<BloodRequirement> requests;
  final Future<void> Function() onRefresh;

  const _CompletedTab({required this.requests, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const EmptyView(
        title: AppConfig.historyNoCompleted,
        subtitle: AppConfig.historyNoCompletedSubtitle,
        icon: Icons.check_circle_outline_rounded,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: Colors.white,
      onRefresh: onRefresh,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: requests.length,
        itemBuilder: (_, i) => _CompletedCard(requirement: requests[i]),
      ),
    );
  }
}

class _CompletedCard extends StatelessWidget {
  final BloodRequirement requirement;
  const _CompletedCard({required this.requirement});

  bool get _isCancelled => requirement.status == 'Cancelled';

  // Fulfilled = green, Cancelled = muted grey-red
  Color get _badgeColor => _isCancelled
      ? const Color(0xFF6B3A3A)
      : const Color(0xFF085041);
  Color get _badgeBg => _isCancelled
      ? const Color(0xFFFBEAEA)
      : const Color(0xFFE1F5EE);
  Color get _avatarColor => _isCancelled
      ? AppColors.closedAccent
      : const Color(0xFF1D9E75);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        '/requirement/${requirement.id}',
        extra: {'requirement': requirement},
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blood type badge with status icon overlay
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _avatarColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      requirement.bloodType,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: -3,
                  bottom: -3,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _avatarColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isCancelled ? Icons.close : Icons.check,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    requirement.hospital,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (requirement.patientName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      requirement.patientName,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (requirement.location.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 11, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          requirement.location,
                          style: GoogleFonts.dmSans(
                              fontSize: 10, color: AppColors.textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _isCancelled
                        ? '${requirement.unitsRequired} unit${requirement.unitsRequired != 1 ? "s" : ""} requested'
                        : '${requirement.donorCount} donor${requirement.donorCount != 1 ? "s" : ""} · '
                          '${requirement.unitsRequired} unit${requirement.unitsRequired != 1 ? "s" : ""}',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(requirement.updatedAt),
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: AppColors.textVeryMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    requirement.status,
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: _badgeColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);
    final verb = _isCancelled ? 'Cancelled' : 'Fulfilled';
    if (diff.inDays == 0) return '$verb today';
    if (diff.inDays == 1) return '$verb yesterday';
    return '$verb on ${DateFormat('d MMM yyyy').format(dt)}';
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge(this.count);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$count',
        style: GoogleFonts.dmSans(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
