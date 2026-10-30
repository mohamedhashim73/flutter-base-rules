// Temporary visual-review entry point. Not part of the shipped application.
import 'package:base/app/di/app_dependencies.dart';
import 'package:base/core/core.dart';
import 'package:base/core/navigation/app_navigation.dart';
import 'package:base/main.dart';
import 'package:base/model/domain/app_notification_model.dart';
import 'package:base/model/domain/bank_account_model.dart';
import 'package:base/model/domain/credit_card_model.dart';
import 'package:base/model/domain/expense_model.dart';
import 'package:base/view/approvals/ui/pages/approval_center_page.dart';
import 'package:base/view/audit/data/repository/audit_repository.dart';
import 'package:base/view/audit/ui/controllers/audit_cubit/audit_cubit.dart';
import 'package:base/view/audit/ui/controllers/audit_cubit/audit_states.dart';
import 'package:base/view/audit/ui/pages/audit_page.dart';
import 'package:base/view/catalogs/ui/pages/catalog_management_page.dart';
import 'package:base/view/credit_cards/data/repository/credit_cards_repository.dart';
import 'package:base/view/credit_cards/ui/controllers/credit_cards_cubit/credit_cards_cubit.dart';
import 'package:base/view/credit_cards/ui/controllers/credit_cards_cubit/credit_cards_states.dart';
import 'package:base/view/credit_cards/ui/pages/credit_cards_page.dart';
import 'package:base/view/dashboard/ui/pages/dashboard_page.dart';
import 'package:base/view/notifications/data/repository/notifications_repository.dart';
import 'package:base/view/notifications/ui/controllers/notifications_cubit/notifications_cubit.dart';
import 'package:base/view/notifications/ui/controllers/notifications_cubit/notifications_states.dart';
import 'package:base/view/notifications/ui/pages/notifications_page.dart';
import 'package:base/view/operations/data/repository/operations_repository.dart';
import 'package:base/view/operations/ui/controllers/operations_cubit/operations_cubit.dart';
import 'package:base/view/operations/ui/controllers/operations_cubit/operations_states.dart';
import 'package:base/view/operations/ui/pages/checks_page.dart';
import 'package:base/view/operations/ui/pages/expense_management_page.dart';
import 'package:base/view/operations/ui/pages/installments_page.dart';
import 'package:base/view/operations/ui/pages/operations_page.dart';
import 'package:base/view/operations/ui/pages/personal_withdrawals_page.dart';
import 'package:base/view/operations/ui/pages/settlements_page.dart';
import 'package:base/view/operations/ui/pages/treasury_ledger_page.dart';
import 'package:base/view/reports/ui/pages/reports_page.dart';
import 'package:base/view/users/data/repository/users_repository.dart';
import 'package:base/view/users/ui/controllers/users_cubit/users_cubit.dart';
import 'package:base/view/users/ui/controllers/users_cubit/users_states.dart';
import 'package:base/view/users/ui/pages/users_page.dart';
import 'package:flutter/widgets.dart';

const _now = 1760000000000;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConstants.kAppInitialization();
  registerAppDependencies();

  sl
    ..unregister<CreditCardsCubit>()
    ..registerFactory<CreditCardsCubit>(
      () => _PreviewCreditCardsCubit(sl<CreditCardsRepository>()),
    )
    ..unregister<OperationsCubit>()
    ..registerFactory<OperationsCubit>(
      () => _PreviewOperationsCubit(
        sl<OperationsRepository>(),
        sl<CreditCardsRepository>(),
      ),
    )
    ..unregister<NotificationsCubit>()
    ..registerFactory<NotificationsCubit>(
      () => _PreviewNotificationsCubit(sl<NotificationsRepository>()),
    )
    ..unregister<UsersCubit>()
    ..registerFactory<UsersCubit>(
      () => _PreviewUsersCubit(sl<UsersRepository>()),
    )
    ..unregister<AuditCubit>()
    ..registerFactory<AuditCubit>(
      () => _PreviewAuditCubit(sl<AuditRepository>()),
    );

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

  runApp(const MyApp(home: DashboardPage()));
}

class _PreviewCreditCardsCubit extends CreditCardsCubit {
  _PreviewCreditCardsCubit(super.repository);

  @override
  Future<void> load() async {
    if (isClosed) return;
    emit(const CreditCardsState(status: RequestStatus.success, cards: _cards));
  }
}

