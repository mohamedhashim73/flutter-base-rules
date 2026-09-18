part of 'services.dart';

final GetIt sl = GetIt.instance;

class DI {
  static Future<void> init() async {
    try {
      final sharedPref = await SharedPreferences.getInstance();
      sl.registerLazySingleton<Dio>(() => Dio());
      sl.registerLazySingleton<SharedPreferences>(() => sharedPref);
    } catch (e, stackTrace) {
      LoggingService.showMsg("$e,$stackTrace");
    }
  }
}
