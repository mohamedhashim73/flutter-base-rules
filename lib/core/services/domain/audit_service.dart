import 'package:base/core/constants/constants.dart';
import 'firebase_service.dart';

class AuditService {
  AuditService(this._firebaseService);
  final FirebaseService _firebaseService;

  Future<void> record({
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic> metadata = const {},
    Map<String, dynamic>? previousValues,
    Map<String, dynamic>? newValues,
    String reason = '',
    String? relatedApprovalId,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _firebaseService.newDocumentId();
    return _firebaseService.setDocument(
      collectionName: FirebaseCollections.auditLogs,
      documentId: id,
      data: {
        'id': id,
        'action': action,
        'entityType': entityType,
        'entityId': entityId,
        'metadata': metadata,
        'previousValues': previousValues,
        'newValues': newValues,
        'reason': reason,
        'relatedApprovalId': relatedApprovalId,
        'source': 'client',
        'createdAtMillis': now,
        'createdBy': _firebaseService.currentUserId,
      },
    );
  }
}
