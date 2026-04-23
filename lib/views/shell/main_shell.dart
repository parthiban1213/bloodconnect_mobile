import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/notifications_viewmodel.dart';
import '../../viewmodels/requirements_viewmodel.dart';
import '../../viewmodels/my_requests_viewmodel.dart';
import '../../viewmodels/history_viewmodel.dart';
import '../../viewmodels/donors_viewmodel.dart';
import '../../utils/app_theme.dart';
import '../../utils/app_config.dart';
import '../drawer/app_drawer.dart';

class MainShell extends ConsumerStatefulWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {

  static const _allTabs = [
    _Tab('/home',        Icons.home_outlined,               Icons.home_rounded,               'Home'),
    _Tab('/feed',        Icons.grid_view_outlined,          Icons.grid_view_rounded,          'Feed'),
    _Tab('/my-requests', Icons.bloodtype_outlined,          Icons.bloodtype_rounded,          'Requests'),
    _Tab('/donors',      Icons.volunteer_activism_outlined, Icons.volunteer_activism_rounded, 'Donors'),
  ];

  static Map<String, String> get _titles => AppConfig.shellTitles;

  String _prevLocation = '';

  int _locationToIndex(String location) {
    for (int i = 0; i < _allTabs.length; i++) {
      if (location.startsWith(_allTabs[i].path)) return i;
    }
    return -1;
  }

  String _titleFor(String location) {
    for (final entry in _titles.entries) {
      if (location.startsWith(entry.key)) return entry.value;
    }
    return AppConfig.shellDefaultTitle;
  }

  void _onTabTap(int index) {
    final path = _allTabs[index].path;
    context.go(path);
    _refreshForPath(path);
    _prevLocation = path;
  }

  void _refreshForPath(String path) {
    if (path.startsWith('/feed')) {
      ref.read(requirementsViewModelProvider.notifier).load();
    } else if (path.startsWith('/my-requests')) {
      ref.read(myRequestsViewModelProvider.notifier).load();
    } else if (path.startsWith('/donors')) {
      ref.read(donorsViewModelProvider.notifier).load();
    } else if (path.startsWith('/history')) {
      ref.read(historyViewModelProvider.notifier).load();
    }
  }

  void _onLocationChanged(String location) {
    if (location == _prevLocation) return;
    _prevLocation = location;
    _refreshForPath(location);
  }

  @override
  Widget build(BuildContext context) {
    final location    = GoRouterState.of(context).matchedLocation;
    final currentIdx  = _locationToIndex(location);
    final unreadCount = ref.watch(notificationsViewModelProvider).unreadCount;

    final myReqState   = ref.watch(myRequestsViewModelProvider);
    final pendingCount = myReqState.activeRequests.fold<int>(
      0, (sum, r) => sum + r.pendingCount,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onLocationChanged(location);
    });

    // Back button: home tab exits the app; all other tabs go back to /home.
    final isOnHome = location.startsWith('/home');

