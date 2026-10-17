part of '../services.dart';

class RequestLock {
  bool _isLocked = false;

  bool tryAcquire() {
    if (_isLocked) {
      return false;
    }

    _isLocked = true;
    return true;
  }

  void release() {
    _isLocked = false;
  }
}

class RequestHelper {
  const RequestHelper._();

  static Future<void> execute<S, T extends LoadableResponse>({
    required void Function(S state) emit,
    required S Function({String? message, required RequestStatus status}) state,
    required T? Function() current,
    required void Function(T? value) setCurrent,
    required Future<BackendResult<ApiResponse<Object?>>> Function() request,
    required T Function(ApiResponse<Object?> response) fromResponse,
    T? Function()? cachedCurrent,
    bool refresh = false,
    bool reset = false,
    FutureOr<void> Function(T result)? onSuccess,
    RequestLock? lock,
    bool Function()? isClosed,
  }) async {
    if (lock != null && !lock.tryAcquire()) {
      return;
    }

    try {
      var currentValue = current();

      if (!currentValue.shouldLoad(refresh: refresh, reset: reset)) {
        return;
      }

      if (!refresh && !reset && currentValue == null) {
        final cachedValue = cachedCurrent?.call();

        if (cachedValue != null) {
          currentValue = cachedValue;
          setCurrent(cachedValue);
          _emitIfOpen(
            emit,
            state(status: RequestStatus.success),
            isClosed: isClosed,
          );
        }
      }

      if (reset) {
        currentValue = null;
        setCurrent(null);
      }

      _emitIfOpen(
        emit,
        state(status: RequestStatus.loading),
        isClosed: isClosed,
      );

      try {
        final response = await request();

        final apiResponse = response.data;
        if (apiResponse == null) {
          _emitIfOpen(
            emit,
            state(
              status: RequestStatus.failure,
              message: response.failure?.safeMessage,
            ),
            isClosed: isClosed,
          );
          return;
        }

        final incoming = fromResponse(apiResponse);

        final result = currentValue.mergeIncoming(
          incoming,
          refresh: refresh,
          reset: reset,
        );

        setCurrent(result);

        await onSuccess?.call(result);

        _emitIfOpen(
          emit,
          state(status: RequestStatus.success),
          isClosed: isClosed,
        );
      } catch (error) {
        _emitIfOpen(
          emit,
          state(
            status: RequestStatus.failure,
            message: ErrorHandler.error(error),
          ),
          isClosed: isClosed,
        );
      }
    } finally {
      lock?.release();
    }
  }

  static Future<void>
  executeAction<BaseState extends RequestState, ActionState extends BaseState>({
    required void Function(BaseState state) emit,
    required ActionState Function({
      required RequestStatus status,
      String? message,
      VoidCallback? onDone,
      VoidCallback? onTap,
    })
    state,
    required Future<BackendResult<ApiResponse<Object?>>> Function() request,
    String? Function(Map<String, dynamic> json)? successMessage,
    FutureOr<void> Function(Map<String, dynamic> json)? onSuccess,
    VoidCallback? onTap,
    ActionState Function(ActionState base)? extras,
    bool Function()? isClosed,
  }) async {
    _emitIfOpen(emit, state(status: RequestStatus.loading), isClosed: isClosed);

    try {
      final response = await request();
      final apiResponse = response.data;
      final json = _responseAsMap(apiResponse?.data);

      if (apiResponse != null) {
        await onSuccess?.call(json);

        var successState = state(
          status: RequestStatus.success,
          message: successMessage?.call(json),
          onDone: null,
          onTap: onTap,
        );

        if (extras != null) {
          successState = extras(successState);
        }

        _emitIfOpen(emit, successState, isClosed: isClosed);
        return;
      }

      var failureState = state(
        status: RequestStatus.failure,
        message: response.failure?.safeMessage ?? ErrorHandler.error(json),
        onTap: onTap,
      );

      if (extras != null) {
        failureState = extras(failureState);
      }

      _emitIfOpen(emit, failureState, isClosed: isClosed);
    } catch (error) {
      var errorState = state(
        status: RequestStatus.failure,
        message: ErrorHandler.error(error),
        onTap: onTap,
      );

      if (extras != null) {
        errorState = extras(errorState);
      }

      _emitIfOpen(emit, errorState, isClosed: isClosed);
    }
  }

  static Map<String, dynamic> _responseAsMap(Object? data) =>
      data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};

  static void _emitIfOpen<S>(
    void Function(S state) emit,
    S state, {
    required bool Function()? isClosed,
  }) {
    if (isClosed?.call() != true) {
      emit(state);
    }
  }
}
