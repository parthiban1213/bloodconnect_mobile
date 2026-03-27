import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../viewmodels/notifications_viewmodel.dart';
import '../../models/notification_model.dart';
import '../../utils/app_extensions.dart';
import '../../utils/app_theme.dart';
import '../../widgets/app_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsViewModelProvider);
    final vm = ref.read(notificationsViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Blood alerts',
                            style: GoogleFonts.dmSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Notifications',
                            style: GoogleFonts.dmSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (state.notifications.isNotEmpty)
                        GestureDetector(
                          onTap: () => vm.markAllAsRead(),
                          child: Text(
                            'Mark all read',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (state.unreadCount > 0) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.circle,
                              size: 6, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            '${state.unreadCount} unread',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: state.isLoading
                  ? ListView.builder(
                      padding:
                          const EdgeInsets.fromLTRB(14, 0, 14, 100),
                      itemCount: 5,
                      itemBuilder: (_, __) => const _NotifShimmer(),
                    )
                  : state.error != null
                      ? ErrorView(
                          message: state.error!,
                          onRetry: () => vm.load(),
                        )
                      : state.notifications.isEmpty
                          ? const EmptyView(
                              title: 'No notifications yet',
                              subtitle:
                                  'You\'ll be notified when blood requests match your type.',
                              icon: Icons.notifications_none_rounded,
                            )
                          : RefreshIndicator(
                              color: AppColors.primary,
                              backgroundColor: Colors.white,
                              onRefresh: () => vm.load(),
                              child: ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                    14, 0, 14, 100),
                                itemCount: state.notifications.length,
                                itemBuilder: (_, i) {
                                  final n = state.notifications[i];
                                  return _NotifCard(
                                    notification: n,
                                    onTap: () {
                                      if (!n.isRead) vm.markAsRead(n.id);
                                      if (n.requirementId != null) {
                                        context.push(
                                            '/requirement/${n.requirementId}');
                                      }
                                    },
                                    onDismiss: () =>
                                        vm.deleteNotification(n.id),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotifCard({
    required this.notification,
    required this.onTap,
    required this.onDismiss,
  });

  Color get _iconBg {
    final bt = notification.bloodType;
    if (bt.isEmpty) return AppColors.plannedBg;
    // Use type-based color loosely
    return notification.type == 'requirement'
        ? AppColors.urgentBg
        : AppColors.plannedBg;
  }

  Color get _iconColor {
    return notification.type == 'requirement'
        ? AppColors.urgentText
        : AppColors.plannedText;
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        onDismiss();
        return true;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.urgentBg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded,
            color: AppColors.urgentText),
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : const Color(0xFFFFFCFA),
            borderRadius: BorderRadius.circular(18),
            border: Border.fromBorderSide(BorderSide(
              color: notification.isRead
                  ? AppColors.border
                  : AppColors.urgentBorder,
            )),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  notification.bloodType.isNotEmpty
                      ? Icons.bloodtype_rounded
                      : Icons.notifications_rounded,
                  size: 16,
                  color: _iconColor,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      notification.message,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.createdAt.timeAgo,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: AppColors.textVeryMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead)
                Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotifShimmer extends StatelessWidget {
  const _NotifShimmer();

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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.closedBg,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 12, width: 160, color: AppColors.closedBg),
                const SizedBox(height: 6),
                Container(height: 10, width: double.infinity, color: AppColors.closedBg),
                const SizedBox(height: 4),
                Container(height: 10, width: 100, color: AppColors.closedBg),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
