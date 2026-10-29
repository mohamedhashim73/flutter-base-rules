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

abstract interface class OperationsRepository {
  Future<List<TreasuryAccountModel>> getTreasuryAccounts();
  Future<List<TreasuryMovementModel>> getTreasuryMovements();
  Future<List<TreasuryTransferModel>> getTreasuryTransfers();
  Future<List<PersonalWithdrawalModel>> getPersonalWithdrawals();
  Future<List<WithdrawalPersonModel>> getWithdrawalPeople();
  Future<List<TreasuryReconciliationModel>> getReconciliations();
  Future<List<ExpenseModel>> getExpenses();
  Future<List<ExpenseCategoryModel>> getExpenseCategories();
  Future<List<InstallmentAccountModel>> getInstallments();
  Future<List<IssuedCheckModel>> getChecks();
  Future<List<SettlementModel>> getSettlements();
  Future<List<BankAccountModel>> getBankAccounts();
  Future<List<ReceivingCompanyModel>> getReceivingCompanies();
  Future<List<CollectionRequestModel>> getCollectionRequests();
  Future<List<BrandModel>> getBrands();
  Future<List<BankMovementModel>> getBankMovements();
  Future<List<InstallmentScheduleModel>> getInstallmentSchedules();
  Future<void> refreshDueNotifications({
    required List<InstallmentAccountModel> installments,
    required List<IssuedCheckModel> checks,
  });
  Future<void> createTreasuryAccount(
    String name, {
    int openingBalanceMinor = 0,
  });
  Future<void> createBankAccount({
    required String bankName,
    required String accountName,
    required String lastFour,
    required int openingBalanceMinor,
  });
  Future<void> createReceivingCompany({
    required String name,
    required String bankAccountId,
  });
  Future<void> addBankAccountToReceivingCompany({
    required String companyId,
    required String bankAccountId,
  });
  Future<void> updateBankAccount(BankAccountModel account);
  Future<void> updateReceivingCompany(ReceivingCompanyModel company);
  Future<void> updateExpenseCategory(ExpenseCategoryModel category);
  Future<void> recordTreasuryMovement({
    required String accountId,
    required String type,
    required int amountMinor,
    required String note,
    String relatedParty = '',
    int? transactionDateMillis,
  });
  Future<void> approveTreasuryMovement(String movementId);
  Future<void> recordBankMovement({
    required String accountId,
    required String type,
    required int amountMinor,
    required String note,
    String relatedParty = '',
  });
  Future<void> approveBankMovement(String movementId);
  Future<void> rejectPendingOperation({
    required String entityType,
    required String entityId,
    required String reason,
  });
  Future<void> createTreasuryTransfer({
    required String sourceAccountId,
    required String destinationAccountId,
    required int amountMinor,
    required int feeMinor,
    String sourceAccountType = 'treasury',
    String destinationAccountType = 'treasury',
  });
  Future<void> approveTreasuryTransfer(String transferId);
  Future<void> createPersonalWithdrawal({
    required String personName,
    required String accountId,
    required int amountMinor,
    required String reason,
    int? withdrawalDateMillis,
  });
  Future<void> createWithdrawalPerson(String name);
  Future<void> updateWithdrawalPerson(WithdrawalPersonModel person);
  Future<void> approvePersonalWithdrawal(String withdrawalId);
  Future<void> createReconciliation({
    required String accountId,
    required int expectedMinor,
    required int actualMinor,
    required String reason,
  });
  Future<void> createExpense({
    required String accountId,
    required String category,
    required String description,
    required int amountMinor,
    String beneficiary = '',
    String notes = '',
    int? expenseDateMillis,
  });
  Future<void> createExpenseCategory(String name);
  Future<void> approveExpense(String expenseId);
  Future<void> createInstallment({
    required String customerName,
    required String reference,
    required int principalMinor,
    required int totalDueMinor,
    required int nextDueMillis,
    int totalLimitMinor = 0,
    int availableMinor = 0,
    int monthlyInstallmentMinor = 0,
    int totalInstallments = 0,
  });
  Future<void> createInstallmentSchedule({
    required String accountId,
    required String description,
    required int principalMinor,
    required int totalDueMinor,
    required int monthlyAmountMinor,
    required int totalInstallments,
    required int nextDueMillis,
  });
  Future<void> updateInstallmentAccount({
    required String accountId,
    required String customerName,
    required String reference,
    String? status,
  });
  Future<void> recordInstallmentPayment({
    required String id,
    required String accountId,
    required int amountMinor,
    required int nextDueMillis,
    String? scheduleId,
  });
  Future<void> createCheck({
    required String payee,
    required String reference,
    required int amountMinor,
    required int dueDateMillis,
    required String accountId,
    String bankName = '',
    String notes = '',
  });
  Future<void> updateCheckStatus({
    required String checkId,
    required String status,
  });
  Future<void> createSettlement({
    required String providerName,
    required String periodLabel,
    required int grossMinor,
    required int commissionMinor,
    String brandId = '',
    String brandName = '',
    String receivingCompanyId = '',
    String receivingCompanyName = '',
    String destinationBankAccountId = '',
    String destinationBankAccountName = '',
    String posMachineId = '',
    String posMachineName = '',
    List<String> includedTransactionIds = const [],
  });
  Future<void> approveSettlement(String settlementId);
  Future<void> rejectSettlement({
    required String settlementId,
    required String reason,
  });
  Future<void> createCollectionRequest({
    required String settlementId,
    required int amountMinor,
    String collectionType = 'instant',
  });
  Future<void> confirmCollectionRequest({
    required String requestId,
    required String confirmationReference,
  });
}
