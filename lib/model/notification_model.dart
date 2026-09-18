import 'package:base/core/utils/utils.dart';
import 'package:base/model/notification_data_model.dart';

class NotificationModel extends Equatable {
  final String id;
  final NotificationDataModel data;
  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationModel({
    required this.id,
    required this.data,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: asStringOr(json, 'id'),
      data: NotificationDataModel.fromJson(asMapOr(json, 'data')),
      createdAt: asLocalDateTimeOrNull(json, 'created_at') ?? DateTime.now(),
      readAt: asLocalDateTimeOrNull(json, 'read_at'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'data': data.toJson(),
    'created_at': createdAt.toIso8601String(),
    'read_at': readAt?.toIso8601String(),
  };

  NotificationModel copyWith({
    String? id,
    NotificationDataModel? data,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  @override
  List<Object?> get props => [id];
}
