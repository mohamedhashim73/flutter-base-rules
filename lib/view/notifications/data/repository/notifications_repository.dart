import 'package:base/model/domain/app_notification_model.dart';

abstract interface class NotificationsRepository {
  Future<List<AppNotificationModel>> getNotifications();
  Future<void> markRead(String notificationId);
}
