import 'package:base/model/domain/audit_log_model.dart';
import '../datasource/audit_data_source.dart';
import 'audit_repository.dart';

class AuditRepositoryImpl implements AuditRepository {
  AuditRepositoryImpl(this._dataSource);

  final AuditDataSource _dataSource;

  @override
  Future<List<AuditLogModel>> getAuditLogs() => _dataSource.getAuditLogs();
}
