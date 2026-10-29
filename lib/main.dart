import 'package:base/core/core.dart';
import 'package:base/core/navigation/app_navigation.dart';
import 'package:base/app/di/app_dependencies.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:base/view/auth/ui/pages/auth_gate_page.dart';
import 'package:base/view/auth/ui/pages/login_page.dart';
import 'package:base/view/auth/ui/controllers/auth_cubit/auth_cubit.dart';
import 'package:base/view/approvals/ui/pages/approval_center_page.dart';
import 'package:base/view/audit/ui/pages/audit_page.dart';
import 'package:base/view/catalogs/ui/pages/catalog_management_page.dart';
import 'package:base/view/credit_cards/ui/pages/credit_cards_page.dart';
import 'package:base/view/dashboard/ui/pages/dashboard_page.dart';
import 'package:base/view/notifications/ui/pages/notifications_page.dart';
import 'package:base/view/operations/ui/pages/checks_page.dart';
import 'package:base/view/operations/ui/pages/expense_management_page.dart';
import 'package:base/view/operations/ui/pages/installments_page.dart';
import 'package:base/view/operations/ui/pages/operations_page.dart';
import 'package:base/view/operations/ui/pages/personal_withdrawals_page.dart';
import 'package:base/view/operations/ui/pages/settlements_page.dart';
import 'package:base/view/operations/ui/pages/treasury_ledger_page.dart';
import 'package:base/view/reports/ui/pages/reports_page.dart';
import 'package:base/view/users/ui/pages/users_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConstants.kAppInitialization();
  registerAppDependencies();
  AppNavigation.register({
    AppDestination.dashboard: (_) => const DashboardPage(),
    AppDestination.creditCards: (_) => const CreditCardsPage(),
    AppDestination.operations: (_) => const OperationsPage(),
    AppDestination.treasury: (_) => const TreasuryLedgerPage(),
    AppDestination.expenses: (_) => const ExpenseManagementPage(),
    AppDestination.withdrawals: (_) => const PersonalWithdrawalsPage(),
    AppDestination.installments: (_) => const InstallmentsPage(),
    AppDestination.checks: (_) => const ChecksPage(),
    AppDestination.settlements: (_) => const SettlementsPage(),
    AppDestination.reports: (_) => const ReportsPage(),
    AppDestination.notifications: (_) => const NotificationsPage(),
    AppDestination.users: (_) => const UsersPage(),
    AppDestination.audit: (_) => const AuditPage(),
    AppDestination.approvals: (_) => const ApprovalCenterPage(),
    AppDestination.catalogs: (_) => const CatalogManagementPage(),
  });
  AppRoutes.goToLogin = () =>
      AppRoutes.pushAndRemovePreviousRoutes(LoginPage(cubit: sl<AuthCubit>()));
  runApp(
    MyApp(
      home: AppSecurityGate(
        child: AuthGatePage(
          authService: sl<FirebaseAuthService>(),
          authCubit: sl(),
        ),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.home});

  final Widget? home;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep `.r`/`.sp` close to logical pixels on every form factor. The
        // previous fixed 430pt design width made desktop/web layouts scale up
        // beyond their containers.
        final width = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? constraints.maxWidth
            : 430.0;
        final height =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : 932.0;
        return ScreenUtilInit(
          designSize: Size(width, height),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1)),
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorObservers: [
                AppRoutes.routeObserver,
                AppRoutes.stackObserver,
              ],
              theme: AppTheme.themeData(isDarkModeOverride: false),
              themeMode: ThemeMode.light,
              locale: Locale(_language.name),
              localizationsDelegates: GlobalMaterialLocalizations.delegates,
              supportedLocales: const [Locale("en"), Locale("ar")],
              builder: (context, widget) {
                return widget!;
              },
              localeResolutionCallback: (deviceLocale, supportedLocales) {
                return Locale(_language.name);
              },
              navigatorKey: AppRoutes.key,
              home: home ?? const SizedBox(),
            ),
          ),
        );
      },
    );
  }

  LanguageEnums get _language {
    return sl.isRegistered<SharedPreferences>()
        ? UserSessionService.kCurrentLang
        : LanguageEnums.ar;
  }
}
