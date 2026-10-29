import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class AuditLogModel extends Equatable {
  const AuditLogModel({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.previousValues,
    required this.newValues,
    required this.reason,
    required this.createdBy,
    required this.createdAtMillis,
    required this.source,
  });

  final String id;
  final String action;
  final String entityType;
  final String entityId;
  final Map<String, dynamic> previousValues;
  final Map<String, dynamic> newValues;
  final String reason;
  final String createdBy;
  final int createdAtMillis;
  final String source;

  factory AuditLogModel.fromJson(Object? json) => AuditLogModel(
    id: asStringOr(json, 'id'),
    action: asStringOr(json, 'action'),
    entityType: asStringOr(json, 'entityType'),
    entityId: asStringOr(json, 'entityId'),
    previousValues: asMapOr(json, 'previousValues'),
    newValues: asMapOr(json, 'newValues'),
    reason: asStringOr(json, 'reason'),
    createdBy: asStringOr(json, 'createdBy'),
    createdAtMillis: asIntOr(json, 'createdAtMillis'),
    source: asStringOr(json, 'source', fallback: 'client'),
  );

  @override
  List<Object?> get props => [id, createdAtMillis];
}
