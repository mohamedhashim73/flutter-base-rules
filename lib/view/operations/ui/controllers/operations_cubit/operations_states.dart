import 'package:base/core/enums/enums.dart';
import 'package:base/model/base/request_state.dart';
import 'package:base/model/domain/expense_model.dart';
import 'package:base/model/domain/expense_category_model.dart';
import 'package:base/model/domain/bank_account_model.dart';
import 'package:base/model/domain/collection_request_model.dart';
import 'package:base/model/domain/issued_check_model.dart';
import 'package:base/model/domain/installment_account_model.dart';
import 'package:base/model/domain/settlement_model.dart';
import 'package:base/model/domain/treasury_account_model.dart';
import 'package:base/model/domain/treasury_movement_model.dart';
import 'package:base/model/domain/treasury_transfer_model.dart';
import 'package:base/model/domain/personal_withdrawal_model.dart';
import 'package:base/model/domain/withdrawal_person_model.dart';
import 'package:base/model/domain/treasury_reconciliation_model.dart';
import 'package:base/model/domain/receiving_company_model.dart';
import 'package:base/model/domain/brand_model.dart';
import 'package:base/model/domain/bank_movement_model.dart';
import 'package:base/model/domain/installment_schedule_model.dart';
import 'package:base/model/domain/credit_purchase_model.dart';

class OperationsState extends RequestState {
  const OperationsState({
    super.status,
    super.message,
    this.accounts = const [],
    this.movements = const [],
    this.expenses = const [],
    this.expenseCategories = const [],
    this.installments = const [],
    this.checks = const [],
    this.settlements = const [],
    this.bankAccounts = const [],
    this.receivingCompanies = const [],
    this.collectionRequests = const [],
    this.transfers = const [],
    this.personalWithdrawals = const [],
    this.withdrawalPeople = const [],
    this.reconciliations = const [],
    this.brands = const [],
    this.bankMovements = const [],
    this.installmentSchedules = const [],
    this.creditPurchases = const [],
    this.actionStatus,
    this.actionMessage,
  });
  final List<TreasuryAccountModel> accounts;
  final List<TreasuryMovementModel> movements;
  final List<ExpenseModel> expenses;
  final List<ExpenseCategoryModel> expenseCategories;
  final List<InstallmentAccountModel> installments;
  final List<IssuedCheckModel> checks;
  final List<SettlementModel> settlements;
  final List<BankAccountModel> bankAccounts;
  final List<ReceivingCompanyModel> receivingCompanies;
  final List<CollectionRequestModel> collectionRequests;
  final List<TreasuryTransferModel> transfers;
  final List<PersonalWithdrawalModel> personalWithdrawals;
  final List<WithdrawalPersonModel> withdrawalPeople;
  final List<TreasuryReconciliationModel> reconciliations;
  final List<BrandModel> brands;
  final List<BankMovementModel> bankMovements;
  final List<InstallmentScheduleModel> installmentSchedules;
  final List<CreditPurchaseModel> creditPurchases;
  final RequestStatus? actionStatus;
  final String? actionMessage;

  OperationsState copyWith({
    RequestStatus? status,
    String? message,
    List<TreasuryAccountModel>? accounts,
    List<TreasuryMovementModel>? movements,
    List<ExpenseModel>? expenses,
    List<ExpenseCategoryModel>? expenseCategories,
    List<InstallmentAccountModel>? installments,
    List<IssuedCheckModel>? checks,
    List<SettlementModel>? settlements,
    List<BankAccountModel>? bankAccounts,
    List<ReceivingCompanyModel>? receivingCompanies,
    List<CollectionRequestModel>? collectionRequests,
    List<TreasuryTransferModel>? transfers,
    List<PersonalWithdrawalModel>? personalWithdrawals,
    List<WithdrawalPersonModel>? withdrawalPeople,
    List<TreasuryReconciliationModel>? reconciliations,
    List<BrandModel>? brands,
    List<BankMovementModel>? bankMovements,
    List<InstallmentScheduleModel>? installmentSchedules,
    List<CreditPurchaseModel>? creditPurchases,
    RequestStatus? actionStatus,
    String? actionMessage,
  }) => OperationsState(
    status: status ?? this.status,
    message: message,
    accounts: accounts ?? this.accounts,
    movements: movements ?? this.movements,
    expenses: expenses ?? this.expenses,
    expenseCategories: expenseCategories ?? this.expenseCategories,
    installments: installments ?? this.installments,
    checks: checks ?? this.checks,
    settlements: settlements ?? this.settlements,
    bankAccounts: bankAccounts ?? this.bankAccounts,
    receivingCompanies: receivingCompanies ?? this.receivingCompanies,
    collectionRequests: collectionRequests ?? this.collectionRequests,
    transfers: transfers ?? this.transfers,
    personalWithdrawals: personalWithdrawals ?? this.personalWithdrawals,
    withdrawalPeople: withdrawalPeople ?? this.withdrawalPeople,
    reconciliations: reconciliations ?? this.reconciliations,
    brands: brands ?? this.brands,
    bankMovements: bankMovements ?? this.bankMovements,
    installmentSchedules: installmentSchedules ?? this.installmentSchedules,
    creditPurchases: creditPurchases ?? this.creditPurchases,
    actionStatus: actionStatus,
    actionMessage: actionMessage,
  );
}
