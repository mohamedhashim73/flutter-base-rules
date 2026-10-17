import 'package:base/core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConstants.kAppInitialization();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(1)),
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          navigatorObservers: [AppRoutes.routeObserver],
          theme: AppTheme.themeData(isDarkModeOverride: false),
          themeMode: ThemeMode.light,
          locale: Locale(UserSessionService.kCurrentLang.name),
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          supportedLocales: const [Locale("en"), Locale("ar")],
          builder: (context, widget) {
            return widget!;
          },
          localeResolutionCallback: (deviceLocale, supportedLocales) {
            return Locale(UserSessionService.kCurrentLang.name);
          },
          navigatorKey: AppRoutes.key,
          home: AppSecurityGate(child: UserSessionService.kGetMainRoute),
        ),
      ),
    );
  }
}
