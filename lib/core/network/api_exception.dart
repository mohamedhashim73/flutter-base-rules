import 'package:playx/playx.dart';

enum ApiExceptionType {
  connectionTimeout,
  sendTimeout,
  receiveTimeout,
  noInternet,
  badResponse,
  cancelled,
  badCertificate,
  unknown,
}

class AppNetworkException implements Exception {
  const AppNetworkException({
    required this.type,
    required this.message,
    this.statusCode,
    this.data,
    this.originalException,
  });

  final ApiExceptionType type;
  final String message;
  final int? statusCode;
  final Object? data;
  final DioException? originalException;

  bool get isUnauthorized => statusCode == 401 || statusCode == 419;

  bool get isServerError => statusCode != null && statusCode! >= 500;

  factory AppNetworkException.fromDioException(DioException exception) {
    final statusCode = exception.response?.statusCode;
    final responseData = exception.response?.data;

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
        return AppNetworkException(
          type: ApiExceptionType.connectionTimeout,
          message: 'Connection timeout',
          originalException: exception,
        );

      case DioExceptionType.sendTimeout:
        return AppNetworkException(
          type: ApiExceptionType.sendTimeout,
          message: 'Send timeout',
          originalException: exception,
        );

      case DioExceptionType.receiveTimeout:
        return AppNetworkException(
          type: ApiExceptionType.receiveTimeout,
          message: 'Receive timeout',
          originalException: exception,
        );

      case DioExceptionType.transformTimeout:
        return AppNetworkException(
          type: ApiExceptionType.receiveTimeout,
          message: 'Response processing timeout',
          originalException: exception,
        );

      case DioExceptionType.connectionError:
        return AppNetworkException(
          type: ApiExceptionType.noInternet,
          message: 'No internet connection',
          originalException: exception,
        );

      case DioExceptionType.badResponse:
        return AppNetworkException(
          type: ApiExceptionType.badResponse,
          message: _extractErrorMessage(
            data: responseData,
            fallback: exception.message,
          ),
          statusCode: statusCode,
          data: responseData,
          originalException: exception,
        );

      case DioExceptionType.cancel:
        return AppNetworkException(
          type: ApiExceptionType.cancelled,
          message: 'Request cancelled',
          originalException: exception,
        );

      case DioExceptionType.badCertificate:
        return AppNetworkException(
          type: ApiExceptionType.badCertificate,
          message: 'Invalid server certificate',
          originalException: exception,
        );

      case DioExceptionType.unknown:
        return AppNetworkException(
          type: ApiExceptionType.unknown,
          message: _extractErrorMessage(
            data: responseData,
            fallback: exception.message,
          ),
          statusCode: statusCode,
          data: responseData,
          originalException: exception,
        );
    }
  }

  static String _extractErrorMessage({
    required Object? data,
    String? fallback,
  }) {
    if (data is Map) {
      final errors = data['errors'];

      if (errors is List && errors.isNotEmpty) {
        final firstError = errors.first;

        if (firstError is Map) {
          final errorMessage = firstError['message'];

          if (errorMessage is String && errorMessage.trim().isNotEmpty) {
            return errorMessage;
          }
        }
      }

      const keys = ['message', 'error', 'detail', 'description'];

      for (final key in keys) {
        final value = data[key];

        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }
    }

    if (fallback != null && fallback.trim().isNotEmpty) {
      return fallback;
    }

    return 'Something went wrong';
  }

  @override
  String toString() {
    return 'ApiException('
        'type: $type, '
        'statusCode: $statusCode, '
        'message: $message'
        ')';
  }
}
