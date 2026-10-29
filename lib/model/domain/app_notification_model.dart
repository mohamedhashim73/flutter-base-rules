import 'package:base/core/utils/parsing_utils.dart';
import 'package:equatable/equatable.dart';

class AppNotificationModel extends Equatable {
  const AppNotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.targetType,
    required this.targetId,
    required this.read,
    required this.createdAtMillis,
  });
  final String id;
  final String title;
  final String body;
  final String category;
  final String targetType;
  final String targetId;
  final bool read;
  final int createdAtMillis;

  factory AppNotificationModel.fromJson(Object? json) => AppNotificationModel(
    id: asStringOr(json, 'id'),
    title: asStringOr(json, 'title'),
    body: asStringOr(json, 'body'),
    category: asStringOr(json, 'category', fallback: 'critical'),
    targetType: asStringOr(json, 'targetType'),
    targetId: asStringOr(json, 'targetId'),
    read: asBoolOr(json, 'read'),
    createdAtMillis: asIntOr(json, 'createdAtMillis'),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'category': category,
    'targetType': targetType,
    'targetId': targetId,
    'read': read,
    'createdAtMillis': createdAtMillis,
  };

  @override
  List<Object?> get props => [id, read, createdAtMillis];
}
