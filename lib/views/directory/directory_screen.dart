import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:$phone');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(directoryViewModelProvider);
    final vm = ref.read(directoryViewModelProvider.notifier);

    final categories = AppConfig.directoryCategories
        .map((c) => _Cat(label: c['label']!, key: c['key']!))
        .toList();

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
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConfig.directoryTitle,
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Search
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
                                fontSize: 12, color: AppColors.textPrimary),
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
                  // Category chips
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categories.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 7),
                      itemBuilder: (_, i) {
                        final cat = categories[i];
                        final isActive =
                            state.selectedCategory == cat.key;
                        return GestureDetector(
                          onTap: () => vm.setCategory(cat.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isActive
                                  ? AppColors.primaryDark
                                  : _catBg(cat.key),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.fromBorderSide(BorderSide(
                                color: isActive
                                    ? AppColors.primaryDark
                                    : _catBorder(cat.key),
                                width: 1.5,
                              )),
                            ),
                            child: Text(
                              cat.label,
                              style: GoogleFonts.dmSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isActive
                                    ? Colors.white
                                    : _catTextColor(cat.key),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
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
                          ? const EmptyView(
                              title: AppConfig.directoryEmptyTitle,
                              subtitle:
                                  AppConfig.directoryEmptyBody,
                              icon: Icons.local_hospital_outlined,
                            )
                          : RefreshIndicator(
                              color: AppColors.primary,
                              backgroundColor: Colors.white,
                              onRefresh: () => vm.load(),
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    14, 0, 14, 100),
                                itemCount: state.filtered.length,
                                itemBuilder: (_, i) =>
                                    _DirCard(
                                  entry: state.filtered[i],
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

  Color _catBg(String key) {
    switch (key) {
      case 'Hospital': return AppColors.urgentBg;
      case 'Blood Bank': return AppColors.secondaryLight;
      case 'Ambulance': return AppColors.moderateBg;
      default: return AppColors.background;
    }
  }

  Color _catBorder(String key) {
    switch (key) {
      case 'Hospital': return AppColors.urgentBorder;
      case 'Blood Bank': return const Color(0xFF9FE1CB);
      case 'Ambulance': return AppColors.moderateBorder;
      default: return AppColors.border;
    }
  }

  Color _catTextColor(String key) {
    switch (key) {
      case 'Hospital': return AppColors.urgentText;
      case 'Blood Bank': return const Color(0xFF085041);
      case 'Ambulance': return AppColors.moderateText;
      default: return const Color(0xFF6B6560);
    }
  }
}

class _Cat {
  final String label;
  final String key;
  const _Cat({required this.label, required this.key});
}

class _DirCard extends StatelessWidget {
  final InfoEntry entry;
  final VoidCallback onCall;

  const _DirCard({required this.entry, required this.onCall});

  Color get _iconBg {
    switch (entry.category) {
      case 'Hospital': return AppColors.urgentBg;
      case 'Blood Bank': return AppColors.secondaryLight;
      default: return AppColors.moderateBg;
    }
  }

  Color get _iconColor {
    switch (entry.category) {
      case 'Hospital': return AppColors.urgentText;
      case 'Blood Bank': return const Color(0xFF085041);
      default: return AppColors.moderateText;
    }
  }

  IconData get _icon {
    switch (entry.category) {
      case 'Hospital': return Icons.local_hospital_rounded;
      case 'Blood Bank': return Icons.bloodtype_rounded;
      default: return Icons.emergency_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
    );
  }
}

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
        border: const Border.fromBorderSide(BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 40, height: 40,
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
                Container(height: 13, width: 150, color: AppColors.closedBg),
                const SizedBox(height: 5),
                Container(height: 10, width: 100, color: AppColors.closedBg),
                const SizedBox(height: 4),
                Container(height: 10, width: 80, color: AppColors.closedBg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
