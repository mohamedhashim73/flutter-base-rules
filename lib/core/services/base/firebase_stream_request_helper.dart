import 'dart:async';
import 'dart:ui';

import 'package:base/core/enums/request_status_enum.dart';
import 'package:base/core/errors/errors_msg_handler.dart';
import 'package:base/core/services/base/request_helper.dart';
import 'package:base/model/base/base_response.dart';
import 'package:base/model/base/request_state.dart';

class FirebaseStreamManager {
  StreamSubscription? _subscription;

  void listen<S extends RequestState, T extends LoadableResponse, R>({
    required void Function(S state) emit,
    required S Function({String? message, RequestStatus? status}) state,
    required T? Function() current,
    bool refresh = false,
    bool reset = false,
    VoidCallback? onReset,
    required Stream<R> Function() stream,
    required void Function(R event) onData,
  }) {
    if (!RequestHelper.shouldLoad(current(), refresh: refresh, reset: reset)) {
      return;
    }

    if (reset) {
      onReset?.call();
    }

    _subscription?.cancel();

    emit(state(status: RequestStatus.loading));

    _subscription = stream().listen(
      (event) {
        onData(event);
        emit(state(status: RequestStatus.success));
      },
      onError: (e) {
        emit(
          state(status: RequestStatus.failure, message: ErrorHandler.error(e)),
        );
      },
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
