import 'dart:io';

import 'package:base/core/network/network.dart';
import 'package:playx/playx.dart';
import '../network/api_exception.dart';
import '../network/api_request_options.dart';
import '../network/interceptors/api_logging_interceptor.dart';
import '../network/interceptors/auth_session_interceptor.dart';
import '../network/session_expiry_coordinator.dart';

class ApiServices {
  ApiServices({
    Dio? dio,
    required AccessTokenProvider accessTokenProvider,
    required RefreshTokenProvider refreshTokenProvider,
    required LocaleProvider localeProvider,
    required TokensUpdatedCallback onTokensUpdated,
    required SessionExpiredCallback onSessionExpired,
    Set<int> expiredStatusCodes = const {401, 419},
  }) : _dio = dio ?? Dio() {
    _configureDio();

    _sessionExpiryCoordinator = SessionExpiryCoordinator(
      onSessionExpired: onSessionExpired,
    );

    _dio.interceptors.addAll([
      AuthSessionInterceptor(
        dio: _dio,
        accessTokenProvider: accessTokenProvider,
        refreshTokenProvider: refreshTokenProvider,
        localeProvider: localeProvider,
        onTokensUpdated: onTokensUpdated,
        expiredStatusCodes: expiredStatusCodes,
        sessionExpiryCoordinator: _sessionExpiryCoordinator,
      ),
      ApiLoggingInterceptor(),
    ]);
  }

  static const int perPage = 10;

  final Dio _dio;

  late final SessionExpiryCoordinator _sessionExpiryCoordinator;

  Dio get client => _dio;

  void _configureDio() {
    _dio.options
      ..baseUrl = ApiEndpoints.baseUrl
      ..connectTimeout = const Duration(seconds: 30)
      ..sendTimeout = const Duration(seconds: 30)
      ..receiveTimeout = const Duration(seconds: 30)
      ..contentType = Headers.jsonContentType
      ..headers.addAll({HttpHeaders.acceptHeader: Headers.jsonContentType});
  }

  void resetSessionExpiryGuard() {
    _sessionExpiryCoordinator.reset();
  }

  Future<Response<dynamic>> get({
    required String endpoint,
    Map<String, dynamic>? queryParameters,
    bool validationOn = true,
    bool logIsOn = true,
    bool skipAuth = false,
    bool skipRefresh = false,
    Map<String, dynamic>? extraHeaders,
    CancelToken? cancelToken,
  }) {
    return _request(
      method: 'GET',
      endpoint: endpoint,
      queryParameters: queryParameters,
      validationOn: validationOn,
      logIsOn: logIsOn,
      skipAuth: skipAuth,
      skipRefresh: skipRefresh,
      extraHeaders: extraHeaders,
      cancelToken: cancelToken,
    );
  }

  Future<Response<dynamic>> post({
    required String endpoint,
    Object? body,
    Map<String, dynamic>? queryParameters,
    bool validationOn = true,
    bool logIsOn = true,
    bool skipAuth = false,
    bool skipRefresh = false,
    Map<String, dynamic>? extraHeaders,
    CancelToken? cancelToken,
  }) {
    return _request(
      method: 'POST',
      endpoint: endpoint,
      data: body,
      queryParameters: queryParameters,
      validationOn: validationOn,
      logIsOn: logIsOn,
      skipAuth: skipAuth,
      skipRefresh: skipRefresh,
      extraHeaders: extraHeaders,
      cancelToken: cancelToken,
    );
  }

  Future<Response<dynamic>> put({
    required String endpoint,
    Object? body,
    Map<String, dynamic>? queryParameters,
    bool validationOn = true,
    bool logIsOn = true,
    bool skipAuth = false,
    bool skipRefresh = false,
    Map<String, dynamic>? extraHeaders,
    CancelToken? cancelToken,
  }) {
    return _request(
      method: 'PUT',
      endpoint: endpoint,
      data: body,
      queryParameters: queryParameters,
      validationOn: validationOn,
      logIsOn: logIsOn,
      skipAuth: skipAuth,
      skipRefresh: skipRefresh,
      extraHeaders: extraHeaders,
      cancelToken: cancelToken,
    );
  }

