import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:base/core/extensions/extensions.dart';
import 'package:base/core/enums/enums.dart';
import 'package:base/core/navigation/app_navigation.dart';
import 'package:base/core/routes/routes.dart';
import 'package:base/core/services/services.dart';
import 'package:base/core/theme/theme.dart';
import 'package:base/core/utils/finance_money.dart';
import 'package:base/core/widgets/widgets.dart';
import 'package:base/model/domain/credit_purchase_model.dart';
import 'package:base/model/domain/expense_model.dart';
import 'package:base/view/credit_cards/data/models/credit_cards_response_model.dart';
import 'package:base/view/credit_cards/ui/controllers/credit_cards_cubit/credit_cards_cubit.dart';
import 'package:base/view/credit_cards/ui/controllers/credit_cards_cubit/credit_cards_states.dart';
import 'package:base/view/notifications/ui/controllers/notifications_cubit/notifications_cubit.dart';
import 'package:base/view/notifications/ui/controllers/notifications_cubit/notifications_states.dart';
import 'package:base/view/operations/ui/controllers/operations_cubit/operations_cubit.dart';
import 'package:base/view/operations/ui/controllers/operations_cubit/operations_states.dart';

enum _DashboardFilter { today, thisWeek, thisMonth, previousMonth, custom }

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late final CreditCardsCubit _creditCubit;
  late final OperationsCubit _operationsCubit;
  late final NotificationsCubit _notificationsCubit;
  _DashboardFilter _filter = _DashboardFilter.thisMonth;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _creditCubit = sl<CreditCardsCubit>()..load();
    _operationsCubit = sl<OperationsCubit>()..load();
    _notificationsCubit = sl<NotificationsCubit>()..load();
  }

  @override
  void dispose() {
    _creditCubit.close();
    _operationsCubit.close();
    _notificationsCubit.close();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([
      _creditCubit.load(),
      _operationsCubit.load(),
      _notificationsCubit.load(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      bloc: _notificationsCubit,
      builder: (context, notificationState) => AppPageScaffold(
        destination: AppDestination.dashboard,
        title: 'لوحة التحكم',
        subtitle:
            'نظرة تنفيذية على أموال المؤسسة والائتمان · ${_rangeLabel(_range)}',
        onRefresh: _refresh,
        actions: [
          _filterControl(context),
          IconButton(
            tooltip: 'تحديث البيانات',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'سجل التدقيق',
            onPressed: () => AppNavigation.go(AppDestination.audit),
            icon: const Icon(Icons.history_rounded),
          ),
        ],
        unreadNotifications: notificationState.unreadCount,
        body: BlocBuilder<CreditCardsCubit, CreditCardsState>(
          bloc: _creditCubit,
          builder: (context, creditState) =>
              BlocBuilder<OperationsCubit, OperationsState>(
                bloc: _operationsCubit,
                builder: (context, operationsState) => DataStateBuilderWidget(
                  shimmerType: AppPageShimmerType.dashboard,
                  dataState: DataState(
                    state: creditState,
                    response: CreditCardsResponseModel(creditState.cards),
                  ),
                  onFailure: _creditCubit.load,
                  widget: _content(context, creditState, operationsState),
                ),
              ),
        ),
      ),
    );
  }

  Widget _filterControl(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: AppSizes.controlHeight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDesignRadius.control),
        border: Border.all(color: colors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<_DashboardFilter>(
          value: _filter,
          borderRadius: BorderRadius.circular(AppDesignRadius.control),
          icon: Icon(
            Icons.expand_more_rounded,
            size: 20,
            color: colors.textSecondary,
          ),
          style: context.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w600,
          ),
          items: const [
            DropdownMenuItem(
              value: _DashboardFilter.today,
              child: Text('اليوم'),
            ),
            DropdownMenuItem(
              value: _DashboardFilter.thisWeek,
              child: Text('هذا الأسبوع'),
            ),
            DropdownMenuItem(
              value: _DashboardFilter.thisMonth,
              child: Text('هذا الشهر'),
            ),
            DropdownMenuItem(
              value: _DashboardFilter.previousMonth,
              child: Text('الشهر السابق'),
            ),
            DropdownMenuItem(
              value: _DashboardFilter.custom,
              child: Text('نطاق مخصص'),
            ),
          ],
          onChanged: (value) async {
            if (value == null) return;
            if (value == _DashboardFilter.custom) {
              await _pickCustomRange();
            } else {
              setState(() => _filter = value);
            }
          },
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    CreditCardsState credit,
    OperationsState operations,
  ) {
    final range = _range;
    final purchases = credit.allPurchases
        .where((item) => _inRange(item.purchaseDateMillis, range))
        .toList();
    final expenses = operations.expenses
        .where(
          (item) =>
              item.status == 'approved' &&
              _inRange(item.createdAtMillis, range),
        )
        .toList();
    final treasuryCash = operations.accounts.fold<int>(
      0,
      (sum, item) => sum + item.balanceMinor,
    );
    final bankBalance = operations.bankAccounts.fold<int>(
      0,
      (sum, item) => sum + item.balanceMinor,
    );
    final outstandingCollections = operations.settlements.fold<int>(
      0,
      (sum, item) =>
          sum + (item.netMinor - item.collectedMinor).clamp(0, 1 << 62),
    );
    final monthlyObligations = operations.installments
        .where((item) => item.status == 'active')
        .fold<int>(0, (sum, item) => sum + item.monthlyObligationMinor);
    final outstandingChecks = operations.checks
        .where((item) => item.status == 'issued' || item.status == 'overdue')
        .fold<int>(0, (sum, item) => sum + item.amountMinor);
    final pendingApprovals =
        operations.movements
            .where((item) => item.approvalStatus == 'pending')
            .length +
        operations.transfers.where((item) => item.status == 'pending').length +
        operations.personalWithdrawals
            .where((item) => item.status == 'pending')
            .length +
        operations.expenses.where((item) => item.status == 'pending').length +
        operations.settlements
            .where((item) => item.approvalStatus == 'pending')
            .length;
    final overdueSettlements = operations.settlements.where(_isOverdue).length;
    final totalLimit = credit.cards.fold<int>(
      0,
      (sum, card) => sum + card.creditLimitMinor,
    );
    final totalAvailable = credit.cards.fold<int>(
      0,
      (sum, card) => sum + card.availableBalanceMinor,
    );
    final totalDebt = credit.cards.fold<int>(
      0,
      (sum, card) => sum + card.currentMonthlyDebtMinor,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppBreakpoints.of(context).sectionSpacing,
      children: [
        AppStatGrid(
          children: [
            AppStatCard(
              label: 'النقد الفعلي',
              value: FinanceMoney.formatEgp(treasuryCash),
              icon: Icons.payments_outlined,
              caption: 'أرصدة الخزينة المجمّعة',
              highlight: true,
              onTap: () => AppNavigation.go(AppDestination.operations),
            ),
            AppStatCard(
              label: 'أرصدة البنوك',
              value: FinanceMoney.formatEgp(bankBalance),
              icon: Icons.account_balance_outlined,
              caption: '${operations.bankAccounts.length} حساب بنكي',
              onTap: () => AppNavigation.go(AppDestination.treasury),
            ),
            AppStatCard(
              label: 'الرصيد الائتماني المتاح',
              value: FinanceMoney.formatEgp(totalAvailable),
              icon: Icons.credit_card_outlined,
              caption: 'عبر ${credit.cards.length} بطاقة',
              onTap: () => AppNavigation.go(AppDestination.creditCards),
            ),
            AppStatCard(
              label: 'إجمالي الحد الائتماني',
              value: FinanceMoney.formatEgp(totalLimit),
              icon: Icons.credit_score_outlined,
              caption: 'الحد المعتمد للبطاقات',
              tone: AppTone.info,
              onTap: () => AppNavigation.go(AppDestination.creditCards),
            ),
            AppStatCard(
              label: 'الدين الشهري المتبقي',
              value: FinanceMoney.formatEgp(totalDebt),
              icon: Icons.calendar_month_outlined,
              caption: 'الاستحقاق القادم',
              tone: AppTone.warning,
              onTap: () => AppNavigation.go(AppDestination.creditCards),
            ),
            AppStatCard(
              label: 'المشتريات في الفترة',
              value: FinanceMoney.formatEgp(
                purchases.fold<int>(0, (sum, item) => sum + item.amountMinor),
              ),
              icon: Icons.shopping_bag_outlined,
              caption: '${purchases.length} عملية شراء',
              onTap: () => AppNavigation.go(AppDestination.reports),
            ),
            AppStatCard(
              label: 'المصروفات المعتمدة',
              value: FinanceMoney.formatEgp(
                expenses.fold<int>(0, (sum, item) => sum + item.amountMinor),
              ),
              icon: Icons.receipt_long_outlined,
              caption: '${expenses.length} مصروف معتمد',
              tone: AppTone.info,
              onTap: () => AppNavigation.go(AppDestination.expenses),
            ),
            AppStatCard(
              label: 'التحصيلات القائمة',
              value: FinanceMoney.formatEgp(outstandingCollections),
              icon: Icons.pending_actions_outlined,
              caption: 'مبالغ لم تُحصّل بعد',
              tone: AppTone.gold,
              onTap: () => AppNavigation.go(AppDestination.settlements),
            ),
            AppStatCard(
              label: 'الالتزامات الشهرية',
              value: FinanceMoney.formatEgp(monthlyObligations),
              icon: Icons.event_note_outlined,
              caption: 'أقساط نشطة',
              onTap: () => AppNavigation.go(AppDestination.installments),
            ),
            AppStatCard(
              label: 'الشيكات القائمة',
              value: FinanceMoney.formatEgp(outstandingChecks),
              icon: Icons.description_outlined,
              caption: 'صادرة أو متأخرة',
              tone: AppTone.warning,
              onTap: () => AppNavigation.go(AppDestination.checks),
            ),
            AppStatCard(
              label: 'اعتمادات معلقة',
              value: '$pendingApprovals',
              icon: Icons.approval_outlined,
              caption: 'بانتظار قرار مالي',
              tone: AppTone.warning,
              onTap: () => AppNavigation.go(AppDestination.approvals),
            ),
            AppStatCard(
              label: 'تسويات متأخرة',
              value: '$overdueSettlements',
              icon: Icons.warning_amber_outlined,
              caption: 'تحتاج متابعة عاجلة',
              tone: AppTone.danger,
              onTap: () => AppNavigation.go(AppDestination.settlements),
            ),
          ],
        ),
        _ProviderSummaryWidget(
          purchases: purchases,
          onProviderTap: (name, providerPurchases) => AppRoutes.push(
            _ProviderDetailsPage(
              providerName: name,
              purchases: providerPurchases,
            ),
          ),
        ),
        _DashboardChartsWidget(
          purchases: purchases,
          expenses: expenses,
          operations: operations,
          range: range,
        ),
        _InsightBanner(
          onCreditCards: () => AppNavigation.go(AppDestination.creditCards),
          onOperations: () => AppNavigation.go(AppDestination.operations),
          onReports: () => AppNavigation.go(AppDestination.reports),
          onNotifications: () => AppNavigation.go(AppDestination.notifications),
          onUsers: () => AppNavigation.go(AppDestination.users),
          onEnablePush: _enablePush,
        ),
      ],
    );
  }

  DateTimeRange _rangeFor(_DashboardFilter filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (filter) {
      _DashboardFilter.today => DateTimeRange(
        start: today,
        end: today.add(const Duration(days: 1)),
      ),
      _DashboardFilter.thisWeek => DateTimeRange(
        start: today.subtract(Duration(days: today.weekday - 1)),
        end: today.add(const Duration(days: 1)),
      ),
      _DashboardFilter.thisMonth => DateTimeRange(
        start: DateTime(now.year, now.month),
        end: DateTime(now.year, now.month + 1),
      ),
      _DashboardFilter.previousMonth => DateTimeRange(
        start: DateTime(now.year, now.month - 1),
        end: DateTime(now.year, now.month),
      ),
      _DashboardFilter.custom =>
        _customRange ??
            DateTimeRange(
              start: DateTime(now.year, now.month),
              end: DateTime(now.year, now.month + 1),
            ),
    };
  }

  DateTimeRange get _range => _rangeFor(_filter);

  bool _inRange(int millis, DateTimeRange range) {
    final value = DateTime.fromMillisecondsSinceEpoch(millis);
    return !value.isBefore(range.start) && value.isBefore(range.end);
  }

  String _rangeLabel(DateTimeRange range) {
    final end = range.end.subtract(const Duration(days: 1));
    return '${range.start.year}/${range.start.month.toString().padLeft(2, '0')}/${range.start.day.toString().padLeft(2, '0')} — ${end.year}/${end.month.toString().padLeft(2, '0')}/${end.day.toString().padLeft(2, '0')}';
  }

  bool _isOverdue(dynamic settlement) {
    if (settlement.status == 'settled') return false;
    final due =
        settlement.expectedCollectionDateMillis ??
        settlement.createdAtMillis + const Duration(days: 7).inMilliseconds;
    return due < DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> _pickCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _customRange,
      helpText: 'اختر نطاق التقرير',
    );
    if (!mounted || picked == null) return;
    setState(() {
      _customRange = DateTimeRange(
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        end: DateTime(picked.end.year, picked.end.month, picked.end.day + 1),
      );
      _filter = _DashboardFilter.custom;
    });
  }

  Future<void> _enablePush() async {
    final status = await sl<WebPushNotificationService>().requestPermission();
    if (!mounted) return;
    final enabled = status.name == 'authorized' || status.name == 'provisional';
    AppToast.showToast(
      message: enabled
          ? 'تم تفعيل إشعارات المتصفح عند دعمها.'
          : 'إشعارات التطبيق الداخلية ما زالت متاحة.',
      type: MsgType.info,
    );
  }
}

