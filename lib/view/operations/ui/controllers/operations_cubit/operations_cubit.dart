import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:base/core/enums/enums.dart';
import 'package:base/core/services/services.dart';
import 'package:base/core/utils/finance_money.dart';
import 'package:base/model/domain/expense_model.dart';
import 'package:base/model/domain/expense_category_model.dart';
import 'package:base/model/domain/bank_account_model.dart';
import 'package:base/model/domain/collection_request_model.dart';
import 'package:base/model/domain/issued_check_model.dart';
import 'package:base/model/domain/installment_account_model.dart';
import 'package:base/model/domain/settlement_model.dart';
import 'package:base/model/domain/receiving_company_model.dart';
import 'package:base/model/domain/treasury_movement_model.dart';
import 'package:base/model/domain/treasury_account_model.dart';
import 'package:base/model/domain/treasury_transfer_model.dart';
import 'package:base/model/domain/personal_withdrawal_model.dart';
import 'package:base/model/domain/withdrawal_person_model.dart';
import 'package:base/model/domain/treasury_reconciliation_model.dart';
import 'package:base/model/domain/brand_model.dart';
import 'package:base/model/domain/bank_movement_model.dart';
import 'package:base/model/domain/installment_schedule_model.dart';
import 'package:base/model/domain/credit_purchase_model.dart';
import 'package:base/view/operations/data/repository/operations_repository.dart';
import 'package:base/view/credit_cards/data/repository/credit_cards_repository.dart';
import 'operations_states.dart';

class OperationsCubit extends Cubit<OperationsState> {
  OperationsCubit(this._repository, this._creditCardsRepository)
    : super(const OperationsState());
  final OperationsRepository _repository;
  final CreditCardsRepository _creditCardsRepository;
  final treasuryFormKey = GlobalKey<FormState>();
  final movementFormKey = GlobalKey<FormState>();
  final expenseFormKey = GlobalKey<FormState>();
  final expenseCategoryFormKey = GlobalKey<FormState>();
  final installmentFormKey = GlobalKey<FormState>();
  final installmentScheduleFormKey = GlobalKey<FormState>();
  final paymentFormKey = GlobalKey<FormState>();
  final checkFormKey = GlobalKey<FormState>();
  final settlementFormKey = GlobalKey<FormState>();
  final collectionRequestFormKey = GlobalKey<FormState>();
  final transferFormKey = GlobalKey<FormState>();
  final personalWithdrawalFormKey = GlobalKey<FormState>();
  final withdrawalPersonFormKey = GlobalKey<FormState>();
  final withdrawalPersonEditFormKey = GlobalKey<FormState>();
  final reconciliationFormKey = GlobalKey<FormState>();
  final bankAccountFormKey = GlobalKey<FormState>();
  final receivingCompanyFormKey = GlobalKey<FormState>();
  final accountNameController = TextEditingController();
  final accountOpeningBalanceController = TextEditingController();
  final movementAmountController = TextEditingController();
  final movementNoteController = TextEditingController();
  final movementRelatedPartyController = TextEditingController();
  final expenseCategoryController = TextEditingController();
  final expenseDescriptionController = TextEditingController();
  final expenseAmountController = TextEditingController();
  final expenseBeneficiaryController = TextEditingController();
  final expenseNotesController = TextEditingController();
  final expenseCategoryNameController = TextEditingController();
  final customerNameController = TextEditingController();
  final installmentReferenceController = TextEditingController();
  final principalController = TextEditingController();
  final totalLimitController = TextEditingController();
  final installmentDueDateController = TextEditingController();
  final totalDueController = TextEditingController();
  final monthlyInstallmentController = TextEditingController();
  final totalInstallmentsController = TextEditingController();
  final scheduleDescriptionController = TextEditingController();
  final schedulePrincipalController = TextEditingController();
  final scheduleTotalDueController = TextEditingController();
  final scheduleMonthlyAmountController = TextEditingController();
  final scheduleTotalInstallmentsController = TextEditingController();
  final paymentAmountController = TextEditingController();
  final checkPayeeController = TextEditingController();
  final checkReferenceController = TextEditingController();
  final checkAmountController = TextEditingController();
  final checkDueDateController = TextEditingController();
  final checkBankNameController = TextEditingController();
  final checkNotesController = TextEditingController();
  final settlementProviderController = TextEditingController();
  final settlementPeriodController = TextEditingController();
  final settlementGrossController = TextEditingController();
  final settlementCommissionController = TextEditingController();
  final settlementTransactionIdsController = TextEditingController();
  final settlementRejectionReasonController = TextEditingController();
  final collectionAmountController = TextEditingController();
  final collectionConfirmationController = TextEditingController();
  final transferAmountController = TextEditingController();
  final transferFeeController = TextEditingController();
  final personNameController = TextEditingController();
  final withdrawalPersonNameController = TextEditingController();
  final personalWithdrawalAmountController = TextEditingController();
  final personalWithdrawalReasonController = TextEditingController();
  final reconciliationExpectedController = TextEditingController();
  final reconciliationActualController = TextEditingController();
  final reconciliationReasonController = TextEditingController();
  final bankNameController = TextEditingController();
  final bankAccountNameController = TextEditingController();
  final bankLastFourController = TextEditingController();
  final bankOpeningBalanceController = TextEditingController();
  final receivingCompanyNameController = TextEditingController();
  String? selectedAccountId;
  String? selectedMovementAccountId;
  String selectedMovementAccountType = 'treasury';
  String? selectedInstallmentId;
  String? selectedInstallmentScheduleId;
  String? selectedSettlementId;
  String? selectedCollectionRequestId;
  String? selectedDestinationAccountId;
  String selectedTransferSourceType = 'treasury';
  String selectedTransferDestinationType = 'treasury';
  DateTime expenseDate = DateTime.now();
  DateTime personalWithdrawalDate = DateTime.now();
  String? selectedReceivingCompanyId;
  String? selectedBankAccountId;
  String? selectedCheckBankAccountId;
  String? selectedAssociationCompanyId;
  String? selectedAssociationBankAccountId;
  String? editingBankAccountId;
  String? editingReceivingCompanyId;
  String? editingExpenseCategoryId;
  String? editingWithdrawalPersonId;
  bool bankAccountActive = true;
  bool receivingCompanyActive = true;
  bool expenseCategoryActive = true;
  bool withdrawalPersonActive = true;
  String? selectedSettlementBrandId;
  String movementType = 'inflow';
  String collectionType = 'instant';
  final selectedSettlementPurchaseIds = <String>{};

