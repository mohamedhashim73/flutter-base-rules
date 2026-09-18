import 'dart:ui';
import 'package:base/core/core.dart';

abstract class RequestState {
  final RequestStatus? status;
  final String? message;
  final VoidCallback? onDone;
  final VoidCallback? onTap;

  const RequestState({this.status, this.message, this.onDone, this.onTap});

  void handleActionState({MsgType? successMsgType}) {
    switch (status) {
      case RequestStatus.failure:
        if (message != null) {
          AppToast.showToast(
            message: message!,
            type: MsgType.error,
            onTap: onTap,
          );
        }
        break;

      case RequestStatus.success:
        onDone?.call();

        if (message != null) {
          AppToast.showToast(
            message: message!,
            type: successMsgType ?? MsgType.success,
            onTap: onTap,
          );
        }
        break;

      case RequestStatus.loading:
      case null:
        break;
    }
  }
}

/// Mixin that marks a state as an "action state" — one that handles its own
/// feedback via handleActionState() and must never affect the page data UI.
/// Any state class that calls handleActionState() should mix this in.
mixin ActionStateMixin on RequestState {}