class _ProviderSummaryWidget extends StatelessWidget {
  const _ProviderSummaryWidget({
    required this.purchases,
    required this.onProviderTap,
  });

  final List<CreditPurchaseModel> purchases;
  final void Function(String name, List<CreditPurchaseModel> purchases)
  onProviderTap;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<CreditPurchaseModel>>{};
    for (final purchase in purchases) {
      grouped.putIfAbsent(purchase.providerName, () => []).add(purchase);
    }
    final entries = grouped.entries.toList()
      ..sort(
        (a, b) => b.value
            .fold<int>(0, (sum, item) => sum + item.amountMinor)
            .compareTo(
              a.value.fold<int>(0, (sum, item) => sum + item.amountMinor),
            ),
      );
    return AppSectionCard(
      title: 'ملخص مزودي الدفع',
      subtitle: 'توزيع المشتريات في الفترة المحددة',
      icon: Icons.storefront_outlined,
      showDivider: true,
      actions: [
        Text(
          '${grouped.length} مزود',
          style: context.textTheme.labelSmall?.copyWith(
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
      child: grouped.isEmpty
          ? const AppStateView(
              icon: Icons.storefront_outlined,
              title: 'لا توجد مشتريات في الفترة المحددة',
              message: 'جرّب توسيع النطاق الزمني لعرض عمليات المزودين.',
              compact: true,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < entries.length; index++)
                  AppRecordTile(
                    icon: Icons.account_balance_outlined,
                    title: entries[index].key,
                    subtitle:
                        '${entries[index].value.length} عملية · عمولة ${FinanceMoney.formatEgp(entries[index].value.fold<int>(0, (sum, item) => sum + item.commissionMinor))}',
                    trailing: Text(
                      FinanceMoney.formatEgp(
                        entries[index].value.fold<int>(
                          0,
                          (sum, item) => sum + item.amountMinor,
                        ),
                      ),
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: context.colors.onSurface,
                      ),
                    ),
                    showDivider: index != entries.length - 1,
                    onTap: () =>
                        onProviderTap(entries[index].key, entries[index].value),
                  ),
              ],
            ),
    );
  }
}

