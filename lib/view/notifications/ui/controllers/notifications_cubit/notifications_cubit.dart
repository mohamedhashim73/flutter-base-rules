import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:base/core/enums/enums.dart';
import 'package:base/model/domain/app_notification_model.dart';
import 'package:base/view/notifications/data/repository/notifications_repository.dart';
import 'notifications_states.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository) : super(const NotificationsState());
  final NotificationsRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: RequestStatus.loading));
    try {
      emit(
        NotificationsState(
          status: RequestStatus.success,
          items: await _repository.getNotifications(),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: RequestStatus.failure,
          message: error.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }

  Future<void> markRead(String id) async {
    await _repository.markRead(id);
    emit(
      state.copyWith(
        items: state.items
            .map(
              (item) => item.id == id
                  ? AppNotificationModel(
                      id: item.id,
                      title: item.title,
                      body: item.body,
                      category: item.category,
                      targetType: item.targetType,
                      targetId: item.targetId,
                      read: true,
                      createdAtMillis: item.createdAtMillis,
                    )
                  : item,
            )
            .toList(),
      ),
    );
  }
}
