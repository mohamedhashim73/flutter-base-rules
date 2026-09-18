part of 'extensions.dart';
extension ResponseEx on Response {
  bool get isSuccess => statusCode == 200 || statusCode == 201;

  bool get isExpired {
    final code = statusCode;

    return code == 401 ||
        code == 403 ||
        (code != null && code >= 301 && code <= 308);
  }
}