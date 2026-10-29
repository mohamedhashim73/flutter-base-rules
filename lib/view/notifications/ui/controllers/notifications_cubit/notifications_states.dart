import 'package:base/model/base/request_state.dart';
import 'package:base/model/domain/app_notification_model.dart';
import 'package:base/core/enums/enums.dart';

class NotificationsState extends RequestState {
  const NotificationsState({
    super.status,
    super.message,
    this.items = const [],
  });
  final List<AppNotificationModel> items;
  int get unreadCount => items.where((item) => !item.read).length;
  NotificationsState copyWith({
    RequestStatus? status,
    String? message,
    List<AppNotificationModel>? items,
  }) => NotificationsState(
    status: status ?? this.status,
    message: message,
    items: items ?? this.items,
  );
}