  void selectTransferSource(String? value) {
    if (value == null) return;
    final parts = value.split(':');
    selectedTransferSourceType = parts.first;
    selectedAccountId = parts.skip(1).join(':');
    emit(state.copyWith());
  }

  void selectTransferDestination(String? value) {
    if (value == null) return;
    final parts = value.split(':');
    selectedTransferDestinationType = parts.first;
    selectedDestinationAccountId = parts.skip(1).join(':');
    emit(state.copyWith());
  }

  void setExpenseDate(DateTime value) {
    expenseDate = DateTime(value.year, value.month, value.day);
    emit(state.copyWith());
  }

  void setPersonalWithdrawalDate(DateTime value) {
    personalWithdrawalDate = DateTime(value.year, value.month, value.day);
    emit(state.copyWith());
  }

  void selectSettlementBrand(String? brandId) {
    selectedSettlementBrandId = brandId;
    selectedSettlementPurchaseIds.clear();
    settlementGrossController.clear();
    settlementCommissionController.clear();
    emit(state.copyWith());
  }

  void toggleSettlementPurchase(CreditPurchaseModel purchase) {
    if (selectedSettlementPurchaseIds.contains(purchase.id)) {
      selectedSettlementPurchaseIds.remove(purchase.id);
    } else {
      selectedSettlementPurchaseIds.add(purchase.id);
    }
    final selected = state.creditPurchases.where(
      (item) => selectedSettlementPurchaseIds.contains(item.id),
    );
    final gross = selected.fold<int>(0, (sum, item) => sum + item.amountMinor);
    final commission = selected.fold<int>(
      0,
      (sum, item) => sum + item.commissionMinor,
    );
    settlementGrossController.text = (gross / 100).toStringAsFixed(2);
    settlementCommissionController.text = (commission / 100).toStringAsFixed(2);
    emit(state.copyWith());
  }

