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
import 'package:base/model/domain/brand_model.dart';
import 'package:base/model/domain/credit_card_model.dart';
import 'package:base/model/domain/credit_purchase_model.dart';
import 'package:base/model/domain/credit_deposit_model.dart';
import 'package:base/model/domain/credit_period_model.dart';
import 'package:base/model/domain/payment_provider_model.dart';
import 'package:base/model/domain/bank_account_model.dart';
import 'package:base/model/domain/receiving_company_model.dart';
import 'package:base/model/domain/pos_machine_model.dart';
import 'package:base/view/credit_cards/ui/controllers/credit_cards_cubit/credit_cards_cubit.dart';
import 'package:base/view/credit_cards/ui/controllers/credit_cards_cubit/credit_cards_states.dart';

class CreditCardsPage extends StatefulWidget {
  const CreditCardsPage({super.key});

  @override
  State<CreditCardsPage> createState() => _CreditCardsPageState();
}

class _CreditCardsPageState extends State<CreditCardsPage> {
  late final CreditCardsCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<CreditCardsCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreditCardsCubit, CreditCardsState>(
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
      child: BlocBuilder<CreditCardsCubit, CreditCardsState>(
        bloc: _cubit,
        builder: (context, state) => AppPageScaffold(
          destination: AppDestination.creditCards,
          title: 'بطاقات الائتمان',
          subtitle: 'الحدود الائتمانية والأرصدة والمشتريات والإيداعات',
          onRefresh: _cubit.load,
          actions: [
            IconButton(
              tooltip: 'تحديث البيانات',
              onPressed: _cubit.load,
              icon: const Icon(Icons.refresh_rounded),
            ),
            BtnWidget(
              title: 'إضافة بطاقة',
              prefix: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 18,
              ),
              onTap: () => _showCardDialog(context),
            ),
          ],
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppBreakpoints.of(context).sectionSpacing,
            children: [
              if (state.actionMessage != null &&
                  state.actionMessage!.isNotEmpty)
                AppInfoBanner(
                  message: state.actionMessage!,
                  tone: state.actionStatus == RequestStatus.failure
                      ? AppTone.danger
                      : AppTone.success,
                  icon: state.actionStatus == RequestStatus.failure
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                ),
              if (state.status == RequestStatus.loading && state.cards.isEmpty)
                const AppStateView(
                  title: 'جاري تحميل بطاقات الائتمان',
                  message: 'يتم تحميل البطاقات والكتالوج المالي الآن.',
                  icon: Icons.credit_card_outlined,
                  tone: AppTone.info,
                  compact: true,
                )
              else if (state.status == RequestStatus.failure &&
                  state.cards.isEmpty)
                AppStateView(
                  title: 'تعذر تحميل بطاقات الائتمان',
                  message: state.message,
                  icon: Icons.error_outline_rounded,
                  tone: AppTone.danger,
                  compact: true,
                  action: BtnWidget(
                    title: 'إعادة المحاولة',
                    onTap: _cubit.load,
                  ),
                )
              else
                _CreditCardsContentWidget(cubit: _cubit, state: state),
              _CatalogManagementWidget(cubit: _cubit),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCardDialog(BuildContext context) {
    return showAdaptiveDialogWidget(
      title: 'إضافة بطاقة ائتمان',
      okTxt: 'حفظ البطاقة',
      content: _CardFormWidget(cubit: _cubit),
      beforeOk: () => _cubit.cardFormKey.currentState?.validate() == true,
      okTap: _cubit.createCard,
    );
  }
}

class _CatalogManagementWidget extends StatelessWidget {
  const _CatalogManagementWidget({required this.cubit});

  final CreditCardsCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreditCardsCubit, CreditCardsState>(
      bloc: cubit,
      builder: (context, state) {
        final hasActiveProvider = state.providers.any((item) => item.active);
        return AppSectionCard(
          title: 'مزودو الدفع والعلامات التجارية',
          subtitle:
              'إدارة مزودي الدفع والعلامات وأجهزة POS ومسارات التسوية البنكية',
          icon: Icons.account_balance_outlined,
          tone: AppTone.info,
          showDivider: true,
          actions: [
            BtnWidget(
              title: 'إضافة مزود',
              txtSize: 12.5,
              height: 38,
              prefix: const Icon(
                Icons.add_business_outlined,
                color: Colors.white,
                size: 17,
              ),
              onTap: () => _showProviderDialog(context),
            ),
            BtnWidget(
              title: 'إضافة علامة',
              txtSize: 12.5,
              height: 38,
              prefix: const Icon(
                Icons.storefront_outlined,
                color: Colors.white,
                size: 17,
              ),
              onTap: hasActiveProvider ? () => _showBrandDialog(context) : null,
            ),
            BtnWidget(
              title: 'إضافة POS',
              txtSize: 12.5,
              height: 38,
              prefix: const Icon(
                Icons.point_of_sale_outlined,
                color: Colors.white,
                size: 17,
              ),
              onTap: hasActiveProvider ? () => _showPosDialog(context) : null,
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpacing.md,
            children: [
              if (!hasActiveProvider)
                const AppInfoBanner(
                  message:
                      'أضف مزود دفع نشطاً أولاً حتى تتمكن من إنشاء العلامات التجارية وأجهزة POS.',
                  tone: AppTone.info,
                ),
              if (state.providers.isEmpty && state.brands.isEmpty)
                const AppStateView(
                  title: 'لا توجد بيانات كتالوج بعد',
                  message:
                      'ابدأ بإضافة مزود دفع، ثم أضف العلامات التجارية وأجهزة POS المرتبطة به.',
                  icon: Icons.account_balance_outlined,
                  tone: AppTone.neutral,
                  compact: true,
                )
              else ...[
                _CatalogGroup(
                  title: 'مزودو الدفع',
                  count: state.providers.length,
                  children: state.providers
                      .map(
                        (provider) => _CatalogChip(
                          icon: Icons.account_balance_outlined,
                          label: provider.name,
                          active: provider.active,
                          onTap: () =>
                              _showProviderEditDialog(context, provider),
                        ),
                      )
                      .toList(),
                ),
                _CatalogGroup(
                  title: 'العلامات التجارية',
                  count: state.brands.length,
                  children: state.brands
                      .map(
                        (brand) => _CatalogChip(
                          icon: Icons.storefront_outlined,
                          label:
                              '${brand.name} · ${brand.providerName} · ${brand.commissionBps / 100}%',
                          active: brand.active,
                          onTap: () {
                            cubit.prepareBrandRouting(brand);
                            _showBrandRoutingDialog(context);
                          },
                          trailing: IconButton(
                            tooltip: 'تعديل العلامة',
                            visualDensity: VisualDensity.compact,
                            constraints: const BoxConstraints(
                              minWidth: 28,
                              minHeight: 28,
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: () =>
                                _showBrandEditDialog(context, brand),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _showProviderDialog(BuildContext context) {
    return showAdaptiveDialogWidget(
      title: 'إضافة مزود دفع',
      okTxt: 'حفظ المزود',
      content: Form(
        key: cubit.providerFormKey,
        child: TxtFieldWidget(
          label: 'اسم المزود',
          hint: 'مثال: Geidea',
          controller: cubit.providerNameController,
        ),
      ),
      beforeOk: () => cubit.providerFormKey.currentState?.validate() == true,
      okTap: cubit.createProvider,
    );
  }

  Future<void> _showBrandDialog(BuildContext context) {
    return showAdaptiveDialogWidget(
      title: 'إضافة علامة تجارية',
      okTxt: 'حفظ العلامة',
      content: _BrandFormWidget(cubit: cubit),
      beforeOk: () => cubit.brandFormKey.currentState?.validate() == true,
      okTap: cubit.createBrand,
    );
  }

  Future<void> _showProviderEditDialog(
    BuildContext context,
    PaymentProviderModel provider,
  ) {
    cubit.prepareProviderEdit(provider);
    return showAdaptiveDialogWidget(
      title: 'تعديل مزود الدفع',
      okTxt: 'حفظ التعديل',
      content: _ProviderEditForm(cubit: cubit, provider: provider),
      beforeOk: () => cubit.providerFormKey.currentState?.validate() == true,
      okTap: cubit.updateProvider,
    );
  }

  Future<void> _showBrandEditDialog(BuildContext context, BrandModel brand) {
    cubit.prepareBrandEdit(brand);
    return showAdaptiveDialogWidget(
      title: 'تعديل العلامة التجارية',
      okTxt: 'حفظ التعديل',
      content: _BrandEditForm(cubit: cubit, brand: brand),
      beforeOk: () => cubit.brandFormKey.currentState?.validate() == true,
      okTap: cubit.updateBrand,
    );
  }

  Future<void> _showPosDialog(BuildContext context) {
    return showAdaptiveDialogWidget(
      title: 'إضافة جهاز POS',
      okTxt: 'حفظ الجهاز',
      content: Form(
        key: cubit.providerFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.sm,
          children: [
            DropDownBtnWidget<PaymentProviderModel>(
              label: 'مزود الدفع',
              hint: 'اختر المزود',
              items: cubit.state.providers
                  .where((item) => item.active)
                  .toList(),
              value: cubit.selectedProvider,
              getLabel: (provider) => provider.name,
              onChanged: (provider) => cubit.selectProvider(provider.id),
            ),
            TxtFieldWidget(
              label: 'اسم جهاز POS',
              hint: 'مثال: POS الفرع الرئيسي',
              controller: cubit.posNameController,
            ),
          ],
        ),
      ),
      beforeOk: () => cubit.providerFormKey.currentState?.validate() == true,
      okTap: cubit.createPosMachine,
    );
  }

  Future<void> _showBrandRoutingDialog(BuildContext context) {
    return showAdaptiveDialogWidget(
      title: 'تعديل مسار التسوية',
      okTxt: 'حفظ المسار',
      content: _BrandRoutingFormWidget(cubit: cubit),
      beforeOk: () => cubit.routingFormKey.currentState?.validate() == true,
      okTap: cubit.updateBrandRouting,
    );
  }
}

class _CatalogGroup extends StatelessWidget {
  const _CatalogGroup({
    required this.title,
    required this.count,
    required this.children,
  });

  final String title;
  final int count;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.xs,
      children: [
        Row(
          children: [
            Text(
              title,
              style: context.textTheme.labelLarge?.copyWith(
                color: context.colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            AppStatusChip(status: 'normal', label: '$count', compact: true),
          ],
        ),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: children,
        ),
      ],
    );
  }
}

class _CatalogChip extends StatelessWidget {
  const _CatalogChip({
    required this.icon,
    required this.label,
    required this.active,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = active ? colors.onSurface : colors.textSecondary;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesignRadius.pill),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: active ? colors.surfaceMuted : colors.surface,
            borderRadius: BorderRadius.circular(AppDesignRadius.pill),
            border: Border.all(color: active ? colors.border : colors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 7,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? colors.primary : colors.textSecondary,
              ),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodySmall?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!active) AppStatusChip(status: 'inactive', compact: true),
              ?trailing,
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandFormWidget extends StatelessWidget {
  const _BrandFormWidget({required this.cubit});

  final CreditCardsCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: cubit.brandFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          DropDownBtnWidget<PaymentProviderModel>(
            label: 'مزود الدفع',
            hint: 'اختر المزود',
            items: cubit.state.providers.where((item) => item.active).toList(),
            value: cubit.selectedProvider,
            getLabel: (provider) => provider.name,
            onChanged: (provider) => cubit.selectProvider(provider.id),
          ),
          TxtFieldWidget(
            label: 'اسم العلامة',
            hint: 'مثال: Well Life',
            controller: cubit.brandNameController,
          ),
          TxtFieldWidget(
            label: 'نسبة العمولة %',
            hint: '2',
            controller: cubit.commissionController,
            isNum: true,
            textInputType: TextInputType.number,
          ),
          DropDownBtnWidget<ReceivingCompanyModel>(
            label: 'شركة التحصيل',
            hint: cubit.state.receivingCompanies.isEmpty
                ? 'أضف شركة من شاشة التشغيل أولاً'
                : 'اختر الشركة',
            items: cubit.state.receivingCompanies
                .where((item) => item.active)
                .toList(),
            value: cubit.selectedReceivingCompany,
            getLabel: (company) => company.name,
            onChanged: (company) => cubit.selectReceivingCompany(company.id),
          ),
          DropDownBtnWidget<BankAccountModel>(
            label: 'حساب التسوية البنكي',
            hint: cubit.selectedReceivingCompany == null
                ? 'اختر الشركة أولاً'
                : 'اختر الحساب',
            items: cubit.state.bankAccounts
                .where(
                  (account) =>
                      account.active &&
                      (cubit.selectedReceivingCompany?.bankAccountIds.contains(
                            account.id,
                          ) ??
                          false),
                )
                .toList(),
            value: cubit.selectedBankAccount,
            getLabel: (account) =>
                '${account.bankName} · •••• ${account.lastFour}',
            onChanged: (account) => cubit.selectBankAccount(account.id),
          ),
          DropDownBtnWidget<PosMachineModel>(
            label: 'جهاز POS',
            hint: cubit.selectedProvider == null
                ? 'اختر مزود الدفع أولاً'
                : 'اختر جهاز POS',
            items: cubit.state.posMachines
                .where(
                  (pos) =>
                      pos.active &&
                      pos.providerId == cubit.selectedProvider?.id,
                )
                .toList(),
            value: cubit.selectedPosMachine,
            getLabel: (pos) => '${pos.name} · ${pos.providerName}',
            onChanged: (pos) => cubit.selectPosMachine(pos.id),
          ),
        ],
      ),
    );
  }
}

class _ProviderEditForm extends StatefulWidget {
  const _ProviderEditForm({required this.cubit, required this.provider});

  final CreditCardsCubit cubit;
  final PaymentProviderModel provider;

  @override
  State<_ProviderEditForm> createState() => _ProviderEditFormState();
}

class _ProviderEditFormState extends State<_ProviderEditForm> {
  @override
  void initState() {
    super.initState();
    widget.cubit.providerNameController.text = widget.provider.name;
    widget.cubit.providerActive = widget.provider.active;
  }

  @override
  Widget build(BuildContext context) => Form(
    key: widget.cubit.providerFormKey,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: [
        TxtFieldWidget(
          label: 'اسم المزود',
          hint: 'اسم مزود الدفع',
          controller: widget.cubit.providerNameController,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('مزود نشط'),
          value: widget.cubit.providerActive,
          onChanged: (value) {
            setState(() => widget.cubit.setProviderActive(value));
          },
        ),
      ],
    ),
  );
}

class _BrandEditForm extends StatefulWidget {
  const _BrandEditForm({required this.cubit, required this.brand});

  final CreditCardsCubit cubit;
  final BrandModel brand;

  @override
  State<_BrandEditForm> createState() => _BrandEditFormState();
}

class _BrandEditFormState extends State<_BrandEditForm> {
  @override
  void initState() {
    super.initState();
    widget.cubit.brandNameController.text = widget.brand.name;
    widget.cubit.commissionController.text = (widget.brand.commissionBps / 100)
        .toString();
    widget.cubit.brandActive = widget.brand.active;
  }

  @override
  Widget build(BuildContext context) => Form(
    key: widget.cubit.brandFormKey,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: [
        TxtFieldWidget(
          label: 'اسم العلامة',
          hint: 'اسم العلامة التجارية',
          controller: widget.cubit.brandNameController,
        ),
        TxtFieldWidget(
          label: 'نسبة العمولة %',
          hint: '2',
          controller: widget.cubit.commissionController,
          isNum: true,
          textInputType: TextInputType.number,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('علامة نشطة'),
          value: widget.cubit.brandActive,
          onChanged: (value) {
            setState(() => widget.cubit.setBrandActive(value));
          },
        ),
      ],
    ),
  );
}

class _BrandRoutingFormWidget extends StatelessWidget {
  const _BrandRoutingFormWidget({required this.cubit});
  final CreditCardsCubit cubit;

  @override
  Widget build(BuildContext context) => Form(
    key: cubit.routingFormKey,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          cubit.selectedBrand?.name ?? '',
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        DropDownBtnWidget<ReceivingCompanyModel>(
          label: 'شركة التحصيل',
          hint: 'اختر الشركة',
          items: cubit.state.receivingCompanies
              .where((item) => item.active)
              .toList(),
          value: cubit.selectedReceivingCompany,
          getLabel: (company) => company.name,
          onChanged: (company) => cubit.selectReceivingCompany(company.id),
        ),
        DropDownBtnWidget<BankAccountModel>(
          label: 'حساب التسوية البنكي',
          hint: cubit.selectedReceivingCompany == null
              ? 'اختر الشركة أولاً'
              : 'اختر الحساب',
          items: cubit.state.bankAccounts
              .where(
                (account) =>
                    account.active &&
                    (cubit.selectedReceivingCompany?.bankAccountIds.contains(
                          account.id,
                        ) ??
                        false),
              )
              .toList(),
          value: cubit.selectedBankAccount,
          getLabel: (account) =>
              '${account.bankName} · •••• ${account.lastFour}',
          onChanged: (account) => cubit.selectBankAccount(account.id),
        ),
      ],
    ),
  );
}

class _CreditCardsContentWidget extends StatelessWidget {
  const _CreditCardsContentWidget({required this.cubit, required this.state});

  final CreditCardsCubit cubit;
  final CreditCardsState state;

  @override
  Widget build(BuildContext context) {
    final totalLimit = state.cards.fold<int>(
      0,
      (sum, card) => sum + card.creditLimitMinor,
    );
    final totalAvailable = state.cards.fold<int>(
      0,
      (sum, card) => sum + card.availableBalanceMinor,
    );
    final totalDebt = state.cards.fold<int>(
      0,
      (sum, card) => sum + card.currentMonthlyDebtMinor,
    );
    final cards = _CardsListWidget(cubit: cubit, cards: state.cards);
    final details = state.selectedCard == null
        ? const AppSectionCard(
            title: 'تفاصيل البطاقة',
            icon: Icons.credit_card_outlined,
            child: AppStateView(
              title: 'اختر بطاقة',
              message: 'اختر بطاقة من القائمة لعرض رصيدها وسجل عملياتها.',
              icon: Icons.touch_app_outlined,
              compact: true,
            ),
          )
        : _CardDetailsWidget(
            cubit: cubit,
            card: state.selectedCard!,
            purchases: state.purchases,
            deposits: state.deposits,
            periods: state.periods,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppBreakpoints.of(context).sectionSpacing,
      children: [
        AppStatGrid(
          children: [
            AppStatCard(
              label: 'إجمالي الحدود الائتمانية',
              value: FinanceMoney.formatEgp(totalLimit),
              icon: Icons.speed_outlined,
              caption: '${state.cards.length} بطاقة مسجلة',
              highlight: true,
            ),
            AppStatCard(
              label: 'الرصيد المتاح',
              value: FinanceMoney.formatEgp(totalAvailable),
              icon: Icons.account_balance_wallet_outlined,
              tone: AppTone.success,
              caption: 'مجموع الأرصدة المتاحة',
              valueColor: totalAvailable < 0 ? context.colors.error : null,
            ),
            AppStatCard(
              label: 'الدين الشهري المتبقي',
              value: FinanceMoney.formatEgp(totalDebt),
              icon: Icons.trending_down_rounded,
              tone: AppTone.warning,
              caption: 'الالتزامات الحالية على البطاقات',
            ),
          ],
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            if (!wide) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: AppSpacing.lg,
                children: [cards, details],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: AppSpacing.lg,
              children: [
                SizedBox(width: 340, child: cards),
                Expanded(child: details),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _CardsListWidget extends StatelessWidget {
  const _CardsListWidget({required this.cubit, required this.cards});

  final CreditCardsCubit cubit;
  final List<CreditCardModel> cards;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'البطاقات',
      subtitle: '${cards.length} بطاقة',
      icon: Icons.credit_card_outlined,
      contentSpacing: AppSpacing.sm,
      child: cards.isEmpty
          ? const AppStateView(
              title: 'لا توجد بطاقات',
              message: 'أضف بطاقة ائتمان للبدء في تسجيل المشتريات والإيداعات.',
              icon: Icons.credit_card_off_outlined,
              compact: true,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.xs,
              children: [
                for (final card in cards)
                  _CardListTileWidget(
                    card: card,
                    selected: cubit.state.selectedCard?.id == card.id,
                    onTap: () => cubit.selectCard(card.id),
                  ),
              ],
            ),
    );
  }
}

class _CardListTileWidget extends StatelessWidget {
  const _CardListTileWidget({
    required this.card,
    required this.selected,
    required this.onTap,
  });

  final CreditCardModel card;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final negative = card.availableBalanceMinor < 0;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesignRadius.control),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected ? colors.primaryPale : colors.surface,
            borderRadius: BorderRadius.circular(AppDesignRadius.control),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Row(
            spacing: AppSpacing.sm,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected ? colors.primary : colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.credit_card_rounded,
                  size: 19,
                  color: selected ? Colors.white : colors.textSecondary,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      card.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      card.maskedNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xxs),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 2,
                children: [
                  Text(
                    FinanceMoney.formatEgp(card.availableBalanceMinor),
                    style: context.textTheme.bodySmall?.copyWith(
                      color: negative ? colors.error : colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    negative ? 'رصيد سالب' : 'المتاح',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: negative ? colors.error : colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardDetailsWidget extends StatelessWidget {
  const _CardDetailsWidget({
    required this.cubit,
    required this.card,
    required this.purchases,
    required this.deposits,
    required this.periods,
  });

  final CreditCardsCubit cubit;
  final CreditCardModel card;
  final List<CreditPurchaseModel> purchases;
  final List<CreditDepositModel> deposits;
  final List<CreditPeriodModel> periods;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppBreakpoints.of(context).sectionSpacing,
      children: [
        _cardHero(context),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            BtnWidget(
              title: 'تسجيل إيداع',
              height: 42,
              prefix: const Icon(
                Icons.add_circle_outline,
                color: Colors.white,
                size: 18,
              ),
              onTap: () => _showDepositDialog(context),
            ),
            BtnWidget(
              title: 'تسجيل شراء',
              height: 42,
              prefix: const Icon(
                Icons.shopping_cart_outlined,
                color: Colors.white,
                size: 18,
              ),
              onTap: () => _showPurchaseDialog(context),
            ),
          ],
        ),
        _CardLedgerWidget(
          card: card,
          purchases: purchases,
          deposits: deposits,
          onEditPurchase: (purchase) =>
              _showEditPurchaseDialog(context, purchase),
          onDeletePurchase: (purchase) =>
              _showDeletePurchaseDialog(context, purchase),
        ),
        _MonthlyArchiveWidget(periods: periods),
      ],
    );
  }

  Widget _cardHero(BuildContext context) {
    final colors = context.colors;
    final negative = card.availableBalanceMinor < 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(AppDesignRadius.card),
        boxShadow: AppShadow.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.sm,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      card.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                    Text(
                      '${card.bankName} · ${card.maskedNumber}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.72),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'تعديل البطاقة',
                visualDensity: VisualDensity.compact,
                onPressed: () => _showEditCardDialog(context),
                icon: const Icon(Icons.edit_outlined, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'الرصيد المتاح',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.72),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              FinanceMoney.formatEgp(card.availableBalanceMinor),
              maxLines: 1,
              style: TextStyle(
                color: negative ? const Color(0xFFFFC9C4) : Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDesignRadius.control),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.event_repeat_outlined,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'الدين الشهري المتبقي: ${FinanceMoney.formatEgp(card.currentMonthlyDebtMinor)}',
                    maxLines: 2,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (negative)
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppDesignRadius.control),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: AppSpacing.xs,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 18,
                    color: colors.surface,
                  ),
                  Expanded(
                    child: Text(
                      'الرصيد المتاح سالب، ويحتاج إلى متابعة مالية عاجلة.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showDepositDialog(BuildContext context) {
    return showAdaptiveDialogWidget(
      title: 'تسجيل إيداع',
      okTxt: 'حفظ الإيداع',
      content: _DepositFormWidget(cubit: cubit),
      beforeOk: () => cubit.depositFormKey.currentState?.validate() == true,
      okTap: cubit.recordDeposit,
    );
  }

  Future<void> _showEditCardDialog(BuildContext context) {
    cubit.prepareCardEdit(card);
    return showAdaptiveDialogWidget(
      title: 'تعديل بيانات البطاقة',
      okTxt: 'حفظ التعديلات',
      content: _CardFormWidget(cubit: cubit),
      beforeOk: () => cubit.cardFormKey.currentState?.validate() == true,
      okTap: cubit.updateCard,
    );
  }

  Future<void> _showPurchaseDialog(BuildContext context) {
    return showAdaptiveDialogWidget(
      title: 'تسجيل شراء',
      okTxt: 'حفظ الشراء',
      content: _PurchaseFormWidget(cubit: cubit),
      beforeOk: () => cubit.purchaseFormKey.currentState?.validate() == true,
      okTap: cubit.recordPurchase,
    );
  }

  Future<void> _showEditPurchaseDialog(
    BuildContext context,
    CreditPurchaseModel purchase,
  ) {
    cubit.purchaseAmountController.text = FinanceMoney.formatEgp(
      purchase.amountMinor,
    ).replaceAll(' EGP', '');
    return showAdaptiveDialogWidget(
      title: 'تصحيح مبلغ الشراء',
      okTxt: 'حفظ التصحيح',
      content: Form(
        key: cubit.purchaseFormKey,
        child: TxtFieldWidget(
          label: 'المبلغ الجديد',
          hint: '0.00',
          controller: cubit.purchaseAmountController,
          isNum: true,
          textInputType: TextInputType.number,
        ),
      ),
      beforeOk: () => cubit.purchaseFormKey.currentState?.validate() == true,
      okTap: () => cubit.updatePurchaseAmount(purchase: purchase),
    );
  }

  Future<void> _showDeletePurchaseDialog(
    BuildContext context,
    CreditPurchaseModel purchase,
  ) {
    return showAdaptiveDialogWidget(
      title: 'حذف شراء',
      okTxt: 'تأكيد الحذف',
      content: Text(
        'سيتم عكس مبلغ ${FinanceMoney.formatEgp(purchase.amountMinor)} من رصيد البطاقة وتسجيل الحذف في سجل التدقيق.',
      ),
      okTap: () => cubit.deletePurchase(purchase),
    );
  }
}

class _CardLedgerWidget extends StatelessWidget {
  const _CardLedgerWidget({
    required this.card,
    required this.purchases,
    required this.deposits,
    required this.onEditPurchase,
    required this.onDeletePurchase,
  });

  final CreditCardModel card;
  final List<CreditPurchaseModel> purchases;
  final List<CreditDepositModel> deposits;
  final ValueChanged<CreditPurchaseModel> onEditPurchase;
  final ValueChanged<CreditPurchaseModel> onDeletePurchase;

  @override
  Widget build(BuildContext context) {
    final entries = <_LedgerEntry>[
      ...purchases.map(
        (purchase) =>
            _LedgerEntry.purchase(purchase, purchase.purchaseDateMillis),
      ),
      ...deposits
          .where((deposit) => deposit.amountMinor != 0)
          .map(_LedgerEntry.deposit),
    ]..sort((a, b) => b.dateMillis.compareTo(a.dateMillis));
    var runningBalance = card.availableBalanceMinor;
    final rows = <_LedgerRow>[];
    for (final entry in entries) {
      rows.add(_LedgerRow(entry: entry, balanceAfterMinor: runningBalance));
      runningBalance += entry.isPurchase
          ? entry.amountMinor
          : -entry.amountMinor;
    }
    return AppSectionCard(
      title: 'سجل عمليات البطاقة',
      subtitle: '${rows.length} حركة مرتبة من الأحدث إلى الأقدم',
      icon: Icons.receipt_long_outlined,
      contentSpacing: AppSpacing.xs,
      child: rows.isEmpty
          ? const AppStateView(
              title: 'لا توجد عمليات مسجلة',
              message: 'سجّل شراءً أو إيداعاً لعرض حركة البطاقة هنا.',
              icon: Icons.receipt_long_outlined,
              compact: true,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < rows.length; index++)
                  if (rows[index].entry.isPurchase)
                    _PurchaseTileWidget(
                      purchase: rows[index].entry.purchase!,
                      runningBalanceMinor: rows[index].balanceAfterMinor,
                      showDivider: index != rows.length - 1,
                      onEdit: () => onEditPurchase(rows[index].entry.purchase!),
                      onDelete: () =>
                          onDeletePurchase(rows[index].entry.purchase!),
                    )
                  else
                    AppRecordTile(
                      title: 'إيداع',
                      subtitle:
                          '${_date(rows[index].entry.dateMillis)} · ${rows[index].entry.deposit!.qualifiesForMonthlyDebt ? 'يخفض الدين الشهري' : 'لا يخفض الدين الشهري'}',
                      icon: Icons.south_west_rounded,
                      tone: AppTone.success,
                      showDivider: index != rows.length - 1,
                      trailing: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        spacing: 2,
                        children: [
                          Text(
                            FinanceMoney.formatEgp(
                              rows[index].entry.amountMinor,
                            ),
                            style: context.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'الرصيد ${FinanceMoney.formatEgp(rows[index].balanceAfterMinor)}',
                            style: context.textTheme.labelSmall?.copyWith(
                              color: context.colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
    );
  }

  String _date(int millis) => DateFormat(
    'dd/MM/yyyy',
  ).format(DateTime.fromMillisecondsSinceEpoch(millis));
}

class _MonthlyArchiveWidget extends StatelessWidget {
  const _MonthlyArchiveWidget({required this.periods});

  final List<CreditPeriodModel> periods;

  @override
  Widget build(BuildContext context) => AppSectionCard(
    title: 'أرشيف الدين الشهري',
    subtitle: '${periods.length} فترة محفوظة',
    icon: Icons.calendar_month_outlined,
    contentSpacing: AppSpacing.xs,
    child: periods.isEmpty
        ? const AppStateView(
            title: 'لا توجد فترات شهرية محفوظة',
            message: 'ستظهر الفترات هنا بعد إغلاق أول دورة شهرية للبطاقة.',
            icon: Icons.calendar_month_outlined,
            compact: true,
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var index = 0; index < periods.length; index++)
                AppRecordTile(
                  title:
                      '${periods[index].year}/${periods[index].month.toString().padLeft(2, '0')}',
                  subtitle:
                      'افتتاحي ${FinanceMoney.formatEgp(periods[index].openingBalanceMinor)} · إيداعات ${FinanceMoney.formatEgp(periods[index].qualifyingDepositsMinor)}',
                  meta:
                      'إغلاق ${FinanceMoney.formatEgp(periods[index].closingBalanceMinor)}',
                  icon: periods[index].fullyPaid
                      ? Icons.check_circle_outline
                      : Icons.calendar_month_outlined,
                  tone: periods[index].fullyPaid
                      ? AppTone.success
                      : AppTone.primary,
                  showDivider: index != periods.length - 1,
                  trailing: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    spacing: 2,
                    children: [
                      Text(
                        FinanceMoney.formatEgp(
                          periods[index].remainingDebtMinor,
                        ),
                        style: context.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'متبقي',
                        style: context.textTheme.labelSmall?.copyWith(
                          color: context.colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
  );
}

class _LedgerEntry {
  const _LedgerEntry.purchase(this.purchase, this.dateMillis)
    : deposit = null,
      isPurchase = true;
  _LedgerEntry.deposit(CreditDepositModel value)
    : purchase = null,
      deposit = value,
      dateMillis = value.depositDateMillis,
      isPurchase = false;

  final CreditPurchaseModel? purchase;
  final CreditDepositModel? deposit;
  final int dateMillis;
  final bool isPurchase;

  int get amountMinor =>
      isPurchase ? purchase!.amountMinor : deposit!.amountMinor;
}

class _LedgerRow {
  const _LedgerRow({required this.entry, required this.balanceAfterMinor});

  final _LedgerEntry entry;
  final int balanceAfterMinor;
}

class _PurchaseTileWidget extends StatelessWidget {
  const _PurchaseTileWidget({
    required this.purchase,
    required this.onEdit,
    required this.onDelete,
    this.runningBalanceMinor,
    this.showDivider = true,
  });

  final CreditPurchaseModel purchase;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final int? runningBalanceMinor;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.xs,
            horizontal: 4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: AppSpacing.sm,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: appToneStyle(context, AppTone.gold).background,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 17,
                  color: appToneStyle(context, AppTone.gold).foreground,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      purchase.brandName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${purchase.providerName} · ${purchase.posMachineName.isEmpty ? 'POS غير محدد' : purchase.posMachineName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    Text(
                      _date(purchase.purchaseDateMillis),
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: 2,
                children: [
                  Text(
                    FinanceMoney.formatEgp(purchase.amountMinor),
                    style: context.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (runningBalanceMinor != null)
                    Text(
                      'الرصيد ${FinanceMoney.formatEgp(runningBalanceMinor!)}',
                      style: context.textTheme.labelSmall?.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'تصحيح المبلغ',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                      ),
                      IconButton(
                        tooltip: 'حذف الشراء',
                        visualDensity: VisualDensity.compact,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        padding: EdgeInsets.zero,
                        onPressed: onDelete,
                        icon: Icon(
                          Icons.delete_outline,
                          size: 16,
                          color: colors.error,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, color: colors.divider.withValues(alpha: 0.7)),
      ],
    );
  }

  String _date(int millis) => DateFormat(
    'dd/MM/yyyy',
  ).format(DateTime.fromMillisecondsSinceEpoch(millis));
}

class _CardFormWidget extends StatelessWidget {
  const _CardFormWidget({required this.cubit});

  final CreditCardsCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: cubit.cardFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          TxtFieldWidget(
            label: 'اسم البطاقة',
            hint: 'مثال: بطاقة المشتريات',
            controller: cubit.cardTitleController,
          ),
          TxtFieldWidget(
            label: 'اسم حامل البطاقة',
            hint: 'الاسم',
            controller: cubit.cardholderController,
          ),
          TxtFieldWidget(
            label: 'البنك',
            hint: 'اسم البنك',
            controller: cubit.bankController,
          ),
          TxtFieldWidget(
            label: 'آخر أربعة أرقام',
            hint: '1234',
            controller: cubit.lastFourController,
            isNum: true,
            maxLength: 4,
            textInputType: TextInputType.number,
          ),
          TxtFieldWidget(
            label: 'الحد الائتماني',
            hint: '0.00',
            controller: cubit.creditLimitController,
            isNum: true,
            textInputType: TextInputType.number,
          ),
          TxtFieldWidget(
            label: 'الرصيد الافتتاحي',
            hint: '0.00',
            controller: cubit.openingBalanceController,
            isNum: true,
            textInputType: TextInputType.number,
          ),
          TxtFieldWidget(
            label: 'يوم الاستحقاق',
            hint: '1 - 31',
            controller: cubit.dueDayController,
            isNum: true,
            textInputType: TextInputType.number,
          ),
          TxtFieldWidget(
            label: 'يوم إغلاق كشف الحساب',
            hint: '1 - 31',
            controller: cubit.statementClosingDayController,
            isNum: true,
            textInputType: TextInputType.number,
          ),
          TxtFieldWidget(
            label: 'لون البطاقة (Hex)',
            hint: '#1565C0',
            controller: cubit.colorHexController,
            isOptional: true,
          ),
          TxtFieldWidget(
            label: 'مرجع شعار البطاقة',
            hint: 'رابط أو مرجع محلي مؤقت',
            controller: cubit.logoUrlController,
            isOptional: true,
          ),
          TxtFieldWidget(
            label: 'ملاحظات',
            hint: 'اختياري',
            controller: cubit.notesController,
            isOptional: true,
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}

class _DepositFormWidget extends StatelessWidget {
  const _DepositFormWidget({required this.cubit});

  final CreditCardsCubit cubit;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: cubit.depositFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.sm,
        children: [
          TxtFieldWidget(
            label: 'مبلغ الإيداع',
            hint: '0.00',
            controller: cubit.depositAmountController,
            isNum: true,
            textInputType: TextInputType.number,
          ),
          CustomBtnWidget(
            onTap: () async {
              final selected = await showDatePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
                initialDate: cubit.depositDate,
              );
              if (selected != null) cubit.setDepositDate(selected);
            },
            withoutBackground: true,
            widget: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'تاريخ الإيداع: ${DateFormat('dd/MM/yyyy').format(cubit.depositDate)}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseFormWidget extends StatelessWidget {
  const _PurchaseFormWidget({required this.cubit});

  final CreditCardsCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CreditCardsCubit, CreditCardsState>(
      bloc: cubit,
      builder: (context, state) => Form(
        key: cubit.purchaseFormKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            DropDownBtnWidget<BrandModel>(
              label: 'العلامة التجارية',
              hint: 'اختر العلامة التجارية',
              items: state.brands.where((item) => item.active).toList(),
              value: cubit.selectedBrand,
              getLabel: (brand) => '${brand.name} — ${brand.providerName}',
              onChanged: (brand) => cubit.selectBrand(brand.id),
            ),
            if (state.selectedBrandWarning != null)
              AppInfoBanner(
                message: state.selectedBrandWarning!,
                tone: AppTone.warning,
                icon: Icons.info_outline_rounded,
              ),
            if (state.brandUsageSummaries.isNotEmpty) ...[
              const Text('اقتراحات الاستخدام الأقل لهذه البطاقة'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: state.brandUsageSummaries.take(4).map((summary) {
                  final lastUsed = summary.lastUsedAtMillis == null
                      ? 'لم تستخدم سابقاً'
                      : 'آخر استخدام ${DateFormat('MM/yyyy').format(DateTime.fromMillisecondsSinceEpoch(summary.lastUsedAtMillis!))}';
                  return Chip(label: Text('${summary.brandName} · $lastUsed'));
                }).toList(),
              ),
            ],
            TxtFieldWidget(
              label: 'مبلغ الشراء',
              hint: '0.00',
              controller: cubit.purchaseAmountController,
              isNum: true,
              textInputType: TextInputType.number,
            ),
            CustomBtnWidget(
              onTap: () async {
                final selected = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDate: cubit.purchaseDate,
                );
                if (selected != null) cubit.setPurchaseDate(selected);
              },
              withoutBackground: true,
              widget: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(
                  'تاريخ الشراء: ${DateFormat('dd/MM/yyyy').format(cubit.purchaseDate)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
