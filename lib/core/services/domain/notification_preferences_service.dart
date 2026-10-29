import 'package:base/core/constants/constants.dart';
import 'package:base/model/domain/notification_preferences_model.dart';
import 'firebase_service.dart';

class NotificationPreferencesService {
  NotificationPreferencesService(this._firebaseService);

  final FirebaseService _firebaseService;

  Future<NotificationPreferencesModel> get() async {
    final data = await _firebaseService.getDocument(
      collectionName: FirebaseCollections.notificationPreferences,
      documentId: 'preferences',
    );
    return NotificationPreferencesModel.fromJson(data);
  }

  Future<void> save(NotificationPreferencesModel preferences) =>
      _firebaseService.setDocument(
        collectionName: FirebaseCollections.notificationPreferences,
        documentId: 'preferences',
        data: preferences.toJson(),
      );

  bool enabledFor(NotificationPreferencesModel preferences, String category) =>
      switch (category) {
        'approval' => preferences.approvals,
        'installment' => preferences.installments,
        'check' => preferences.checks,
        'collection' => preferences.collections,
        _ => true,
      };
}
