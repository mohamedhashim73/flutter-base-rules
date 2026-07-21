part of 'network.dart';

class CacheManager {
  static final sharedPref = sl<SharedPreferences>();

  /// User
  static Future<void> setUser(UserModel? user) async {
    try {
      if (user != null) {
        await sharedPref.setString(
          AppStrings.kCachedUser,
          jsonEncode(user.toJson),
        );
      }
    } catch (_) {}
  }

  static UserModel? get getUser {
    try {
      final raw = sharedPref.getString(AppStrings.kCachedUser);
      if (raw == null) return null;
      return UserModel.fromJson(jsonDecode(raw));
    } catch (e) {
      return null;
    }
  }

  static Future<void> removeUser() async {
    try {
      await sharedPref.remove(AppStrings.kCachedUser);
    } catch (_) {}
  }

  // Lang
  static LanguageEnums getLanguage() {
    try {
      LanguageEnums lang =
          sharedPref.getString(AppStrings.kCachedLanguage) ==
              LanguageEnums.en.name
          ? LanguageEnums.en
          : LanguageEnums.ar;
      return lang;
    } catch (e) {
      return LanguageEnums.en;
    }
  }

  static void selectLanguage({required LanguageEnums lang}) {
    sharedPref.setString(AppStrings.kCachedLanguage, lang.name);
  }
}
