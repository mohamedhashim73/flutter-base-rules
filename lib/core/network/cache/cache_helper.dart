part of '../network.dart';

class CacheHelper {
  static Future<bool> setString({
    required String key,
    required String value,
  }) async {
    try {
      return await sl<SharedPreferences>().setString(key, value);
    } catch (e) {
      return false;
    }
  }

  static Future<bool> insertDouble({
    required String key,
    required double value,
  }) async {
    try {
      return await sl<SharedPreferences>().setDouble(key, value);
    } catch (e) {
      return false;
    }
  }

  static Future<bool> insertInt({
    required String key,
    required int value,
  }) async {
    try {
      return await sl<SharedPreferences>().setInt(key, value);
    } catch (e) {
      return false;
    }
  }

  static Future<bool> insertBool({
    required String key,
    required bool value,
  }) async {
    try {
      return await sl<SharedPreferences>().setBool(key, value);
    } catch (e) {
      return false;
    }
  }

  static bool getBool({required String key}) {
    try {
      return sl<SharedPreferences>().getBool(key) ?? false;
    } catch (e) {
      return false;
    }
  }

  static String? getString({required String key}) {
    try {
      return sl<SharedPreferences>().getString(key);
    } catch (e) {
      return null;
    }
  }

  static int? getInt({required String key}) {
    try {
      return sl<SharedPreferences>().getInt(key);
    } catch (e) {
      return null;
    }
  }

  static double? getDouble({required String key}) {
    try {
      return sl<SharedPreferences>().getDouble(key);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> removeItem({required String key}) async {
    try {
      return await sl<SharedPreferences>().remove(key);
    } catch (e) {
      return false;
    }
  }

  static Future<bool> clearCache() async {
    try {
      return await sl<SharedPreferences>().clear();
    } catch (e) {
      LoggingService.showMsg("CacheHelper.clearCache() error: $e");
      return false;
    }
  }
}
