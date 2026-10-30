import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:base/core/enums/enums.dart';
import 'package:base/core/extensions/extensions.dart';
import 'package:base/core/navigation/app_navigation.dart';
import 'package:base/core/services/services.dart';
import 'package:base/core/utils/finance_money.dart';
import 'package:base/core/widgets/widgets.dart';
import 'package:base/view/operations/ui/controllers/operations_cubit/operations_cubit.dart';
import 'package:base/view/operations/ui/controllers/operations_cubit/operations_states.dart';

enum FinancialRecordsSection {
  treasury,
  expenses,
  withdrawals,
  installments,
  checks,
  settlements,
}

class FinancialRecordsPage extends StatefulWidget {
  const FinancialRecordsPage({required this.section, super.key});

  final FinancialRecordsSection section;

  @override
  State<FinancialRecordsPage> createState() => _FinancialRecordsPageState();
}

class _FinancialRecordsPageState extends State<FinancialRecordsPage> {
  late final OperationsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<OperationsCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    destination: _destination,
    title: _title,
    subtitle: _subtitle,
    onRefresh: _cubit.load,
    actions: [
      IconButton(
        tooltip: 'تحديث',
        onPressed: _cubit.load,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
    body: BlocBuilder<OperationsCubit, OperationsState>(
      bloc: _cubit,
      builder: (context, state) {
        final hasRecords =
            state.accounts.isNotEmpty ||
            state.bankAccounts.isNotEmpty ||
            state.movements.isNotEmpty ||
            state.bankMovements.isNotEmpty ||
            state.expenses.isNotEmpty ||
            state.personalWithdrawals.isNotEmpty ||
            state.installments.isNotEmpty ||
            state.checks.isNotEmpty ||
            state.settlements.isNotEmpty;
        if (state.status == RequestStatus.loading && !hasRecords) {
          return AppPageShimmerWidget(type: _shimmerType);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppBreakpoints.of(context).sectionSpacing,
          children: [_summary(state), ..._records(state)],
        );
      },
    ),
  );

  AppDestination get _destination => switch (widget.section) {
    FinancialRecordsSection.treasury => AppDestination.treasury,
    FinancialRecordsSection.expenses => AppDestination.expenses,
    FinancialRecordsSection.withdrawals => AppDestination.withdrawals,
    FinancialRecordsSection.installments => AppDestination.installments,
    FinancialRecordsSection.checks => AppDestination.checks,
    FinancialRecordsSection.settlements => AppDestination.settlements,
  };

  AppPageShimmerType get _shimmerType => switch (widget.section) {
    FinancialRecordsSection.treasury => AppPageShimmerType.treasuryRecords,
    FinancialRecordsSection.expenses => AppPageShimmerType.expenseRecords,
    FinancialRecordsSection.withdrawals => AppPageShimmerType.withdrawalRecords,
    FinancialRecordsSection.installments =>
      AppPageShimmerType.installmentRecords,
    FinancialRecordsSection.checks => AppPageShimmerType.checkRecords,
    FinancialRecordsSection.settlements => AppPageShimmerType.settlementRecords,
  };

  String get _title => switch (widget.section) {
    FinancialRecordsSection.treasury => 'دفتر الخزينة والبنوك',
    FinancialRecordsSection.expenses => 'إدارة المصروفات',
    FinancialRecordsSection.withdrawals => 'إدارة السحوبات الشخصية',
    FinancialRecordsSection.installments => 'حسابات وأقساط التقسيط',
    FinancialRecordsSection.checks => 'تفاصيل وأرشيف الشيكات',
    FinancialRecordsSection.settlements => 'تفاصيل وأرشيف التسويات',
  };

  String get _subtitle => switch (widget.section) {
    FinancialRecordsSection.treasury => 'أرصدة الحسابات والحركات البنكية',
    FinancialRecordsSection.expenses => 'المصروفات المعتمدة وتصنيفاتها',
    FinancialRecordsSection.withdrawals => 'سحوبات الأشخاص ومراجعاتها',
    FinancialRecordsSection.installments => 'الجداول والأقساط المتبقية',
    FinancialRecordsSection.checks => 'الشيكات الصادرة ومتابعة استحقاقها',
    FinancialRecordsSection.settlements => 'تسويات المزودين وطلبات التحصيل',
  };

  Widget _summary(OperationsState state) {
    final value = switch (widget.section) {
      FinancialRecordsSection.treasury =>
        state.accounts.fold<int>(0, (sum, item) => sum + item.balanceMinor) +
            state.bankAccounts.fold<int>(
              0,
              (sum, item) => sum + item.balanceMinor,
            ),
      FinancialRecordsSection.expenses => state.expenses.fold<int>(
        0,
        (sum, item) => sum + item.amountMinor,
      ),
      FinancialRecordsSection.withdrawals =>
        state.personalWithdrawals.fold<int>(
          0,
          (sum, item) => sum + item.amountMinor,
        ),
      FinancialRecordsSection.installments => state.installments.fold<int>(
        0,
        (sum, item) => sum + item.remainingMinor,
      ),
      FinancialRecordsSection.checks => state.checks.fold<int>(
        0,
        (sum, item) => sum + item.amountMinor,
      ),
      FinancialRecordsSection.settlements => state.settlements.fold<int>(
        0,
        (sum, item) => sum + item.grossMinor,
      ),
    };
    final count = switch (widget.section) {
      FinancialRecordsSection.treasury =>
        state.movements.length + state.bankMovements.length,
      FinancialRecordsSection.expenses => state.expenses.length,
      FinancialRecordsSection.withdrawals => state.personalWithdrawals.length,
      FinancialRecordsSection.installments => state.installments.length,
      FinancialRecordsSection.checks => state.checks.length,
      FinancialRecordsSection.settlements => state.settlements.length,
    };
    return AppStatGrid(
      maxColumns: 4,
      children: [
        AppStatCard(
          label: 'السجلات',
          value: '$count',
          icon: Icons.format_list_numbered_rounded,
          tone: AppTone.info,
        ),
        AppStatCard(
          label: 'الإجمالي',
          value: FinanceMoney.formatEgp(value),
          icon: Icons.payments_outlined,
          highlight: true,
        ),
      ],
    );
  }

  List<Widget> _records(OperationsState state) => switch (widget.section) {
    FinancialRecordsSection.treasury => [
      _recordGroup(
        'حسابات الخزينة',
        Icons.account_balance_wallet_outlined,
        state.accounts
            .map(
              (item) => AppRecordTile(
                icon: Icons.account_balance_wallet_outlined,
                title: item.name,
                subtitle: item.active ? 'نشط' : 'غير نشط',
                status: item.active ? 'active' : 'inactive',
                trailing: _amountText(item.balanceMinor),
                showDivider: false,
              ),
            )
            .toList(),
      ),
      _recordGroup(
        'الحسابات البنكية',
        Icons.account_balance_outlined,
        state.bankAccounts
            .map(
              (item) => AppRecordTile(
                icon: Icons.account_balance_outlined,
                title: '${item.bankName} · ${item.accountName}',
                subtitle: '•••• ${item.lastFour}',
                trailing: _amountText(item.balanceMinor),
                showDivider: false,
              ),
            )
            .toList(),
        tone: AppTone.info,
      ),
      _recordGroup('آخر الحركات', Icons.swap_vert_rounded, [
        ...state.movements
            .take(30)
            .map(
              (item) => AppRecordTile(
                icon: item.type == 'inflow'
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
                tone: item.type == 'inflow' ? AppTone.success : AppTone.danger,
                title: item.note.isEmpty ? 'حركة خزينة' : item.note,
                subtitle: item.accountId,
                status: item.approvalStatus,
                trailing: _amountText(item.amountMinor),
                showDivider: false,
              ),
            ),
        ...state.bankMovements
            .take(30)
            .map(
              (item) => AppRecordTile(
                icon: Icons.account_balance_outlined,
                tone: AppTone.info,
                title: item.note.isEmpty ? 'حركة بنكية' : item.note,
                subtitle: item.accountId,
                status: item.approvalStatus,
                trailing: _amountText(item.amountMinor),
                showDivider: false,
              ),
            ),
      ], tone: AppTone.gold),
    ],
    FinancialRecordsSection.expenses => [
      _recordGroup(
        'المصروفات',
        Icons.receipt_long_outlined,
        state.expenses
            .map(
              (item) => AppRecordTile(
                icon: Icons.receipt_long_outlined,
                title: item.description,
                subtitle: '${item.category} · ${item.beneficiary}',
                status: item.status,
                trailing: _amountText(item.amountMinor),
                showDivider: false,
              ),
            )
            .toList(),
      ),
      _recordGroup(
        'تصنيفات المصروفات',
        Icons.category_outlined,
        state.expenseCategories
            .map(
              (item) => AppRecordTile(
                icon: Icons.sell_outlined,
                title: item.name,
                subtitle: item.active ? 'نشط' : 'غير نشط',
                status: item.active ? 'active' : 'inactive',
                showDivider: false,
              ),
            )
            .toList(),
        tone: AppTone.info,
      ),
    ],
    FinancialRecordsSection.withdrawals => [
      _recordGroup(
        'السحوبات الشخصية',
        Icons.person_remove_outlined,
        state.personalWithdrawals
            .map(
              (item) => AppRecordTile(
                icon: Icons.person_remove_outlined,
                title: item.personName,
                subtitle: item.reason,
                status: item.status,
                trailing: _amountText(item.amountMinor),
                showDivider: false,
              ),
            )
            .toList(),
        tone: AppTone.warning,
      ),
    ],
    FinancialRecordsSection.installments => [
      _recordGroup(
        'حسابات التقسيط',
        Icons.schedule_outlined,
        state.installments
            .map(
              (item) => AppRecordTile(
                icon: Icons.schedule_outlined,
                title: '${item.customerName} · ${item.reference}',
                subtitle:
                    'القسط ${FinanceMoney.formatEgp(item.monthlyObligationMinor)}',
                status: item.status,
                trailing: Text(
                  'متبقي ${FinanceMoney.formatEgp(item.remainingMinor)}',
                  style: _amountStyle(),
                ),
                showDivider: false,
              ),
            )
            .toList(),
      ),
      _recordGroup(
        'الجداول',
        Icons.table_rows_outlined,
        state.installmentSchedules
            .map(
              (item) => AppRecordTile(
                icon: Icons.table_rows_outlined,
                title: item.description,
                subtitle: '${item.totalInstallments} أقساط',
                status: item.status,
                trailing: _amountText(
                  item.monthlyAmountMinor * item.remainingInstallments,
                ),
                showDivider: false,
              ),
            )
            .toList(),
        tone: AppTone.info,
      ),
    ],
    FinancialRecordsSection.checks => [
      _recordGroup(
        'الشيكات',
        Icons.description_outlined,
        state.checks
            .map(
              (item) => AppRecordTile(
                icon: item.status == 'deducted'
                    ? Icons.check_circle_outline_rounded
                    : Icons.pending_actions_outlined,
                tone: item.status == 'deducted'
                    ? AppTone.success
                    : AppTone.warning,
                title: '${item.payee} · ${item.reference}',
                subtitle: item.bankName,
                status:
                    item.status == 'issued' &&
                        item.dueDateMillis <
                            DateTime.now().millisecondsSinceEpoch
                    ? 'overdue'
                    : item.status,
                trailing: _amountText(item.amountMinor),
                showDivider: false,
              ),
            )
            .toList(),
        tone: AppTone.warning,
      ),
    ],
    FinancialRecordsSection.settlements => [
      _recordGroup(
        'التسويات',
        Icons.fact_check_outlined,
        state.settlements
            .map(
              (item) => AppRecordTile(
                icon: Icons.fact_check_outlined,
                title: item.brandName.isEmpty
                    ? item.providerName
                    : item.brandName,
                subtitle: '${item.periodLabel} · ${item.approvalStatus}',
                status: item.status,
                trailing: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      FinanceMoney.formatEgp(item.grossMinor),
                      style: _amountStyle(),
                    ),
                    Text(
                      'متحصل ${FinanceMoney.formatEgp(item.collectedMinor)}',
                      style: context.textTheme.labelSmall,
                    ),
                  ],
                ),
                showDivider: false,
              ),
            )
            .toList(),
      ),
      _recordGroup(
        'طلبات التحصيل',
        Icons.payments_outlined,
        state.collectionRequests
            .map(
              (item) => AppRecordTile(
                icon: Icons.payments_outlined,
                tone: AppTone.info,
                title: item.settlementId,
                subtitle: item.collectionType,
                status: item.status,
                trailing: _amountText(item.amountMinor),
                showDivider: false,
              ),
            )
            .toList(),
        tone: AppTone.gold,
      ),
    ],
  };

  TextStyle? _amountStyle() => context.textTheme.bodyMedium?.copyWith(
    fontWeight: FontWeight.w700,
    color: context.colors.onSurface,
  );

  Widget _amountText(int value) =>
      Text(FinanceMoney.formatEgp(value), style: _amountStyle());

  Widget _recordGroup(
    String title,
    IconData icon,
    List<Widget> children, {
    AppTone tone = AppTone.primary,
  }) => AppSectionCard(
    title: title,
    icon: icon,
    tone: tone,
    showDivider: true,
    child: children.isEmpty
        ? const AppStateView(
            icon: Icons.inbox_outlined,
            title: 'لا توجد سجلات لعرضها',
            message: 'ستظهر السجلات هنا بمجرد إضافتها.',
            compact: true,
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < children.length; index++)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    children[index],
                    if (index != children.length - 1)
                      Divider(
                        height: 1,
                        color: context.colors.divider.withValues(alpha: 0.7),
                      ),
                  ],
                ),
            ],
          ),
  );
}
