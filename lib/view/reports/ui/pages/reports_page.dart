import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:base/core/enums/enums.dart';
import 'package:base/core/extensions/extensions.dart';
import 'package:base/core/navigation/app_navigation.dart';
import 'package:base/core/services/services.dart';
import 'package:base/core/theme/theme.dart';
import 'package:base/core/utils/finance_money.dart';
import 'package:base/core/widgets/widgets.dart';
import 'package:base/model/domain/settlement_model.dart';
import 'package:base/model/domain/credit_purchase_model.dart';
import 'package:base/view/credit_cards/data/models/credit_cards_response_model.dart';
import 'package:base/view/credit_cards/ui/controllers/credit_cards_cubit/credit_cards_cubit.dart';
import 'package:base/view/credit_cards/ui/controllers/credit_cards_cubit/credit_cards_states.dart';
import 'package:base/view/operations/ui/controllers/operations_cubit/operations_cubit.dart';
import 'package:base/view/operations/ui/controllers/operations_cubit/operations_states.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});
  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  late final CreditCardsCubit _creditCubit;
  late final OperationsCubit _operationsCubit;
  DateTime? _selectedMonth;
  @override
  void initState() {
    super.initState();
    _creditCubit = sl<CreditCardsCubit>()..load();
    _operationsCubit = sl<OperationsCubit>()..load();
  }

  @override
  void dispose() {
    _creditCubit.close();
    _operationsCubit.close();
    super.dispose();
  }

  Future<void> _refresh() async {
    await Future.wait([_creditCubit.load(), _operationsCubit.load()]);
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    destination: AppDestination.reports,
    title: 'التقارير والمطابقة',
    subtitle: _selectedMonth == null
        ? 'تقرير تنفيذي قابل للمراجعة · كل الفترات'
        : 'تقرير تنفيذي قابل للمراجعة · ${_selectedMonth!.year}-${_selectedMonth!.month.toString().padLeft(2, '0')}',
    onRefresh: _refresh,
    actions: [
      OutlinedButton.icon(
        onPressed: _pickMonth,
        icon: const Icon(Icons.calendar_month_outlined, size: 18),
        label: Text(
          _selectedMonth == null
              ? 'كل الفترات'
              : '${_selectedMonth!.year}-${_selectedMonth!.month.toString().padLeft(2, '0')}',
        ),
      ),
      IconButton(
        tooltip: 'طباعة التقرير',
        onPressed: PrintService.printPage,
        icon: const Icon(Icons.print_outlined),
      ),
      PopupMenuButton<String>(
        tooltip: 'تصدير التقرير',
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignRadius.control),
        ),
        onSelected: (value) {
          switch (value) {
            case 'csv':
              _copyCsv();
            case 'excel':
              _downloadExcel();
            case 'pdf':
              _downloadPdf();
          }
        },
        itemBuilder: (context) => const [
          PopupMenuItem(
            value: 'csv',
            child: Row(
              spacing: 10,
              children: [Icon(Icons.file_download_outlined), Text('نسخ CSV')],
            ),
          ),
          PopupMenuItem(
            value: 'excel',
            child: Row(
              spacing: 10,
              children: [Icon(Icons.table_view_outlined), Text('تنزيل Excel')],
            ),
          ),
          PopupMenuItem(
            value: 'pdf',
            child: Row(
              spacing: 10,
              children: [
                Icon(Icons.picture_as_pdf_outlined),
                Text('تنزيل PDF'),
              ],
            ),
          ),
        ],
        child: Container(
          height: AppSizes.controlHeight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(AppDesignRadius.control),
            border: Border.all(color: context.colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              Icon(
                Icons.ios_share_rounded,
                size: 18,
                color: context.colors.textSecondary,
              ),
              Text(
                'تصدير',
                style: context.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
      IconButton(
        tooltip: 'تحديث',
        onPressed: _refresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
    body: BlocBuilder<CreditCardsCubit, CreditCardsState>(
      bloc: _creditCubit,
      builder: (context, creditState) =>
          BlocBuilder<OperationsCubit, OperationsState>(
            bloc: _operationsCubit,
            builder: (context, operationsState) => DataStateBuilderWidget(
              shimmerType: AppPageShimmerType.reports,
              dataState: DataState(
                state: creditState,
                response: CreditCardsResponseModel(
                  creditState.cards.isEmpty ? const [] : creditState.cards,
                ),
              ),
              onFailure: _creditCubit.load,
              widget: _content(context, creditState, operationsState),
            ),
          ),
    ),
  );

  Widget _content(
    BuildContext context,
    CreditCardsState credit,
    OperationsState operations,
  ) {
    final filteredPurchases = credit.allPurchases
        .where((item) => _inMonth(item.purchaseDateMillis, _selectedMonth))
        .toList();
    final filteredSettlements = operations.settlements
        .where((item) => _inMonth(item.createdAtMillis, _selectedMonth))
        .toList();
    final purchases = filteredPurchases.fold<int>(
      0,
      (sum, item) => sum + item.amountMinor,
    );
    final commissions = filteredPurchases.fold<int>(
      0,
      (sum, item) => sum + item.commissionMinor,
    );
    final treasury =
        operations.accounts.fold<int>(
          0,
          (sum, item) => sum + item.balanceMinor,
        ) +
        operations.bankAccounts.fold<int>(
          0,
          (sum, item) => sum + item.balanceMinor,
        );
    final openCollections = operations.collectionRequests
        .where((item) => item.status != 'confirmed')
        .length;
    return AppResponsiveBuilder(
      builder: (context, factor) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: factor.sectionSpacing,
        children: [
          AppStatGrid(
            children: [
              AppStatCard(
                label: 'المشتريات',
                value: FinanceMoney.formatEgp(purchases),
                icon: Icons.shopping_bag_outlined,
                caption: '${filteredPurchases.length} عملية',
                highlight: true,
              ),
              AppStatCard(
                label: 'العمولات',
                value: FinanceMoney.formatEgp(commissions),
                icon: Icons.percent_rounded,
                tone: AppTone.gold,
              ),
              AppStatCard(
                label: 'الخزينة',
                value: FinanceMoney.formatEgp(treasury),
                icon: Icons.account_balance_wallet_outlined,
                tone: AppTone.info,
              ),
              AppStatCard(
                label: 'طلبات تحصيل معلقة',
                value: '$openCollections',
                icon: Icons.pending_actions_outlined,
                tone: AppTone.warning,
                onTap: () => AppNavigation.go(AppDestination.settlements),
              ),
            ],
          ),
          AppSectionCard(
            title: 'المطابقة المختصرة',
            subtitle: 'أرصدة البطاقات والتسويات داخل الفترة',
            icon: Icons.compare_arrows_rounded,
            showDivider: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.xs,
              children: [
                for (final card in credit.cards)
                  AppRecordTile(
                    icon: Icons.credit_card_outlined,
                    title: card.title,
                    subtitle:
                        'الدين الشهري المتبقي: ${FinanceMoney.formatEgp(card.currentMonthlyDebtMinor)}',
                    trailing: Text(
                      FinanceMoney.formatEgp(card.availableBalanceMinor),
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    showDivider: false,
                  ),
                if (credit.cards.isNotEmpty && filteredSettlements.isNotEmpty)
                  Divider(color: context.colors.divider),
                for (var index = 0; index < filteredSettlements.length; index++)
                  Builder(
                    builder: (context) {
                      final settlement = filteredSettlements[index];
                      final overdue = _isSettlementOverdue(settlement);
                      return AppRecordTile(
                        icon: Icons.fact_check_outlined,
                        tone: overdue ? AppTone.danger : AppTone.info,
                        title: settlement.brandName.isEmpty
                            ? settlement.providerName
                            : '${settlement.brandName} · ${settlement.providerName}',
                        subtitle:
                            '${settlement.periodLabel} · ${settlement.posMachineName.isEmpty ? 'POS غير محدد' : settlement.posMachineName} · ${settlement.destinationBankAccountName.isEmpty ? 'حساب غير محدد' : settlement.destinationBankAccountName}',
                        meta:
                            'دليل: ${settlement.evidenceStatus}${overdue ? ' · متأخر' : ''}',
                        status: settlement.status,
                        trailing: Text(
                          '${FinanceMoney.formatEgp(settlement.collectedMinor)} / ${FinanceMoney.formatEgp(settlement.netMinor)}',
                          style: context.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        showDivider: index != filteredSettlements.length - 1,
                      );
                    },
                  ),
              ],
            ),
          ),
          AppResponsiveGrid(
            minItemWidth: 340,
            maxColumns: 2,
            children: [
              _rowsSection(
                context,
                title: 'تقرير مزودي الدفع',
                icon: Icons.storefront_outlined,
                rows: _providerReportRows(filteredPurchases),
                empty: 'لا توجد مشتريات في الفترة.',
              ),
              _rowsSection(
                context,
                title: 'تقرير العلامات التجارية',
                icon: Icons.sell_outlined,
                rows: _brandReportRows(filteredPurchases, filteredSettlements),
                empty: 'لا توجد علامات تجارية في الفترة.',
                tone: AppTone.info,
              ),
              _rowsSection(
                context,
                title: 'شركات التحصيل والحسابات',
                icon: Icons.account_balance_outlined,
                rows: _receivingCompanyRows(operations),
                empty: 'لا توجد شركات تحصيل مسجلة.',
                tone: AppTone.gold,
              ),
              _rowsSection(
                context,
                title: 'المصروفات المعتمدة',
                icon: Icons.receipt_long_outlined,
                rows: _expenseRows(operations),
                empty: 'لا توجد مصروفات معتمدة.',
                tone: AppTone.warning,
              ),
              _rowsSection(
                context,
                title: 'السحوبات الشخصية',
                icon: Icons.person_remove_outlined,
                rows: _withdrawalRows(operations),
                empty: 'لا توجد سحوبات مقبولة.',
                tone: AppTone.warning,
              ),
              _rowsSection(
                context,
                title: 'الالتزامات والشيكات',
                icon: Icons.description_outlined,
                rows: [
                  ...operations.installments.map(
                    (item) => AppRecordTile(
                      icon: Icons.schedule_outlined,
                      title: item.customerName,
                      subtitle:
                          '${item.reference} · شهرياً ${FinanceMoney.formatEgp(item.monthlyObligationMinor)}',
                      status: item.status,
                      trailing: Text(
                        FinanceMoney.formatEgp(item.remainingMinor),
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  ...operations.checks.map(
                    (item) => AppRecordTile(
                      icon: Icons.payments_outlined,
                      title: item.payee,
                      subtitle: item.reference,
                      status: item.status,
                      trailing: Text(
                        FinanceMoney.formatEgp(item.amountMinor),
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
                empty: 'لا توجد التزامات أو شيكات.',
                tone: AppTone.danger,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rowsSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> rows,
    required String empty,
    AppTone tone = AppTone.primary,
  }) => AppSectionCard(
    title: title,
    icon: icon,
    tone: tone,
    showDivider: true,
    child: rows.isEmpty
        ? AppStateView(icon: icon, title: empty, compact: true)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < rows.length; index++)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    rows[index],
                    if (index != rows.length - 1)
                      Divider(
                        height: 1,
                        color: context.colors.divider.withValues(alpha: 0.7),
                      ),
                  ],
                ),
            ],
          ),
  );

  List<Widget> _brandReportRows(
    List<CreditPurchaseModel> purchases,
    List<SettlementModel> settlements,
  ) {
    final purchasesByBrand = <String, List<CreditPurchaseModel>>{};
    for (final purchase in purchases) {
      purchasesByBrand.putIfAbsent(purchase.brandName, () => []).add(purchase);
    }
    return purchasesByBrand.entries.map((entry) {
      final gross = entry.value.fold<int>(
        0,
        (sum, item) => sum + item.amountMinor,
      );
      final commission = entry.value.fold<int>(
        0,
        (sum, item) => sum + item.commissionMinor,
      );
      final brandSettlements = settlements.where(
        (item) => item.brandName == entry.key,
      );
      final collected = brandSettlements.fold<int>(
        0,
        (sum, item) => sum + item.collectedMinor,
      );
      final overdue = brandSettlements.where(_isSettlementOverdue).length;
      return AppRecordTile(
        icon: Icons.sell_outlined,
        title: entry.key,
        subtitle:
            '${entry.value.length} عملية · عمولة ${FinanceMoney.formatEgp(commission)} · محصل ${FinanceMoney.formatEgp(collected)}${overdue == 0 ? '' : ' · متأخر $overdue'}',
        trailing: Text(
          FinanceMoney.formatEgp(gross - commission),
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        showDivider: false,
      );
    }).toList();
  }

  List<Widget> _providerReportRows(List<CreditPurchaseModel> purchases) {
    final purchasesByProvider = <String, List<CreditPurchaseModel>>{};
    for (final purchase in purchases) {
      purchasesByProvider
          .putIfAbsent(purchase.providerName, () => [])
          .add(purchase);
    }
    return purchasesByProvider.entries.map((entry) {
      final gross = entry.value.fold<int>(
        0,
        (sum, item) => sum + item.amountMinor,
      );
      final commission = entry.value.fold<int>(
        0,
        (sum, item) => sum + item.commissionMinor,
      );
      return AppRecordTile(
        icon: Icons.storefront_outlined,
        title: entry.key,
        subtitle:
            '${entry.value.length} عملية · عمولة ${FinanceMoney.formatEgp(commission)}',
        trailing: Text(
          FinanceMoney.formatEgp(gross - commission),
          style: context.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        showDivider: false,
      );
    }).toList();
  }

  List<Widget> _receivingCompanyRows(
    OperationsState operations,
  ) => operations.receivingCompanies.map((company) {
    final accounts = operations.bankAccounts.where(
      (account) => company.bankAccountIds.contains(account.id),
    );
    final settlements = operations.settlements.where(
      (item) => item.receivingCompanyId == company.id,
    );
    final expected = settlements.fold<int>(
      0,
      (sum, item) => sum + item.netMinor,
    );
    final collected = settlements.fold<int>(
      0,
      (sum, item) => sum + item.collectedMinor,
    );
    return AppRecordTile(
      icon: Icons.account_balance_outlined,
      title: company.name,
      subtitle:
          '${accounts.length} حساب · متوقع ${FinanceMoney.formatEgp(expected)} · مؤكد ${FinanceMoney.formatEgp(collected)}',
      trailing: Text(
        FinanceMoney.formatEgp(
          accounts.fold<int>(0, (sum, item) => sum + item.balanceMinor),
        ),
        style: context.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
      showDivider: false,
    );
  }).toList();

  List<Widget> _expenseRows(OperationsState operations) {
    final totals = <String, int>{};
    for (final expense in operations.expenses.where(
      (item) => item.status == 'approved',
    )) {
      totals.update(
        expense.category,
        (value) => value + expense.amountMinor,
        ifAbsent: () => expense.amountMinor,
      );
    }
    return totals.entries
        .map(
          (entry) => AppRecordTile(
            icon: Icons.receipt_long_outlined,
            title: 'مصروفات · ${entry.key}',
            trailing: Text(
              FinanceMoney.formatEgp(entry.value),
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            showDivider: false,
            onTap: () => _showExpenseCategory(entry.key, operations),
          ),
        )
        .toList();
  }

  List<Widget> _withdrawalRows(OperationsState operations) {
    final totals = <String, int>{};
    for (final withdrawal in operations.personalWithdrawals.where(
      (item) => item.status == 'approved',
    )) {
      totals.update(
        withdrawal.personName,
        (value) => value + withdrawal.amountMinor,
        ifAbsent: () => withdrawal.amountMinor,
      );
    }
    return totals.entries
        .map(
          (entry) => AppRecordTile(
            icon: Icons.person_remove_outlined,
            title: 'سحب شخصي · ${entry.key}',
            trailing: Text(
              FinanceMoney.formatEgp(entry.value),
              style: context.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            showDivider: false,
            onTap: () => _showPersonWithdrawals(entry.key, operations),
          ),
        )
        .toList();
  }

  Future<void> _showExpenseCategory(
    String category,
    OperationsState operations,
  ) {
    final items = operations.expenses
        .where((item) => item.category == category && item.status == 'approved')
        .toList();
    return showAppDialog<void>(
      context: context,
      title: 'تفاصيل مصروفات $category',
      child: items.isEmpty
          ? Text(
              'لا توجد مصروفات معتمدة في هذه الفئة.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.xs,
              children: items
                  .map(
                    (item) => AppRecordTile(
                      title: item.description,
                      subtitle:
                          '${item.beneficiary.isEmpty ? 'بدون مستفيد' : item.beneficiary} · ${item.notes}',
                      trailing: Text(FinanceMoney.formatEgp(item.amountMinor)),
                      showDivider: false,
                    ),
                  )
                  .toList(),
            ),
      actions: [
        BtnWidget(title: 'إغلاق', onTap: () => Navigator.of(context).pop()),
      ],
    );
  }

  Future<void> _showPersonWithdrawals(
    String person,
    OperationsState operations,
  ) {
    final items = operations.personalWithdrawals
        .where((item) => item.personName == person && item.status == 'approved')
        .toList();
    return showAppDialog<void>(
      context: context,
      title: 'سجل سحوبات $person',
      child: items.isEmpty
          ? Text(
              'لا توجد سحوبات معتمدة لهذا الشخص.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colors.textSecondary,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.xs,
              children: items
                  .map(
                    (item) => AppRecordTile(
                      title: item.reason,
                      subtitle: item.accountId,
                      trailing: Text(FinanceMoney.formatEgp(item.amountMinor)),
                      showDivider: false,
                    ),
                  )
                  .toList(),
            ),
      actions: [
        BtnWidget(title: 'إغلاق', onTap: () => Navigator.of(context).pop()),
      ],
    );
  }

  bool _isSettlementOverdue(SettlementModel settlement) {
    if (settlement.status == 'settled') return false;
    final due =
        settlement.expectedCollectionDateMillis ??
        settlement.createdAtMillis + const Duration(days: 7).inMilliseconds;
    return due < DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> _copyCsv() async {
    final credit = _creditCubit.state;
    final operations = _operationsCubit.state;
    final purchases = credit.allPurchases.where(
      (item) => _inMonth(item.purchaseDateMillis, _selectedMonth),
    );
    final settlements = operations.settlements.where(
      (item) => _inMonth(item.createdAtMillis, _selectedMonth),
    );
    final lines = <String>[
      'type,id,provider_or_brand,pos,amount_minor,commission_minor,status',
      ...purchases.map(
        (item) =>
            'purchase,${item.id},${item.brandName},${item.posMachineName},${item.amountMinor},${item.commissionMinor},posted',
      ),
      ...settlements.map(
        (item) =>
            'settlement,${item.id},${item.brandName.isEmpty ? item.providerName : item.brandName},${item.posMachineName},${item.netMinor},${item.commissionMinor},${item.status}',
      ),
      ...operations.bankMovements.map(
        (item) =>
            'bank_movement,${item.id},${item.referenceType},,${item.amountMinor},0,${item.type}',
      ),
    ];
    await Clipboard.setData(ClipboardData(text: lines.join('\n')));
    if (!mounted) return;
    AppToast.showToast(
      message: 'تم نسخ تقرير CSV إلى الحافظة.',
      type: MsgType.success,
    );
  }

  String _reportCsv() {
    final credit = _creditCubit.state;
    final operations = _operationsCubit.state;
    final purchases = credit.allPurchases.where(
      (item) => _inMonth(item.purchaseDateMillis, _selectedMonth),
    );
    final settlements = operations.settlements.where(
      (item) => _inMonth(item.createdAtMillis, _selectedMonth),
    );
    return [
      'type,id,provider_or_brand,pos,amount_minor,commission_minor,status',
      ...purchases.map(
        (item) =>
            'purchase,${item.id},${item.brandName},${item.posMachineName},${item.amountMinor},${item.commissionMinor},posted',
      ),
      ...settlements.map(
        (item) =>
            'settlement,${item.id},${item.brandName.isEmpty ? item.providerName : item.brandName},${item.posMachineName},${item.netMinor},${item.commissionMinor},${item.status}',
      ),
      ...operations.bankMovements.map(
        (item) =>
            'bank_movement,${item.id},${item.referenceType},,${item.amountMinor},0,${item.type}',
      ),
    ].join('\n');
  }

  void _downloadExcel() {
    PrintService.downloadXlsx(
      filename: 'credexa_report.xlsx',
      rows: _reportCsv().split('\n').map((line) => line.split(',')).toList(),
    );
  }

  void _downloadPdf() {
    PrintService.downloadPdf(
      filename: 'credexa_report.pdf',
      lines: _reportCsv().split('\n'),
    );
  }

  bool _inMonth(int millis, DateTime? month) {
    if (month == null) return true;
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    return date.year == month.year && date.month == month.month;
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDate: _selectedMonth ?? DateTime.now(),
      helpText: 'اختر أي يوم من الشهر المطلوب',
    );
    if (!mounted || picked == null) return;
    setState(() => _selectedMonth = DateTime(picked.year, picked.month));
  }
}
