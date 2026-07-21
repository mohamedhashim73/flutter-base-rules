import 'package:http/http.dart' as http;

extension ResponseEx on http.Response {
  bool get isSuccess => statusCode == 200 || statusCode == 201;
  bool get isExpired =>
      statusCode == 401 ||
      statusCode == 403 ||
      (statusCode >= 301 && statusCode <= 308);
}