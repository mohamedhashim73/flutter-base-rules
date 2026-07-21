import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:base/core/constants/extensions/models_extensions.dart';
import 'package:base/core/services/user_session_service.dart';
import '../constants/endpoints.dart';
import 'dependency_injection.dart';
import 'logging_service.dart';

class ApiServices {
  static http.Client httpClient = sl<http.Client>();
  static int perPage = 10;
  static Future<http.Response> postAsFormData({
    required String endpoint,
    bool logIsOn = false,
    Map<String, String>? fields,
    Map<String, File>? singleFiles,
    Map<String, List<File>>? multipleFiles,
  }) async {
    var uri = Uri.parse("${ApiEndpoints.baseUrl}$endpoint");
    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] =
        "bearer ${UserSessionService.kCachedUser?.accessToken}";
    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
    }
    if (singleFiles != null && singleFiles.isNotEmpty) {
      for (var entry in singleFiles.entries) {
        request.files.add(
          await http.MultipartFile.fromPath(entry.key, entry.value.path),
        );
      }
    }
    if (multipleFiles != null && multipleFiles.isNotEmpty) {
      for (var entry in multipleFiles.entries) {
        for (var file in entry.value) {
          request.files.add(
            await http.MultipartFile.fromPath(entry.key, file.path),
          );
        }
      }
    }
    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);
    LoggingService.showMsg(
      "Url : ${ApiEndpoints.baseUrl}$endpoint | Status code : ${response.statusCode} | body : $fields | Response ${response.body}",
      isOn: logIsOn,
    );
    await UserSessionService.validateSessionExpire(
      isExpired: response.isExpired,
    );

    return response;
  }

  static Future<http.Response> post({
    required String endpoint,
    dynamic body,
    bool validationOn = true,
    bool logIsOn = false,
    Map<String, String>? extraHeaders,
  }) async {
    http.Response response = await httpClient.post(
      Uri.parse("${ApiEndpoints.baseUrl}$endpoint"),
      body: jsonEncode(body),
      headers: headers,
    );
    LoggingService.showMsg(
      "Url : ${ApiEndpoints.baseUrl}$endpoint | Headers : $headers Status code : ${response.statusCode} | body : $body | Response ${response.body}",
      isOn: logIsOn,
    );
    if (validationOn) {
      await UserSessionService.validateSessionExpire(
        isExpired: response.isExpired,
      );
    }
    return response;
  }

  static Future<http.Response> delete({
    required String endpoint,
    dynamic body,
    bool logIsOn = false,
    bool validationOn = true,
  }) async {
    LoggingService.showMsg("Url : ${ApiEndpoints.baseUrl}$endpoint");
    http.Response response = await httpClient.delete(
      Uri.parse("${ApiEndpoints.baseUrl}$endpoint"),
      body: jsonEncode(body),
      headers: headers,
    );
    LoggingService.showMsg(
      "Status code : ${response.statusCode} | body : $body | Response ${response.body}",
      isOn: logIsOn,
    );
    if (validationOn) {
      await UserSessionService.validateSessionExpire(
        isExpired: response.isExpired,
      );
    }

    return response;
  }

  static Map<String, String> get headers => {
    "Content-Type": "application/json",
    if (UserSessionService.kCachedUser?.accessToken != null)
      "Authorization": "Bearer ${UserSessionService.kCachedUser?.accessToken}",
  };

  static Future<http.Response> get({
    required String endpoint,
    bool logIsOn = false,
    bool validationOn = true,

    dynamic body,
  }) async {
    http.Response response = await httpClient.get(
      Uri.parse("${ApiEndpoints.baseUrl}$endpoint"),
      headers: headers,
    );
    if (validationOn) {
      await UserSessionService.validateSessionExpire(
        isExpired: response.isExpired,
      );
    }
    LoggingService.showMsg(
      "Url : ${ApiEndpoints.baseUrl}$endpoint | Headers : $headers | Response : ${response.body} | Status code : ${response.statusCode}",
      isOn: logIsOn,
    );
    return response;
  }

  static Future<http.Response> put({
    bool logIsOn = false,
    required String endpoint,
    dynamic body,
  }) async {
    LoggingService.showMsg("Url : ${ApiEndpoints.baseUrl}$endpoint");
    http.Response response = await httpClient.put(
      Uri.parse("${ApiEndpoints.baseUrl}$endpoint"),
      body: jsonEncode(body),
      headers: headers,
    );
    LoggingService.showMsg(
      "Status code : ${response.statusCode} | body : $body | Response ${response.body}",
      isOn: logIsOn,
    );
    await UserSessionService.validateSessionExpire(
      isExpired: response.isExpired,
    );

    return response;
  }

  static Future<http.Response> patch({
    required String endpoint,
    bool logIsOn = false,
    dynamic body,
  }) async {
    LoggingService.showMsg("Url : ${ApiEndpoints.baseUrl}$endpoint");
    http.Response response = await httpClient.patch(
      Uri.parse("${ApiEndpoints.baseUrl}$endpoint"),
      body: jsonEncode(body),
      headers: headers,
    );
    LoggingService.showMsg(
      "Status code : ${response.statusCode} | body : $body | Response ${response.body}",
      isOn: logIsOn,
    );
    await UserSessionService.validateSessionExpire(
      isExpired: response.isExpired,
    );

    return response;
  }
}