class _DashboardChartsWidget extends StatelessWidget {
  const _DashboardChartsWidget({
    required this.purchases,
    required this.expenses,
    required this.operations,
    required this.range,
  });

  final List<CreditPurchaseModel> purchases;
  final List<ExpenseModel> expenses;
  final OperationsState operations;
  final DateTimeRange range;

  @override
  Widget build(BuildContext context) {
    final providers = <String, int>{};
    for (final purchase in purchases) {
      providers.update(
        purchase.providerName,
        (value) => value + purchase.amountMinor,
        ifAbsent: () => purchase.amountMinor,
      );
    }
    final expenseTotals = <String, int>{};
    for (final expense in expenses) {
      expenseTotals.update(
        expense.category,
        (value) => value + expense.amountMinor,
        ifAbsent: () => expense.amountMinor,
      );
    }
    final settlementStatuses = <String, int>{};
    for (final settlement in operations.settlements) {
      settlementStatuses.update(
        settlement.status,
        (value) => value + 1,
        ifAbsent: () => 1,
      );
    }
    final cashFlow = <String, int>{'إيداعات': 0, 'سحوبات': 0};
    for (final movement in operations.movements.where(
      (item) =>
          _inRange(item.transactionDateMillis ?? item.createdAtMillis, range),
    )) {
      final key = movement.type == 'outflow' ? 'سحوبات' : 'إيداعات';
      cashFlow[key] = cashFlow[key]! + movement.amountMinor;
    }
    return AppResponsiveGrid(
      minItemWidth: 340,
      maxColumns: 2,
      spacing: AppBreakpoints.of(context).gridSpacing,
      runSpacing: AppBreakpoints.of(context).gridSpacing,
      children: [
        _BarsCard(
          title: 'التدفق النقدي في الفترة',
          icon: Icons.swap_vert_rounded,
          values: cashFlow,
          money: true,
        ),
        _BarsCard(
          title: 'المشتريات حسب مزود الدفع',
          icon: Icons.credit_card_outlined,
          values: providers,
          money: true,
        ),
        _BarsCard(
          title: 'توزيع المصروفات',
          icon: Icons.pie_chart_outline_rounded,
          values: expenseTotals,
          money: true,
          tone: AppTone.info,
        ),
        _BarsCard(
          title: 'التسويات حسب الحالة',
          icon: Icons.fact_check_outlined,
          values: settlementStatuses,
          money: false,
          tone: AppTone.gold,
        ),
        _BarsCard(
          title: 'الالتزامات الشهرية حسب الحساب',
          icon: Icons.event_note_outlined,
          values: {
            for (final item in operations.installments)
              item.customerName: item.monthlyObligationMinor,
          },
          money: true,
          tone: AppTone.warning,
        ),
      ],
    );
  }

