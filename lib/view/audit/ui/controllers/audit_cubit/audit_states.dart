import 'package:base/core/enums/enums.dart';
import 'package:base/model/base/request_state.dart';
import 'package:base/model/domain/audit_log_model.dart';

class AuditState extends RequestState {
  const AuditState({super.status, super.message, this.items = const []});

  final List<AuditLogModel> items;

  AuditState copyWith({
    RequestStatus? status,
    String? message,
    List<AuditLogModel>? items,
  }) => AuditState(
    status: status ?? this.status,
    message: message,
    items: items ?? this.items,
  );
}
