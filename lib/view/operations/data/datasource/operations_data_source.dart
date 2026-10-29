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

abstract interface class OperationsDataSource {
  String newDocumentId();
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
  Future<void> saveTreasuryAccount(TreasuryAccountModel account);
  Future<void> addTreasuryMovement(TreasuryMovementModel movement);
  Future<void> approveTreasuryMovement(String movementId);
  Future<void> addBankMovement(BankMovementModel movement);
  Future<void> approveBankMovement(String movementId);
  Future<void> rejectPendingOperation({
    required String entityType,
    required String entityId,
    required String reason,
  });
  Future<void> addTreasuryTransfer(TreasuryTransferModel transfer);
  Future<void> approveTreasuryTransfer(String transferId);
  Future<void> addPersonalWithdrawal(PersonalWithdrawalModel withdrawal);
  Future<void> saveWithdrawalPerson(WithdrawalPersonModel person);
  Future<void> approvePersonalWithdrawal(String withdrawalId);
  Future<void> addReconciliation(TreasuryReconciliationModel reconciliation);
  Future<void> addExpense(ExpenseModel expense);
  Future<void> saveExpenseCategory(ExpenseCategoryModel category);
  Future<void> approveExpense(String expenseId);
  Future<void> saveInstallment(InstallmentAccountModel account);
  Future<void> saveInstallmentSchedule(InstallmentScheduleModel schedule);
  Future<void> updateInstallmentAccount({
    required String accountId,
    required String customerName,
    required String reference,
    String? status,
  });
  Future<void> addInstallmentPayment({
    required String id,
    required String accountId,
    required int amountMinor,
    required int nextDueMillis,
    String? scheduleId,
  });
  Future<void> saveCheck(IssuedCheckModel check);
  Future<void> updateCheckStatus({
    required String checkId,
    required String status,
  });
  Future<void> saveSettlement(SettlementModel settlement);
  Future<void> createSettlement({
    required String settlementId,
    required String brandId,
    required String periodLabel,
    required List<String> includedTransactionIds,
  });
  Future<void> approveSettlement(String settlementId);
  Future<void> rejectSettlement({
    required String settlementId,
    required String reason,
  });
  Future<void> saveBankAccount(BankAccountModel account);
  Future<void> saveReceivingCompany(ReceivingCompanyModel company);
  Future<void> addBankAccountToReceivingCompany({
    required String companyId,
    required String bankAccountId,
  });
  Future<void> addCollectionRequest(CollectionRequestModel request);
  Future<void> confirmCollectionRequest({
    required String requestId,
    required String confirmationReference,
  });
}
