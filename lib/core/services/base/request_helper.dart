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

  static bool shouldLoad(
    LoadableResponse? response, {
    bool refresh = false,
    bool reset = false,
  }) {
    if (refresh || reset) {
      return true;
    }

    if (response == null || response.data == null) {
      return true;
    }

    if (response is PaginatedResponse<dynamic, dynamic>) {
      return response.pagination?.hasNext ?? false;
    }

    return false;
  }

  static bool shouldReplace({
    required Object? current,
    required bool refresh,
    required bool reset,
  }) {
    return current == null || refresh || reset;
  }

  static int nextPage(PaginatedResponse<dynamic, dynamic>? response) {
    return (response?.pagination?.currentPage ?? 0) + 1;
  }

  static String buildEndpoint(String endpoint, {PaginationParams? params}) {
    return Uri.parse(
      endpoint,
    ).replace(queryParameters: params?.toMap()).toString();
  }

  static PaginationParams paginationParams(
    PaginatedResponse<List, dynamic>? response, {
    required bool refresh,
    String? search,
  }) {
    final loadedItems = response?.data?.length ?? ApiServices.perPage;

    return PaginationParams(
      page: refresh ? 1 : nextPage(response),
      perPage: refresh ? loadedItems : ApiServices.perPage,
      search: search,
    );
  }

  static Future<void> execute<S, T extends LoadableResponse>({
    required void Function(S state) emit,
    required S Function({String? message, required RequestStatus status}) state,
    required T? Function() current,
    required void Function(T? value) setCurrent,
    required Future<Response<dynamic>> Function() request,
    required T Function(Response<dynamic> response) fromResponse,
    T? Function()? cachedCurrent,
    bool refresh = false,
    bool reset = false,
    FutureOr<void> Function(T result)? onSuccess,
    RequestLock? lock,
  }) async {
    if (lock != null && !lock.tryAcquire()) {
      return;
    }

    try {
      var currentValue = current();

      if (!shouldLoad(currentValue, refresh: refresh, reset: reset)) {
        return;
      }

      if (!refresh && !reset && currentValue == null) {
        final cachedValue = cachedCurrent?.call();

        if (cachedValue != null) {
          currentValue = cachedValue;
          setCurrent(cachedValue);
          emit(state(status: RequestStatus.success));
        }
      }

      if (reset) {
        currentValue = null;
        setCurrent(null);
      }

      emit(state(status: RequestStatus.loading));

      try {
        final response = await request();

        if (!_isSuccess(response)) {
          emit(
            state(
              status: RequestStatus.failure,
              message: _responseError(response),
            ),
          );
          return;
        }

        final incoming = fromResponse(response);

        final result = _resolveResult<T>(
          current: currentValue,
          incoming: incoming,
          refresh: refresh,
          reset: reset,
        );

        setCurrent(result);

        await onSuccess?.call(result);

        emit(state(status: RequestStatus.success));
      } catch (error) {
        emit(
          state(
            status: RequestStatus.failure,
            message: ErrorHandler.error(error),
          ),
        );
      }
    } finally {
      lock?.release();
    }
  }

  static T _resolveResult<T extends LoadableResponse>({
    required T? current,
    required T incoming,
    required bool refresh,
    required bool reset,
  }) {
    if (incoming is PaginatedResponse<List, dynamic>) {
      return _mergePaginated(
            current: current,
            incoming: incoming,
            refresh: refresh,
            reset: reset,
          )
          as T;
    }

    return incoming;
  }

  static PaginatedResponse<List, dynamic> _mergePaginated({
    required LoadableResponse? current,
    required PaginatedResponse<List, dynamic> incoming,
    required bool refresh,
    required bool reset,
  }) {
    if (shouldReplace(current: current, refresh: refresh, reset: reset)) {
      return incoming;
    }

    final currentPaginated = current as PaginatedResponse<List, dynamic>;

    final currentItems = currentPaginated.data ?? [];
    final incomingItems = incoming.data ?? [];

    final mergedItems = <dynamic>[...currentItems];

    for (final item in incomingItems) {
      if (!mergedItems.contains(item)) {
        mergedItems.add(item);
      }
    }

    return incoming.copyWithPagination(
      data: mergedItems,
      pagination: incoming.pagination,
    );
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
    required Future<Response<dynamic>> Function() request,
    String? Function(Map<String, dynamic> json)? successMessage,
    FutureOr<void> Function(Map<String, dynamic> json)? onSuccess,
    VoidCallback? onTap,
    ActionState Function(ActionState base)? extras,
  }) async {
    emit(state(status: RequestStatus.loading));

    try {
      final response = await request();
      final json = _responseAsMap(response.data);

      if (_isSuccess(response)) {
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

        emit(successState);
        return;
      }

      var failureState = state(
        status: RequestStatus.failure,
        message: ErrorHandler.error(json),
        onTap: onTap,
      );

      if (extras != null) {
        failureState = extras(failureState);
      }

      emit(failureState);
    } catch (error) {
      var errorState = state(
        status: RequestStatus.failure,
        message: ErrorHandler.error(error),
        onTap: onTap,
      );

      if (extras != null) {
        errorState = extras(errorState);
      }

      emit(errorState);
    }
  }

  static bool _isSuccess(Response<dynamic> response) {
    final statusCode = response.statusCode;

    if (statusCode == null) {
      return false;
    }

    return statusCode >= 200 && statusCode < 300;
  }

  static String _responseError(Response<dynamic> response) {
    return ErrorHandler.error(_decodeResponseData(response.data));
  }

  static Map<String, dynamic> _responseAsMap(dynamic data) {
    final decodedData = _decodeResponseData(data);

    if (decodedData is Map<String, dynamic>) {
      return decodedData;
    }

    if (decodedData is Map) {
      return Map<String, dynamic>.from(decodedData);
    }

    return <String, dynamic>{};
  }

  static dynamic _decodeResponseData(dynamic data) {
    if (data == null) {
      return <String, dynamic>{};
    }

    // Dio عادةً يحول JSON تلقائيًا إلى Map أو List.
    if (data is Map || data is List) {
      return data;
    }

    // احتياطًا لو الـ backend أعاد JSON كنص.
    if (data is String) {
      if (data.trim().isEmpty) {
        return <String, dynamic>{};
      }

      try {
        return jsonDecode(data);
      } catch (_) {
        return data;
      }
    }

    return data;
  }
}