  Future<Response<dynamic>> patch({
    required String endpoint,
    Object? body,
    Map<String, dynamic>? queryParameters,
    bool validationOn = true,
    bool logIsOn = true,
    bool skipAuth = false,
    bool skipRefresh = false,
    Map<String, dynamic>? extraHeaders,
    CancelToken? cancelToken,
  }) {
    return _request(
      method: 'PATCH',
      endpoint: endpoint,
      data: body,
      queryParameters: queryParameters,
      validationOn: validationOn,
      logIsOn: logIsOn,
      skipAuth: skipAuth,
      skipRefresh: skipRefresh,
      extraHeaders: extraHeaders,
      cancelToken: cancelToken,
    );
  }

  Future<Response<dynamic>> delete({
    required String endpoint,
    Object? body,
    Map<String, dynamic>? queryParameters,
    bool validationOn = true,
    bool logIsOn = true,
    bool skipAuth = false,
    bool skipRefresh = false,
    Map<String, dynamic>? extraHeaders,
    CancelToken? cancelToken,
  }) {
    return _request(
      method: 'DELETE',
      endpoint: endpoint,
      data: body,
      queryParameters: queryParameters,
      validationOn: validationOn,
      logIsOn: logIsOn,
      skipAuth: skipAuth,
      skipRefresh: skipRefresh,
      extraHeaders: extraHeaders,
      cancelToken: cancelToken,
    );
  }

  Future<Response<dynamic>> postAsFormData({
    required String endpoint,
    Map<String, dynamic>? fields,
    Map<String, File>? singleFiles,
    Map<String, List<File>>? multipleFiles,
    Map<String, dynamic>? queryParameters,
    bool validationOn = true,
    bool logIsOn = true,
    bool skipAuth = false,
    bool skipRefresh = false,
    Map<String, dynamic>? extraHeaders,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData();

    if (fields != null) {
      for (final entry in fields.entries) {
        final value = entry.value;

        if (value == null) {
          continue;
        }

        if (value is Iterable) {
          for (final item in value) {
            if (item == null) {
              continue;
            }

            formData.fields.add(MapEntry(entry.key, item.toString()));
          }
        } else {
          formData.fields.add(MapEntry(entry.key, value.toString()));
        }
      }
    }

    if (singleFiles != null) {
      for (final entry in singleFiles.entries) {
        final file = entry.value;

        formData.files.add(
          MapEntry(
            entry.key,
            await MultipartFile.fromFile(file.path, filename: _fileName(file)),
          ),
        );
      }
    }

    if (multipleFiles != null) {
      for (final entry in multipleFiles.entries) {
        for (final file in entry.value) {
          formData.files.add(
            MapEntry(
              entry.key,
              await MultipartFile.fromFile(
                file.path,
                filename: _fileName(file),
              ),
            ),
          );
        }
      }
    }

    return _request(
      method: 'POST',
      endpoint: endpoint,
      data: formData,
      queryParameters: queryParameters,
      validationOn: validationOn,
      logIsOn: logIsOn,
      skipAuth: skipAuth,
      skipRefresh: skipRefresh,
      extraHeaders: extraHeaders,
      contentType: Headers.multipartFormDataContentType,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
    );
  }

  Future<Response<dynamic>> _request({
    required String method,
    required String endpoint,
    Object? data,
    Map<String, dynamic>? queryParameters,
    bool validationOn = true,
    bool logIsOn = true,
    bool skipAuth = false,
    bool skipRefresh = false,
    Map<String, dynamic>? extraHeaders,
    String? contentType,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      return await _dio.request<dynamic>(
        endpoint,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          method: method,
          headers: extraHeaders,
          contentType: contentType,
          extra: {
            logIsOnKey: logIsOn,
            validationOnKey: validationOn,
            skipAuthKey: skipAuth,
            skipRefreshKey: skipRefresh,
          },
        ),
      );
    } on DioException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AppNetworkException.fromDioException(error),
        stackTrace,
      );
    }
  }

  String _fileName(File file) {
    final segments = file.uri.pathSegments;

    if (segments.isEmpty) {
      return 'file';
    }

    return segments.last;
  }
}