  Future<void> load() async {
    if (isClosed) return;
    emit(state.copyWith(status: RequestStatus.loading));
    try {
      final results = await Future.wait<Object>([
        _repository.getTreasuryAccounts(),
        _repository.getTreasuryMovements(),
        _repository.getExpenses(),
        _repository.getExpenseCategories(),
        _repository.getInstallments(),
        _repository.getChecks(),
        _repository.getSettlements(),
        _repository.getBankAccounts(),
        _repository.getReceivingCompanies(),
        _repository.getCollectionRequests(),
        _repository.getTreasuryTransfers(),
        _repository.getPersonalWithdrawals(),
        _repository.getReconciliations(),
        _repository.getBrands(),
        _repository.getBankMovements(),
        _repository.getInstallmentSchedules(),
        _repository.getWithdrawalPeople(),
      ]);
      if (isClosed) return;
      final accounts = results[0] as List<TreasuryAccountModel>;
      selectedAccountId ??= accounts.firstOrNull?.id;
      selectedMovementAccountId ??= accounts.firstOrNull?.id;
      selectedDestinationAccountId ??= accounts.length > 1
          ? accounts[1].id
          : null;
      final settlements = results[6] as List<SettlementModel>;
      selectedSettlementId ??= settlements.firstOrNull?.id;
      final requests = results[9] as List<CollectionRequestModel>;
      selectedCollectionRequestId ??= requests.firstOrNull?.id;
      final brands = results[13] as List<BrandModel>;
      final bankMovements = results[14] as List<BankMovementModel>;
      final installmentSchedules =
          results[15] as List<InstallmentScheduleModel>;
      final withdrawalPeople = results[16] as List<WithdrawalPersonModel>;
      List<CreditPurchaseModel> creditPurchases = const [];
      try {
        creditPurchases = await _creditCardsRepository.getAllPurchases();
      } catch (_) {
        // Operations remain usable from their own cache/domain if credit
        // purchase reads are temporarily unavailable.
      }
      if (isClosed) return;
      selectedInstallmentScheduleId ??= installmentSchedules.firstOrNull?.id;
      selectedSettlementBrandId ??= brands.firstOrNull?.id;
      await _repository.refreshDueNotifications(
        installments: results[4] as List<InstallmentAccountModel>,
        checks: results[5] as List<IssuedCheckModel>,
      );
      if (isClosed) return;
      emit(
        OperationsState(
          status: RequestStatus.success,
          accounts: accounts,
          movements: results[1] as List<TreasuryMovementModel>,
          expenses: results[2] as List<ExpenseModel>,
          expenseCategories: results[3] as List<ExpenseCategoryModel>,
          installments: results[4] as List<InstallmentAccountModel>,
          checks: results[5] as List<IssuedCheckModel>,
          settlements: results[6] as List<SettlementModel>,
          bankAccounts: results[7] as List<BankAccountModel>,
          receivingCompanies: results[8] as List<ReceivingCompanyModel>,
          collectionRequests: results[9] as List<CollectionRequestModel>,
          transfers: results[10] as List<TreasuryTransferModel>,
          personalWithdrawals: results[11] as List<PersonalWithdrawalModel>,
          reconciliations: results[12] as List<TreasuryReconciliationModel>,
          brands: brands,
          bankMovements: bankMovements,
          installmentSchedules: installmentSchedules,
          creditPurchases: creditPurchases,
          withdrawalPeople: withdrawalPeople,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: RequestStatus.failure,
          message: _friendlyError(error),
        ),
      );
    }
  }

  Future<void> createTreasuryAccount() async {
    if (treasuryFormKey.currentState?.validate() != true) return;
    final opening = FinanceMoney.parseToMinor(
      accountOpeningBalanceController.text,
    );
    if (opening < 0) return _fail('أدخل رصيداً افتتاحياً صحيحاً.');
    await _action(
      () => _repository.createTreasuryAccount(
        accountNameController.text,
        openingBalanceMinor: opening,
      ),
      'تم إنشاء حساب الخزينة.',
    );
    accountNameController.clear();
    accountOpeningBalanceController.clear();
  }

  Future<void> createBankAccount() async {
    if (bankAccountFormKey.currentState?.validate() != true) return;
    final opening = FinanceMoney.parseToMinor(
      bankOpeningBalanceController.text,
    );
    if (opening < 0) return _fail('أدخل رصيداً افتتاحياً صحيحاً.');
    await _action(
      () => _repository.createBankAccount(
        bankName: bankNameController.text,
        accountName: bankAccountNameController.text,
        lastFour: bankLastFourController.text,
        openingBalanceMinor: opening,
      ),
      'تم إنشاء الحساب البنكي.',
    );
    bankNameController.clear();
    bankAccountNameController.clear();
    bankLastFourController.clear();
    bankOpeningBalanceController.clear();
  }

  Future<void> createReceivingCompany() async {
    if (receivingCompanyFormKey.currentState?.validate() != true ||
        selectedBankAccountId == null) {
      return;
    }
    await _action(
      () => _repository.createReceivingCompany(
        name: receivingCompanyNameController.text,
        bankAccountId: selectedBankAccountId!,
      ),
      'تم إنشاء شركة التحصيل.',
    );
    receivingCompanyNameController.clear();
  }

  Future<void> updateBankAccount(BankAccountModel account) async {
    await _action(
      () => _repository.updateBankAccount(account),
      'تم تحديث الحساب البنكي.',
    );
  }

  Future<void> updateReceivingCompany(ReceivingCompanyModel company) async {
    await _action(
      () => _repository.updateReceivingCompany(company),
      'تم تحديث شركة التحصيل.',
    );
  }

  void prepareBankAccountEdit(BankAccountModel account) {
    editingBankAccountId = account.id;
    bankNameController.text = account.bankName;
    bankAccountNameController.text = account.accountName;
    bankLastFourController.text = account.lastFour;
    bankAccountActive = account.active;
    emit(state.copyWith());
  }

  void setBankAccountActive(bool value) {
    bankAccountActive = value;
    emit(state.copyWith());
  }