  bool _inRange(int millis, DateTimeRange range) {
    final value = DateTime.fromMillisecondsSinceEpoch(millis);
    return !value.isBefore(range.start) && value.isBefore(range.end);
  }
}

class _BarsCard extends StatelessWidget {
  const _BarsCard({
    required this.title,
    required this.values,
    required this.money,
    required this.icon,
    this.tone = AppTone.primary,
  });

  final String title;
  final Map<String, int> values;
  final bool money;
  final IconData icon;
  final AppTone tone;

  @override
  Widget build(BuildContext context) {
    final max = values.values.fold<int>(0, (a, b) => a > b ? a : b);
    return AppSectionCard(
      title: title,
      icon: icon,
      tone: tone,
      showDivider: true,
      child: values.isEmpty
          ? const AppStateView(
              icon: Icons.bar_chart_rounded,
              title: 'لا توجد بيانات للفترة المحددة',
              compact: true,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final entry in values.entries)
                  AppProgressRow(
                    label: entry.key,
                    value: money
                        ? FinanceMoney.formatEgp(entry.value)
                        : '${entry.value}',
                    ratio: max == 0 ? 0 : entry.value / max,
                    tone: tone,
                  ),
              ],
            ),
    );
  }
}

class _InsightBanner extends StatelessWidget {
  const _InsightBanner({
    required this.onCreditCards,
    required this.onOperations,
    required this.onReports,
    required this.onNotifications,
    required this.onUsers,
    required this.onEnablePush,
  });

