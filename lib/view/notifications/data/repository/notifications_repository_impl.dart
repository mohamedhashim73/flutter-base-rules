import 'package:base/model/domain/app_notification_model.dart';
import '../datasource/notifications_data_source.dart';
import 'notifications_repository.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  NotificationsRepositoryImpl(this._dataSource);
  final NotificationsDataSource _dataSource;
  @override
  Future<List<AppNotificationModel>> getNotifications() =>
      _dataSource.getNotifications();
  @override
  Future<void> markRead(String notificationId) =>
      _dataSource.markRead(notificationId);
}
