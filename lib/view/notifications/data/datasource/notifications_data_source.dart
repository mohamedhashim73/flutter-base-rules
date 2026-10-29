import 'package:base/model/domain/app_notification_model.dart';

abstract interface class NotificationsDataSource {
  Future<List<AppNotificationModel>> getNotifications();
  Future<void> saveNotification(AppNotificationModel notification);
  Future<void> markRead(String notificationId);
}
