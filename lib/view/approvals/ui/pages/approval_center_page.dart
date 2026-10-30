import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:base/core/enums/enums.dart';
import 'package:base/core/extensions/extensions.dart';
import 'package:base/core/navigation/app_navigation.dart';
import 'package:base/core/services/services.dart';
import 'package:base/core/theme/theme.dart';
import 'package:base/core/utils/finance_money.dart';
import 'package:base/core/widgets/widgets.dart';
import 'package:base/view/credit_cards/ui/controllers/credit_cards_cubit/credit_cards_cubit.dart';
import 'package:base/view/credit_cards/ui/controllers/credit_cards_cubit/credit_cards_states.dart';
import 'package:base/view/operations/ui/controllers/operations_cubit/operations_cubit.dart';
import 'package:base/view/operations/ui/controllers/operations_cubit/operations_states.dart';

class ApprovalCenterPage extends StatefulWidget {
  const ApprovalCenterPage({super.key});

  @override
  State<ApprovalCenterPage> createState() => _ApprovalCenterPageState();
}

class _ApprovalCenterPageState extends State<ApprovalCenterPage> {
  late final OperationsCubit _cubit;
  late final CreditCardsCubit _creditCubit;

  @override
  void initState() {
    super.initState();
    _cubit = sl<OperationsCubit>()..load();
    _creditCubit = sl<CreditCardsCubit>()..load();
  }

