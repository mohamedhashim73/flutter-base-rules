import 'package:base/core/services/services.dart';
import 'package:base/model/domain/audit_log_model.dart';

class AuditResponseModel implements LoadableResponse<List<AuditLogModel>> {
  const AuditResponseModel(this.data);

  @override
  final List<AuditLogModel> data;
}