    void handleBack() {
      final router = GoRouter.of(context);
      if (router.canPop()) {
        router.pop();
      } else if (isOnHome) {
        SystemNavigator.pop();
      } else {
        context.go('/home');
      }
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) handleBack();
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          systemNavigationBarColor:          Colors.transparent,
          systemNavigationBarIconBrightness: Brightness.dark,
          statusBarColor:                    Colors.transparent,
          statusBarIconBrightness:           Brightness.dark,
        ),
        child: Scaffold(
          backgroundColor: AppColors.background,
          resizeToAvoidBottomInset: false,
          extendBody: true,
          drawer: const AppDrawer(),
          appBar: _GlobalAppBar(
            title: _titleFor(location),
            unreadCount: unreadCount,
            showBack: !isOnHome,
            onBack: handleBack,
          ),
          body: widget.child,
          bottomNavigationBar: _FloatingNav(
            tabs:         _allTabs,
            currentIndex: currentIdx,
            onTabTap:     _onTabTap,
            pendingCount: pendingCount,
            onPost:       () => context.push('/add-requirement'),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Floating Nav — 4 tabs
// ─────────────────────────────────────────────────────────────
class _FloatingNav extends StatelessWidget {
  final List<_Tab> tabs;
  final int currentIndex;
  final ValueChanged<int> onTabTap;
  final int pendingCount;
  final VoidCallback onPost;

  const _FloatingNav({
    required this.tabs,
    required this.currentIndex,
    required this.onTabTap,
    required this.pendingCount,
    required this.onPost,
  });

  static const _pillH = 62.0;
  // FAB diameter — sized to sit flush within the pill height
  static const _fabSize = 46.0;

  @override
  Widget build(BuildContext context) {
    // Split tabs into left half and right half around the FAB
    final leftTabs  = tabs.sublist(0, tabs.length ~/ 2);
    final rightTabs = tabs.sublist(tabs.length ~/ 2);

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: SizedBox(
          height: _pillH,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // ── Nav pill ───────────────────────────────────────────
              Container(
                height: _pillH,
                decoration: BoxDecoration(
                  color: AppColors.navBg,
                  borderRadius: BorderRadius.circular(34),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navBg.withOpacity(0.38),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Left tabs
                    ...leftTabs.map((tab) {
                      final i = tabs.indexOf(tab);
                      final badge = (i == 2 && pendingCount > 0) ? pendingCount : 0;
                      return Expanded(
                        child: _PillTab(
                          icon:       tab.icon,
                          activeIcon: tab.activeIcon,
                          label:      tab.label,
                          active:     currentIndex == i,
                          onTap:      () => onTabTap(i),
                          badgeCount: badge,
                        ),
                      );
                    }),
                    // Centre gap — space reserved for the FAB
                    SizedBox(width: _fabSize + 8),
                    // Right tabs
                    ...rightTabs.map((tab) {
                      final i = tabs.indexOf(tab);
                      final badge = (i == 2 && pendingCount > 0) ? pendingCount : 0;
                      return Expanded(
                        child: _PillTab(
                          icon:       tab.icon,
                          activeIcon: tab.activeIcon,
                          label:      tab.label,
                          active:     currentIndex == i,
                          onTap:      () => onTabTap(i),
                          badgeCount: badge,
                        ),
                      );
                    }),
                  ],
                ),
              ),

              // ── FAB centred over the nav pill ─────────────────────
              GestureDetector(
                onTap: onPost,
                child: Container(
                  width:  _fabSize,
                  height: _fabSize,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.background,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.40),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Colors.white,
                    size: 24,
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
//  Pill tab item
// ─────────────────────────────────────────────────────────────
class _PillTab extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final int badgeCount;

  const _PillTab({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.active,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
        decoration: BoxDecoration(
          color: active ? Colors.white.withOpacity(0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  active ? activeIcon : icon,
                  size: 19,
                  color: active ? Colors.white : Colors.white.withOpacity(0.45),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: GoogleFonts.syne(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: active ? Colors.white : Colors.white.withOpacity(0.45),
                  ),
                ),
              ],
            ),
            if (badgeCount > 0)
              Positioned(
                top: 2,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.navBg, width: 1.5),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: GoogleFonts.syne(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  App Bar
// ─────────────────────────────────────────────────────────────
class _GlobalAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final int unreadCount;
  final bool showBack;
  final VoidCallback? onBack;
  const _GlobalAppBar({
    required this.title,
    required this.unreadCount,
    this.showBack = false,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(54);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      scrolledUnderElevation: 0,
      leadingWidth: 52,
      leading: showBack
          ? GestureDetector(
              onTap: onBack,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.only(left: 16),
                child: Icon(Icons.arrow_back_ios_new_rounded,
                    size: 20, color: AppColors.textPrimary),
              ),
            )
          : Builder(
              builder: (ctx) => GestureDetector(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Bar(18), const SizedBox(height: 4),
                      _Bar(13), const SizedBox(height: 4),
                      _Bar(18),
                    ],
                  ),
                ),
              ),
            ),
      title: Text(
        title,
        style: GoogleFonts.syne(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: GestureDetector(
            onTap: () => context.push('/notifications'),
            behavior: HitTestBehavior.opaque,
            child: _BellWithBadge(unreadCount: unreadCount),
          ),
        ),
      ],
    );
  }
}

class _Bar extends StatelessWidget {
  final double width;
  const _Bar(this.width);
  @override
  Widget build(BuildContext context) => Container(
    width: width, height: 2,
    decoration: BoxDecoration(
      color: AppColors.textPrimary,
      borderRadius: BorderRadius.circular(1),
    ),
  );
}

class _BellWithBadge extends StatelessWidget {
  final int unreadCount;
  const _BellWithBadge({required this.unreadCount});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36, height: 36,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: AppColors.border),
          ),
          child: const Center(
            child: Icon(Icons.notifications_outlined,
                size: 18, color: AppColors.textSecondary),
          ),
        ),
        if (unreadCount > 0)
          Positioned(
            top: 4, right: 4,
            child: Container(
              width: 7, height: 7,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 1),
              ),
            ),
          ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  Data model
// ─────────────────────────────────────────────────────────────
class _Tab {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _Tab(this.path, this.icon, this.activeIcon, this.label);
}