  @override
  void dispose() {
    _cubit.close();
    _creditCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppPageScaffold(
    destination: AppDestination.approvals,
    title: 'مركز الاعتمادات',
    subtitle: 'الطلبات التي تنتظر قراراً مالياً',
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
        bloc: _cubit,
        builder: (context, state) {
          if (state.status == RequestStatus.loading &&
              state.accounts.isEmpty &&
              state.settlements.isEmpty) {
            return const AppPageShimmerWidget(
              type: AppPageShimmerType.approvals,
            );
          }
          final sections = <_ApprovalSection>[
            _approvalSection(
              title: 'إيداعات بطاقات الائتمان',
              icon: Icons.credit_score_outlined,
              tone: AppTone.primary,
              children: creditState.allDeposits
                  .where((item) => item.approvalStatus == 'pending')
                  .map(
                    (item) => _ApprovalTile(
                      title: 'إيداع بطاقة ${item.cardId}',
                      subtitle:
                          'تاريخ الإيداع: ${DateTime.fromMillisecondsSinceEpoch(item.depositDateMillis).toIso8601String().split('T').first}',
                      amountMinor: item.amountMinor,
                      actionLabel: 'اعتماد',
                      onAction: () => _runCredit(
                        () => _creditCubit.approveDeposit(item.id),
                      ),
                      secondaryActionLabel: 'رفض',
                      onSecondaryAction: () => _rejectCreditDeposit(item.id),
                    ),
                  )
                  .toList(),
            ),
            _approvalSection(
              title: 'حركات الخزينة',
              icon: Icons.account_balance_wallet_outlined,
              tone: AppTone.info,
              children: state.movements
                  .where((item) => item.approvalStatus == 'pending')
                  .map(
                    (item) => _ApprovalTile(
                      title: item.note.isEmpty ? 'حركة خزينة' : item.note,
                      subtitle:
                          '${item.type} · ${item.relatedParty.isEmpty ? 'بدون طرف مرتبط' : item.relatedParty}',
                      amountMinor: item.amountMinor,
                      actionLabel: 'اعتماد',
                      onAction: () =>
                          _run(() => _cubit.approveTreasuryMovement(item.id)),
                      secondaryActionLabel: 'رفض',
                      onSecondaryAction: () =>
                          _rejectPending('treasury_movement', item.id),
                    ),
                  )
                  .toList(),
            ),
            _approvalSection(
              title: 'حركات الحسابات البنكية',
              icon: Icons.account_balance_outlined,
              tone: AppTone.info,
              children: state.bankMovements
                  .where((item) => item.approvalStatus == 'pending')
                  .map(
                    (item) => _ApprovalTile(
                      title: item.note.isEmpty ? 'حركة بنكية' : item.note,
                      subtitle: item.relatedParty,
                      amountMinor: item.amountMinor,
                      actionLabel: 'اعتماد',
                      onAction: () =>
                          _run(() => _cubit.approveBankMovement(item.id)),
                      secondaryActionLabel: 'رفض',
                      onSecondaryAction: () =>
                          _rejectPending('bank_movement', item.id),
                    ),
                  )
                  .toList(),
            ),
            _approvalSection(
              title: 'المصروفات',
              icon: Icons.receipt_long_outlined,
              tone: AppTone.gold,
              children: state.expenses
                  .where((item) => item.status == 'pending')
                  .map(
                    (item) => _ApprovalTile(
                      title: item.description,
                      subtitle: '${item.category} · ${item.beneficiary}',
                      amountMinor: item.amountMinor,
                      actionLabel: 'اعتماد',
                      onAction: () =>
                          _run(() => _cubit.approveExpense(item.id)),
                      secondaryActionLabel: 'رفض',
                      onSecondaryAction: () =>
                          _rejectPending('expense', item.id),
                    ),
                  )
                  .toList(),
            ),
            _approvalSection(
              title: 'السحوبات الشخصية',
              icon: Icons.person_remove_outlined,
              tone: AppTone.warning,
              children: state.personalWithdrawals
                  .where((item) => item.status == 'pending')
                  .map(
                    (item) => _ApprovalTile(
                      title: item.personName,
                      subtitle: item.reason,
                      amountMinor: item.amountMinor,
                      actionLabel: 'اعتماد',
                      onAction: () =>
                          _run(() => _cubit.approvePersonalWithdrawal(item.id)),
                      secondaryActionLabel: 'رفض',
                      onSecondaryAction: () =>
                          _rejectPending('personal_withdrawal', item.id),
                    ),
                  )
                  .toList(),
            ),
            _approvalSection(
              title: 'التحويلات الداخلية',
              icon: Icons.swap_horiz_outlined,
              tone: AppTone.info,
              children: state.transfers
                  .where((item) => item.status == 'pending')
                  .map(
                    (item) => _ApprovalTile(
                      title:
                          '${item.sourceAccountId} ← ${item.destinationAccountId}',
                      subtitle:
                          '${item.sourceAccountType} → ${item.destinationAccountType}',
                      amountMinor: item.amountMinor,
                      actionLabel: 'اعتماد',
                      onAction: () =>
                          _run(() => _cubit.approveTreasuryTransfer(item.id)),
                      secondaryActionLabel: 'رفض',
                      onSecondaryAction: () =>
                          _rejectPending('treasury_transfer', item.id),
                    ),
                  )
                  .toList(),
            ),
            _approvalSection(
              title: 'مراجعة التسويات',
              icon: Icons.fact_check_outlined,
              tone: AppTone.success,
              children: state.settlements
                  .where((item) => item.approvalStatus == 'pending')
                  .map(
                    (item) => _ApprovalTile(
                      title: item.brandName.isEmpty
                          ? item.providerName
                          : item.brandName,
                      subtitle: '${item.periodLabel} · ${item.providerName}',
                      amountMinor: item.grossMinor,
                      actionLabel: 'اعتماد',
                      onAction: () =>
                          _run(() => _cubit.approveSettlement(item.id)),
                      secondaryActionLabel: 'رفض',
                      onSecondaryAction: () => _rejectSettlement(item.id),
                    ),
                  )
                  .toList(),
            ),
            _approvalSection(
              title: 'طلبات تحصيل بانتظار التأكيد البنكي',
              icon: Icons.account_balance_outlined,
              tone: AppTone.gold,
              children: state.collectionRequests
                  .where((item) => item.status == 'pending')
                  .map(
                    (item) => _ApprovalTile(
                      title: item.collectionType == 'instant'
                          ? 'تحصيل فوري'
                          : 'تحصيل عادي',
                      subtitle: item.settlementId,
                      amountMinor: item.amountMinor,
                      actionLabel: 'تأكيد بنكي',
                      onAction: () => _confirmCollection(item.id),
                    ),
                  )
                  .toList(),
            ),
          ];
          final active = sections
              .where((section) => section.hasChildren)
              .toList();
          final pendingCount = active.fold<int>(
            0,
            (sum, section) => sum + section.children.length,
          );
          if (active.isEmpty) {
            return const AppStateView(
              icon: Icons.verified_outlined,
              tone: AppTone.success,
              title: 'لا توجد معاملات بانتظار الاعتماد',
              message: 'كل الطلبات المالية تمت معالجتها بنجاح.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppBreakpoints.of(context).sectionSpacing,
            children: [
              AppInfoBanner(
                icon: Icons.pending_actions_outlined,
                tone: AppTone.warning,
                message:
                    '$pendingCount طلب مالي بانتظار قرارك عبر ${active.length} فئة.',
              ),
              ...active,
            ],
          );
        },
      ),
    ),
  );

