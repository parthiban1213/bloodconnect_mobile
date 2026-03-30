import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../models/donor_model.dart';
import '../../viewmodels/donors_viewmodel.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';
import '../../widgets/app_widgets.dart';

class DonorsScreen extends ConsumerStatefulWidget {
  const DonorsScreen({super.key});

  @override
  ConsumerState<DonorsScreen> createState() => _DonorsScreenState();
}

class _DonorsScreenState extends ConsumerState<DonorsScreen> {
  final _searchController = TextEditingController();

  static const _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // Fix #2: show as centered popup dialog instead of bottom sheet
  void _showDonorDetail(BuildContext context, DonorModel donor) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: _DonorDetailPopup(
            donor: donor, onCall: () => _call(donor.phone)),
      ),
    );
  }

  bool _hasActiveFilter(DonorsState state) =>
      state.bloodTypeFilter.isNotEmpty || state.availabilityFilter.isNotEmpty;

  // Fix #3: donor filter popup
  void _showDonorFilterPopup(
      BuildContext context, DonorsState state, DonorsViewModel vm) {
    // selected values must live OUTSIDE the builder so setPopState doesn't reset them
    String selBlood = state.bloodTypeFilter;
    String selAvail = state.availabilityFilter;
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(20),
          child: StatefulBuilder(
            builder: (ctx, setPopState) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + close
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(AppConfig.donorsFilterTitle,
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

                    // Blood type section
                    Text(AppConfig.donorsFilterBloodType,
                        style: GoogleFonts.syne(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        )),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _bloodTypes.map((bt) {
                        final active = selBlood == bt;
                        return GestureDetector(
                          onTap: () => setPopState(
                              () => selBlood = active ? '' : bt),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.primary
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active
                                    ? AppColors.primary
                                    : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              bt,
                              style: GoogleFonts.syne(
                                fontSize: 12,
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

                    const SizedBox(height: 16),

                    // Availability section
                    Text(AppConfig.donorsFilterAvailability,
                        style: GoogleFonts.syne(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 0.5,
                        )),
                    const SizedBox(height: 8),
                    Row(children: [
                      _AvailChip(
                        label: AppConfig.donorsFilterAvailable,
                        value: 'true',
                        selected: selAvail,
                        dotColor: AppColors.secondary,
                        onTap: (v) => setPopState(
                            () => selAvail = selAvail == v ? '' : v),
                      ),
                      const SizedBox(width: 8),
                      _AvailChip(
                        label: AppConfig.donorsFilterUnavailable,
                        value: 'false',
                        selected: selAvail,
                        dotColor: AppColors.primary,
                        onTap: (v) => setPopState(
                            () => selAvail = selAvail == v ? '' : v),
                      ),
                    ]),

                    const SizedBox(height: 20),

                    // Action buttons
                    Row(children: [
                      if (selBlood.isNotEmpty || selAvail.isNotEmpty)
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              vm.setBloodType('');
                              vm.setAvailability('');
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Center(
                                child: Text(AppConfig.donorsFilterClear,
                                    style: GoogleFonts.syne(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    )),
                              ),
                            ),
                          ),
                        ),
                      if (selBlood.isNotEmpty || selAvail.isNotEmpty)
                        const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () {
                            vm.setBloodType(selBlood);
                            vm.setAvailability(selAvail);
                            Navigator.pop(ctx);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: AppColors.navBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(AppConfig.donorsFilterApply,
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
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(donorsViewModelProvider);
    final vm    = ref.read(donorsViewModelProvider.notifier);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/feed');
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Donors',
                              style: GoogleFonts.syne(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (!state.isLoading && state.error == null)
                              Text(
                                '${state.filtered.length} of ${state.donors.length} donors',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Search + Filter button (Fix #3) ────────────
                  Row(children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: const Border.fromBorderSide(
                              BorderSide(color: AppColors.border)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded,
                                size: 15, color: AppColors.textMuted),
                            const SizedBox(width: 9),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                style: GoogleFonts.dmSans(
                                    fontSize: 12,
                                    color: AppColors.textPrimary),
                                decoration: InputDecoration(
                                  hintText: AppConfig.donorsSearchHint,
                                  hintStyle: GoogleFonts.dmSans(
                                      fontSize: 12,
                                      color: AppColors.textMuted),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (v) => vm.setSearch(v),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  vm.setSearch('');
                                },
                                child: const Icon(Icons.clear_rounded,
                                    size: 15, color: AppColors.textMuted),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          _showDonorFilterPopup(context, state, vm),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _hasActiveFilter(state)
                              ? AppColors.navBg
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.fromBorderSide(BorderSide(
                            color: _hasActiveFilter(state)
                                ? AppColors.navBg
                                : AppColors.border,
                          )),
                        ),
                        child: Icon(
                          Icons.tune_rounded,
                          size: 18,
                          color: _hasActiveFilter(state)
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ]),

                  // Fix #3: active filter chips with clear
                  if (_hasActiveFilter(state)) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      if (state.bloodTypeFilter.isNotEmpty) ...[
                        _ActiveFilterChip(
                          label: state.bloodTypeFilter,
                          onClear: () => vm.setBloodType(''),
                        ),
                        if (state.availabilityFilter.isNotEmpty)
                          const SizedBox(width: 6),
                      ],
                      if (state.availabilityFilter.isNotEmpty)
                        _ActiveFilterChip(
                          label: state.availabilityFilter == 'true'
                              ? 'Available'
                              : 'Unavailable',
                          onClear: () => vm.setAvailability(''),
                        ),
                    ]),
                  ],
                  const SizedBox(height: 14),
                ],
              ),
            ),

            // ── List ──────────────────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(14, 0, 14, 100),
                      itemCount: 6,
                      itemBuilder: (_, __) => const _DonorShimmer(),
                    )
                  : state.error != null
                      ? ErrorView(
                          message: state.error!,
                          onRetry: () => vm.load(),
                        )
                      : state.filtered.isEmpty
                          ? const EmptyView(
                              title: AppConfig.donorsEmptyTitle,
                              subtitle:
                                  AppConfig.donorsEmptySubtitle,
                              icon: Icons.person_search_outlined,
                            )
                          : RefreshIndicator(
                              color: AppColors.primary,
                              backgroundColor: Colors.white,
                              onRefresh: () => vm.load(),
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    14, 0, 14, 100),
                                itemCount: state.filtered.length,
                                itemBuilder: (_, i) => _DonorCard(
                                  donor: state.filtered[i],
                                  onTap: () => _showDonorDetail(
                                      context, state.filtered[i]),
                                  onCall: () =>
                                      _call(state.filtered[i].phone),
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Active filter chip (Fix #3)
// ─────────────────────────────────────────────────────────────
class _ActiveFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onClear;
  const _ActiveFilterChip({required this.label, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.navBg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(label,
            style: GoogleFonts.syne(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            )),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onClear,
          child: const Icon(Icons.close_rounded,
              size: 12, color: Colors.white),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Availability chip used inside filter popup (Fix #3)
// ─────────────────────────────────────────────────────────────
class _AvailChip extends StatelessWidget {
  final String label, value, selected;
  final Color dotColor;
  final ValueChanged<String> onTap;
  const _AvailChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.dotColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = selected == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.navBg : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.navBg : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(
              color: active ? Colors.white : dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(label,
              style: GoogleFonts.syne(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.textSecondary,
              )),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Donor card
// ─────────────────────────────────────────────────────────────
class _DonorCard extends StatelessWidget {
  final DonorModel donor;
  final VoidCallback onTap;
  final VoidCallback onCall;

  const _DonorCard(
      {required this.donor, required this.onTap, required this.onCall});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: const Border.fromBorderSide(
              BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.urgentBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Icon(
                  Icons.person_rounded,
                  size: 24,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          donor.fullName,
                          style: GoogleFonts.dmSans(
                            fontSize: 13, fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _StatusDot(available: donor.isAvailable),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(donor.phone,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: AppColors.linkColor)),
                  if (donor.address.isNotEmpty)
                    Text(
                      donor.address,
                      style: GoogleFonts.dmSans(
                          fontSize: 10, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Blood type + call
            Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.urgentBg,
                    borderRadius: BorderRadius.circular(10),
                    border: const Border.fromBorderSide(
                        BorderSide(color: AppColors.urgentBorder)),
                  ),
                  child: Text(
                    donor.bloodType,
                    style: GoogleFonts.syne(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: onCall,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.plannedBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.call_rounded,
                            size: 11, color: AppColors.plannedText),
                        const SizedBox(width: 4),
                        Text(AppConfig.commonCallBtn,
                            style: GoogleFonts.dmSans(
                              fontSize: 10, fontWeight: FontWeight.w600,
                              color: AppColors.plannedText,
                            )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Donor detail popup (Fix #2: replaces bottom sheet)
// ─────────────────────────────────────────────────────────────
class _DonorDetailPopup extends StatelessWidget {
  final DonorModel donor;
  final VoidCallback onCall;

  const _DonorDetailPopup({required this.donor, required this.onCall});

  String _fmt(DateTime? d) =>
      d == null ? '—' : DateFormat('dd MMM yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppConfig.donorDetailTitle,
                style: GoogleFonts.syne(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
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
          const SizedBox(height: 14),

          // Hero row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.urgentBg,
              borderRadius: BorderRadius.circular(16),
              border: const Border.fromBorderSide(
                  BorderSide(color: AppColors.urgentBorder)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: const Border.fromBorderSide(
                        BorderSide(color: AppColors.urgentBorder)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person_rounded,
                      size: 28,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(donor.fullName,
                          style: GoogleFonts.syne(
                            fontSize: 14, fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          )),
                      if (donor.email != null && donor.email!.isNotEmpty)
                        Text(donor.email!,
                            style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      _StatusDot(
                          available: donor.isAvailable, showLabel: true),
                    ],
                  ),
                ),
                Text(donor.bloodType,
                    style: GoogleFonts.syne(
                      fontSize: 26, fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Detail grid
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: const Border.fromBorderSide(
                  BorderSide(color: AppColors.border)),
            ),
            child: Column(
              children: [
                _DetailRow(label: 'Phone', value: donor.phone),
                _DetailRow(
                    label: 'Address',
                    value:
                        donor.address.isNotEmpty ? donor.address : '—'),
                _DetailRow(
                    label: 'Last Donation',
                    value: _fmt(donor.lastDonationDate)),
                _DetailRow(
                    label: 'Registered',
                    value: _fmt(donor.createdAt),
                    isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Call button
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              onCall();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.plannedBg,
                borderRadius: BorderRadius.circular(14),
                border: const Border.fromBorderSide(
                    BorderSide(color: AppColors.plannedBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.call_rounded,
                      size: 16, color: AppColors.plannedText),
                  const SizedBox(width: 8),
                  Text('Call ${donor.phone}',
                      style: GoogleFonts.dmSans(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: AppColors.plannedText,
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Shared sub-widgets
// ─────────────────────────────────────────────────────────────
class _StatusDot extends StatelessWidget {
  final bool available;
  final bool showLabel;
  const _StatusDot({required this.available, this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    final color = available ? AppColors.secondary : AppColors.primary;
    final label = available ? 'Available' : 'Unavailable';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7, height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        if (showLabel) ...[
          const SizedBox(width: 5),
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: color)),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;
  const _DetailRow(
      {required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 110,
                child: Text(label,
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: AppColors.textMuted)),
              ),
              Expanded(
                child: Text(value,
                    style: GoogleFonts.dmSans(
                      fontSize: 12, fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    )),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
              height: 1,
              thickness: 1,
              color: AppColors.borderSoft),
      ],
    );
  }
}

class _DonorShimmer extends StatelessWidget {
  const _DonorShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: const Border.fromBorderSide(
            BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: AppColors.closedBg,
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 13, width: 140, color: AppColors.closedBg),
                const SizedBox(height: 5),
                Container(height: 10, width: 90, color: AppColors.closedBg),
                const SizedBox(height: 4),
                Container(height: 10, width: 120, color: AppColors.closedBg),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              Container(
                  width: 44, height: 28,
                  decoration: BoxDecoration(
                      color: AppColors.closedBg,
                      borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 6),
              Container(
                  width: 44, height: 26,
                  decoration: BoxDecoration(
                      color: AppColors.closedBg,
                      borderRadius: BorderRadius.circular(10))),
            ],
          ),
        ],
      ),
    );
  }
}