  Future<void> saveBankAccountEdit() async {
    final account = state.bankAccounts
        .where((item) => item.id == editingBankAccountId)
        .firstOrNull;
    if (account == null ||
        bankNameController.text.trim().isEmpty ||
        bankAccountNameController.text.trim().isEmpty ||
        !RegExp(r'^\d{4}$').hasMatch(bankLastFourController.text.trim())) {
      return _fail('تحقق من بيانات الحساب البنكي وآخر أربعة أرقام.');
    }
    await updateBankAccount(
      account.copyWith(
        bankName: bankNameController.text.trim(),
        accountName: bankAccountNameController.text.trim(),
        lastFour: bankLastFourController.text.trim(),
        active: bankAccountActive,
      ),
    );
  }

  void prepareReceivingCompanyEdit(ReceivingCompanyModel company) {
    editingReceivingCompanyId = company.id;
    receivingCompanyNameController.text = company.name;
    selectedBankAccountId = company.bankAccountId;
    receivingCompanyActive = company.active;
    emit(state.copyWith());
  }

  void setReceivingCompanyActive(bool value) {
    receivingCompanyActive = value;
    emit(state.copyWith());
  }

  Future<void> saveReceivingCompanyEdit() async {
    final company = state.receivingCompanies
        .where((item) => item.id == editingReceivingCompanyId)
        .firstOrNull;
    if (company == null ||
        receivingCompanyNameController.text.trim().isEmpty ||
        selectedBankAccountId == null) {
      return _fail('تحقق من اسم الشركة وحسابها البنكي.');
    }
    await updateReceivingCompany(
      company.copyWith(
        name: receivingCompanyNameController.text.trim(),
        bankAccountId: selectedBankAccountId,
        active: receivingCompanyActive,
      ),
    );
  }

  void prepareExpenseCategoryEdit(ExpenseCategoryModel category) {
    editingExpenseCategoryId = category.id;
    expenseCategoryNameController.text = category.name;
    expenseCategoryActive = category.active;
    emit(state.copyWith());
  }

  void setExpenseCategoryActive(bool value) {
    expenseCategoryActive = value;
    emit(state.copyWith());
  }

  Future<void> saveExpenseCategoryEdit() async {
    final category = state.expenseCategories
        .where((item) => item.id == editingExpenseCategoryId)
        .firstOrNull;
    if (category == null || expenseCategoryNameController.text.trim().isEmpty) {
      return _fail('أدخل اسم تصنيف المصروف.');
    }
    await updateExpenseCategory(
      category.copyWith(
        name: expenseCategoryNameController.text.trim(),
        active: expenseCategoryActive,
      ),
    );
  }

  Future<void> addBankAccountToReceivingCompany() async {
    if (selectedAssociationCompanyId == null ||
        selectedAssociationBankAccountId == null) {
      return _fail('اختر الشركة والحساب البنكي.');
    }
    await _action(
      () => _repository.addBankAccountToReceivingCompany(
        companyId: selectedAssociationCompanyId!,
        bankAccountId: selectedAssociationBankAccountId!,
      ),
      'تم ربط الحساب البنكي بشركة التحصيل.',
    );
  }

  Future<void> recordMovement() async {
    if (movementFormKey.currentState?.validate() != true ||
        selectedMovementAccountId == null) {
      return;
    }
    final amount = FinanceMoney.parseToMinor(movementAmountController.text);
    if (amount <= 0) return _fail('أدخل مبلغاً صحيحاً.');
    await _action(
      selectedMovementAccountType == 'bank'
          ? () => _repository.recordBankMovement(
              accountId: selectedMovementAccountId!,
              type: movementType == 'inflow' ? 'deposit' : 'withdrawal',
              amountMinor: amount,
              note: movementNoteController.text,
              relatedParty: movementRelatedPartyController.text,
            )
          : () => _repository.recordTreasuryMovement(
              accountId: selectedMovementAccountId!,
              type: movementType,
              amountMinor: amount,
              note: movementNoteController.text,
              relatedParty: movementRelatedPartyController.text,
            ),
      selectedMovementAccountType == 'bank'
          ? 'تم تسجيل حركة الحساب البنكي.'
          : 'تم تسجيل حركة الخزينة.',
    );
    movementAmountController.clear();
    movementNoteController.clear();
    movementRelatedPartyController.clear();
  }

  Future<void> createExpense() async {
    if (expenseFormKey.currentState?.validate() != true ||
        selectedAccountId == null) {
      return;
    }
    final amount = FinanceMoney.parseToMinor(expenseAmountController.text);
    if (amount <= 0) return _fail('أدخل مبلغ مصروف صحيح.');
    await _action(
      () => _repository.createExpense(
        accountId: selectedAccountId!,
        category: expenseCategoryController.text,
        description: expenseDescriptionController.text,
        amountMinor: amount,
        beneficiary: expenseBeneficiaryController.text,
        notes: expenseNotesController.text,
        expenseDateMillis: expenseDate.millisecondsSinceEpoch,
      ),
      'تم تسجيل المصروف.',
    );
    expenseAmountController.clear();
    expenseDescriptionController.clear();
    expenseBeneficiaryController.clear();
    expenseNotesController.clear();
  }

