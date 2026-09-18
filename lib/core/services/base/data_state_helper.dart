part of '../services.dart';

class DataState<T> {
  final RequestStatus? status;
  final String? error;
  final LoadableResponse<T>? response;

  DataState({
    this.response,
    RequestState? state,
    RequestStatus? status,
    String? error,
  }) : status = state?.status ?? status,
       error = state?.message ?? error;

  bool get isError => status == RequestStatus.failure;

  bool get isLoading => status == RequestStatus.loading;

  bool get isSuccess => status == RequestStatus.success || hasData;

  bool get isEmpty => !hasData;

  bool get hasData {
    final value = response?.data;

    if (value == null) return false;

    if (value is Iterable) return value.isNotEmpty;

    if (value is Map) return value.isNotEmpty;

    if (value is String) return value.isNotEmpty;

    return true;
  }
}
