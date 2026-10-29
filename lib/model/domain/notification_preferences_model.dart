import 'package:base/core/utils/parsing_utils.dart';

class NotificationPreferencesModel {
  const NotificationPreferencesModel({
    this.approvals = true,
    this.installments = true,
    this.checks = true,
    this.collections = true,
    this.push = true,
  });

  final bool approvals;
  final bool installments;
  final bool checks;
  final bool collections;
  final bool push;

  factory NotificationPreferencesModel.fromJson(Object? json) =>
      NotificationPreferencesModel(
        approvals: asBoolOr(json, 'approvals', fallback: true),
        installments: asBoolOr(json, 'installments', fallback: true),
        checks: asBoolOr(json, 'checks', fallback: true),
        collections: asBoolOr(json, 'collections', fallback: true),
        push: asBoolOr(json, 'push', fallback: true),
      );

  Map<String, dynamic> toJson() => {
    'approvals': approvals,
    'installments': installments,
    'checks': checks,
    'collections': collections,
    'push': push,
  };

  NotificationPreferencesModel copyWith({
    bool? approvals,
    bool? installments,
    bool? checks,
    bool? collections,
    bool? push,
  }) => NotificationPreferencesModel(
    approvals: approvals ?? this.approvals,
    installments: installments ?? this.installments,
    checks: checks ?? this.checks,
    collections: collections ?? this.collections,
    push: push ?? this.push,
  );
}
