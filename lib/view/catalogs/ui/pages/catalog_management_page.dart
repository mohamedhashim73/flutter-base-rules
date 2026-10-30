import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:base/core/enums/enums.dart';
import 'package:base/core/extensions/extensions.dart';
import 'package:base/core/navigation/app_navigation.dart';
import 'package:base/core/services/services.dart';
import 'package:base/core/theme/theme.dart';
import 'package:base/core/widgets/widgets.dart';
import 'package:base/model/domain/bank_account_model.dart';
import 'package:base/model/domain/expense_category_model.dart';
import 'package:base/model/domain/receiving_company_model.dart';
import 'package:base/model/domain/withdrawal_person_model.dart';
import 'package:base/view/credit_cards/ui/controllers/credit_cards_cubit/credit_cards_cubit.dart';
import 'package:base/view/credit_cards/ui/controllers/credit_cards_cubit/credit_cards_states.dart';
import 'package:base/view/operations/ui/controllers/operations_cubit/operations_cubit.dart';
import 'package:base/view/operations/ui/controllers/operations_cubit/operations_states.dart';

class CatalogManagementPage extends StatefulWidget {
  const CatalogManagementPage({super.key});

  @override
  State<CatalogManagementPage> createState() => _CatalogManagementPageState();
}

class _CatalogManagementPageState extends State<CatalogManagementPage> {
  late final CreditCardsCubit _creditCubit;
  late final OperationsCubit _operationsCubit;
  final _personController = TextEditingController();

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
    _personController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    destination: AppDestination.catalogs,
    title: 'إدارة الكتالوجات',
    subtitle: 'المزودون والعلامات والحسابات',
    onRefresh: _refresh,
    actions: [
      IconButton(
        tooltip: 'تحديث',
        onPressed: _refresh,
        icon: const Icon(Icons.refresh_rounded),
      ),
    ],
    body: BlocBuilder<CreditCardsCubit, CreditCardsState>(
      bloc: _creditCubit,
      builder: (context, creditState) => BlocBuilder<OperationsCubit, OperationsState>(
        bloc: _operationsCubit,
        builder: (context, operationsState) {
          final isLoading =
              creditState.status == RequestStatus.loading &&
              operationsState.status == RequestStatus.loading &&
              creditState.providers.isEmpty &&
              creditState.brands.isEmpty &&
              creditState.posMachines.isEmpty &&
              operationsState.bankAccounts.isEmpty &&
              operationsState.receivingCompanies.isEmpty;
          if (isLoading) {
            return const AppPageShimmerWidget(
              type: AppPageShimmerType.catalogs,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppBreakpoints.of(context).sectionSpacing,
            children: [
              AppStatGrid(
                maxColumns: 4,
                children: [
                  AppStatCard(
                    label: 'مزودو الدفع',
                    value: '${creditState.providers.length}',
                    icon: Icons.storefront_outlined,
                    tone: AppTone.primary,
                  ),
                  AppStatCard(
                    label: 'العلامات التجارية',
                    value: '${creditState.brands.length}',
                    icon: Icons.sell_outlined,
                    tone: AppTone.info,
                  ),
                  AppStatCard(
                    label: 'أجهزة POS',
                    value: '${creditState.posMachines.length}',
                    icon: Icons.point_of_sale_outlined,
                    tone: AppTone.gold,
                  ),
                  AppStatCard(
                    label: 'الحسابات البنكية',
                    value: '${operationsState.bankAccounts.length}',
                    icon: Icons.account_balance_outlined,
                    highlight: true,
                  ),
                ],
              ),
              _section(
                'مزودو الدفع',
                Icons.storefront_outlined,
                creditState.providers
                    .map(
                      (provider) => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(provider.name),
                        subtitle: Text(provider.active ? 'نشط' : 'غير نشط'),
                        value: provider.active,
                        onChanged: (value) async {
                          await _creditCubit.updateProviderRecord(
                            provider.copyWith(active: value),
                          );
                          await _creditCubit.load();
                        },
                      ),
                    )
                    .toList(),
              ),
              _section(
                'العلامات التجارية',
                Icons.sell_outlined,
                creditState.brands
                    .map(
                      (brand) => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(brand.name),
                        subtitle: Text(
                          '${brand.providerName} · ${brand.commissionBps / 100}%',
                        ),
                        value: brand.active,
                        onChanged: (value) async {
                          await _creditCubit.updateBrandRecord(
                            brand.copyWith(active: value),
                          );
                          await _creditCubit.load();
                        },
                      ),
                    )
                    .toList(),
                tone: AppTone.info,
              ),
              _section(
                'أجهزة POS',
                Icons.point_of_sale_outlined,
                creditState.posMachines
                    .map(
                      (machine) => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(machine.name),
                        subtitle: Text(machine.providerName),
                        value: machine.active,
                        onChanged: (value) async {
                          await _creditCubit.updatePosMachine(
                            machine.copyWith(active: value),
                          );
                          await _creditCubit.load();
                        },
                      ),
                    )
                    .toList(),
                tone: AppTone.gold,
              ),
              _section(
                'الحسابات البنكية',
                Icons.account_balance_outlined,
                operationsState.bankAccounts
                    .map(
                      (account) => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${account.bankName} · ${account.accountName}',
                        ),
                        subtitle: Text(
                          '•••• ${account.lastFour} · الرصيد ${account.balanceMinor / 100}',
                        ),
                        value: account.active,
                        onChanged: (value) =>
                            _updateBankAccount(account, value),
                        secondary: IconButton(
                          tooltip: 'تعديل الحساب',
                          onPressed: () => _showBankAccountEdit(account),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ),
                    )
                    .toList(),
              ),
              _section(
                'شركات التحصيل',
                Icons.business_outlined,
                operationsState.receivingCompanies
                    .map(
                      (company) => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(company.name),
                        subtitle: Text(
                          '${company.bankAccountIds.length} حساب مرتبط',
                        ),
                        value: company.active,
                        onChanged: (value) =>
                            _updateReceivingCompany(company, value),
                        secondary: IconButton(
                          tooltip: 'تعديل الشركة',
                          onPressed: () => _showReceivingCompanyEdit(company),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ),
                    )
                    .toList(),
                tone: AppTone.info,
              ),
              _section(
                'تصنيفات المصروفات',
                Icons.category_outlined,
                operationsState.expenseCategories
                    .map(
                      (category) => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(category.name),
                        subtitle: Text(category.active ? 'نشط' : 'غير نشط'),
                        value: category.active,
                        onChanged: (value) => _updateCategory(category, value),
                        secondary: IconButton(
                          tooltip: 'تعديل التصنيف',
                          onPressed: () => _showCategoryEdit(category),
                          icon: const Icon(Icons.edit_outlined),
                        ),
                      ),
                    )
                    .toList(),
                tone: AppTone.warning,
              ),
              _withdrawalPeopleSection(operationsState),
            ],
          );
        },
      ),
    ),
  );

  Widget _section(
    String title,
    IconData icon,
    List<Widget> children, {
    AppTone tone = AppTone.primary,
  }) => AppSectionCard(
    title: title,
    subtitle: '${children.length} سجل',
    icon: icon,
    tone: tone,
    showDivider: true,
    child: children.isEmpty
        ? const AppStateView(
            icon: Icons.inbox_outlined,
            title: 'لا توجد سجلات لعرضها',
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

  Future<void> _refresh() async {
    await Future.wait([_creditCubit.load(), _operationsCubit.load()]);
  }

  Future<void> _updateBankAccount(BankAccountModel account, bool active) async {
    await _operationsCubit.updateBankAccount(account.copyWith(active: active));
    await _operationsCubit.load();
  }

  Future<void> _updateReceivingCompany(
    ReceivingCompanyModel company,
    bool active,
  ) async {
    await _operationsCubit.updateReceivingCompany(
      company.copyWith(active: active),
    );
    await _operationsCubit.load();
  }

  Future<void> _updateCategory(
    ExpenseCategoryModel category,
    bool active,
  ) async {
    await _operationsCubit.updateExpenseCategory(
      category.copyWith(active: active),
    );
    await _operationsCubit.load();
  }

  Widget _withdrawalPeopleSection(OperationsState state) => AppSectionCard(
    title: 'أسماء السحوبات الشخصية',
    subtitle: '${state.withdrawalPeople.length} مستفيد',
    icon: Icons.person_remove_outlined,
    tone: AppTone.warning,
    showDivider: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: [
        Form(
          key: _operationsCubit.withdrawalPersonFormKey,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final field = TextField(
                controller: _personController,
                decoration: const InputDecoration(labelText: 'اسم المستفيد'),
              );
              final button = FilledButton.icon(
                onPressed: () async {
                  if (_personController.text.trim().isEmpty) return;
                  _operationsCubit.withdrawalPersonNameController.text =
                      _personController.text.trim();
                  await _operationsCubit.createWithdrawalPerson();
                  _personController.clear();
                  if (mounted) await _operationsCubit.load();
                },
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('إضافة'),
              );
              if (constraints.maxWidth < 480) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: AppSpacing.xs,
                  children: [
                    field,
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: button,
                    ),
                  ],
                );
              }
              return Row(
                spacing: AppSpacing.sm,
                children: [
                  Expanded(child: field),
                  button,
                ],
              );
            },
          ),
        ),
        if (state.withdrawalPeople.isEmpty)
          const AppStateView(
            icon: Icons.person_outline_rounded,
            title: 'لا توجد أسماء مسجلة',
            compact: true,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (
                var index = 0;
                index < state.withdrawalPeople.length;
                index++
              )
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _withdrawalPersonTile(state.withdrawalPeople[index]),
                    if (index != state.withdrawalPeople.length - 1)
                      Divider(
                        height: 1,
                        color: context.colors.divider.withValues(alpha: 0.7),
                      ),
                  ],
                ),
            ],
          ),
      ],
    ),
  );

  Widget _withdrawalPersonTile(WithdrawalPersonModel person) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(person.name),
    subtitle: Text(person.active ? 'نشط' : 'غير نشط'),
    value: person.active,
    onChanged: (active) async {
      await _operationsCubit.updateWithdrawalPerson(
        person.copyWith(active: active),
      );
      if (mounted) await _operationsCubit.load();
    },
    secondary: IconButton(
      tooltip: 'تعديل الاسم',
      onPressed: () => _showWithdrawalPersonEdit(person),
      icon: const Icon(Icons.edit_outlined),
    ),
  );

  Future<void> _showBankAccountEdit(BankAccountModel account) {
    _operationsCubit.prepareBankAccountEdit(account);
    return showAdaptiveDialogWidget(
      title: 'تعديل الحساب البنكي',
      okTxt: 'حفظ التعديل',
      content: Form(
        key: _operationsCubit.bankAccountFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TxtFieldWidget(
              label: 'اسم البنك',
              hint: 'اسم البنك',
              controller: _operationsCubit.bankNameController,
            ),
            TxtFieldWidget(
              label: 'اسم الحساب',
              hint: 'اسم الحساب',
              controller: _operationsCubit.bankAccountNameController,
            ),
            TxtFieldWidget(
              label: 'آخر أربعة أرقام',
              hint: '1234',
              controller: _operationsCubit.bankLastFourController,
              isNum: true,
              textInputType: TextInputType.number,
            ),
            BlocBuilder<OperationsCubit, OperationsState>(
              bloc: _operationsCubit,
              builder: (context, state) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('حساب نشط'),
                value: _operationsCubit.bankAccountActive,
                onChanged: _operationsCubit.setBankAccountActive,
              ),
            ),
          ],
        ),
      ),
      beforeOk: () =>
          _operationsCubit.bankAccountFormKey.currentState?.validate() == true,
      okTap: _operationsCubit.saveBankAccountEdit,
    );
  }

  Future<void> _showReceivingCompanyEdit(ReceivingCompanyModel company) {
    _operationsCubit.prepareReceivingCompanyEdit(company);
    return showAdaptiveDialogWidget(
      title: 'تعديل شركة التحصيل',
      okTxt: 'حفظ التعديل',
      content: Form(
        key: _operationsCubit.receivingCompanyFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TxtFieldWidget(
              label: 'اسم الشركة',
              hint: 'اسم الشركة',
              controller: _operationsCubit.receivingCompanyNameController,
            ),
            DropDownBtnWidget<String>(
              label: 'الحساب البنكي الأساسي',
              hint: 'اختر الحساب',
              value: _operationsCubit.selectedBankAccountId,
              items: _operationsCubit.state.bankAccounts
                  .where((item) => item.active)
                  .map((item) => item.id)
                  .toList(),
              getLabel: (id) {
                final account = _operationsCubit.state.bankAccounts.firstWhere(
                  (item) => item.id == id,
                );
                return '${account.bankName} · •••• ${account.lastFour}';
              },
              onChanged: (id) => _operationsCubit.selectedBankAccountId = id,
            ),
            BlocBuilder<OperationsCubit, OperationsState>(
              bloc: _operationsCubit,
              builder: (context, state) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('شركة نشطة'),
                value: _operationsCubit.receivingCompanyActive,
                onChanged: _operationsCubit.setReceivingCompanyActive,
              ),
            ),
          ],
        ),
      ),
      beforeOk: () =>
          _operationsCubit.receivingCompanyFormKey.currentState?.validate() ==
          true,
      okTap: _operationsCubit.saveReceivingCompanyEdit,
    );
  }

  Future<void> _showCategoryEdit(ExpenseCategoryModel category) {
    _operationsCubit.prepareExpenseCategoryEdit(category);
    return showAdaptiveDialogWidget(
      title: 'تعديل تصنيف المصروف',
      okTxt: 'حفظ التعديل',
      content: Form(
        key: _operationsCubit.expenseCategoryFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TxtFieldWidget(
              label: 'اسم التصنيف',
              hint: 'اسم التصنيف',
              controller: _operationsCubit.expenseCategoryNameController,
            ),
            BlocBuilder<OperationsCubit, OperationsState>(
              bloc: _operationsCubit,
              builder: (context, state) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('تصنيف نشط'),
                value: _operationsCubit.expenseCategoryActive,
                onChanged: _operationsCubit.setExpenseCategoryActive,
              ),
            ),
          ],
        ),
      ),
      beforeOk: () =>
          _operationsCubit.expenseCategoryFormKey.currentState?.validate() ==
          true,
      okTap: _operationsCubit.saveExpenseCategoryEdit,
    );
  }

  Future<void> _showWithdrawalPersonEdit(WithdrawalPersonModel person) {
    _operationsCubit.prepareWithdrawalPersonEdit(person);
    return showAdaptiveDialogWidget(
      title: 'تعديل اسم المستفيد',
      okTxt: 'حفظ التعديل',
      content: Form(
        key: _operationsCubit.withdrawalPersonEditFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TxtFieldWidget(
              label: 'اسم المستفيد',
              hint: 'الاسم',
              controller: _operationsCubit.withdrawalPersonNameController,
            ),
            BlocBuilder<OperationsCubit, OperationsState>(
              bloc: _operationsCubit,
              builder: (context, state) => SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('اسم نشط'),
                value: _operationsCubit.withdrawalPersonActive,
                onChanged: _operationsCubit.setWithdrawalPersonActive,
              ),
            ),
          ],
        ),
      ),
      beforeOk: () =>
          _operationsCubit.withdrawalPersonEditFormKey.currentState
              ?.validate() ==
          true,
      okTap: _operationsCubit.saveWithdrawalPersonEdit,
    );
  }
}
