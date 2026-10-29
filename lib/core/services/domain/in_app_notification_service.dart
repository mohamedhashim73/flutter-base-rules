import 'package:base/core/constants/constants.dart';
import 'firebase_service.dart';
import 'notification_preferences_service.dart';

class InAppNotificationService {
  InAppNotificationService(this._firebaseService, this._preferencesService);
  final FirebaseService _firebaseService;
  final NotificationPreferencesService _preferencesService;

  Future<void> create({
    required String title,
    required String body,
    required String category,
    required String targetType,
    required String targetId,
  }) async {
    if (!_preferencesService.enabledFor(
      await _preferencesService.get(),
      category,
    )) {
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final day = DateTime.fromMillisecondsSinceEpoch(now);
    final documentId =
        '${targetType}_${targetId}_${category}_${day.year}_${day.month}_${day.day}';
    final existing = await _firebaseService.getDocument(
      collectionName: FirebaseCollections.notifications,
      documentId: documentId,
    );
    if (existing != null) return;
    await _firebaseService.setDocument(
      collectionName: FirebaseCollections.notifications,
      documentId: documentId,
      data: {
        'title': title,
        'body': body,
        'category': category,
        'targetType': targetType,
        'targetId': targetId,
        'read': false,
        'createdAtMillis': now,
      },
    );
  }
}
