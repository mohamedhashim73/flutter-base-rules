import 'package:base/core/constants/constants.dart';
import 'package:base/core/services/services.dart';
import 'package:base/model/domain/audit_log_model.dart';
import 'audit_data_source.dart';

class FirebaseAuditDataSource implements AuditDataSource {
  FirebaseAuditDataSource(this._firebaseService);

  final FirebaseService _firebaseService;

  @override
  Future<List<AuditLogModel>> getAuditLogs() async {
    final data = await _firebaseService.getCollection(
      collectionName: FirebaseCollections.auditLogs,
      query: (ref) =>
          ref.orderBy('createdAtMillis', descending: true).limit(200),
    );
    return data.map(AuditLogModel.fromJson).toList();
  }
}
