import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import '../services/notifications_service.dart';
import '../utils/api_exception.dart';

// ─────────────────────────────────────────────────────────────
//  NotificationsViewModel
//
//  Polls /notifications every 20 s to keep the bell badge
//  count up-to-date. No in-app banner is shown — users see
//  new notifications by opening the Notifications screen or
//  via Firebase push notifications.
// ─────────────────────────────────────────────────────────────

class NotificationsState {
  final bool isLoading;
  final List<NotificationModel> notifications;
  final int unreadCount;
  final String? error;

  const NotificationsState({
    this.isLoading     = false,
    this.notifications = const [],
    this.unreadCount   = 0,
    this.error,
  });

  NotificationsState copyWith({
    bool? isLoading,
    List<NotificationModel>? notifications,
    int? unreadCount,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      isLoading:     isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      unreadCount:   unreadCount ?? this.unreadCount,
      error:         clearError ? null : (error ?? this.error),
    );
  }
}

class NotificationsViewModel extends StateNotifier<NotificationsState> {
  final NotificationsService _service = NotificationsService();
  Timer? _pollTimer;

  NotificationsViewModel() : super(const NotificationsState()) {
    load();
    _startPolling();
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final result = await _service.getNotifications();
      state = state.copyWith(
        notifications: result.notifications,
        unreadCount:   result.unreadCount,
      );
    } catch (_) {
      // Silent poll — never surface errors
    }
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _service.getNotifications();
      state = state.copyWith(
        isLoading:     false,
        notifications: result.notifications,
        unreadCount:   result.unreadCount,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
          isLoading: false, error: 'Failed to load notifications.');
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _service.markAsRead(id);
      final updated = state.notifications.map((n) {
        return n.id == id && !n.isRead ? n.copyWith(isRead: true) : n;
      }).toList();
      state = state.copyWith(
        notifications: updated,
        unreadCount:   updated.where((n) => !n.isRead).length,
      );
    } catch (_) {}
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      final updated =
          state.notifications.map((n) => n.copyWith(isRead: true)).toList();
      state = state.copyWith(notifications: updated, unreadCount: 0);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  Future<void> deleteNotification(String id) async {
    try {
      await _service.deleteNotification(id);
      final updated = state.notifications.where((n) => n.id != id).toList();
      state = state.copyWith(
        notifications: updated,
        unreadCount:   updated.where((n) => !n.isRead).length,
      );
    } catch (_) {}
  }

  Future<void> clearAll() async {
    try {
      await _service.clearAllNotifications();
      state = state.copyWith(notifications: [], unreadCount: 0);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}

final notificationsViewModelProvider =
    StateNotifierProvider<NotificationsViewModel, NotificationsState>(
        (_) => NotificationsViewModel());
