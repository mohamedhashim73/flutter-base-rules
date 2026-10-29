import 'package:base/core/enums/enums.dart';
import 'package:base/model/base/request_state.dart';
import 'package:base/model/domain/managed_user_model.dart';

class UsersState extends RequestState {
  const UsersState({
    super.status,
    super.message,
    this.users = const [],
    this.actionStatus,
    this.actionMessage,
  });
  final List<ManagedUserModel> users;
  final RequestStatus? actionStatus;
  final String? actionMessage;
  UsersState copyWith({
    RequestStatus? status,
    String? message,
    List<ManagedUserModel>? users,
    RequestStatus? actionStatus,
    String? actionMessage,
  }) => UsersState(
    status: status ?? this.status,
    message: message,
    users: users ?? this.users,
    actionStatus: actionStatus,
    actionMessage: actionMessage,
  );
}
