import 'package:http/http.dart' as http;
import 'package:playx/playx.dart';

import 'logging_service.dart';

final GetIt sl = GetIt.instance;

class DI {
  static Future<void> init() async {
    try {
      final sharedPref = await SharedPreferences.getInstance();
      sl.registerLazySingleton<http.Client>(() => http.Client());
      sl.registerLazySingleton<SharedPreferences>(() => sharedPref);
    } catch (e, stackTrace) {
      LoggingService.showMsg("$e,$stackTrace");
    }
  }
}
