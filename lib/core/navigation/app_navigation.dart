import 'package:flutter/material.dart';
import 'package:base/core/routes/routes.dart';

/// Navigation groups used by the adaptive shell sidebar.
enum AppNavGroup { overview, finance, governance }

/// Single source of truth for the app's navigation destinations.
///
/// Pages register a builder in `main.dart` so this file stays free of view
/// imports while every screen still shares the same destinations, labels and
/// icons.
enum AppDestination {
  dashboard,
  creditCards,
  operations,
  treasury,
  expenses,
  withdrawals,
  installments,
  checks,
  settlements,
  reports,
  notifications,
  users,
  audit,
  approvals,
  catalogs,
}

extension AppDestinationInfo on AppDestination {
  String get label => switch (this) {
    AppDestination.dashboard => 'لوحة التحكم',
    AppDestination.creditCards => 'بطاقات الائتمان',
    AppDestination.operations => 'التشغيل والخزينة',
    AppDestination.treasury => 'دفتر الخزينة والبنوك',
    AppDestination.expenses => 'إدارة المصروفات',
    AppDestination.withdrawals => 'السحوبات الشخصية',
    AppDestination.installments => 'حسابات التقسيط',
    AppDestination.checks => 'الشيكات',
    AppDestination.settlements => 'التسويات والتحصيل',
    AppDestination.reports => 'التقارير والتصدير',
    AppDestination.notifications => 'مركز الإشعارات',
    AppDestination.users => 'المستخدمون والإعدادات',
    AppDestination.audit => 'سجل التدقيق',
    AppDestination.approvals => 'مركز الاعتمادات',
    AppDestination.catalogs => 'إدارة الكتالوجات',
  };

  String get description => switch (this) {
    AppDestination.dashboard => 'نظرة تنفيذية على أموال المؤسسة والائتمان',
    AppDestination.creditCards => 'حدود البطاقات والمشتريات والإيداعات',
    AppDestination.operations => 'الحركات اليومية والتحصيل والالتزامات',
    AppDestination.treasury => 'أرصدة الحسابات والحركات البنكية',
    AppDestination.expenses => 'المصروفات المعتمدة وتصنيفاتها',
    AppDestination.withdrawals => 'سحوبات الأشخاص ومراجعاتها',
    AppDestination.installments => 'الجداول والأقساط المتبقية',
    AppDestination.checks => 'الشيكات الصادرة ومتابعة استحقاقها',
    AppDestination.settlements => 'تسويات مزودي الدفع وطلبات التحصيل',
    AppDestination.reports => 'تقارير قابلة للطباعة والتصدير',
    AppDestination.notifications => 'التنبيهات والتفضيلات',
    AppDestination.users => 'الأدوار والصلاحيات والإعدادات',
    AppDestination.audit => 'أثر التغييرات على السجلات المالية',
    AppDestination.approvals => 'الطلبات التي تنتظر قراراً مالياً',
    AppDestination.catalogs => 'المزودون والعلامات والحسابات',
  };

  IconData get icon => switch (this) {
    AppDestination.dashboard => Icons.space_dashboard_outlined,
    AppDestination.creditCards => Icons.credit_card_outlined,
    AppDestination.operations => Icons.account_balance_wallet_outlined,
    AppDestination.treasury => Icons.account_balance_outlined,
    AppDestination.expenses => Icons.receipt_long_outlined,
    AppDestination.withdrawals => Icons.person_remove_outlined,
    AppDestination.installments => Icons.schedule_outlined,
    AppDestination.checks => Icons.description_outlined,
    AppDestination.settlements => Icons.fact_check_outlined,
    AppDestination.reports => Icons.assessment_outlined,
    AppDestination.notifications => Icons.notifications_none_rounded,
    AppDestination.users => Icons.manage_accounts_outlined,
    AppDestination.audit => Icons.history_rounded,
    AppDestination.approvals => Icons.approval_outlined,
    AppDestination.catalogs => Icons.category_outlined,
  };

  AppNavGroup get group => switch (this) {
    AppDestination.dashboard => AppNavGroup.overview,
    AppDestination.reports ||
    AppDestination.notifications => AppNavGroup.overview,
    AppDestination.creditCards ||
    AppDestination.operations ||
    AppDestination.treasury ||
    AppDestination.expenses ||
    AppDestination.withdrawals ||
    AppDestination.installments ||
    AppDestination.checks ||
    AppDestination.settlements => AppNavGroup.finance,
    AppDestination.users ||
    AppDestination.audit ||
    AppDestination.approvals ||
    AppDestination.catalogs => AppNavGroup.governance,
  };
}

extension AppNavGroupInfo on AppNavGroup {
  String get label => switch (this) {
    AppNavGroup.overview => 'نظرة عامة',
    AppNavGroup.finance => 'الوحدات المالية',
    AppNavGroup.governance => 'الحوكمة والإدارة',
  };
}

/// Opens destinations without duplicating navigation code per screen.
class AppNavigation {
  static final Map<AppDestination, WidgetBuilder> _builders = {};

  static void register(Map<AppDestination, WidgetBuilder> builders) {
    _builders
      ..clear()
      ..addAll(builders);
  }

  static bool isRegistered(AppDestination destination) =>
      _builders.containsKey(destination);

  static void go(AppDestination destination) {
    final navigator = AppRoutes.key.currentState;
    if (navigator == null) return;
    if (destination == AppDestination.dashboard) {
      const routeName = 'destination:dashboard';
      if (AppRoutes.hasRouteNamed(routeName)) {
        navigator.popUntil((route) => route.settings.name == routeName);
        return;
      }

      // The authenticated shell is the root route in the normal flow, and it
      // already displays the dashboard. Popping back to it is enough.
      navigator.popUntil((route) => route.isFirst);
      final rootName = AppRoutes.currentRouteName;
      if (rootName == null || rootName == '/') return;

      final builder = _builders[destination];
      final context = AppRoutes.key.currentContext;
      if (builder == null || context == null) return;

      // A direct deep link can make another destination the first route. Keep
      // that gated root intact and push the dashboard above it instead of
      // replacing it and dropping the auth/security gate.
      AppRoutes.push(builder(context), name: routeName);
      return;
    }
    final builder = _builders[destination];
    if (builder == null) return;
    final context = AppRoutes.key.currentContext;
    if (context == null) return;

    final routeName = 'destination:${destination.name}';
    if (AppRoutes.currentRouteName == routeName) return;

    // Reuse a destination that is already in the stack (for example after
    // opening provider details on top of it) instead of pushing a duplicate.
    if (AppRoutes.hasRouteNamed(routeName)) {
      navigator.popUntil((route) => route.settings.name == routeName);
      return;
    }

    // Keep the dashboard as the single root route. Replacing the current
    // destination avoids an ever-growing back stack while the browser/app back
    // button still returns to the dashboard.
    navigator.popUntil((route) => route.isFirst);
    AppRoutes.push(builder(context), name: routeName);
  }

  static List<AppDestination> get all => AppDestination.values;
}
