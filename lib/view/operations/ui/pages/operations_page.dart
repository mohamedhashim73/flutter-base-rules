import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:base/core/enums/enums.dart';
import 'package:base/core/extensions/extensions.dart';
import 'package:base/core/navigation/app_navigation.dart';
import 'package:base/core/services/services.dart';
import 'package:base/core/theme/theme.dart';
import 'package:base/core/utils/finance_money.dart';
import 'package:base/core/widgets/widgets.dart';
import 'package:base/model/domain/treasury_account_model.dart';
import 'package:base/model/domain/installment_account_model.dart';
import 'package:base/model/domain/issued_check_model.dart';
import 'package:base/view/operations/data/models/operations_response_model.dart';
import 'package:base/view/operations/ui/controllers/operations_cubit/operations_cubit.dart';
import 'package:base/view/operations/ui/controllers/operations_cubit/operations_states.dart';

class OperationsPage extends StatefulWidget {
  const OperationsPage({super.key});
  @override
  State<OperationsPage> createState() => _OperationsPageState();
}

class _OperationsPageState extends State<OperationsPage> {
  late final OperationsCubit _cubit;
  TemporaryAttachment? _settlementAttachment;
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

  Future<void> _pickSettlementAttachment({bool camera = false}) async {
    final attachment = await sl<TemporaryAttachmentService>().pickImage(
      camera: camera,
    );
    if (!mounted || attachment == null) return;
    setState(() => _settlementAttachment = attachment);
  }

