import 'package:base/core/extensions/string_extensions.dart';
import 'package:playx/playx.dart';
import 'package:base/core/enums/notification_type_enum.dart';

class NotificationDataModel {
  final String title;
  final String body;
  final String? titleKey;
  final String? bodyKey;
  final dynamic params;
  final int? orderId;
  final int? refundRequestId;
  final int? requestId;
  final String? status;
  final NotifyType type;
  final String? image;

  const NotificationDataModel({
    required this.title,
    required this.body,
    this.titleKey,
    this.bodyKey,
    this.params,
    this.orderId,
    this.refundRequestId,
    this.requestId,
    this.status,
    required this.type,
    this.image,
  });

  factory NotificationDataModel.fromJson(Map<String, dynamic> json) {
    return NotificationDataModel(
      title: asStringOr(json, 'title'),
      body: asStringOr(json, 'body'),
      titleKey: asStringOrNull(json, 'title_key'),
      bodyKey: asStringOrNull(json, 'body_key'),
      params: json['params'],
      orderId: asIntOrNull(json, 'order_id'),
      refundRequestId: asIntOrNull(json, 'refund_request_id'),
      requestId: asIntOrNull(json, 'request_id'),
      status: asStringOrNull(json, 'status'),
      type: asStringOr(json, 'type').toNotifyType,
      image: asStringOrNull(json, 'image'),
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'body': body,
    'title_key': titleKey,
    'body_key': bodyKey,
    'params': params,
    'order_id': orderId,
    'refund_request_id': refundRequestId,
    'request_id': requestId,
    'status': status,
    'type': type.name,
    'image': image,
  };

  NotificationDataModel copyWith({
    String? title,
    String? body,
    String? titleKey,
    String? bodyKey,
    dynamic params,
    int? orderId,
    int? refundRequestId,
    int? requestId,
    String? status,
    NotifyType? type,
    String? image,
  }) {
    return NotificationDataModel(
      title: title ?? this.title,
      body: body ?? this.body,
      titleKey: titleKey ?? this.titleKey,
      bodyKey: bodyKey ?? this.bodyKey,
      params: params ?? this.params,
      orderId: orderId ?? this.orderId,
      refundRequestId: refundRequestId ?? this.refundRequestId,
      requestId: requestId ?? this.requestId,
      status: status ?? this.status,
      type: type ?? this.type,
      image: image ?? this.image,
    );
  }
}
