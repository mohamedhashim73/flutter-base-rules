import 'dart:io';
import 'package:playx/playx.dart';
import '../../services/logging_service.dart';
import '../api_request_options.dart';

class ApiLoggingInterceptor extends Interceptor {
  static const int _maximumBodyLength = 3000;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final logIsOn = options.extra[logIsOnKey] == true;

    LoggingService.showMsg('''
➡️ API Request
Method: ${options.method}
URL: ${options.uri}
Headers: ${_safeHeaders(options.headers)}
Query: ${options.queryParameters}
Body: ${_safeBody(options.data)}
''', isOn: logIsOn);

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;
    final logIsOn = options.extra[logIsOnKey] == true;

    LoggingService.showMsg('''
✅ API Response
Method: ${options.method}
URL: ${options.uri}
Status Code: ${response.statusCode}
Response: ${_truncate(response.data)}
''', isOn: logIsOn);

    handler.next(response);
  }

  @override
  void onError(DioException dioError, ErrorInterceptorHandler handler) {
    final options = dioError.requestOptions;
    final logIsOn = options.extra[logIsOnKey] == true;

    LoggingService.showMsg('''
❌ API Error
Method: ${options.method}
URL: ${options.uri}
Status Code: ${dioError.response?.statusCode}
Type: ${dioError.type}
Message: ${dioError.message}
Response: ${_truncate(dioError.response?.data)}
''', isOn: logIsOn);

    handler.next(dioError);
  }

  Map<String, dynamic> _safeHeaders(Map<String, dynamic> headers) {
    final safeHeaders = Map<String, dynamic>.from(headers);

    for (final key in safeHeaders.keys.toList()) {
      if (key.toLowerCase() == HttpHeaders.authorizationHeader.toLowerCase()) {
        safeHeaders[key] = 'Bearer ***';
      }
    }

    return safeHeaders;
  }

  Object? _safeBody(Object? body) {
    if (body is! FormData) {
      return _truncate(body);
    }

    return {
      'fields': [
        for (final field in body.fields)
          {'name': field.key, 'value': field.value},
      ],
      'files': [
        for (final file in body.files)
          {
            'field': file.key,
            'filename': file.value.filename,
            'contentType': file.value.contentType?.toString(),
          },
      ],
    };
  }

  String _truncate(Object? value) {
    final text = value?.toString() ?? 'null';

    if (text.length <= _maximumBodyLength) {
      return text;
    }

    return '${text.substring(0, _maximumBodyLength)}...';
  }
}
