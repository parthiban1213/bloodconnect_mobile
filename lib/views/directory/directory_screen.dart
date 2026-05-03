import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../viewmodels/directory_viewmodel.dart';
import '../../models/info_entry.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';
import '../../widgets/app_widgets.dart';

class DirectoryScreen extends ConsumerStatefulWidget {
  const DirectoryScreen({super.key});

  @override
  ConsumerState<DirectoryScreen> createState() => _DirectoryScreenState();
}

class _DirectoryScreenState extends ConsumerState<DirectoryScreen> {
  final _searchController = TextEditingController();
  bool _showMap = false;

  static const _categories = ['All', 'Hospital', 'Blood Bank', 'Ambulance'];
  static const _categoryLabels = {
    'All': 'All',
    'Hospital': 'Hospitals',
    'Blood Bank': 'Blood Banks',
    'Ambulance': 'Ambulance',
  };

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openMaps(InfoEntry entry) async {
    if (entry.lat == null || entry.lng == null) return;
    final uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=${entry.lat},${entry.lng}');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  // ── Entry detail popup — same pattern as _DonorDetailPopup ──────────────
  void _showEntryDetail(BuildContext context, InfoEntry entry) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.45),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding:
        const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: _EntryDetailPopup(
          entry: entry,
          onCall: () => _call(entry.phone),
          onDirections:
          entry.lat != null ? () => _openMaps(entry) : null,
        ),
      ),
    );
  }

  // ── Filter popup — mirrors _showDonorFilterPopup exactly ────────────────
  void _showFilterPopup(
      BuildContext context, DirectoryState state, DirectoryViewModel vm) {
    String selCategory = state.selectedCategory;
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
              final hasFilter =
                  selCategory != 'All' || selAvail.isNotEmpty;

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Title + close ──────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppConfig.dirFilterTitle,
                          style: GoogleFonts.syne(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.close_rounded,
                                size: 16,
                                color: AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ── Category ───────────────────────────────────
                    Text(
                      'CATEGORY',
                      style: GoogleFonts.syne(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((key) {
                        final label = _categoryLabels[key]!;
                        final active = selCategory == key;
                        return GestureDetector(
                          onTap: () =>
                              setPopState(() => selCategory = key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.primaryDark
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: active
                                    ? AppColors.primaryDark
                                    : AppColors.border,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _categoryIcon(key),
                                  size: 13,
                                  color: active
                                      ? Colors.white
                                      : _categoryIconColor(key),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  label,
                                  style: GoogleFonts.syne(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: active
                                        ? Colors.white
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // ── Availability ───────────────────────────────
                    Text(
                      AppConfig.dirAvailability,
                      style: GoogleFonts.syne(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _AvailChip(
                          label: AppConfig.dirAvail24h,
                          value: 'true',
                          selected: selAvail,
                          dotColor: AppColors.secondary,
                          onTap: (v) => setPopState(
                                  () => selAvail = selAvail == v ? '' : v),
                        ),
                        const SizedBox(width: 8),
                        _AvailChip(
                          label: AppConfig.dirNotAvail24h,
                          value: 'false',
                          selected: selAvail,
                          dotColor: AppColors.textMuted,
                          onTap: (v) => setPopState(
                                  () => selAvail = selAvail == v ? '' : v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // ── Action buttons ─────────────────────────────
                    Row(
                      children: [
                        if (hasFilter) ...[
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                vm.clearFilters();
                                Navigator.pop(ctx);
                              },
                              child: Container(
                                padding:
                                const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                  Border.all(color: AppColors.border),
                                ),
                                child: Center(
                                  child: Text(
                                    'Clear',
                                    style: GoogleFonts.syne(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          flex: 2,
                          child: GestureDetector(
                            onTap: () {
                              vm.setCategory(selCategory);
                              vm.setAvailability(selAvail);
                              Navigator.pop(ctx);
                            },
                            child: Container(
                              padding:
                              const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.navBg,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Apply',
                                  style: GoogleFonts.syne(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String key) {
    switch (key) {
      case 'Hospital':
        return Icons.local_hospital_rounded;
      case 'Blood Bank':
        return Icons.bloodtype_rounded;
      case 'Ambulance':
        return Icons.emergency_rounded;
      default:
        return Icons.apps_rounded;
    }
  }

  Color _categoryIconColor(String key) {
    switch (key) {
      case 'Hospital':
        return AppColors.urgentText;
      case 'Blood Bank':
        return const Color(0xFF085041);
      case 'Ambulance':
        return AppColors.moderateText;
      default:
        return AppColors.textSecondary;
    }
  }

  // Builds a compact label showing the active filters, e.g. "Hospital · 24h"
  String _activeFilterLabel(DirectoryState state) {
    final parts = <String>[];
    if (state.selectedCategory != 'All') {
      parts.add(_categoryLabels[state.selectedCategory] ?? state.selectedCategory);
    }
    if (state.availabilityFilter == 'true') parts.add('24h');
    if (state.availabilityFilter == 'false') parts.add(AppConfig.dirNotAvail24h);
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(directoryViewModelProvider);
    final vm = ref.read(directoryViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: false,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      AppConfig.directoryTitle,
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Search bar
                    Container(
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
                                hintText: AppConfig.directorySearchHint,
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
                    const SizedBox(height: 14),

                    // Filter button (left) + List/Map toggle (right)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Filter button — shows active selections inline
                        GestureDetector(
                          onTap: () =>
                              _showFilterPopup(context, state, vm),
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10),
                            decoration: BoxDecoration(
                              color: state.hasActiveFilter
                                  ? AppColors.navBg
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: state.hasActiveFilter
                                    ? AppColors.navBg
                                    : AppColors.border,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.tune_rounded,
                                  size: 15,
                                  color: state.hasActiveFilter
                                      ? Colors.white
                                      : AppColors.textSecondary,
                                ),
                                if (state.hasActiveFilter) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    _activeFilterLabel(state),
                                    style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GestureDetector(
                                    onTap: vm.clearFilters,
                                    behavior: HitTestBehavior.opaque,
                                    child: const Icon(
                                      Icons.close_rounded,
                                      size: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        // List / Map toggle pill
                        _ViewTogglePill(
                          showMap: _showMap,
                          onToggle: (v) => setState(() => _showMap = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),

              // ── Content ─────────────────────────────────────────────
              Expanded(
                child: state.isLoading
                    ? ListView.builder(
                  padding:
                  const EdgeInsets.fromLTRB(14, 0, 14, 100),
                  itemCount: 6,
                  itemBuilder: (_, __) => const _DirShimmer(),
                )
                    : state.error != null
                    ? ErrorView(
                  message: state.error!,
                  onRetry: () => vm.load(),
                )
                    : state.filtered.isEmpty
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const EmptyView(
                      title: AppConfig.directoryEmptyTitle,
                      subtitle: AppConfig.directoryEmptyBody,
                      icon: Icons.local_hospital_outlined,
                    ),
                    if (state.hasActiveFilter)
                      GestureDetector(
                        onTap: vm.clearFilters,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius:
                            BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.border),
                          ),
                          child: Text(
                            AppConfig.dirClearFilters,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                  ],
                )
                    : _showMap
                    ? _DirectoryMapView(
                  entries: state.filtered,
                  onEntryTap: (e) =>
                      _showEntryDetail(context, e),
                )
                    : RefreshIndicator(
                  color: AppColors.primary,
                  backgroundColor: Colors.white,
                  onRefresh: () => vm.load(),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                        14, 0, 14, 100),
                    itemCount: state.filtered.length,
                    itemBuilder: (_, i) => _DirCard(
                      entry: state.filtered[i],
                      onCall: () =>
                          _call(state.filtered[i].phone),
                      onTap: () => _showEntryDetail(
                          context, state.filtered[i]),
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

// ── _AvailChip — same as donors screen ───────────────────────────────────────

class _AvailChip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final Color dotColor;
  final void Function(String) onTap;

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
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.navBg : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.navBg : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: active ? Colors.white : dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.syne(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color:
                active ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _DirCard ──────────────────────────────────────────────────────────────────

class _DirCard extends StatelessWidget {
  final InfoEntry entry;
  final VoidCallback onCall;
  final VoidCallback onTap;

  const _DirCard({
    required this.entry,
    required this.onCall,
    required this.onTap,
  });

  Color get _iconBg {
    switch (entry.category) {
      case 'Hospital':
        return AppColors.urgentBg;
      case 'Blood Bank':
        return AppColors.secondaryLight;
      default:
        return AppColors.moderateBg;
    }
  }

  Color get _iconColor {
    switch (entry.category) {
      case 'Hospital':
        return AppColors.urgentText;
      case 'Blood Bank':
        return const Color(0xFF085041);
      default:
        return AppColors.moderateText;
    }
  }

  IconData get _icon {
    switch (entry.category) {
      case 'Hospital':
        return Icons.local_hospital_rounded;
      case 'Blood Bank':
        return Icons.bloodtype_rounded;
      default:
        return Icons.emergency_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding:
        const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: const Border.fromBorderSide(
              BorderSide(color: AppColors.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_icon, size: 18, color: _iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.name,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (entry.available24h) ...[
                        const SizedBox(width: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryLight,
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Text(
                            '24h',
                            style: GoogleFonts.dmSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF085041),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (entry.area.isNotEmpty)
                    Text(
                      entry.area,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  Text(
                    entry.phone,
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: AppColors.linkColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onCall,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.plannedBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.call_rounded,
                        size: 12, color: AppColors.plannedText),
                    const SizedBox(width: 5),
                    Text(
                      AppConfig.commonCallBtn,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.plannedText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _EntryDetailPopup — mirrors _DonorDetailPopup ────────────────────────────

class _EntryDetailPopup extends StatelessWidget {
  final InfoEntry entry;
  final VoidCallback onCall;
  final VoidCallback? onDirections;

  const _EntryDetailPopup({
    required this.entry,
    required this.onCall,
    this.onDirections,
  });

  Color get _heroBg {
    switch (entry.category) {
      case 'Hospital':
        return AppColors.urgentBg;
      case 'Blood Bank':
        return AppColors.secondaryLight;
      default:
        return AppColors.moderateBg;
    }
  }

  Color get _heroBorder {
    switch (entry.category) {
      case 'Hospital':
        return AppColors.urgentBorder;
      case 'Blood Bank':
        return const Color(0xFF9FE1CB);
      default:
        return AppColors.moderateBorder;
    }
  }

  Color get _iconColor {
    switch (entry.category) {
      case 'Hospital':
        return AppColors.urgentText;
      case 'Blood Bank':
        return const Color(0xFF085041);
      default:
        return AppColors.moderateText;
    }
  }

  IconData get _icon {
    switch (entry.category) {
      case 'Hospital':
        return Icons.local_hospital_rounded;
      case 'Blood Bank':
        return Icons.bloodtype_rounded;
      default:
        return Icons.emergency_rounded;
    }
  }

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
          // Title + close
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppConfig.dirLocationDetails,
                style: GoogleFonts.syne(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 30,
                  height: 30,
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

          // Hero card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _heroBg,
              borderRadius: BorderRadius.circular(16),
              border:
              Border.fromBorderSide(BorderSide(color: _heroBorder)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.fromBorderSide(
                        BorderSide(color: _heroBorder)),
                  ),
                  child: Icon(_icon, size: 26, color: _iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.name,
                        style: GoogleFonts.syne(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (entry.area.isNotEmpty)
                        Text(
                          entry.area,
                          style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: AppColors.textSecondary),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            entry.category,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _iconColor,
                            ),
                          ),
                          if (entry.available24h) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                '24h',
                                style: GoogleFonts.dmSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF085041),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
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
                _DetailRow(label: 'Phone', value: entry.phone),
                if (entry.address.isNotEmpty)
                  _DetailRow(label: 'Address', value: entry.address),
                if (entry.area.isNotEmpty)
                  _DetailRow(label: 'Area', value: entry.area),
                _DetailRow(
                  label: 'Available',
                  value: entry.available24h ? '24 hours' : 'Check timings',
                  isLast: entry.notes.isEmpty,
                ),
                if (entry.notes.isNotEmpty)
                  _DetailRow(
                      label: 'Notes', value: entry.notes, isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 12),

          if (onDirections != null) ...[
            GestureDetector(
              onTap: onDirections,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: const Border.fromBorderSide(
                      BorderSide(color: AppColors.border)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.directions_rounded,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      AppConfig.dirGetDirections,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

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
                  Text(
                    '${AppConfig.commonCallBtn} ${entry.phone}',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.plannedText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _DetailRow — same as donors screen ───────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLast;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

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
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    )),
              ),
            ],
          ),
        ),
        if (!isLast)
          const Divider(
              height: 1, thickness: 1, color: AppColors.borderSoft),
      ],
    );
  }
}

// ── _DirectoryMapView ─────────────────────────────────────────────────────────

class _DirectoryMapView extends StatefulWidget {
  final List<InfoEntry> entries;
  final void Function(InfoEntry) onEntryTap;

  const _DirectoryMapView({
    required this.entries,
    required this.onEntryTap,
  });

  @override
  State<_DirectoryMapView> createState() => _DirectoryMapViewState();
}

class _DirectoryMapViewState extends State<_DirectoryMapView> {
  final MapController _mapController = MapController();
  InfoEntry? _selectedEntry;

  List<InfoEntry> get _mappable =>
      widget.entries.where((e) => e.lat != null && e.lng != null).toList();

  LatLng get _center {
    if (_mappable.isNotEmpty) {
      return LatLng(_mappable.first.lat!, _mappable.first.lng!);
    }
    return const LatLng(11.0168, 76.9558);
  }

  Color _markerColor(InfoEntry e) {
    switch (e.category) {
      case 'Hospital':
        return AppColors.urgentText;
      case 'Blood Bank':
        return AppColors.primary;
      default:
        return AppColors.moderateText;
    }
  }

  IconData _markerIcon(InfoEntry e) {
    switch (e.category) {
      case 'Hospital':
        return Icons.local_hospital_rounded;
      case 'Blood Bank':
        return Icons.bloodtype_rounded;
      default:
        return Icons.emergency_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: 12.0,
            minZoom: 5,
            maxZoom: 18,
            onTap: (_, __) => setState(() => _selectedEntry = null),
          ),
          children: [
            TileLayer(
              urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.hsblood.bloodconnect',
              maxZoom: 19,
            ),
            MarkerLayer(
              markers: _mappable.map((entry) {
                final isSelected = _selectedEntry?.id == entry.id;
                final color = _markerColor(entry);
                final size = isSelected ? 48.0 : 40.0;
                return Marker(
                  point: LatLng(entry.lat!, entry.lng!),
                  width: size,
                  height: size,
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _selectedEntry = entry),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white,
                            width: isSelected ? 3 : 2),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.35),
                            blurRadius: isSelected ? 12 : 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(_markerIcon(entry),
                          size: isSelected ? 22 : 18,
                          color: Colors.white),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),

        if (_mappable.isEmpty)
          Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: const Border.fromBorderSide(
                    BorderSide(color: AppColors.border)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.map_outlined,
                      size: 32, color: AppColors.textMuted),
                  const SizedBox(height: 10),
                  Text(
                    AppConfig.dirNoLocations,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),

        if (_selectedEntry != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: GestureDetector(
              onTap: () {
                final entry = _selectedEntry!;
                setState(() => _selectedEntry = null);
                widget.onEntryTap(entry);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 15, vertical: 13),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: const Border.fromBorderSide(
                      BorderSide(color: AppColors.border)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedEntry!.name,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (_selectedEntry!.area.isNotEmpty)
                            Text(
                              _selectedEntry!.area,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          Text(
                            _selectedEntry!.phone,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: AppColors.linkColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      AppConfig.dirViewDetails,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded,
                        size: 16, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ── _ViewTogglePill ───────────────────────────────────────────────────────────

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
        padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color:
                active ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color:
                active ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _DirShimmer ───────────────────────────────────────────────────────────────

class _DirShimmer extends StatelessWidget {
  const _DirShimmer();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: const Border.fromBorderSide(
            BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
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
                Container(
                    height: 13, width: 150, color: AppColors.closedBg),
                const SizedBox(height: 5),
                Container(
                    height: 10, width: 100, color: AppColors.closedBg),
                const SizedBox(height: 4),
                Container(
                    height: 10, width: 80, color: AppColors.closedBg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}