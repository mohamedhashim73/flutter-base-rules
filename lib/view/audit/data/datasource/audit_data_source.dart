import 'package:base/model/domain/audit_log_model.dart';

abstract interface class AuditDataSource {
  Future<List<AuditLogModel>> getAuditLogs();
}
