import '../models/notification_model.dart';
import 'api_client.dart';

class NotificationsService {
  final ApiClient _client = ApiClient.instance;

  Future<({List<NotificationModel> notifications, int unreadCount})>
      getNotifications() async {
    final res = await _client.get('/notifications');
    final data = res['data'] as List<dynamic>? ?? [];
    final notifications = data
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final unreadCount = (res['unreadCount'] as num?)?.toInt() ?? 0;
    return (notifications: notifications, unreadCount: unreadCount);
  }

  Future<void> markAsRead(String id) async {
    await _client.put('/notifications/$id/read');
  }

  Future<void> markAllAsRead() async {
    await _client.put('/notifications/read-all');
  }

  Future<void> deleteNotification(String id) async {
    await _client.delete('/notifications/$id');
  }

  Future<void> clearAllNotifications() async {
    await _client.delete('/notifications');
  }
}
