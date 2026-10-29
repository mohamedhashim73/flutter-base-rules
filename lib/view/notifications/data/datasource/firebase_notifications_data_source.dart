import 'package:base/core/constants/constants.dart';
import 'package:base/core/services/services.dart';
import 'package:base/model/domain/app_notification_model.dart';
import 'notifications_data_source.dart';

class FirebaseNotificationsDataSource implements NotificationsDataSource {
  FirebaseNotificationsDataSource(this._firebaseService);
  final FirebaseService _firebaseService;

  @override
  Future<List<AppNotificationModel>> getNotifications() async {
    final data = await _firebaseService.getCollection(
      collectionName: FirebaseCollections.notifications,
      query: (ref) =>
          ref.orderBy('createdAtMillis', descending: true).limit(100),
    );
    return data.map(AppNotificationModel.fromJson).toList();
  }

  @override
  Future<void> saveNotification(AppNotificationModel notification) =>
      _firebaseService.setDocument(
        collectionName: FirebaseCollections.notifications,
        documentId: notification.id,
        data: notification.toJson(),
      );

  @override
  Future<void> markRead(String notificationId) =>
      _firebaseService.updateDocument(
        collectionName: FirebaseCollections.notifications,
        documentId: notificationId,
        data: {'read': true},
      );
}
