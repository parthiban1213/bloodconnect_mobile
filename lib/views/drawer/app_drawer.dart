import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authViewModelProvider).user;

    return Drawer(
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ───────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
              decoration: const BoxDecoration(
                color: AppColors.navBg,
                borderRadius:
                    BorderRadius.only(topRight: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        user?.initials ?? '?',
                        style: GoogleFonts.syne(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.displayName ?? 'User',
                    style: GoogleFonts.syne(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      if (user?.bloodType.isNotEmpty == true) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            user!.bloodType,
                            style: GoogleFonts.syne(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          user?.email ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: const Color(0xFF566080),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // ── Nav items ─────────────────────────────────
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                children: [
                  _Item(
                    icon: Icons.grid_view_rounded,
                    label: AppConfig.drawerFeed,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/feed');
                    },
                  ),
                  _Item(
                    icon: Icons.bloodtype_outlined,
                    label: AppConfig.drawerMyRequests,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/my-requests');
                    },
                  ),
                  _Item(
                    icon: Icons.history_rounded,
                    label: AppConfig.drawerHistory,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/history');
                    },
                  ),
                  _Item(
                    icon: Icons.people_outline_rounded,
                    label: AppConfig.drawerDonorDirectory,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/directory');
                    },
                  ),
                  _Item(
                    icon: Icons.notifications_outlined,
                    label: AppConfig.drawerNotifications,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/notifications');
                    },
                  ),
                  // Support — navigates to in-app support screen
                  _Item(
                    icon: Icons.help_outline_rounded,
                    label: AppConfig.drawerSupport,
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/support'); // push so user can go back
                    },
                  ),
                  // ── How It Works ─────────────────────────────
                  _HowItWorksItem(
                    onTap: () {
                      Navigator.pop(context);
                      context.push('/how-it-works');
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 6),
                    child: Divider(
                        color: AppColors.border, height: 1, thickness: 1),
                  ),
                  _Item(
                    icon: Icons.person_outline_rounded,
                    label: AppConfig.drawerMyProfile,
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/profile');
                    },
                  ),
                ],
              ),
            ),

            // ── Sign Out ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Divider(
                  color: AppColors.border, height: 1, thickness: 1),
            ),
            _Item(
              icon: Icons.logout_rounded,
              label: AppConfig.drawerSignOut,
              textColor: AppColors.primary,
              iconColor: AppColors.primary,
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authViewModelProvider.notifier).logout();
              },
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}

// ── How It Works special drawer item ─────────────────────────

class _HowItWorksItem extends StatelessWidget {
  final VoidCallback onTap;
  const _HowItWorksItem({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.urgentBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.urgentBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.route_rounded,
                  size: 15,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConfig.drawerHowItWorks,
                      style: GoogleFonts.syne(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                    Text(
                      AppConfig.drawerHowItWorksSub,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: AppColors.urgentText,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const _Item({
    required this.icon,
    required this.label,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: iconColor ?? AppColors.textSecondary),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.syne(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
