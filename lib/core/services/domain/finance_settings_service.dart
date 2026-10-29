import 'package:base/core/constants/constants.dart';
import 'firebase_service.dart';

class FinanceSettingsService {
  FinanceSettingsService(this._firebaseService);
  final FirebaseService _firebaseService;
  static const defaultApprovalThresholdMinor = 500000;
  static const defaultReminderDays = 3;

  Future<int> getApprovalThresholdMinor() async {
    final data = await _firebaseService.getDocument(
      collectionName: FirebaseCollections.systemSettings,
      documentId: 'finance',
    );
    final value = data?['approvalThresholdMinor'];
    return value is num ? value.toInt() : defaultApprovalThresholdMinor;
  }

  Future<void> saveApprovalThresholdMinor(int value) {
    return _firebaseService.setDocument(
      collectionName: FirebaseCollections.systemSettings,
      documentId: 'finance',
      data: {
        'approvalThresholdMinor': value,
        'updatedAtMillis': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  Future<Map<String, int>> getNotificationSettings() async {
    final data = await _firebaseService.getDocument(
      collectionName: FirebaseCollections.systemSettings,
      documentId: 'finance',
    );
    return {
      'installmentReminderDays': _readDays(
        data?['installmentReminderDays'],
      ),
      'checkReminderDays': _readDays(data?['checkReminderDays']),
    };
  }

  Future<void> saveNotificationSettings({
    required int installmentReminderDays,
    required int checkReminderDays,
  }) {
    return _firebaseService.setDocument(
      collectionName: FirebaseCollections.systemSettings,
      documentId: 'finance',
      data: {
        'installmentReminderDays': installmentReminderDays,
        'checkReminderDays': checkReminderDays,
        'updatedAtMillis': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  int _readDays(Object? value) {
    final days = value is num ? value.toInt() : int.tryParse('$value');
    return days != null && days >= 0 && days <= 60
        ? days
        : defaultReminderDays;
  }
}
