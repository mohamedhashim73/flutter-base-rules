import 'dart:io';
import 'package:base/core/network/network.dart';
import 'package:base/core/services/logging_service.dart';
import 'package:playx/playx.dart';
import '../api_request_options.dart';
import '../session_expiry_coordinator.dart';

typedef AccessTokenProvider = String? Function();
typedef RefreshTokenProvider = String? Function();
typedef LocaleProvider = String Function();

typedef TokensUpdatedCallback =
    Future<void> Function({required String accessToken, String? refreshToken});

class AuthSessionInterceptor extends QueuedInterceptor {
  AuthSessionInterceptor({
    required Dio dio,
    required this.accessTokenProvider,
    required this.refreshTokenProvider,
    required this.localeProvider,
    required this.onTokensUpdated,
    required this.expiredStatusCodes,
    required this.sessionExpiryCoordinator,
  }) : _dio = dio,
       _refreshDio = Dio(
         BaseOptions(
           baseUrl: dio.options.baseUrl,
           connectTimeout: dio.options.connectTimeout,
           sendTimeout: dio.options.sendTimeout,
           receiveTimeout: dio.options.receiveTimeout,
           contentType: Headers.jsonContentType,
           headers: {HttpHeaders.acceptHeader: Headers.jsonContentType},
         ),
       );

  final Dio _dio;
  final Dio _refreshDio;

  final AccessTokenProvider accessTokenProvider;
  final RefreshTokenProvider refreshTokenProvider;
  final LocaleProvider localeProvider;
  final TokensUpdatedCallback onTokensUpdated;
  final Set<int> expiredStatusCodes;
  final SessionExpiryCoordinator sessionExpiryCoordinator;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['X-Locale'] = localeProvider();

    final skipAuth = options.extra[skipAuthKey] == true;

    if (!skipAuth) {
      final accessToken = accessTokenProvider();

      if (accessToken != null && accessToken.trim().isNotEmpty) {
        options.headers[HttpHeaders.authorizationHeader] =
            'Bearer $accessToken';

        options.extra[requestTokenKey] = accessToken;
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final requestOptions = err.requestOptions;
    final statusCode = err.response?.statusCode;

    final validationOn = requestOptions.extra[validationOnKey] != false;

    final skipRefresh = requestOptions.extra[skipRefreshKey] == true;

    final isRetryRequest = requestOptions.extra[isRetryRequestKey] == true;

    final isSessionExpired =
        validationOn &&
        statusCode != null &&
        expiredStatusCodes.contains(statusCode);

    if (!isSessionExpired || skipRefresh || isRetryRequest) {
      handler.next(err);
      return;
    }

    final refreshToken = refreshTokenProvider();

    if (refreshToken == null || refreshToken.trim().isEmpty) {
      await _expireSession(requestOptions);
      handler.next(err);
      return;
    }

    try {
      final refreshed = await _refreshToken(refreshToken);

      if (!refreshed) {
        await _expireSession(requestOptions);
        handler.next(err);
        return;
      }

      final newAccessToken = accessTokenProvider();

      if (newAccessToken == null || newAccessToken.trim().isEmpty) {
        await _expireSession(requestOptions);
        handler.next(err);
        return;
      }

      final response = await _retryRequest(
        requestOptions,
        accessToken: newAccessToken,
      );

      handler.resolve(response);
    } catch (_) {
      await _expireSession(requestOptions);
      handler.next(err);
    }
  }

  Future<bool> _refreshToken(String refreshToken) async {
    try {
      LoggingService.showMsg(
        '=========== Start Calling Token refresh API =========== ',
      );
      final response = await _refreshDio.post<dynamic>(
        ApiEndpoints.refreshToken,
        data: {'refresh_token': refreshToken},
        options: Options(headers: {'X-Locale': localeProvider()}),
      );
      LoggingService.showMsg(
        '=========== Token refresh API called successfully ===========',
      );

      final responseJson = _asMap(response.data);

      final nestedData = _asMap(responseJson['data']);

      final tokenData = nestedData.isNotEmpty ? nestedData : responseJson;

      final newAccessToken = tokenData['access_token']?.toString();

      final newRefreshToken = tokenData['refresh_token']?.toString();

      if (newAccessToken == null || newAccessToken.trim().isEmpty) {
        return false;
      }

      await onTokensUpdated(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken?.trim().isNotEmpty == true
            ? newRefreshToken
            : null,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Response<dynamic>> _retryRequest(
    RequestOptions requestOptions, {
    required String accessToken,
  }) {
    final headers = Map<String, dynamic>.from(requestOptions.headers);

    headers[HttpHeaders.authorizationHeader] = 'Bearer $accessToken';

    final extra = Map<String, dynamic>.from(requestOptions.extra);

    extra[isRetryRequestKey] = true;
    extra[requestTokenKey] = accessToken;

    return _dio.request<dynamic>(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      cancelToken: requestOptions.cancelToken,
      options: Options(
        method: requestOptions.method,
        headers: headers,
        extra: extra,
        contentType: requestOptions.contentType,
        responseType: requestOptions.responseType,
        followRedirects: requestOptions.followRedirects,
        receiveDataWhenStatusError: requestOptions.receiveDataWhenStatusError,
        validateStatus: requestOptions.validateStatus,
        sendTimeout: requestOptions.sendTimeout,
        receiveTimeout: requestOptions.receiveTimeout,
      ),
    );
  }

  Future<void> _expireSession(RequestOptions requestOptions) async {
    final requestToken = requestOptions.extra[requestTokenKey] as String?;

    try {
      await sessionExpiryCoordinator.handle(requestToken: requestToken);
    } catch (_) {}
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return <String, dynamic>{};
  }
}
