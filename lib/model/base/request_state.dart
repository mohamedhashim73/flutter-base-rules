import 'dart:ui';
import 'package:base/core/widgets/custom_dialogs_widget/show_snack_bar.dart';
import 'package:base/core/enums/msg_type_enum.dart';
import 'package:base/core/enums/request_status_enum.dart';


abstract class RequestState {
  final RequestStatus? status;
  final String? message;
  final VoidCallback? onDone;
  final VoidCallback? onTap;

  const RequestState({
    this.status,
    this.message,
    this.onDone,
    this.onTap,
  });

  void handleActionState({
    MsgType? successMsgType,
  }) {
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