  final VoidCallback onCreditCards;
  final VoidCallback onOperations;
  final VoidCallback onReports;
  final VoidCallback onNotifications;
  final VoidCallback onUsers;
  final VoidCallback onEnablePush;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(AppDesignRadius.card),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.sm,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.insights_outlined,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const Expanded(
                child: Text(
                  'كل رقم في لوحة التحكم قابل للتتبع إلى سجله المالي الأصلي.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _BannerButton(
                title: 'إدارة البطاقات',
                icon: Icons.credit_card_outlined,
                onTap: onCreditCards,
                filled: true,
              ),
              _BannerButton(
                title: 'مركز العمليات',
                icon: Icons.account_balance_wallet_outlined,
                onTap: onOperations,
              ),
              _BannerButton(
                title: 'التقارير',
                icon: Icons.assessment_outlined,
                onTap: onReports,
              ),
              _BannerButton(
                title: 'الإشعارات',
                icon: Icons.notifications_none_rounded,
                onTap: onNotifications,
              ),
              _BannerButton(
                title: 'المستخدمون',
                icon: Icons.manage_accounts_outlined,
                onTap: onUsers,
              ),
              _BannerButton(
                title: 'تفعيل إشعارات المتصفح',
                icon: Icons.notifications_active_outlined,
                onTap: onEnablePush,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BannerButton extends StatelessWidget {
  const _BannerButton({
    required this.title,
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final foreground = filled ? context.colors.primary : Colors.white;
    return Material(
      color: filled ? Colors.white : Colors.white.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppDesignRadius.control),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesignRadius.control),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Icon(icon, size: 17, color: foreground),
              Text(
                title,
                style: TextStyle(
                  color: foreground,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProviderDetailsPage extends StatelessWidget {
  const _ProviderDetailsPage({
    required this.providerName,
    required this.purchases,
  });

  final String providerName;
  final List<CreditPurchaseModel> purchases;

  @override
  Widget build(BuildContext context) {
    final byBrand = <String, List<CreditPurchaseModel>>{};
    for (final purchase in purchases) {
      byBrand.putIfAbsent(purchase.brandName, () => []).add(purchase);
    }
    return AppPageScaffold(
      title: 'مزود الدفع: $providerName',
      subtitle:
          'إجمالي المشتريات: ${FinanceMoney.formatEgp(purchases.fold<int>(0, (sum, item) => sum + item.amountMinor))}',
      leading: IconButton(
        tooltip: 'رجوع',
        onPressed: AppRoutes.pop,
        icon: const Icon(Icons.arrow_back_rounded),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          AppStatGrid(
            maxColumns: 3,
            children: [
              AppStatCard(
                label: 'عدد العمليات',
                value: '${purchases.length}',
                icon: Icons.receipt_long_outlined,
                tone: AppTone.info,
              ),
              AppStatCard(
                label: 'إجمالي المبلغ',
                value: FinanceMoney.formatEgp(
                  purchases.fold<int>(0, (sum, item) => sum + item.amountMinor),
                ),
                icon: Icons.payments_outlined,
                highlight: true,
              ),
              AppStatCard(
                label: 'إجمالي العمولة',
                value: FinanceMoney.formatEgp(
                  purchases.fold<int>(
                    0,
                    (sum, item) => sum + item.commissionMinor,
                  ),
                ),
                icon: Icons.percent_rounded,
                tone: AppTone.gold,
              ),
            ],
          ),
          for (final entry in byBrand.entries)
            AppSectionCard(
              title: entry.key,
              subtitle:
                  '${entry.value.length} عملية · ${FinanceMoney.formatEgp(entry.value.fold<int>(0, (sum, item) => sum + item.amountMinor))}',
              icon: Icons.sell_outlined,
              showDivider: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var index = 0; index < entry.value.length; index++)
                    AppRecordTile(
                      title: FinanceMoney.formatEgp(
                        entry.value[index].amountMinor,
                      ),
                      subtitle:
                          'عمولة ${FinanceMoney.formatEgp(entry.value[index].commissionMinor)} · ${entry.value[index].posMachineName.isEmpty ? 'POS غير محدد' : entry.value[index].posMachineName}',
                      meta: DateTime.fromMillisecondsSinceEpoch(
                        entry.value[index].purchaseDateMillis,
                      ).toLocal().toString(),
                      showDivider: index != entry.value.length - 1,
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
