part of '../services.dart';

final GetIt sl = GetIt.instance;

class DI {
  static Future<void> init() async {
    try {
      final sharedPref = await SharedPreferences.getInstance();
      sl.registerLazySingleton<SharedPreferences>(() => sharedPref);
      sl.registerLazySingleton<BackendApiService>(BackendApiService.new);
    } catch (e, stackTrace) {
      LoggingService.showMsg("$e,$stackTrace");
    }
  }
}
