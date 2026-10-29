part of '../services.dart';

final GetIt sl = GetIt.instance;

class DI {
  static Future<void> init() async {
    try {
      final sharedPref = await SharedPreferences.getInstance();
      sl.registerLazySingleton<SharedPreferences>(() => sharedPref);
      sl.registerLazySingleton<FirebaseAuthService>(FirebaseAuthService.new);
      sl.registerLazySingleton<FirebaseService>(
        () => FirebaseService(sl<FirebaseAuthService>()),
      );
      sl.registerLazySingleton<AuditService>(
        () => AuditService(sl<FirebaseService>()),
      );
      sl.registerLazySingleton<FinanceSettingsService>(
        () => FinanceSettingsService(sl<FirebaseService>()),
      );
      sl.registerLazySingleton<InAppNotificationService>(
        () => InAppNotificationService(
          sl<FirebaseService>(),
          sl<NotificationPreferencesService>(),
        ),
      );
      sl.registerLazySingleton<NotificationPreferencesService>(
        () => NotificationPreferencesService(sl<FirebaseService>()),
      );
      sl.registerLazySingleton<WebPushNotificationService>(
        WebPushNotificationService.new,
      );
      sl.registerLazySingleton<TemporaryAttachmentService>(
        createTemporaryAttachmentService,
      );
      sl.registerLazySingleton<FirebaseCacheService>(
        () => FirebaseCacheService(
          sl<SharedPreferences>(),
          sl<FirebaseAuthService>(),
        ),
      );
    } catch (e, stackTrace) {
      LoggingService.showMsg("$e,$stackTrace");
    }
  }
}
