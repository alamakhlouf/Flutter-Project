import '../../../core/network/api_client.dart';
import '../models/notification_model.dart';

class NotificationService {
  NotificationService({required this.api});

  final ApiClient api;

  Future<List<NotificationModel>> fetchNotifications() async {
    final response = await api.getJson('/api/notifications', authenticated: true);
    if (response is! List) return [];
    return response
        .whereType<Map>()
        .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<int> fetchUnreadCount() async {
    try {
      final response = await api.getJson('/api/notifications/unread-count', authenticated: true);
      if (response is Map && response['count'] is num) {
        return (response['count'] as num).toInt();
      }
    } catch (_) {}
    return 0;
  }

  Future<void> markAsRead(String id) async {
    await api.patch('/api/notifications/$id/read', authenticated: true);
  }

  Future<void> markAllAsRead() async {
    await api.patch('/api/notifications/read-all', authenticated: true);
  }
}