  Future<void> createExpenseCategory() async {
    if (expenseCategoryFormKey.currentState?.validate() != true) return;
    await _action(
      () =>
          _repository.createExpenseCategory(expenseCategoryNameController.text),
      'تم إنشاء تصنيف المصروف.',
    );
    expenseCategoryNameController.clear();
  }

  Future<void> updateExpenseCategory(ExpenseCategoryModel category) async {
    await _action(
      () => _repository.updateExpenseCategory(category),
      'تم تحديث تصنيف المصروف.',
    );
  }

  Future<void> approveExpense(String expenseId) async {
    await _action(
      () => _repository.approveExpense(expenseId),
      'تم اعتماد المصروف وتحديث الخزينة.',
    );
  }

  Future<void> approveTreasuryMovement(String movementId) async {
    await _action(
      () => _repository.approveTreasuryMovement(movementId),
      'تم اعتماد حركة الخزينة وتحديث الرصيد.',
    );
  }

  Future<void> approveBankMovement(String movementId) async {
    await _action(
      () => _repository.approveBankMovement(movementId),
      'تم اعتماد حركة الحساب البنكي وتحديث الرصيد.',
    );
  }

  Future<void> rejectPendingOperation({
    required String entityType,
    required String entityId,
    required String reason,
  }) async {
    await _action(
      () => _repository.rejectPendingOperation(
        entityType: entityType,
        entityId: entityId,
        reason: reason,
      ),
      'تم رفض المعاملة وتسجيل السبب.',
    );
  }

  void selectMovementAccount(String? value) {
    if (value == null) return;
    final parts = value.split(':');
    selectedMovementAccountType = parts.first;
    selectedMovementAccountId = parts.skip(1).join(':');
    emit(state.copyWith());
  }

  void selectCollectionType(String? value) {
    if (value == null) return;
    collectionType = value;
    emit(state.copyWith());
  }

  Future<void> createInstallment() async {
    if (installmentFormKey.currentState?.validate() != true) return;
    final principal = FinanceMoney.parseToMinor(principalController.text);
    final totalLimit = FinanceMoney.parseToMinor(totalLimitController.text);
    final total = FinanceMoney.parseToMinor(totalDueController.text);
    final monthly = FinanceMoney.parseToMinor(
      monthlyInstallmentController.text,
    );
    final totalInstallments =
        int.tryParse(totalInstallmentsController.text.trim()) ?? 0;
    final dueDate = DateTime.tryParse(installmentDueDateController.text.trim());
    if (principal <= 0 ||
        totalLimit < principal ||
        total < principal ||
        monthly <= 0 ||
        totalInstallments <= 0) {
      return _fail('تحقق من أصل التمويل وإجمالي الاستحقاق.');
    }
    if (dueDate == null &&
        installmentDueDateController.text.trim().isNotEmpty) {
      return _fail('أدخل تاريخ الاستحقاق بصيغة YYYY-MM-DD.');
    }
    await _action(
      () => _repository.createInstallment(
        customerName: customerNameController.text,
        reference: installmentReferenceController.text,
        principalMinor: principal,
        totalDueMinor: total,
        totalLimitMinor: totalLimit,
        availableMinor: totalLimit - principal,
        nextDueMillis: (dueDate ?? DateTime.now().add(const Duration(days: 30)))
            .millisecondsSinceEpoch,
        monthlyInstallmentMinor: monthly,
        totalInstallments: totalInstallments,
      ),
      'تم إنشاء حساب التقسيط.',
    );
    customerNameController.clear();
    installmentReferenceController.clear();
    principalController.clear();
    totalLimitController.clear();
    installmentDueDateController.clear();
    totalDueController.clear();
    monthlyInstallmentController.clear();
    totalInstallmentsController.clear();
  }

  void prepareInstallmentEdit(InstallmentAccountModel account) {
    selectedInstallmentId = account.id;
    customerNameController.text = account.customerName;
    installmentReferenceController.text = account.reference;
    emit(state.copyWith());
  }

  Future<void> updateInstallmentAccount({String? status}) async {
    if (selectedInstallmentId == null ||
        customerNameController.text.trim().isEmpty ||
        installmentReferenceController.text.trim().isEmpty) {
      return _fail('أدخل اسم الشخص واسم تطبيق التقسيط.');
    }
    await _action(
      () => _repository.updateInstallmentAccount(
        accountId: selectedInstallmentId!,
        customerName: customerNameController.text.trim(),
        reference: installmentReferenceController.text.trim(),
        status: status,
      ),
      status == 'archived'
          ? 'تمت أرشفة حساب التقسيط.'
          : 'تم تحديث حساب التقسيط.',
    );
  }