  void _removeSettlementAttachment() {
    setState(() => _settlementAttachment = null);
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<OperationsCubit, OperationsState>(
        bloc: _cubit,
        listener: (context, state) {
          if (state.actionMessage != null &&
              (state.actionStatus == RequestStatus.success ||
                  state.actionStatus == RequestStatus.failure)) {
            AppToast.showToast(
              message: state.actionMessage!,
              type: state.actionStatus == RequestStatus.failure
                  ? MsgType.error
                  : MsgType.success,
            );
          }
        },
        child: BlocBuilder<OperationsCubit, OperationsState>(
          bloc: _cubit,
          builder: (context, state) => AppPageScaffold(
            destination: AppDestination.operations,
            title: 'التشغيل المالي',
            subtitle: 'الخزينة والبنوك والمصروفات والتقسيط والتحصيل',
            onRefresh: _cubit.load,
            actions: [
              IconButton(
                tooltip: 'تحديث البيانات',
                onPressed: _cubit.load,
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
            body: DataStateBuilderWidget(
              dataState: DataState(
                state: state,
                response: OperationsResponseModel(
                  state.accounts.isEmpty
                      ? const [
                          TreasuryAccountModel(
                            id: '__empty__',
                            name: '',
                            balanceMinor: 0,
                            active: false,
                            updatedAtMillis: 0,
                          ),
                        ]
                      : state.accounts,
                ),
              ),
              onFailure: _cubit.load,
              widget: _content(context, state),
            ),
          ),
        ),
      );

  Widget _content(BuildContext context, OperationsState state) {
    final balance =
        state.accounts.fold<int>(0, (sum, item) => sum + item.balanceMinor) +
        state.bankAccounts.fold<int>(0, (sum, item) => sum + item.balanceMinor);
    final outstanding = state.installments.fold<int>(
      0,
      (sum, item) => sum + item.remainingMinor,
    );
    final monthlyObligation = state.installments.fold<int>(
      0,
      (sum, item) => sum + item.monthlyObligationMinor,
    );
    final expensesTotal = state.expenses.fold<int>(
      0,
      (sum, item) => sum + item.amountMinor,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppBreakpoints.of(context).sectionSpacing,
      children: [
        AppStatGrid(
          children: [
            AppStatCard(
              label: 'أموال الخزينة والبنوك',
              value: FinanceMoney.formatEgp(balance),
              icon: Icons.account_balance_wallet_outlined,
              caption:
                  '${state.accounts.length} خزينة · ${state.bankAccounts.length} حساب بنكي',
              highlight: true,
            ),
            AppStatCard(
              label: 'ذمم التقسيط',
              value: FinanceMoney.formatEgp(outstanding),
              icon: Icons.schedule_outlined,
              tone: AppTone.warning,
              caption: '${state.installments.length} حساب تقسيط',
            ),
            AppStatCard(
              label: 'الالتزام الشهري',
              value: FinanceMoney.formatEgp(monthlyObligation),
              icon: Icons.calendar_month_outlined,
              tone: AppTone.info,
              caption: 'مجموع الأقساط الشهرية',
            ),
            AppStatCard(
              label: 'المصروفات',
              value: FinanceMoney.formatEgp(expensesTotal),
              icon: Icons.receipt_long_outlined,
              tone: AppTone.danger,
              caption: '${state.expenses.length} مصروف مسجل',
            ),
            AppStatCard(
              label: 'التسويات',
              value: '${state.settlements.length}',
              icon: Icons.compare_arrows_rounded,
              tone: AppTone.gold,
              caption: '${state.collectionRequests.length} طلب تحصيل',
            ),
          ],
        ),
        _section(
          'شركات التحصيل والحسابات البنكية',
          Icons.business_outlined,
          AppTone.info,
          subtitle: 'ربط الحسابات البنكية بشركات التحصيل المستخدمة في التسويات',
          children: [_bankAccountForm(), _receivingCompanyForm(state)],
        ),
        _section(
          'الخزينة والحسابات',
          Icons.account_balance_outlined,
          AppTone.primary,
          subtitle: 'إنشاء حسابات الخزينة وتسجيل الحركات اليومية',
          children: [_accountForm(), _movementForm(state)],
        ),
        _section(
          'التحويلات والسحوبات والمطابقة',
          Icons.swap_horiz_rounded,
          AppTone.primary,
          subtitle: 'التحويل بين الحسابات والسحوبات الشخصية والمطابقة',
          children: [
            _transferForm(state),
            _personalWithdrawalForm(state),
            _reconciliationForm(state),
          ],
        ),
        _section(
          'المصروفات',
          Icons.receipt_long_outlined,
          AppTone.warning,
          subtitle: 'تصنيفات المصروفات وتسجيل مصروف جديد',
          children: [_expenseCategoryForm(), _expenseForm(state)],
        ),
        _section(
          'التقسيط والتحصيل',
          Icons.payments_outlined,
          AppTone.info,
          subtitle: 'حسابات التقسيط والجداول والدفعات المسجلة',
          children: [
            _installmentForm(),
            _scheduleForm(state),
            _paymentForm(state),
            _scheduleRecords(state),
          ],
        ),
        _section(
          'التسويات والشيكات',
          Icons.fact_check_outlined,
          AppTone.gold,
          subtitle: 'تسويات مزودي الدفع وطلبات التحصيل والشيكات الصادرة',
          children: [
            _settlementForm(),
            _collectionForm(state),
            _checkForm(state),
          ],
        ),
        _records(context, state),
      ],
    );
  }

  Widget _section(
    String title,
    IconData icon,
    AppTone tone, {
    required List<Widget> children,
    String? subtitle,
  }) => AppSectionCard(
    title: title,
    subtitle: subtitle,
    icon: icon,
    tone: tone,
    showDivider: true,
    child: AppResponsiveGrid(
      minItemWidth: 420,
      maxColumns: 2,
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.lg,
      children: children,
    ),
  );

  Widget _record({
    required String title,
    String? subtitle,
    String? meta,
    IconData? icon,
    AppTone tone = AppTone.neutral,
    String? amount,
    String? caption,
    String approveLabel = 'اعتماد',
    VoidCallback? onApprove,
    VoidCallback? onReject,
    bool showDivider = true,
  }) {
    final hasTrailing =
        amount != null ||
        caption != null ||
        onApprove != null ||
        onReject != null;
    return AppRecordTile(
      title: title,
      subtitle: subtitle,
      meta: meta,
      icon: icon,
      tone: tone,
      showDivider: showDivider,
      trailing: !hasTrailing
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              spacing: 3,
              children: [
                if (amount != null)
                  Text(
                    amount,
                    style: context.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                if (caption != null)
                  Text(
                    caption,
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colors.textSecondary,
                    ),
                  ),
                if (onApprove != null || onReject != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    spacing: AppSpacing.xxs,
                    children: [
                      if (onReject != null)
                        TextBtnWidget(
                          title: 'رفض',
                          txtColor: context.colors.error,
                          txtSize: 11.5,
                          onTap: onReject,
                        ),
                      if (onApprove != null)
                        SizedBox(
                          height: 30,
                          child: BtnWidget(
                            title: approveLabel,
                            height: 30,
                            minWidth: 0,
                            txtSize: 11.5,
                            onTap: onApprove,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
    );
  }

  Widget _groupTitle(String title, IconData icon, {Widget? trailing}) =>
      Padding(
        padding: const EdgeInsetsDirectional.only(
          top: AppSpacing.xs,
          bottom: AppSpacing.xxs,
        ),
        child: Row(
          spacing: AppSpacing.xs,
          children: [
            Icon(icon, size: 17, color: context.colors.textSecondary),
            Expanded(
              child: Text(
                title,
                style: context.textTheme.labelLarge?.copyWith(
                  color: context.colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ?trailing,
          ],
        ),
      );

  Widget _accountForm() => Form(
    key: _cubit.treasuryFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _field(
          'اسم الحساب',
          'مثال: الخزينة الرئيسية',
          _cubit.accountNameController,
        ),
        _field(
          'الرصيد الافتتاحي',
          '0.00',
          _cubit.accountOpeningBalanceController,
          isNum: true,
        ),
        BtnWidget(
          title: 'إنشاء حساب خزينة',
          onTap: _cubit.createTreasuryAccount,
        ),
      ],
    ),
  );

  Widget _bankAccountForm() => Form(
    key: _cubit.bankAccountFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _field('اسم البنك', 'مثال: CIB', _cubit.bankNameController),
        _field(
          'اسم الحساب',
          'الحساب باسم الشركة المستقبلة',
          _cubit.bankAccountNameController,
        ),
        _field(
          'آخر أربعة أرقام',
          '1234',
          _cubit.bankLastFourController,
          isNum: true,
        ),
        _field(
          'الرصيد الافتتاحي',
          '0.00',
          _cubit.bankOpeningBalanceController,
          isNum: true,
        ),
        BtnWidget(title: 'إضافة حساب بنكي', onTap: _cubit.createBankAccount),
        if (_cubit.state.bankAccounts.isNotEmpty)
          ..._cubit.state.bankAccounts.map(
            (account) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.account_balance_outlined),
              title: Text('${account.bankName} · ${account.accountName}'),
              subtitle: Text('•••• ${account.lastFour}'),
              trailing: Text(FinanceMoney.formatEgp(account.balanceMinor)),
            ),
          ),
      ],
    ),
  );

  Widget _receivingCompanyForm(OperationsState state) => Form(
    key: _cubit.receivingCompanyFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _field(
          'اسم شركة التحصيل',
          'مثال: Market Link',
          _cubit.receivingCompanyNameController,
        ),
        DropDownBtnWidget<String>(
          label: 'الحساب البنكي الأساسي',
          hint: state.bankAccounts.isEmpty ? 'أضف حساباً أولاً' : 'اختر الحساب',
          value:
              state.bankAccounts.any(
                (account) => account.id == _cubit.selectedBankAccountId,
              )
              ? _cubit.selectedBankAccountId
              : null,
          items: state.bankAccounts.map((account) => account.id).toList(),
          getLabel: (id) {
            final account = state.bankAccounts.firstWhere(
              (item) => item.id == id,
            );
            return '${account.bankName} · •••• ${account.lastFour}';
          },
          onChanged: (id) => _cubit.selectedBankAccountId = id,
        ),
        BtnWidget(
          title: 'إضافة شركة تحصيل',
          onTap: _cubit.createReceivingCompany,
        ),
        DropDownBtnWidget<String>(
          label: 'الشركة لإضافة حساب آخر',
          hint: state.receivingCompanies.isEmpty
              ? 'أضف شركة أولاً'
              : 'اختر الشركة',
          value:
              state.receivingCompanies.any(
                (company) => company.id == _cubit.selectedAssociationCompanyId,
              )
              ? _cubit.selectedAssociationCompanyId
              : null,
          items: state.receivingCompanies.map((company) => company.id).toList(),
          getLabel: (id) => state.receivingCompanies
              .firstWhere((company) => company.id == id)
              .name,
          onChanged: (id) => _cubit.selectedAssociationCompanyId = id,
        ),
        DropDownBtnWidget<String>(
          label: 'الحساب البنكي الإضافي',
          hint: state.bankAccounts.isEmpty ? 'أضف حساباً أولاً' : 'اختر الحساب',
          value:
              state.bankAccounts.any(
                (account) =>
                    account.id == _cubit.selectedAssociationBankAccountId,
              )
              ? _cubit.selectedAssociationBankAccountId
              : null,
          items: state.bankAccounts.map((account) => account.id).toList(),
          getLabel: (id) {
            final account = state.bankAccounts.firstWhere(
              (item) => item.id == id,
            );
            return '${account.bankName} · •••• ${account.lastFour}';
          },
          onChanged: (id) => _cubit.selectedAssociationBankAccountId = id,
        ),
        BtnWidget(
          title: 'ربط حساب إضافي بالشركة',
          onTap: _cubit.addBankAccountToReceivingCompany,
        ),
        if (state.receivingCompanies.isNotEmpty)
          ...state.receivingCompanies.map(
            (company) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.business_outlined),
              title: Text(company.name),
              subtitle: Text('الحساب الأساسي: ${company.bankAccountId}'),
            ),
          ),
      ],
    ),
  );
  Widget _movementForm(OperationsState state) => Form(
    key: _cubit.movementFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _movementAccountDrop(state),
        DropDownBtnWidget<String>(
          label: 'نوع الحركة',
          hint: 'اختر النوع',
          value: _cubit.movementType,
          items: const ['inflow', 'outflow'],
          getLabel: (v) =>
              v == 'inflow' ? 'إيداع / تدفق داخل' : 'سحب / تدفق خارج',
          onChanged: (v) {
            _cubit.movementType = v;
          },
        ),
        _field('المبلغ', '0.00', _cubit.movementAmountController, isNum: true),
        _field(
          'البيان',
          'وصف الحركة',
          _cubit.movementNoteController,
          optional: true,
        ),
        _field(
          'المصدر أو الطرف المرتبط',
          'اسم العميل أو الجهة',
          _cubit.movementRelatedPartyController,
          optional: true,
        ),
        BtnWidget(title: 'تسجيل حركة', onTap: _cubit.recordMovement),
      ],
    ),
  );
  Widget _transferForm(OperationsState state) => Form(
    key: _cubit.transferFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _financialAccountDrop(state, 'الحساب المصدر', true),
        _financialAccountDrop(state, 'الحساب الوجهة', false),
        _field(
          'قيمة التحويل',
          '0.00',
          _cubit.transferAmountController,
          isNum: true,
        ),
        _field(
          'الرسوم',
          '0.00',
          _cubit.transferFeeController,
          isNum: true,
          optional: true,
        ),
        BtnWidget(
          title: 'تسجيل تحويل داخلي',
          onTap: _cubit.createTreasuryTransfer,
        ),
      ],
    ),
  );
  Widget _personalWithdrawalForm(OperationsState state) => Form(
    key: _cubit.personalWithdrawalFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _accountDrop(state, 'حساب السحب الشخصي'),
        if (state.withdrawalPeople.any((person) => person.active))
          DropdownButtonFormField<String>(
            initialValue:
                state.withdrawalPeople
                    .where((person) => person.active)
                    .map((person) => person.name)
                    .contains(_cubit.personNameController.text)
                ? _cubit.personNameController.text
                : null,
            decoration: const InputDecoration(labelText: 'اسم محفوظ'),
            items: state.withdrawalPeople
                .where((person) => person.active)
                .map(
                  (person) => DropdownMenuItem(
                    value: person.name,
                    child: Text(person.name),
                  ),
                )
                .toList(),
            onChanged: (name) {
              if (name != null) _cubit.personNameController.text = name;
            },
          ),
        _field('الشخص', 'اسم المستفيد', _cubit.personNameController),
        _datePickerButton(
          label: 'تاريخ السحب',
          value: _cubit.personalWithdrawalDate,
          onTap: _pickPersonalWithdrawalDate,
        ),
        _field(
          'المبلغ',
          '0.00',
          _cubit.personalWithdrawalAmountController,
          isNum: true,
        ),
        _field('السبب', 'سبب السحب', _cubit.personalWithdrawalReasonController),
        BtnWidget(
          title: 'تسجيل سحب شخصي',
          onTap: _cubit.createPersonalWithdrawal,
        ),
      ],
    ),
  );
  Widget _reconciliationForm(OperationsState state) => Form(
    key: _cubit.reconciliationFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _accountDrop(state, 'الحساب للمطابقة'),
        _field(
          'الرصيد المتوقع',
          '0.00',
          _cubit.reconciliationExpectedController,
          isNum: true,
        ),
        _field(
          'الرصيد الفعلي',
          '0.00',
          _cubit.reconciliationActualController,
          isNum: true,
        ),
        _field(
          'سبب الفارق',
          'شرح المطابقة',
          _cubit.reconciliationReasonController,
        ),
        BtnWidget(title: 'حفظ المطابقة', onTap: _cubit.createReconciliation),
      ],
    ),
  );
  Widget _expenseForm(OperationsState state) => Form(
    key: _cubit.expenseFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _accountDrop(state, 'حساب الدفع'),
        if (state.expenseCategories.isEmpty)
          _field(
            'التصنيف',
            'أنشئ تصنيفاً أو اكتب اسماً',
            _cubit.expenseCategoryController,
          )
        else
          DropDownBtnWidget<String>(
            label: 'التصنيف',
            hint: 'اختر تصنيفاً',
            items: state.expenseCategories
                .map((category) => category.name)
                .toList(),
            getLabel: (name) => name,
            onChanged: (name) => _cubit.expenseCategoryController.text = name,
          ),
        _field('الوصف', 'تفاصيل المصروف', _cubit.expenseDescriptionController),
        _field(
          'المستفيد أو الجهة',
          'اسم المستفيد',
          _cubit.expenseBeneficiaryController,
          optional: true,
        ),
        _field('المبلغ', '0.00', _cubit.expenseAmountController, isNum: true),
        _datePickerButton(
          label: 'تاريخ المصروف',
          value: _cubit.expenseDate,
          onTap: _pickExpenseDate,
        ),
        _field(
          'ملاحظات',
          'ملاحظات إضافية',
          _cubit.expenseNotesController,
          optional: true,
        ),
        BtnWidget(title: 'حفظ المصروف', onTap: _cubit.createExpense),
      ],
    ),
  );
  Widget _expenseCategoryForm() => Form(
    key: _cubit.expenseCategoryFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _field(
          'تصنيف جديد',
          'مثال: إيجار أو نقل',
          _cubit.expenseCategoryNameController,
        ),
        BtnWidget(title: 'إضافة تصنيف', onTap: _cubit.createExpenseCategory),
      ],
    ),
  );
  Widget _installmentForm() => Form(
    key: _cubit.installmentFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _field('اسم الشخص', 'اسم صاحب الحساب', _cubit.customerNameController),
        _field(
          'اسم تطبيق التقسيط',
          'مثال: Valu أو Halan',
          _cubit.installmentReferenceController,
        ),
        _field(
          'حد التطبيق الكلي',
          '0.00',
          _cubit.totalLimitController,
          isNum: true,
        ),
        _field(
          'المبلغ المستخدم',
          '0.00',
          _cubit.principalController,
          isNum: true,
        ),
        _field(
          'تاريخ الاستحقاق التالي',
          'اختياري — YYYY-MM-DD',
          _cubit.installmentDueDateController,
          optional: true,
        ),
        _field(
          'إجمالي الاستحقاق',
          '0.00',
          _cubit.totalDueController,
          isNum: true,
        ),
        _field(
          'القسط الشهري',
          '0.00',
          _cubit.monthlyInstallmentController,
          isNum: true,
        ),
        _field(
          'عدد الأقساط',
          'مثال: 12',
          _cubit.totalInstallmentsController,
          isNum: true,
        ),
        BtnWidget(title: 'إنشاء حساب تقسيط', onTap: _cubit.createInstallment),
      ],
    ),
  );
  Widget _paymentForm(OperationsState state) => Form(
    key: _cubit.paymentFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _accountDrop(state, 'مصدر دفع القسط'),
        _installmentDrop(state),
        _scheduleDrop(state),
        _field(
          'قيمة الدفعة',
          '0.00',
          _cubit.paymentAmountController,
          isNum: true,
        ),
        BtnWidget(title: 'تسجيل دفعة', onTap: _cubit.recordInstallmentPayment),
      ],
    ),
  );

  Widget _scheduleForm(OperationsState state) => Form(
    key: _cubit.installmentScheduleFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _installmentDrop(state),
        _field(
          'وصف جدول التقسيط',
          'مثال: جهاز أو عملية شراء',
          _cubit.scheduleDescriptionController,
        ),
        _field(
          'أصل الجدول',
          '0.00',
          _cubit.schedulePrincipalController,
          isNum: true,
        ),
        _field(
          'إجمالي الجدول',
          '0.00',
          _cubit.scheduleTotalDueController,
          isNum: true,
        ),
        _field(
          'القسط الشهري',
          '0.00',
          _cubit.scheduleMonthlyAmountController,
          isNum: true,
        ),
        _field(
          'عدد الأقساط',
          'مثال: 12',
          _cubit.scheduleTotalInstallmentsController,
          isNum: true,
        ),
        BtnWidget(
          title: 'إضافة جدول للحساب',
          onTap: _cubit.createInstallmentSchedule,
        ),
      ],
    ),
  );

  Widget _scheduleRecords(OperationsState state) => AppSurface(
    padding: const EdgeInsets.all(AppSpacing.md),
    color: context.colors.surfaceMuted,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xs,
      children: [
        _groupTitle('حسابات التقسيط', Icons.schedule_outlined),
        if (state.installments.isEmpty)
          AppStateView(
            title: 'لا توجد حسابات تقسيط مسجلة',
            message: 'أنشئ حساب تقسيط لعرضه هنا ومتابعة جداوله.',
            icon: Icons.schedule_outlined,
            compact: true,
          )
        else
          for (var index = 0; index < state.installments.length; index++)
            AppRecordTile(
              title:
                  '${state.installments[index].customerName} · ${state.installments[index].reference}',
              subtitle:
                  '${appStatusLabel(state.installments[index].status)} · متاح ${FinanceMoney.formatEgp(state.installments[index].currentAvailableMinor)}',
              icon: Icons.schedule_outlined,
              tone: AppTone.info,
              showDivider: index != state.installments.length - 1,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.xxs,
                children: [
                  IconButton(
                    tooltip: 'تعديل الحساب',
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints(
                      minWidth: 30,
                      minHeight: 30,
                    ),
                    padding: EdgeInsets.zero,
                    onPressed: () =>
                        _showInstallmentEdit(state.installments[index]),
                    icon: const Icon(Icons.edit_outlined, size: 17),
                  ),
                  if (state.installments[index].status == 'active')
                    TextBtnWidget(
                      title: 'أرشفة',
                      txtSize: 11.5,
                      onTap: () => _changeInstallmentStatus(
                        state.installments[index],
                        'archived',
                      ),
                    )
                  else if (state.installments[index].status == 'archived')
                    TextBtnWidget(
                      title: 'إعادة تفعيل',
                      txtSize: 11.5,
                      onTap: () => _changeInstallmentStatus(
                        state.installments[index],
                        'active',
                      ),
                    ),
                ],
              ),
            ),
        Divider(height: AppSpacing.lg, color: context.colors.divider),
        _groupTitle('جداول الأقساط', Icons.receipt_long_outlined),
        if (state.installmentSchedules.isEmpty)
          const Text('لا توجد جداول أقساط مسجلة.')
        else
          for (
            var index = 0;
            index < state.installmentSchedules.length;
            index++
          )
            AppRecordTile(
              title: state.installmentSchedules[index].description,
              subtitle:
                  '${state.installmentSchedules[index].paidInstallments}/${state.installmentSchedules[index].totalInstallments} · القسط ${FinanceMoney.formatEgp(state.installmentSchedules[index].monthlyAmountMinor)}',
              meta: appStatusLabel(state.installmentSchedules[index].status),
              icon: Icons.event_note_outlined,
              tone: AppTone.neutral,
              showDivider: index != state.installmentSchedules.length - 1,
              trailing: Text(
                FinanceMoney.formatEgp(
                  state.installmentSchedules[index].totalDueMinor,
                ),
                style: context.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
      ],
    ),
  );
  Widget _settlementForm() => Form(
    key: _cubit.settlementFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        DropDownBtnWidget<String>(
          label: 'العلامة التجارية',
          hint: _cubit.state.brands.isEmpty
              ? 'أنشئ علامة مرتبطة بالتوجيه أولاً'
              : 'اختر العلامة',
          value:
              _cubit.state.brands.any(
                (brand) => brand.id == _cubit.selectedSettlementBrandId,
              )
              ? _cubit.selectedSettlementBrandId
              : null,
          items: _cubit.state.brands.map((brand) => brand.id).toList(),
          getLabel: (id) {
            final brand = _cubit.state.brands.firstWhere(
              (item) => item.id == id,
            );
            return '${brand.name} · ${brand.providerName} · ${brand.receivingCompanyName.isEmpty ? 'لم يحدد الحساب' : brand.receivingCompanyName}';
          },
          onChanged: _cubit.selectSettlementBrand,
        ),
        _settlementPurchaseSelector(_cubit.state),
        _field('الفترة', 'مثال: 2026-10', _cubit.settlementPeriodController),
        _field(
          'الإجمالي',
          '0.00',
          _cubit.settlementGrossController,
          isNum: true,
        ),
        _field(
          'العمولة',
          '0.00',
          _cubit.settlementCommissionController,
          isNum: true,
        ),
        _field(
          'معرفات المعاملات المشمولة',
          'اختياري — افصل المعرفات بفاصلة أو سطر جديد',
          _cubit.settlementTransactionIdsController,
          optional: true,
        ),
        AppSurface(
          color: context.colors.surfaceMuted,
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.sm,
            children: [
              Row(
                spacing: AppSpacing.xs,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 18,
                    color: context.colors.textSecondary,
                  ),
                  Expanded(
                    child: Text(
                      'إيصال التسوية — معاينة مؤقتة فقط',
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              if (_settlementAttachment == null)
                Text(
                  'لم يتم اختيار إيصال. لن يتم حفظ أي ملف بشكل دائم.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              if (_settlementAttachment != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppDesignRadius.control),
                  child: SizedBox(
                    height: 180,
                    child: Image.memory(
                      _settlementAttachment!.bytes,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Text(
                  '${_settlementAttachment!.fileName} · لن يتم رفعه أو تخزينه بعد إعادة التحميل.',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.textSecondary,
                  ),
                ),
              ],
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  BtnWidget(
                    title: 'اختيار صورة',
                    height: 38,
                    txtSize: 12.5,
                    prefix: const Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white,
                      size: 17,
                    ),
                    onTap: () => _pickSettlementAttachment(),
                  ),
                  BtnWidget(
                    title: 'الكاميرا',
                    height: 38,
                    txtSize: 12.5,
                    prefix: const Icon(
                      Icons.camera_alt_outlined,
                      color: Colors.white,
                      size: 17,
                    ),
                    onTap: () => _pickSettlementAttachment(camera: true),
                  ),
                  if (_settlementAttachment != null)
                    TextBtnWidget(
                      title: 'إزالة',
                      txtColor: context.colors.error,
                      onTap: _removeSettlementAttachment,
                    ),
                ],
              ),
            ],
          ),
        ),
        _field(
          'سبب رفض التسوية',
          'يستخدم عند رفض تسوية معلقة',
          _cubit.settlementRejectionReasonController,
          optional: true,
        ),
        BtnWidget(title: 'إنشاء تسوية', onTap: _cubit.createSettlement),
      ],
    ),
  );

  Widget _settlementPurchaseSelector(OperationsState state) {
    final alreadyIncluded = state.settlements
        .expand((settlement) => settlement.includedTransactionIds)
        .toSet();
    final eligible = state.creditPurchases
        .where(
          (purchase) =>
              purchase.brandId == _cubit.selectedSettlementBrandId &&
              !alreadyIncluded.contains(purchase.id),
        )
        .toList();
    if (eligible.isEmpty) {
      return AppInfoBanner(
        message:
            'لا توجد مشتريات مؤهلة غير مسواة لهذه العلامة. يمكنك إدخال معرفات المعاملات يدوياً عند الحاجة.',
        tone: AppTone.info,
        icon: Icons.info_outline_rounded,
      );
    }
    return AppSurface(
      color: context.colors.surfaceMuted,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.xxs,
        children: [
          Row(
            spacing: AppSpacing.xs,
            children: [
              Icon(
                Icons.checklist_rounded,
                size: 18,
                color: context.colors.textSecondary,
              ),
              Expanded(
                child: Text(
                  'المعاملات المؤهلة للتسوية',
                  style: context.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              AppStatusChip(
                status: 'normal',
                label: '${eligible.length}',
                compact: true,
              ),
            ],
          ),
          for (final purchase in eligible)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.trailing,
              value: _cubit.selectedSettlementPurchaseIds.contains(purchase.id),
              onChanged: (_) => _cubit.toggleSettlementPurchase(purchase),
              title: Text(
                '${purchase.brandName} · ${FinanceMoney.formatEgp(purchase.amountMinor)}',
              ),
              subtitle: Text(
                '${purchase.providerName} · ${purchase.posMachineName.isEmpty ? 'POS غير محدد' : purchase.posMachineName} · ${purchase.id}',
              ),
            ),
        ],
      ),
    );
  }

  Widget _checkForm(OperationsState state) => Form(
    key: _cubit.checkFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        DropDownBtnWidget<String>(
          label: 'الحساب البنكي المصدر',
          hint: state.bankAccounts.isEmpty
              ? 'أضف حساباً بنكياً أولاً'
              : 'اختر الحساب',
          value:
              state.bankAccounts.any(
                (account) => account.id == _cubit.selectedCheckBankAccountId,
              )
              ? _cubit.selectedCheckBankAccountId
              : null,
          items: state.bankAccounts.map((account) => account.id).toList(),
          getLabel: (id) {
            final account = state.bankAccounts.firstWhere(
              (item) => item.id == id,
            );
            return '${account.bankName} · •••• ${account.lastFour}';
          },
          onChanged: (id) => _cubit.selectedCheckBankAccountId = id,
        ),
        _field('المستفيد', 'اسم المستفيد', _cubit.checkPayeeController),
        _field('رقم الشيك', 'المرجع', _cubit.checkReferenceController),
        _field(
          'البنك',
          'اسم البنك',
          _cubit.checkBankNameController,
          optional: true,
        ),
        _field('القيمة', '0.00', _cubit.checkAmountController, isNum: true),
        _field('تاريخ الاستحقاق', 'YYYY-MM-DD', _cubit.checkDueDateController),
        _field(
          'ملاحظات',
          'ملاحظات إضافية',
          _cubit.checkNotesController,
          optional: true,
        ),
        BtnWidget(title: 'تسجيل شيك صادر', onTap: _cubit.createCheck),
      ],
    ),
  );

  Widget _collectionForm(OperationsState state) => Form(
    key: _cubit.collectionRequestFormKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        DropDownBtnWidget<String>(
          label: 'التسوية',
          hint: state.settlements.isEmpty ? 'أنشئ تسوية أولاً' : 'اختر التسوية',
          value:
              state.settlements.any((s) => s.id == _cubit.selectedSettlementId)
              ? _cubit.selectedSettlementId
              : null,
          items: state.settlements.map((s) => s.id).toList(),
          getLabel: (id) =>
              state.settlements.firstWhere((s) => s.id == id).periodLabel,
          onChanged: (id) => _cubit.selectedSettlementId = id,
        ),
        DropDownBtnWidget<String>(
          label: 'نوع التحصيل',
          hint: 'اختر النوع',
          value: _cubit.collectionType,
          items: const ['normal', 'instant'],
          getLabel: (type) =>
              type == 'instant' ? 'تحصيل فوري · 0.1%' : 'تحصيل عادي',
          onChanged: _cubit.selectCollectionType,
        ),
        _field(
          'قيمة طلب التحصيل',
          '0.00',
          _cubit.collectionAmountController,
          isNum: true,
        ),
        BtnWidget(
          title: _cubit.collectionType == 'instant'
              ? 'طلب تحصيل فوري 0.1%'
              : 'طلب تحصيل عادي',
          onTap: _cubit.createCollectionRequest,
        ),
        DropDownBtnWidget<String>(
          label: 'طلب التحصيل للتأكيد',
          hint: state.collectionRequests.isEmpty
              ? 'لا توجد طلبات'
              : 'اختر الطلب',
          value:
              state.collectionRequests.any(
                (r) => r.id == _cubit.selectedCollectionRequestId,
              )
              ? _cubit.selectedCollectionRequestId
              : null,
          items: state.collectionRequests.map((r) => r.id).toList(),
          getLabel: (id) => FinanceMoney.formatEgp(
            state.collectionRequests.firstWhere((r) => r.id == id).amountMinor,
          ),
          onChanged: (id) => _cubit.selectedCollectionRequestId = id,
        ),
        _field(
          'مرجع التحويل البنكي',
          'رقم العملية',
          _cubit.collectionConfirmationController,
        ),
        BtnWidget(
          title: 'تأكيد التحصيل يدوياً',
          onTap: _cubit.confirmCollectionRequest,
        ),
      ],
    ),
  );

  Widget _accountDrop(OperationsState state, String label) =>
      DropDownBtnWidget<String>(
        label: label,
        hint: state.accounts.isEmpty ? 'أنشئ حساباً أولاً' : 'اختر الحساب',
        value: state.accounts.any((a) => a.id == _cubit.selectedAccountId)
            ? _cubit.selectedAccountId
            : null,
        items: state.accounts.map((a) => a.id).toList(),
        getLabel: (id) => state.accounts.firstWhere((a) => a.id == id).name,
        onChanged: (id) => _cubit.selectedAccountId = id,
      );

  Widget _movementAccountDrop(OperationsState state) {
    final values = [
      ...state.accounts.map((account) => 'treasury:${account.id}'),
      ...state.bankAccounts.map((account) => 'bank:${account.id}'),
    ];
    final selected = _cubit.selectedMovementAccountId == null
        ? null
        : '${_cubit.selectedMovementAccountType}:${_cubit.selectedMovementAccountId}';
    return DropDownBtnWidget<String>(
      label: 'الحساب المالي',
      hint: values.isEmpty ? 'أنشئ حساباً أولاً' : 'اختر الحساب',
      value: values.contains(selected) ? selected : null,
      items: values,
      getLabel: (value) {
        final parts = value.split(':');
        final id = parts.skip(1).join(':');
        if (parts.first == 'bank') {
          final account = state.bankAccounts.firstWhere(
            (item) => item.id == id,
          );
          return 'بنك · ${account.bankName} · •••• ${account.lastFour}';
        }
        return 'خزينة · ${state.accounts.firstWhere((item) => item.id == id).name}';
      },
      onChanged: _cubit.selectMovementAccount,
    );
  }

  Widget _financialAccountDrop(
    OperationsState state,
    String label,
    bool source,
  ) {
    final values = [
      ...state.accounts.map((account) => 'treasury:${account.id}'),
      ...state.bankAccounts.map((account) => 'bank:${account.id}'),
    ];
    final selectedId = source
        ? _cubit.selectedAccountId
        : _cubit.selectedDestinationAccountId;
    final selectedType = source
        ? _cubit.selectedTransferSourceType
        : _cubit.selectedTransferDestinationType;
    final selected = selectedId == null ? null : '$selectedType:$selectedId';
    return DropDownBtnWidget<String>(
      label: label,
      hint: values.isEmpty ? 'أنشئ حساباً أولاً' : 'اختر الحساب',
      value: values.contains(selected) ? selected : null,
      items: values,
      getLabel: (value) {
        final parts = value.split(':');
        final id = parts.skip(1).join(':');
        if (parts.first == 'bank') {
          final account = state.bankAccounts.firstWhere(
            (item) => item.id == id,
          );
          return 'بنك · ${account.bankName} · •••• ${account.lastFour}';
        }
        return 'خزينة · ${state.accounts.firstWhere((item) => item.id == id).name}';
      },
      onChanged: source
          ? _cubit.selectTransferSource
          : _cubit.selectTransferDestination,
    );
  }

  Widget _installmentDrop(OperationsState state) => DropDownBtnWidget<String>(
    label: 'حساب التقسيط',
    hint: state.installments.isEmpty ? 'أنشئ حساباً أولاً' : 'اختر الحساب',
    value: state.installments.any((a) => a.id == _cubit.selectedInstallmentId)
        ? _cubit.selectedInstallmentId
        : null,
    items: state.installments.map((a) => a.id).toList(),
    getLabel: (id) =>
        state.installments.firstWhere((a) => a.id == id).customerName,
    onChanged: (id) => _cubit.selectedInstallmentId = id,
  );
  Widget _scheduleDrop(OperationsState state) {
    final schedules = state.installmentSchedules
        .where((item) => item.accountId == _cubit.selectedInstallmentId)
        .toList();
    return DropDownBtnWidget<String>(
      label: 'جدول الدفعة',
      hint: schedules.isEmpty ? 'لا توجد جداول لهذا الحساب' : 'اختر الجدول',
      value:
          schedules.any(
            (item) => item.id == _cubit.selectedInstallmentScheduleId,
          )
          ? _cubit.selectedInstallmentScheduleId
          : null,
      items: schedules.map((item) => item.id).toList(),
      getLabel: (id) =>
          schedules.firstWhere((item) => item.id == id).description,
      onChanged: (id) => _cubit.selectedInstallmentScheduleId = id,
    );
  }

  Widget _field(
    String label,
    String hint,
    TextEditingController controller, {
    bool isNum = false,
    bool optional = false,
  }) => TxtFieldWidget(
    label: label,
    hint: hint,
    controller: controller,
    isNum: isNum,
    isOptional: optional,
    textInputType: isNum ? TextInputType.number : null,
  );

  Widget _datePickerButton({
    required String label,
    required DateTime value,
    required Future<void> Function() onTap,
  }) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: TextButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_month_outlined),
      label: Text('$label: ${DateFormat('yyyy-MM-dd').format(value)}'),
    ),
  );

  Future<void> _pickExpenseDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _cubit.expenseDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (value != null) _cubit.setExpenseDate(value);
  }

  Future<void> _pickPersonalWithdrawalDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _cubit.personalWithdrawalDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (value != null) _cubit.setPersonalWithdrawalDate(value);
  }

  Widget _records(BuildContext context, OperationsState state) {
    final recentMovements = state.movements.take(5).toList();
    final bankMovements = state.bankMovements.take(8).toList();
    final pendingExpenses = state.expenses
        .where((item) => item.status == 'pending')
        .toList();
    final pendingWithdrawals = state.personalWithdrawals
        .where((item) => item.status == 'pending')
        .toList();
    final pendingSettlements = state.settlements
        .where((item) => item.approvalStatus == 'pending')
        .toList();
    final hasApprovals =
        pendingExpenses.isNotEmpty ||
        pendingWithdrawals.isNotEmpty ||
        pendingSettlements.isNotEmpty;
    final recentExpenses = state.expenses.take(5).toList();
    final recentReconciliations = state.reconciliations.take(5).toList();
    final recentSettlements = state.settlements.take(5).toList();
    final recentChecks = state.checks.take(3).toList();

    return AppSectionCard(
      title: 'آخر السجلات والاعتمادات المعلقة',
      subtitle: 'متابعة أحدث الحركات المالية واعتماد الطلبات العالقة',
      icon: Icons.history_rounded,
      tone: AppTone.neutral,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _groupTitle('آخر حركات الخزينة', Icons.swap_vert_rounded),
          if (recentMovements.isEmpty)
            _emptyRecords('لا توجد حركات خزينة مسجلة.')
          else
            for (var index = 0; index < recentMovements.length; index++)
              _record(
                title: recentMovements[index].note.isEmpty
                    ? 'حركة خزينة'
                    : recentMovements[index].note,
                subtitle: appStatusLabel(recentMovements[index].approvalStatus),
                icon: recentMovements[index].type == 'inflow'
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
                tone: recentMovements[index].type == 'inflow'
                    ? AppTone.success
                    : AppTone.danger,
                amount: FinanceMoney.formatEgp(
                  recentMovements[index].amountMinor,
                ),
                showDivider: index != recentMovements.length - 1,
                onApprove: recentMovements[index].approvalStatus == 'pending'
                    ? () => _cubit.approveTreasuryMovement(
                        recentMovements[index].id,
                      )
                    : null,
              ),
          if (bankMovements.isNotEmpty) ...[
            _groupTitle('الحركات البنكية', Icons.account_balance_outlined),
            for (var index = 0; index < bankMovements.length; index++)
              _record(
                title: bankMovements[index].type == 'collection_inflow'
                    ? 'تحصيل بنكي · ${bankMovements[index].referenceId}'
                    : 'خصم شيك · ${bankMovements[index].referenceId}',
                subtitle: bankMovements[index].note,
                icon: bankMovements[index].type == 'collection_inflow'
                    ? Icons.south_west_rounded
                    : Icons.north_east_rounded,
                tone: bankMovements[index].type == 'collection_inflow'
                    ? AppTone.success
                    : AppTone.warning,
                amount: FinanceMoney.formatEgp(
                  bankMovements[index].amountMinor,
                ),
                showDivider: index != bankMovements.length - 1,
              ),
          ],
          if (state.transfers.isNotEmpty) ...[
            _groupTitle('سجل التحويلات الداخلية', Icons.swap_horiz_rounded),
            for (var index = 0; index < state.transfers.length; index++)
              _record(
                title:
                    'تحويل داخلي · ${state.transfers[index].sourceAccountId} → ${state.transfers[index].destinationAccountId}',
                subtitle: appStatusLabel(state.transfers[index].status),
                icon: Icons.swap_horiz_rounded,
                tone: AppTone.info,
                amount: FinanceMoney.formatEgp(
                  state.transfers[index].amountMinor,
                ),
                showDivider: index != state.transfers.length - 1,
                onApprove: state.transfers[index].status == 'pending'
                    ? () => _cubit.approveTreasuryTransfer(
                        state.transfers[index].id,
                      )
                    : null,
              ),
          ],
          if (hasApprovals) ...[
            _groupTitle(
              'مركز الاعتمادات المعلقة',
              Icons.approval_outlined,
              trailing: AppStatusChip(
                status: 'pending',
                label:
                    '${pendingExpenses.length + pendingWithdrawals.length + pendingSettlements.length}',
                compact: true,
              ),
            ),
            for (var index = 0; index < pendingExpenses.length; index++)
              _record(
                title: 'مصروف: ${pendingExpenses[index].description}',
                subtitle: pendingExpenses[index].category,
                icon: Icons.receipt_long_outlined,
                tone: AppTone.warning,
                amount: FinanceMoney.formatEgp(
                  pendingExpenses[index].amountMinor,
                ),
                showDivider:
                    index != pendingExpenses.length - 1 ||
                    pendingWithdrawals.isNotEmpty ||
                    pendingSettlements.isNotEmpty,
                onApprove: () =>
                    _cubit.approveExpense(pendingExpenses[index].id),
              ),
            for (var index = 0; index < pendingWithdrawals.length; index++)
              _record(
                title: 'سحب شخصي: ${pendingWithdrawals[index].personName}',
                subtitle: pendingWithdrawals[index].reason,
                icon: Icons.person_remove_outlined,
                tone: AppTone.danger,
                amount: FinanceMoney.formatEgp(
                  pendingWithdrawals[index].amountMinor,
                ),
                showDivider:
                    index != pendingWithdrawals.length - 1 ||
                    pendingSettlements.isNotEmpty,
                onApprove: () => _cubit.approvePersonalWithdrawal(
                  pendingWithdrawals[index].id,
                ),
              ),
            for (var index = 0; index < pendingSettlements.length; index++)
              _record(
                title: 'تسوية: ${pendingSettlements[index].brandName}',
                subtitle: pendingSettlements[index].periodLabel,
                icon: Icons.fact_check_outlined,
                tone: AppTone.info,
                amount: FinanceMoney.formatEgp(
                  pendingSettlements[index].grossMinor,
                ),
                showDivider: index != pendingSettlements.length - 1,
                onApprove: () =>
                    _cubit.approveSettlement(pendingSettlements[index].id),
                onReject: () =>
                    _cubit.rejectSettlement(pendingSettlements[index].id),
              ),
          ],
          if (recentChecks.isNotEmpty) ...[
            _groupTitle('الشيكات الصادرة', Icons.description_outlined),
            for (var index = 0; index < recentChecks.length; index++)
              _checkTile(
                recentChecks[index],
                showDivider: index != recentChecks.length - 1,
              ),
          ],
          if (recentExpenses.isNotEmpty) ...[
            _groupTitle('أحدث المصروفات', Icons.receipt_long_outlined),
            for (var index = 0; index < recentExpenses.length; index++)
              _record(
                title: recentExpenses[index].description,
                subtitle:
                    '${recentExpenses[index].category} · ${appStatusLabel(recentExpenses[index].status)}',
                icon: Icons.receipt_long_outlined,
                tone: AppTone.warning,
                amount: FinanceMoney.formatEgp(
                  recentExpenses[index].amountMinor,
                ),
                showDivider: index != recentExpenses.length - 1,
                onApprove: recentExpenses[index].status != 'approved'
                    ? () => _cubit.approveExpense(recentExpenses[index].id)
                    : null,
              ),
          ],
          if (state.personalWithdrawals.isNotEmpty) ...[
            _groupTitle('سجل السحوبات الشخصية', Icons.person_remove_outlined),
            for (
              var index = 0;
              index < state.personalWithdrawals.length;
              index++
            )
              _record(
                title:
                    'سحب شخصي · ${state.personalWithdrawals[index].personName}',
                subtitle: state.personalWithdrawals[index].reason,
                meta: appStatusLabel(state.personalWithdrawals[index].status),
                icon: Icons.person_remove_outlined,
                tone: AppTone.danger,
                amount: FinanceMoney.formatEgp(
                  state.personalWithdrawals[index].amountMinor,
                ),
                showDivider: index != state.personalWithdrawals.length - 1,
                onApprove: state.personalWithdrawals[index].status == 'pending'
                    ? () => _cubit.approvePersonalWithdrawal(
                        state.personalWithdrawals[index].id,
                      )
                    : null,
              ),
          ],
          if (recentReconciliations.isNotEmpty) ...[
            _groupTitle('عمليات مطابقة الخزينة', Icons.fact_check_outlined),
            for (var index = 0; index < recentReconciliations.length; index++)
              _record(
                title: 'مطابقة خزينة',
                subtitle: recentReconciliations[index].reason,
                icon: recentReconciliations[index].differenceMinor == 0
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_outlined,
                tone: recentReconciliations[index].differenceMinor == 0
                    ? AppTone.success
                    : AppTone.warning,
                amount: FinanceMoney.formatEgp(
                  recentReconciliations[index].differenceMinor,
                ),
                showDivider: index != recentReconciliations.length - 1,
              ),
          ],
          if (recentSettlements.isNotEmpty) ...[
            _groupTitle('أحدث التسويات', Icons.compare_arrows_rounded),
            for (var index = 0; index < recentSettlements.length; index++)
              _record(
                title:
                    '${recentSettlements[index].providerName} · ${appStatusLabel(recentSettlements[index].approvalStatus)}',
                subtitle: recentSettlements[index].periodLabel,
                icon: Icons.fact_check_outlined,
                tone: AppTone.info,
                amount: FinanceMoney.formatEgp(
                  recentSettlements[index].netMinor,
                ),
                showDivider: index != recentSettlements.length - 1,
                onApprove: recentSettlements[index].approvalStatus == 'pending'
                    ? () =>
                          _cubit.approveSettlement(recentSettlements[index].id)
                    : null,
                onReject: recentSettlements[index].approvalStatus == 'pending'
                    ? () => _cubit.rejectSettlement(recentSettlements[index].id)
                    : null,
              ),
          ],
        ],
      ),
    );
  }

  Widget _checkTile(IssuedCheckModel check, {required bool showDivider}) {
    final dueDate = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.fromMillisecondsSinceEpoch(check.dueDateMillis));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _record(
          title: check.payee,
          subtitle:
              'شيك · ${check.reference} · ${appStatusLabel(check.status)}',
          meta: 'تاريخ الاستحقاق $dueDate',
          icon: Icons.description_outlined,
          tone: AppTone.info,
          amount: FinanceMoney.formatEgp(check.amountMinor),
          showDivider: false,
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(bottom: AppSpacing.xs),
          child: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            alignment: WrapAlignment.end,
            children: [
              if (check.status != 'deducted' && check.status != 'archived')
                SizedBox(
                  height: 32,
                  child: BtnWidget(
                    title: 'تأكيد الخصم',
                    height: 32,
                    minWidth: 0,
                    txtSize: 11.5,
                    onTap: () => _cubit.updateCheckStatus(check.id, 'deducted'),
                  ),
                ),
              if (check.status == 'issued')
                SizedBox(
                  height: 32,
                  child: BtnWidget(
                    title: 'مرتجع',
                    height: 32,
                    minWidth: 0,
                    txtSize: 11.5,
                    backgroundColor: context.colors.surfaceMuted,
                    color: context.colors.onSurface,
                    borderColor: context.colors.border,
                    onTap: () => _cubit.updateCheckStatus(check.id, 'returned'),
                  ),
                ),
              if (check.status == 'issued' &&
                  check.dueDateMillis < DateTime.now().millisecondsSinceEpoch)
                SizedBox(
                  height: 32,
                  child: BtnWidget(
                    title: 'متأخر',
                    height: 32,
                    minWidth: 0,
                    txtSize: 11.5,
                    backgroundColor: AppColors.kLandscapeWarningPale,
                    color: AppColors.kLandscapeWarning,
                    borderColor: AppColors.kLandscapeWarningLine,
                    onTap: () => _cubit.updateCheckStatus(check.id, 'overdue'),
                  ),
                ),
              if (check.status == 'deducted')
                SizedBox(
                  height: 32,
                  child: BtnWidget(
                    title: 'أرشفة',
                    height: 32,
                    minWidth: 0,
                    txtSize: 11.5,
                    backgroundColor: context.colors.surfaceMuted,
                    color: context.colors.onSurface,
                    borderColor: context.colors.border,
                    onTap: () => _cubit.updateCheckStatus(check.id, 'archived'),
                  ),
                ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: context.colors.divider.withValues(alpha: 0.7),
          ),
      ],
    );
  }

  Widget _emptyRecords(String message) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
    child: Text(
      message,
      style: context.textTheme.bodySmall?.copyWith(
        color: context.colors.textSecondary,
      ),
    ),
  );

  Future<void> _showInstallmentEdit(InstallmentAccountModel account) {
    _cubit.prepareInstallmentEdit(account);
    return showAdaptiveDialogWidget(
      title: 'تعديل حساب التقسيط',
      okTxt: 'حفظ التعديل',
      content: Form(
        key: _cubit.installmentFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(
              'اسم الشخص',
              'اسم صاحب الحساب',
              _cubit.customerNameController,
            ),
            _field(
              'اسم تطبيق التقسيط',
              'اسم التطبيق أو الحساب',
              _cubit.installmentReferenceController,
            ),
          ],
        ),
      ),
      beforeOk: () =>
          _cubit.installmentFormKey.currentState?.validate() == true,
      okTap: _cubit.updateInstallmentAccount,
    );
  }

  Future<void> _changeInstallmentStatus(
    InstallmentAccountModel account,
    String status,
  ) async {
    _cubit.prepareInstallmentEdit(account);
    await _cubit.updateInstallmentAccount(status: status);
  }
}
