import 'package:base/model/domain/audit_log_model.dart';

abstract interface class AuditRepository {
  Future<List<AuditLogModel>> getAuditLogs();
}