  Future<void> recordInstallmentPayment() async {
    if (paymentFormKey.currentState?.validate() != true ||
        selectedInstallmentId == null ||
        selectedAccountId == null) {
      return;
    }
    final amount = FinanceMoney.parseToMinor(paymentAmountController.text);
    if (amount <= 0) return _fail('أدخل دفعة صحيحة.');
    final scheduleId =
        state.installmentSchedules.any(
          (item) =>
              item.id == selectedInstallmentScheduleId &&
              item.accountId == selectedInstallmentId,
        )
        ? selectedInstallmentScheduleId
        : null;
    await _action(
      () => _repository.recordInstallmentPayment(
        id: selectedInstallmentId!,
        accountId: selectedAccountId!,
        amountMinor: amount,
        nextDueMillis: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
        scheduleId: scheduleId,
      ),
      'تم تسجيل دفعة التقسيط.',
    );
    paymentAmountController.clear();
  }

  Future<void> createInstallmentSchedule() async {
    if (installmentScheduleFormKey.currentState?.validate() != true ||
        selectedInstallmentId == null) {
      return;
    }
    final principal = FinanceMoney.parseToMinor(
      schedulePrincipalController.text,
    );
    final totalDue = FinanceMoney.parseToMinor(scheduleTotalDueController.text);
    final monthly = FinanceMoney.parseToMinor(
      scheduleMonthlyAmountController.text,
    );
    final totalInstallments =
        int.tryParse(scheduleTotalInstallmentsController.text.trim()) ?? 0;
    if (principal <= 0 ||
        totalDue < principal ||
        monthly <= 0 ||
        totalInstallments <= 0) {
      return _fail('تحقق من بيانات جدول التقسيط.');
    }
    await _action(
      () => _repository.createInstallmentSchedule(
        accountId: selectedInstallmentId!,
        description: scheduleDescriptionController.text,
        principalMinor: principal,
        totalDueMinor: totalDue,
        monthlyAmountMinor: monthly,
        totalInstallments: totalInstallments,
        nextDueMillis: DateTime.now()
            .add(const Duration(days: 30))
            .millisecondsSinceEpoch,
      ),
      'تمت إضافة جدول تقسيط جديد.',
    );
    scheduleDescriptionController.clear();
    schedulePrincipalController.clear();
    scheduleTotalDueController.clear();
    scheduleMonthlyAmountController.clear();
    scheduleTotalInstallmentsController.clear();
  }

  Future<void> createCheck() async {
    if (checkFormKey.currentState?.validate() != true ||
        selectedCheckBankAccountId == null) {
      return;
    }
    final amount = FinanceMoney.parseToMinor(checkAmountController.text);
    if (amount <= 0) return _fail('أدخل قيمة الشيك.');
    final dueDate = DateTime.tryParse(checkDueDateController.text.trim());
    if (dueDate == null) {
      return _fail('أدخل تاريخ استحقاق صحيحاً بصيغة YYYY-MM-DD.');
    }
    await _action(
      () => _repository.createCheck(
        payee: checkPayeeController.text,
        reference: checkReferenceController.text,
        amountMinor: amount,
        dueDateMillis: dueDate.millisecondsSinceEpoch,
        accountId: selectedCheckBankAccountId!,
        bankName: checkBankNameController.text,
        notes: checkNotesController.text,
      ),
      'تم تسجيل الشيك.',
    );
    checkPayeeController.clear();
    checkReferenceController.clear();
    checkAmountController.clear();
    checkDueDateController.clear();
    checkBankNameController.clear();
    checkNotesController.clear();
  }