  _ApprovalSection _approvalSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    AppTone tone = AppTone.primary,
  }) => _ApprovalSection(
    title: title,
    icon: icon,
    tone: tone,
    children: children,
  );

  Future<void> _run(Future<void> Function() action) async {
    await action();
    if (mounted) await _cubit.load();
  }

  Future<void> _runCredit(Future<void> Function() action) async {
    await action();
    if (mounted) await _creditCubit.load();
  }

  Future<void> _refresh() async {
    await Future.wait([_cubit.load(), _creditCubit.load()]);
  }

  Future<void> _rejectSettlement(String settlementId) async {
    final reason = await showAppPromptDialog(
      context: context,
      title: 'سبب رفض التسوية',
      label: 'السبب',
      confirmText: 'رفض',
    );
    if (reason == null) return;
    _cubit.settlementRejectionReasonController.text = reason;
    await _run(() => _cubit.rejectSettlement(settlementId));
  }

  Future<void> _rejectCreditDeposit(String depositId) async {
    final reason = await _reasonDialog('سبب رفض إيداع البطاقة');
    if (reason == null) return;
    await _runCredit(
      () => _creditCubit.rejectDeposit(depositId: depositId, reason: reason),
    );
  }

  Future<void> _rejectPending(String entityType, String entityId) async {
    final reason = await _reasonDialog('سبب رفض المعاملة');
    if (reason == null) return;
    await _run(
      () => _cubit.rejectPendingOperation(
        entityType: entityType,
        entityId: entityId,
        reason: reason,
      ),
    );
  }

  Future<String?> _reasonDialog(String title) {
    return showAppPromptDialog(
      context: context,
      title: title,
      label: 'السبب',
      confirmText: 'رفض',
    );
  }

  Future<void> _confirmCollection(String requestId) async {
    final reference = await showAppPromptDialog(
      context: context,
      title: 'تأكيد التحصيل البنكي',
      label: 'مرجع التحويل',
      confirmText: 'تأكيد',
      multiline: false,
    );
    if (reference == null) return;
    _cubit.selectedCollectionRequestId = requestId;
    _cubit.collectionConfirmationController.text = reference;
    await _run(_cubit.confirmCollectionRequest);
  }
}

class _ApprovalSection extends StatelessWidget {
  const _ApprovalSection({
    required this.title,
    required this.icon,
    required this.children,
    this.tone = AppTone.primary,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final AppTone tone;

  bool get hasChildren => children.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return AppSectionCard(
      title: title,
      subtitle: '${children.length} طلب',
      icon: icon,
      tone: tone,
      showDivider: true,
      trailing: AppStatusChip(
        status: 'pending',
        label: '${children.length}',
        compact: true,
      ),
      child: Column(
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
}

class _ApprovalTile extends StatelessWidget {
  const _ApprovalTile({
    required this.title,
    required this.subtitle,
    required this.amountMinor,
    required this.actionLabel,
    required this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String subtitle;
  final int amountMinor;
  final String actionLabel;
  final Future<void> Function() onAction;
  final String? secondaryActionLabel;
  final Future<void> Function()? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 3,
      children: [
        Text(
          title,
          style: context.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(subtitle, style: context.textTheme.bodySmall),
        Text(
          FinanceMoney.formatEgp(amountMinor),
          style: context.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: context.colors.onSurface,
          ),
        ),
      ],
    );
    final actions = Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xxs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (secondaryActionLabel != null && onSecondaryAction != null)
          OutlinedButton(
            onPressed: () => onSecondaryAction!(),
            child: Text(secondaryActionLabel!),
          ),
        FilledButton(onPressed: () => onAction(), child: Text(actionLabel)),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: AppSpacing.xs,
              children: [
                details,
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: actions,
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            spacing: AppSpacing.md,
            children: [
              Expanded(child: details),
              actions,
            ],
          ),
        );
      },
    );
  }
}
