import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:base/model/base/request_state.dart';
import 'package:http/http.dart' as http;
import 'package:base/core/constants/enums/request_status_enum.dart';
import 'package:base/core/constants/extensions/models_extensions.dart';
import 'package:base/core/errors/errors_msg_handler.dart';
import 'package:base/core/services/api_services.dart';
import 'package:base/model/base/base_response.dart';

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

  static Future<void> execute<S, T extends LoadableResponse, R>({
    required void Function(S state) emit,
    required S Function({String? message, RequestStatus? status}) state,
    required T? Function() current,
    required void Function(T? value) setCurrent,
    required Future<R> Function() request,
    required T Function(R result) fromResponse,
    bool Function(R result)? isSuccess,
    String? Function(R result)? errorMessage,
    T? Function()? cachedCurrent,
    bool refresh = false,
    bool reset = false,
    FutureOr<void> Function(T result)? onSuccess,
  }) async {
    var currentValue = current();
    if (!refresh && !reset && currentValue == null) {
      final cachedValue = cachedCurrent?.call();
      if (cachedValue != null) {
        setCurrent(cachedValue);
        currentValue = cachedValue;
      }
    }
    if (!shouldLoad(currentValue, refresh: refresh, reset: reset)) return;
    if (reset) setCurrent(null);
    emit(state(status: RequestStatus.loading));
    try {
      final result = await request();

      final success = isSuccess?.call(result) ??
          (result is http.Response && result.isSuccess);

      if (!success) {
        final error = errorMessage?.call(result) ??
            (result is http.Response ? _responseError(result) : 'حدث خطأ');
        emit(
          state(
            status: RequestStatus.failure,
            message: error,
          ),
        );
        return;
      }
      final incoming = fromResponse(result);
      final resolved = _resolveResult<T>(
        current: currentValue,
        incoming: incoming,
        refresh: refresh,
        reset: reset,
      );
      setCurrent(resolved);
      await onSuccess?.call(resolved);
      emit(state(status: RequestStatus.success));
    } catch (error) {
      emit(
        state(
          status: RequestStatus.failure,
          message: ErrorHandler.error(error),
        ),
      );
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

  static String _responseError(http.Response response) {
    try {
      return ErrorHandler.error(jsonDecode(response.body));
    } catch (_) {
      return ErrorHandler.error(response.body);
    }
  }

  static Future<void>
  executeAction<BaseState extends RequestState, ActionState extends BaseState, T>({
    required void Function(BaseState state) emit,
    required ActionState Function({
      RequestStatus? status,
      String? message,
      VoidCallback? onDone,
      VoidCallback? onTap,
    })
    state,
    required Future<T> Function() request,
    bool Function(T result)? isSuccess,
    String? Function(T result)? successMessage,
    FutureOr<void> Function(T result)? onSuccess,
    VoidCallback? onTap,
  }) async {
    emit(state(status: RequestStatus.loading));

    try {
      final result = await request();

      final success = isSuccess?.call(result) ??
          (result is http.Response && result.isSuccess);

      if (success) {
        emit(
          state(
            status: RequestStatus.success,
            message: successMessage?.call(result),
            onDone: onSuccess == null
                ? null
                : () async {
                    await onSuccess(result);
                  },
            onTap: onTap,
          ),
        );

        return;
      }

      final errorMessage = result is http.Response
          ? ErrorHandler.error(jsonDecode(result.body))
          : 'حدث خطأ';
      emit(
        state(
          status: RequestStatus.failure,
          message: errorMessage,
          onTap: onTap,
        ),
      );
    } catch (error) {
      emit(
        state(
          status: RequestStatus.failure,
          message: ErrorHandler.error(error),
          onTap: onTap,
        ),
      );
    }
  }
}