  Future<void> createSettlement() async {
    if (settlementFormKey.currentState?.validate() != true) return;
    final gross = FinanceMoney.parseToMinor(settlementGrossController.text);
    final commission = FinanceMoney.parseToMinor(
      settlementCommissionController.text,
    );
    if (gross <= 0 || commission < 0 || commission > gross) {
      return _fail('تحقق من إجمالي التسوية والعمولة.');
    }
    final brand = state.brands
        .where((item) => item.id == selectedSettlementBrandId)
        .firstOrNull;
    if (brand == null) return _fail('اختر العلامة التجارية للتسوية.');
    final typedTransactionIds = settlementTransactionIdsController.text
        .split(RegExp(r'[,\n]'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList();
    final includedTransactionIds = selectedSettlementPurchaseIds.isEmpty
        ? typedTransactionIds
        : selectedSettlementPurchaseIds.toList();
    await _action(
      () => _repository.createSettlement(
        providerName: brand.providerName,
        periodLabel: settlementPeriodController.text,
        grossMinor: gross,
        commissionMinor: commission,
        brandId: brand.id,
        brandName: brand.name,
        receivingCompanyId: brand.receivingCompanyId,
        receivingCompanyName: brand.receivingCompanyName,
        destinationBankAccountId: brand.settlementBankAccountId,
        destinationBankAccountName: brand.settlementBankAccountName,
        posMachineId: brand.posMachineId,
        posMachineName: brand.posMachineName,
        includedTransactionIds: includedTransactionIds,
      ),
      'تم إنشاء التسوية.',
    );
    settlementTransactionIdsController.clear();
    selectedSettlementPurchaseIds.clear();
  }

  Future<void> createCollectionRequest() async {
    if (selectedSettlementId == null) return _fail('اختر التسوية أولاً.');
    if (collectionAmountController.text.trim().isEmpty) {
      return _fail('أدخل قيمة تحصيل صحيحة.');
    }
    final amount = FinanceMoney.parseToMinor(collectionAmountController.text);
    if (amount <= 0) return _fail('أدخل قيمة تحصيل صحيحة.');
    await _action(
      () => _repository.createCollectionRequest(
        settlementId: selectedSettlementId!,
        amountMinor: amount,
        collectionType: collectionType,
      ),
      'تم إنشاء طلب التحصيل.',
    );
    collectionAmountController.clear();
  }

  Future<void> approveSettlement(String settlementId) async {
    await _action(
      () => _repository.approveSettlement(settlementId),
      'تم اعتماد التسوية.',
    );
  }

  Future<void> rejectSettlement(String settlementId) async {
    final reason = settlementRejectionReasonController.text.trim();
    if (reason.isEmpty) return _fail('أدخل سبب رفض التسوية أولاً.');
    await _action(
      () => _repository.rejectSettlement(
        settlementId: settlementId,
        reason: reason,
      ),
      'تم رفض التسوية وتسجيل السبب.',
    );
    settlementRejectionReasonController.clear();
  }

  Future<void> confirmCollectionRequest() async {
    final reference = collectionConfirmationController.text.trim();
    if (selectedCollectionRequestId == null || reference.isEmpty) {
      return _fail('أدخل مرجع التحويل البنكي.');
    }
    await _action(
      () => _repository.confirmCollectionRequest(
        requestId: selectedCollectionRequestId!,
        confirmationReference: reference,
      ),
      'تم تأكيد التحصيل.',
    );
    collectionConfirmationController.clear();
  }

  Future<void> createTreasuryTransfer() async {
    if (transferFormKey.currentState?.validate() != true ||
        selectedAccountId == null ||
        selectedDestinationAccountId == null) {
      return;
    }
    final amount = FinanceMoney.parseToMinor(transferAmountController.text);
    final fee = FinanceMoney.parseToMinor(transferFeeController.text);
    if (amount <= 0 || fee < 0) return _fail('تحقق من قيمة التحويل والرسوم.');
    await _action(
      () => _repository.createTreasuryTransfer(
        sourceAccountId: selectedAccountId!,
        destinationAccountId: selectedDestinationAccountId!,
        amountMinor: amount,
        feeMinor: fee,
        sourceAccountType: selectedTransferSourceType,
        destinationAccountType: selectedTransferDestinationType,
      ),
      'تم تسجيل التحويل الداخلي.',
    );
    transferAmountController.clear();
    transferFeeController.clear();
  }

  Future<void> approveTreasuryTransfer(String transferId) async {
    await _action(
      () => _repository.approveTreasuryTransfer(transferId),
      'تم اعتماد التحويل الداخلي.',
    );
  }

  Future<void> createPersonalWithdrawal() async {
    if (personalWithdrawalFormKey.currentState?.validate() != true ||
        selectedAccountId == null) {
      return;
    }
    final amount = FinanceMoney.parseToMinor(
      personalWithdrawalAmountController.text,
    );
    if (amount <= 0) return _fail('أدخل قيمة سحب شخصية صحيحة.');
    await _action(
      () => _repository.createPersonalWithdrawal(
        personName: personNameController.text,
        accountId: selectedAccountId!,
        amountMinor: amount,
        reason: personalWithdrawalReasonController.text,
        withdrawalDateMillis: personalWithdrawalDate.millisecondsSinceEpoch,
      ),
      'تم تسجيل السحب الشخصي.',
    );
    personNameController.clear();
    personalWithdrawalAmountController.clear();
    personalWithdrawalReasonController.clear();
  }

  Future<void> createWithdrawalPerson() async {
    if (withdrawalPersonFormKey.currentState?.validate() != true) return;
    await _action(
      () => _repository.createWithdrawalPerson(
        withdrawalPersonNameController.text,
      ),
      'تم حفظ اسم المستفيد.',
    );
    withdrawalPersonNameController.clear();
  }

  Future<void> updateWithdrawalPerson(WithdrawalPersonModel person) async {
    await _action(
      () => _repository.updateWithdrawalPerson(person),
      'تم تحديث اسم المستفيد.',
    );
  }

  void prepareWithdrawalPersonEdit(WithdrawalPersonModel person) {
    editingWithdrawalPersonId = person.id;
    withdrawalPersonNameController.text = person.name;
    withdrawalPersonActive = person.active;
    emit(state.copyWith());
  }

  void setWithdrawalPersonActive(bool value) {
    withdrawalPersonActive = value;
    emit(state.copyWith());
  }

  Future<void> saveWithdrawalPersonEdit() async {
    final person = state.withdrawalPeople
        .where((item) => item.id == editingWithdrawalPersonId)
        .firstOrNull;
    if (person == null || withdrawalPersonNameController.text.trim().isEmpty) {
      return _fail('أدخل اسم المستفيد.');
    }
    await updateWithdrawalPerson(
      person.copyWith(
        name: withdrawalPersonNameController.text.trim(),
        active: withdrawalPersonActive,
      ),
    );
  }

  Future<void> approvePersonalWithdrawal(String withdrawalId) async {
    await _action(
      () => _repository.approvePersonalWithdrawal(withdrawalId),
      'تم اعتماد السحب الشخصي وتحديث الخزينة.',
    );
  }

  Future<void> updateCheckStatus(String checkId, String status) async {
    await _action(
      () => _repository.updateCheckStatus(checkId: checkId, status: status),
      status == 'deducted'
          ? 'تم تأكيد خصم الشيك من الحساب البنكي.'
          : 'تم تحديث حالة الشيك.',
    );
  }

  Future<void> createReconciliation() async {
    if (reconciliationFormKey.currentState?.validate() != true ||
        selectedAccountId == null) {
      return;
    }
    final expected = FinanceMoney.parseToMinor(
      reconciliationExpectedController.text,
    );
    final actual = FinanceMoney.parseToMinor(
      reconciliationActualController.text,
    );
    await _action(
      () => _repository.createReconciliation(
        accountId: selectedAccountId!,
        expectedMinor: expected,
        actualMinor: actual,
        reason: reconciliationReasonController.text,
      ),
      'تم حفظ المطابقة والفارق.',
    );
    reconciliationExpectedController.clear();
    reconciliationActualController.clear();
    reconciliationReasonController.clear();
  }

  Future<void> _action(Future<void> Function() action, String message) async {
    if (isClosed) return;
    emit(state.copyWith(actionStatus: RequestStatus.loading));
    try {
      await action();
      if (isClosed) return;
      await sl<FirebaseCacheService>().clearCurrentScope();
      await load();
      if (isClosed) return;
      emit(
        state.copyWith(
          actionStatus: RequestStatus.success,
          actionMessage: message,
        ),
      );
    } catch (error) {
      if (isClosed) return;
      emit(
        state.copyWith(
          actionStatus: RequestStatus.failure,
          actionMessage: _friendlyError(error),
        ),
      );
    }
  }

  void _fail(String message) => emit(
    state.copyWith(actionStatus: RequestStatus.failure, actionMessage: message),
  );
  String _friendlyError(Object error) => error is FirebaseException
      ? error.message ?? 'حدث خطأ في الاتصال.'
      : error.toString().replaceFirst('Exception: ', '');
  @override
  Future<void> close() {
    for (final c in [
      accountNameController,
      accountOpeningBalanceController,
      movementAmountController,
      movementNoteController,
      movementRelatedPartyController,
      expenseCategoryController,
      expenseDescriptionController,
      expenseAmountController,
      expenseBeneficiaryController,
      expenseNotesController,
      expenseCategoryNameController,
      customerNameController,
      installmentReferenceController,
      principalController,
      totalLimitController,
      installmentDueDateController,
      totalDueController,
      monthlyInstallmentController,
      totalInstallmentsController,
      scheduleDescriptionController,
      schedulePrincipalController,
      scheduleTotalDueController,
      scheduleMonthlyAmountController,
      scheduleTotalInstallmentsController,
      paymentAmountController,
      checkPayeeController,
      checkReferenceController,
      checkAmountController,
      checkDueDateController,
      checkBankNameController,
      checkNotesController,
      settlementProviderController,
      settlementPeriodController,
      settlementGrossController,
      settlementCommissionController,
      settlementRejectionReasonController,
      settlementTransactionIdsController,
      collectionAmountController,
      collectionConfirmationController,
      transferAmountController,
      transferFeeController,
      personNameController,
      withdrawalPersonNameController,
      personalWithdrawalAmountController,
      personalWithdrawalReasonController,
      reconciliationExpectedController,
      reconciliationActualController,
      reconciliationReasonController,
      bankNameController,
      bankAccountNameController,
      bankLastFourController,
      bankOpeningBalanceController,
      receivingCompanyNameController,
    ]) {
      c.dispose();
    }
    return super.close();
  }
}