class _PreviewOperationsCubit extends OperationsCubit {
  _PreviewOperationsCubit(super.repository, super.creditCardsRepository);

  @override
  Future<void> load() async {
    if (isClosed) return;
    emit(
      const OperationsState(
        status: RequestStatus.success,
        bankAccounts: _bankAccounts,
        expenses: _expenses,
      ),
    );
  }
}

class _PreviewNotificationsCubit extends NotificationsCubit {
  _PreviewNotificationsCubit(super.repository);

  @override
  Future<void> load() async {
    if (isClosed) return;
    emit(
      const NotificationsState(
        status: RequestStatus.success,
        items: [
          AppNotificationModel(
            id: 'n1',
            title: 'فاتورة بطاقة تقترب من الاستحقاق',
            body: 'بطاقة الخزينة الرئيسية مستحقة خلال ثلاثة أيام.',
            category: 'billing',
            targetType: 'card',
            targetId: 'c1',
            read: false,
            createdAtMillis: _now,
          ),
          AppNotificationModel(
            id: 'n2',
            title: 'تم اعتماد تسوية المزود',
            body: 'اعتمد مدير الخزينة تسوية مزود الشبكة.',
            category: 'settlement',
            targetType: 'settlement',
            targetId: 's1',
            read: true,
            createdAtMillis: _now,
          ),
        ],
      ),
    );
  }
}

class _PreviewUsersCubit extends UsersCubit {
  _PreviewUsersCubit(super.repository);

  @override
  Future<void> load() async {
    if (isClosed) return;
    emit(const UsersState(status: RequestStatus.success));
  }
}

class _PreviewAuditCubit extends AuditCubit {
  _PreviewAuditCubit(super.repository);

  @override
  Future<void> load() async {
    if (isClosed) return;
    emit(const AuditState(status: RequestStatus.success));
  }
}

const _cards = [
  CreditCardModel(
    id: 'c1',
    title: 'بطاقة الخزينة الرئيسية',
    cardholderName: 'خزينة كريديكسا',
    bankName: 'البنك الأهلي',
    maskedNumber: '•••• 4821',
    lastFour: '4821',
    creditLimitMinor: 5000000,
    availableBalanceMinor: 3120000,
    monthlyPaidMinor: 820000,
    currentMonthlyDebtMinor: 1880000,
    dueDay: 24,
    active: true,
    notes: '',
    createdAtMillis: _now,
    updatedAtMillis: _now,
    colorHex: '14382F',
  ),
  CreditCardModel(
    id: 'c2',
    title: 'بطاقة المشتريات التشغيلية',
    cardholderName: 'إدارة التشغيل',
    bankName: 'بنك الرياض',
    maskedNumber: '•••• 9054',
    lastFour: '9054',
    creditLimitMinor: 2500000,
    availableBalanceMinor: 1690000,
    monthlyPaidMinor: 380000,
    currentMonthlyDebtMinor: 810000,
    dueDay: 18,
    active: true,
    notes: '',
    createdAtMillis: _now,
    updatedAtMillis: _now,
    colorHex: '0F8A5F',
  ),
];

const _bankAccounts = [
  BankAccountModel(
    id: 'b1',
    bankName: 'البنك الأهلي',
    accountName: 'الحساب التشغيلي',
    lastFour: '1120',
    active: true,
    updatedAtMillis: _now,
    openingBalanceMinor: 8400000,
    balanceMinor: 9725000,
  ),
  BankAccountModel(
    id: 'b2',
    bankName: 'بنك الرياض',
    accountName: 'حساب التحصيل',
    lastFour: '7742',
    active: true,
    updatedAtMillis: _now,
    openingBalanceMinor: 2100000,
    balanceMinor: 1840000,
  ),
];

const _expenses = [
  ExpenseModel(
    id: 'e1',
    category: 'تشغيل',
    description: 'اشتراك منصة الفوترة',
    amountMinor: 125000,
    accountId: 'b1',
    status: 'approved',
    createdBy: 'manager',
    createdAtMillis: _now,
    beneficiary: 'منصة الفوترة',
  ),
  ExpenseModel(
    id: 'e2',
    category: 'صيانة',
    description: 'صيانة أجهزة نقاط البيع',
    amountMinor: 68000,
    accountId: 'b1',
    status: 'pending',
    createdBy: 'employee',
    createdAtMillis: _now,
    beneficiary: 'مزود الصيانة',
  ),
];
