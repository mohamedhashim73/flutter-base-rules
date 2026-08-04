part of '../network.dart';

class CacheManager {
  static final sharedPref = sl<SharedPreferences>();

  /// User
  static Future<void> setUser(UserModel? user) async {
    try {
      if (user != null) {
        final cachedUser = getUser;
        final safeUser = user.copyWith(
          // Profile responses do not contain auth tokens. Never allow a
          // response without tokens to erase the current session.
          accessToken: _nonEmpty(user.accessToken)
              ? user.accessToken
              : cachedUser?.accessToken,
          refreshToken: _nonEmpty(user.refreshToken)
              ? user.refreshToken
              : cachedUser?.refreshToken,
        );
        await sharedPref.setString(
          CacheKeys.user,
          jsonEncode(safeUser.toJson),
        );
      }
    } catch (_) {}
  }

  static bool _nonEmpty(String? value) => value?.trim().isNotEmpty == true;

  static UserModel? get getUser {
    try {
      final raw = sharedPref.getString(CacheKeys.user);
      if (raw == null) return null;
      return UserModel.fromJson(jsonDecode(raw));
    } catch (e) {
      return null;
    }
  }

  static Future<void> removeUser() async {
    try {
      await sharedPref.remove(CacheKeys.user);
    } catch (_) {}
  }

  /// Recent Searches
  static Future<void> setRecentSearches(List<String> searches) async {
    try {
      await sharedPref.setString(
        CacheKeys.recentSearches,
        jsonEncode(searches),
      );
    } catch (_) {}
  }

  static List<String>? get getRecentSearches {
    try {
      final raw = sharedPref.getString(CacheKeys.recentSearches);
      if (raw == null) return null;
      return (jsonDecode(raw) as List).cast<String>();
    } catch (_) {
      return null;
    }
  }

  // Lang
  static LanguageEnums getLanguage() {
    try {
      LanguageEnums lang =
          sharedPref.getString(CacheKeys.language) ==
              LanguageEnums.en.name
          ? LanguageEnums.en
          : LanguageEnums.ar;
      return lang;
    } catch (e) {
      return LanguageEnums.ar;
    }
  }

  static void selectLanguage({required LanguageEnums lang}) {
    sharedPref.setString(CacheKeys.language, lang.name);
  }
}
