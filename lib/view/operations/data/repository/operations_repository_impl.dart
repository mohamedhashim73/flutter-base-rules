import 'package:base/core/services/services.dart';
import 'package:base/core/utils/finance_money.dart';
import 'package:base/model/domain/bank_account_model.dart';
import 'package:base/model/domain/collection_request_model.dart';
import 'package:base/model/domain/expense_model.dart';
import 'package:base/model/domain/expense_category_model.dart';
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
import '../datasource/operations_data_source.dart';
import 'operations_repository.dart';

class OperationsRepositoryImpl implements OperationsRepository {
  OperationsRepositoryImpl(
    this._dataSource,
    this._authService,
    this._auditService,
    this._settingsService,
    this._notificationService,
  );
  final OperationsDataSource _dataSource;
  final FirebaseAuthService _authService;
  final AuditService _auditService;
  final FinanceSettingsService _settingsService;
  final InAppNotificationService _notificationService;
  int _now() => DateTime.now().millisecondsSinceEpoch;
  String _id(String suffix) => '${_dataSource.newDocumentId()}_$suffix';

  @override
  Future<List<TreasuryAccountModel>> getTreasuryAccounts() =>
      _dataSource.getTreasuryAccounts();
  @override
  Future<List<TreasuryMovementModel>> getTreasuryMovements() =>
      _dataSource.getTreasuryMovements();
  @override
  Future<List<TreasuryTransferModel>> getTreasuryTransfers() =>
      _dataSource.getTreasuryTransfers();
  @override
  Future<List<PersonalWithdrawalModel>> getPersonalWithdrawals() =>
      _dataSource.getPersonalWithdrawals();

  @override
  Future<List<WithdrawalPersonModel>> getWithdrawalPeople() =>
      _dataSource.getWithdrawalPeople();
  @override
  Future<List<TreasuryReconciliationModel>> getReconciliations() =>
      _dataSource.getReconciliations();
  @override
  Future<List<ExpenseModel>> getExpenses() => _dataSource.getExpenses();
  @override
  Future<List<ExpenseCategoryModel>> getExpenseCategories() =>
      _dataSource.getExpenseCategories();
  @override
  Future<List<InstallmentAccountModel>> getInstallments() =>
      _dataSource.getInstallments();
  @override
  Future<List<IssuedCheckModel>> getChecks() => _dataSource.getChecks();
  @override
  Future<List<SettlementModel>> getSettlements() =>
      _dataSource.getSettlements();
  @override
  Future<List<BankAccountModel>> getBankAccounts() =>
      _dataSource.getBankAccounts();
  @override
  Future<List<ReceivingCompanyModel>> getReceivingCompanies() =>
      _dataSource.getReceivingCompanies();
  @override
  Future<List<CollectionRequestModel>> getCollectionRequests() =>
      _dataSource.getCollectionRequests();
  @override
  Future<List<BrandModel>> getBrands() => _dataSource.getBrands();
  @override
  Future<List<BankMovementModel>> getBankMovements() =>
      _dataSource.getBankMovements();
  @override
  Future<List<InstallmentScheduleModel>> getInstallmentSchedules() =>
      _dataSource.getInstallmentSchedules();

  @override
  Future<void> refreshDueNotifications({
    required List<InstallmentAccountModel> installments,
    required List<IssuedCheckModel> checks,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final settings = await _settingsService.getNotificationSettings();
    final installmentHorizon =
        now +
        Duration(
          days:
              settings['installmentReminderDays'] ??
              FinanceSettingsService.defaultReminderDays,
        ).inMilliseconds;
    final checkHorizon =
        now +
        Duration(
          days:
              settings['checkReminderDays'] ??
              FinanceSettingsService.defaultReminderDays,
        ).inMilliseconds;
    for (final installment in installments.where(
      (item) =>
          item.status == 'active' && item.nextDueMillis <= installmentHorizon,
    )) {
      final overdue = installment.nextDueMillis < now;
      await _safeNotification(
        () => _notificationService.create(
          title: overdue ? 'قسط متأخر' : 'قسط مستحق قريباً',
          body: '${installment.customerName} · ${installment.reference}',
          category: overdue ? 'installment_overdue' : 'installment_due',
          targetType: 'installment_account',
          targetId: installment.id,
        ),
      );
    }
    for (final check in checks.where(
      (item) => item.status == 'issued' && item.dueDateMillis <= checkHorizon,
    )) {
      final overdue = check.dueDateMillis < now;
      await _safeNotification(
        () => _notificationService.create(
          title: overdue ? 'شيك متأخر' : 'شيك مستحق قريباً',
          body: '${check.payee} · ${check.reference}',
          category: overdue ? 'check_overdue' : 'check_due',
          targetType: 'issued_check',
          targetId: check.id,
        ),
      );
    }
  }

  Future<void> _safeNotification(Future<void> Function() create) async {
    try {
      await create();
    } catch (_) {
      // Notifications are helpful but must not make cached financial reads
      // fail when the browser is temporarily offline.
    }
  }

  @override
  Future<void> createTreasuryAccount(
    String name, {
    int openingBalanceMinor = 0,
  }) async {
    if (openingBalanceMinor > 0 && !await _authService.hasRole('manager')) {
      throw StateError('الرصيد الافتتاحي للخزينة يحتاج اعتماد المدير.');
    }
    final now = _now();
    final id = _id('treasury');
    await _dataSource.saveTreasuryAccount(
      TreasuryAccountModel(
        id: id,
        name: name.trim(),
        balanceMinor: openingBalanceMinor,
        active: true,
        updatedAtMillis: now,
        openingBalanceMinor: openingBalanceMinor,
      ),
    );
    await _auditService.record(
      action: 'create',
      entityType: 'treasury_account',
      entityId: id,
    );
  }

  @override
  Future<void> createBankAccount({
    required String bankName,
    required String accountName,
    required String lastFour,
    required int openingBalanceMinor,
  }) async {
    final now = _now();
    final id = _id('bank');
    await _dataSource.saveBankAccount(
      BankAccountModel(
        id: id,
        bankName: bankName.trim(),
        accountName: accountName.trim(),
        lastFour: lastFour.trim(),
        active: true,
        updatedAtMillis: now,
        openingBalanceMinor: openingBalanceMinor,
      ),
    );
    await _auditService.record(
      action: 'create',
      entityType: 'bank_account',
      entityId: id,
    );
  }

  @override
  Future<void> createReceivingCompany({
    required String name,
    required String bankAccountId,
  }) async {
    final now = _now();
    final id = _id('receiving_company');
    await _dataSource.saveReceivingCompany(
      ReceivingCompanyModel(
        id: id,
        name: name.trim(),
        bankAccountId: bankAccountId,
        active: true,
        updatedAtMillis: now,
      ),
    );
    await _auditService.record(
      action: 'create',
      entityType: 'receiving_company',
      entityId: id,
    );
  }

  @override
  Future<void> addBankAccountToReceivingCompany({
    required String companyId,
    required String bankAccountId,
  }) async {
    await _dataSource.addBankAccountToReceivingCompany(
      companyId: companyId,
      bankAccountId: bankAccountId,
    );
    await _auditService.record(
      action: 'associate',
      entityType: 'receiving_company_bank_account',
      entityId: companyId,
      metadata: {'bankAccountId': bankAccountId},
    );
  }

  @override
  Future<void> updateBankAccount(BankAccountModel account) async {
    await _dataSource.saveBankAccount(
      account.copyWith(updatedAtMillis: _now()),
    );
    await _auditService.record(
      action: 'update',
      entityType: 'bank_account',
      entityId: account.id,
    );
  }

  @override
  Future<void> updateReceivingCompany(ReceivingCompanyModel company) async {
    await _dataSource.saveReceivingCompany(
      company.copyWith(updatedAtMillis: _now()),
    );
    await _auditService.record(
      action: 'update',
      entityType: 'receiving_company',
      entityId: company.id,
    );
  }

  @override
  Future<void> recordTreasuryMovement({
    required String accountId,
    required String type,
    required int amountMinor,
    required String note,
    String relatedParty = '',
    int? transactionDateMillis,
  }) async {
    final now = _now();
    final id = _id('movement');
    final manager = await _authService.hasRole('manager');
    final threshold = await _settingsService.getApprovalThresholdMinor();
    await _dataSource.addTreasuryMovement(
      TreasuryMovementModel(
        id: id,
        accountId: accountId,
        type: type == 'outflow' ? 'outflow' : 'inflow',
        amountMinor: amountMinor,
        note: note.trim(),
        relatedParty: relatedParty.trim(),
        transactionDateMillis: transactionDateMillis ?? now,
        createdBy: _authService.currentUser?.uid ?? '',
        createdAtMillis: now,
        approvalStatus: manager || amountMinor <= threshold
            ? 'approved'
            : 'pending',
        approvedBy: manager || amountMinor <= threshold
            ? _authService.currentUser?.uid
            : null,
        approvedAtMillis: manager || amountMinor <= threshold ? now : null,
      ),
    );
    if (!manager && amountMinor > threshold) {
      await _notificationService.create(
        title: 'طلب اعتماد حركة خزينة',
        body: 'توجد حركة خزينة تتجاوز حد الاعتماد وتحتاج إلى مراجعة المدير.',
        category: 'approval',
        targetType: 'treasury_movement',
        targetId: id,
      );
    }
  }

  @override
  Future<void> approveTreasuryMovement(String movementId) async {
    if (!await _authService.hasRole('manager')) {
      throw StateError('اعتماد حركات الخزينة متاح للمدير الرئيسي فقط.');
    }
    await _dataSource.approveTreasuryMovement(movementId);
  }

  @override
  Future<void> recordBankMovement({
    required String accountId,
    required String type,
    required int amountMinor,
    required String note,
    String relatedParty = '',
  }) async {
    final now = _now();
    final manager = await _authService.hasRole('manager');
    final threshold = await _settingsService.getApprovalThresholdMinor();
    final approvalStatus = manager || amountMinor <= threshold
        ? 'approved'
        : 'pending';
    final id = _id('bank_movement');
    await _dataSource.addBankMovement(
      BankMovementModel(
        id: id,
        accountId: accountId,
        type: type == 'withdrawal' ? 'withdrawal' : 'deposit',
        amountMinor: amountMinor,
        referenceType: 'manual',
        referenceId: id,
        note: note.trim(),
        relatedParty: relatedParty.trim(),
        createdBy: _authService.currentUser?.uid ?? '',
        createdAtMillis: now,
        approvalStatus: approvalStatus,
        approvedBy: approvalStatus == 'approved'
            ? _authService.currentUser?.uid
            : null,
        approvedAtMillis: approvalStatus == 'approved' ? now : null,
        updatedAtMillis: now,
      ),
    );
  }

  @override
  Future<void> approveBankMovement(String movementId) async {
    if (!await _authService.hasRole('manager')) {
      throw StateError('اعتماد حركة البنك متاح للمدير الرئيسي فقط.');
    }
    await _dataSource.approveBankMovement(movementId);
  }

  @override
  Future<void> rejectPendingOperation({
    required String entityType,
    required String entityId,
    required String reason,
  }) async {
    if (!await _authService.hasRole('manager') || reason.trim().isEmpty) {
      throw StateError('رفض المعاملة يحتاج إلى المدير وسبب واضح.');
    }
    await _dataSource.rejectPendingOperation(
      entityType: entityType,
      entityId: entityId,
      reason: reason.trim(),
    );
  }

  @override
  Future<void> createTreasuryTransfer({
    required String sourceAccountId,
    required String destinationAccountId,
    required int amountMinor,
    required int feeMinor,
    String sourceAccountType = 'treasury',
    String destinationAccountType = 'treasury',
  }) async {
    if (sourceAccountId == destinationAccountId) {
      throw StateError('يجب اختيار حسابين مختلفين.');
    }
    final id = _id('transfer');
    final isManager = await _authService.hasRole('manager');
    final threshold = await _settingsService.getApprovalThresholdMinor();
    final status = isManager || amountMinor <= threshold
        ? 'approved'
        : 'pending';
    final now = _now();
    await _dataSource.addTreasuryTransfer(
      TreasuryTransferModel(
        id: id,
        sourceAccountId: sourceAccountId,
        destinationAccountId: destinationAccountId,
        amountMinor: amountMinor,
        feeMinor: feeMinor,
        status: status,
        createdBy: _authService.currentUser?.uid ?? '',
        createdAtMillis: now,
        sourceAccountType: sourceAccountType,
        destinationAccountType: destinationAccountType,
        approvedBy: status == 'approved' ? _authService.currentUser?.uid : null,
        approvedAtMillis: status == 'approved' ? now : null,
      ),
    );
    await _auditService.record(
      action: 'create',
      entityType: 'treasury_transfer',
      entityId: id,
    );
    if (status == 'pending') {
      await _notificationService.create(
        title: 'تحويل خزينة بانتظار الاعتماد',
        body: 'يوجد تحويل داخلي يتجاوز حد الاعتماد.',
        category: 'approval',
        targetType: 'treasury_transfer',
        targetId: id,
      );
    }
  }

  @override
  Future<void> approveTreasuryTransfer(String transferId) async {
    if (!await _authService.hasRole('manager')) {
      throw StateError('اعتماد التحويلات متاح للمدير الرئيسي فقط.');
    }
    await _dataSource.approveTreasuryTransfer(transferId);
    await _auditService.record(
      action: 'approve',
      entityType: 'treasury_transfer',
      entityId: transferId,
    );
  }

  @override
  Future<void> createPersonalWithdrawal({
    required String personName,
    required String accountId,
    required int amountMinor,
    required String reason,
    int? withdrawalDateMillis,
  }) async {
    final id = _id('personal_withdrawal');
    final isManager = await _authService.hasRole('manager');
    final threshold = await _settingsService.getApprovalThresholdMinor();
    final status = isManager || amountMinor <= threshold
        ? 'approved'
        : 'pending';
    final now = _now();
    await _dataSource.addPersonalWithdrawal(
      PersonalWithdrawalModel(
        id: id,
        personName: personName.trim(),
        accountId: accountId,
        amountMinor: amountMinor,
        reason: reason.trim(),
        withdrawalDateMillis: withdrawalDateMillis ?? now,
        createdBy: _authService.currentUser?.uid ?? '',
        createdAtMillis: now,
        status: status,
      ),
    );
    await _auditService.record(
      action: 'create',
      entityType: 'personal_withdrawal',
      entityId: id,
    );
    if (status == 'pending') {
      await _notificationService.create(
        title: 'سحب شخصي بانتظار الاعتماد',
        body: 'يوجد سحب شخصي يتجاوز حد الاعتماد.',
        category: 'approval',
        targetType: 'personal_withdrawal',
        targetId: id,
      );
    }
  }

  @override
  Future<void> createWithdrawalPerson(String name) async {
    final now = _now();
    final id = _id('withdrawal_person');
    await _dataSource.saveWithdrawalPerson(
      WithdrawalPersonModel(
        id: id,
        name: name.trim(),
        active: true,
        createdAtMillis: now,
        updatedAtMillis: now,
      ),
    );
    await _auditService.record(
      action: 'create',
      entityType: 'withdrawal_person',
      entityId: id,
    );
  }

  @override
  Future<void> updateWithdrawalPerson(WithdrawalPersonModel person) async {
    await _dataSource.saveWithdrawalPerson(
      person.copyWith(updatedAtMillis: _now()),
    );
    await _auditService.record(
      action: 'update',
      entityType: 'withdrawal_person',
      entityId: person.id,
    );
  }

  @override
  Future<void> approvePersonalWithdrawal(String withdrawalId) async {
    if (!await _authService.hasRole('manager')) {
      throw StateError('اعتماد السحب متاح للمدير الرئيسي فقط.');
    }
    await _dataSource.approvePersonalWithdrawal(withdrawalId);
  }

  @override
  Future<void> createReconciliation({
    required String accountId,
    required int expectedMinor,
    required int actualMinor,
    required String reason,
  }) async {
    final id = _id('reconciliation');
    await _dataSource.addReconciliation(
      TreasuryReconciliationModel(
        id: id,
        accountId: accountId,
        expectedMinor: expectedMinor,
        actualMinor: actualMinor,
        differenceMinor: actualMinor - expectedMinor,
        reason: reason.trim(),
        createdBy: _authService.currentUser?.uid ?? '',
        createdAtMillis: _now(),
      ),
    );
  }

  @override
  Future<void> createExpense({
    required String accountId,
    required String category,
    required String description,
    required int amountMinor,
    String beneficiary = '',
    String notes = '',
    int? expenseDateMillis,
  }) async {
    final now = _now();
    final id = _id('expense');
    final manager = await _authService.hasRole('manager');
    final threshold = await _settingsService.getApprovalThresholdMinor();
    final expenseStatus = manager || amountMinor <= threshold
        ? 'approved'
        : 'pending';
    await _dataSource.addExpense(
      ExpenseModel(
        id: id,
        category: category.trim(),
        description: description.trim(),
        amountMinor: amountMinor,
        accountId: accountId,
        status: expenseStatus,
        createdBy: _authService.currentUser?.uid ?? '',
        createdAtMillis: now,
        beneficiary: beneficiary.trim(),
        notes: notes.trim(),
        expenseDateMillis: expenseDateMillis ?? now,
      ),
    );
    await _auditService.record(
      action: 'create',
      entityType: 'expense',
      entityId: id,
    );
    if (expenseStatus == 'pending') {
      await _notificationService.create(
        title: 'مصروف بانتظار الاعتماد',
        body: 'تم تسجيل مصروف جديد ويحتاج إلى مراجعة المدير.',
        category: 'approval',
        targetType: 'expense',
        targetId: id,
      );
    }
  }

  @override
  Future<void> createExpenseCategory(String name) async {
    final now = _now();
    final id = _id('expense_category');
    await _dataSource.saveExpenseCategory(
      ExpenseCategoryModel(
        id: id,
        name: name.trim(),
        active: true,
        createdAtMillis: now,
      ),
    );
    await _auditService.record(
      action: 'create',
      entityType: 'expense_category',
      entityId: id,
    );
  }

  @override
  Future<void> updateExpenseCategory(ExpenseCategoryModel category) async {
    await _dataSource.saveExpenseCategory(category);
    await _auditService.record(
      action: 'update',
      entityType: 'expense_category',
      entityId: category.id,
    );
  }

  @override
  Future<void> approveExpense(String expenseId) =>
      _dataSource.approveExpense(expenseId);

  @override
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
  }) async {
    final id = _id('installment');
    final now = _now();
    await _dataSource.saveInstallment(
      InstallmentAccountModel(
        id: id,
        customerName: customerName.trim(),
        reference: reference.trim(),
        principalMinor: principalMinor,
        totalDueMinor: totalDueMinor,
        paidMinor: 0,
        totalLimitMinor: totalLimitMinor,
        availableMinor: availableMinor,
        nextDueMillis: nextDueMillis,
        monthlyInstallmentMinor: monthlyInstallmentMinor,
        totalInstallments: totalInstallments,
        paidInstallments: 0,
        status: 'active',
        createdAtMillis: now,
      ),
    );
    await _notificationService.create(
      title: 'تذكير بالتقسيط',
      body: 'تم إنشاء التزام تقسيط جديد ويجب متابعة موعد الاستحقاق.',
      category: 'installment',
      targetType: 'installment_account',
      targetId: id,
    );
  }

  @override
  Future<void> recordInstallmentPayment({
    required String id,
    required String accountId,
    required int amountMinor,
    required int nextDueMillis,
    String? scheduleId,
  }) async {
    await _dataSource.addInstallmentPayment(
      id: id,
      accountId: accountId,
      amountMinor: amountMinor,
      nextDueMillis: nextDueMillis,
      scheduleId: scheduleId,
    );
  }

  @override
  Future<void> createInstallmentSchedule({
    required String accountId,
    required String description,
    required int principalMinor,
    required int totalDueMinor,
    required int monthlyAmountMinor,
    required int totalInstallments,
    required int nextDueMillis,
  }) async {
    final now = _now();
    await _dataSource.saveInstallmentSchedule(
      InstallmentScheduleModel(
        id: _id('installment_schedule'),
        accountId: accountId,
        description: description.trim(),
        principalMinor: principalMinor,
        totalDueMinor: totalDueMinor,
        monthlyAmountMinor: monthlyAmountMinor,
        totalInstallments: totalInstallments,
        paidInstallments: 0,
        nextDueMillis: nextDueMillis,
        status: 'active',
        createdAtMillis: now,
      ),
    );
  }

  @override
  Future<void> updateInstallmentAccount({
    required String accountId,
    required String customerName,
    required String reference,
    String? status,
  }) async {
    await _dataSource.updateInstallmentAccount(
      accountId: accountId,
      customerName: customerName,
      reference: reference,
      status: status,
    );
  }

  @override
  Future<void> createCheck({
    required String payee,
    required String reference,
    required int amountMinor,
    required int dueDateMillis,
    required String accountId,
    String bankName = '',
    String notes = '',
  }) async {
    final id = _id('check');
    await _dataSource.saveCheck(
      IssuedCheckModel(
        id: id,
        payee: payee.trim(),
        reference: reference.trim(),
        amountMinor: amountMinor,
        dueDateMillis: dueDateMillis,
        accountId: accountId,
        bankName: bankName.trim(),
        notes: notes.trim(),
        status: 'issued',
        createdAtMillis: _now(),
      ),
    );
    await _notificationService.create(
      title: 'تذكير بشيك صادر',
      body: 'تم تسجيل شيك صادر ويجب متابعة موعده البنكي.',
      category: 'check',
      targetType: 'issued_check',
      targetId: id,
    );
  }

  @override
  Future<void> updateCheckStatus({
    required String checkId,
    required String status,
  }) async {
    final allowed =
        await _authService.hasRole('manager') ||
        await _authService.hasPermission('records.edit');
    if (!allowed) {
      throw StateError('تحديث حالة الشيك متاح للمصرح لهم فقط.');
    }
    if (status == 'deducted') {
      await _dataSource.updateCheckStatus(checkId: checkId, status: status);
    } else {
      await _dataSource.updateCheckStatus(checkId: checkId, status: status);
    }
    await _auditService.record(
      action: 'update_status',
      entityType: 'issued_check',
      entityId: checkId,
      metadata: {'status': status},
    );
  }

  @override
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
  }) async {
    final id = _id('settlement');
    if (brandId.isEmpty || includedTransactionIds.isEmpty) {
      throw StateError('اختر العلامة والمعاملات المؤهلة للتسوية.');
    }
    await _dataSource.createSettlement(
      settlementId: id,
      brandId: brandId,
      periodLabel: periodLabel.trim(),
      includedTransactionIds: includedTransactionIds,
    );
    await _notificationService.create(
      title: 'تسوية بانتظار المراجعة',
      body: 'تم إعداد تسوية جديدة وتحتاج إلى مراجع مختلف عن منشئها.',
      category: 'approval',
      targetType: 'settlement',
      targetId: id,
    );
  }

  @override
  Future<void> approveSettlement(String settlementId) async {
    final allowed =
        await _authService.hasRole('manager') ||
        await _authService.hasPermission('settlements.review');
    if (!allowed) {
      throw StateError('مراجعة التسويات متاحة للمصرح لهم فقط.');
    }
    await _dataSource.approveSettlement(settlementId);
  }

  @override
  Future<void> rejectSettlement({
    required String settlementId,
    required String reason,
  }) async {
    final allowed =
        await _authService.hasRole('manager') ||
        await _authService.hasPermission('settlements.review');
    if (!allowed || reason.trim().isEmpty) {
      throw StateError('أدخل سبب الرفض وتأكد من امتلاك صلاحية المراجعة.');
    }
    await _dataSource.rejectSettlement(
      settlementId: settlementId,
      reason: reason.trim(),
    );
  }

  @override
  Future<void> createCollectionRequest({
    required String settlementId,
    required int amountMinor,
    String collectionType = 'instant',
  }) async {
    if (amountMinor <= 0) {
      throw StateError('قيمة التحصيل يجب أن تكون موجبة.');
    }
    if (collectionType != 'normal' && collectionType != 'instant') {
      throw StateError('نوع التحصيل غير صحيح.');
    }
    final id = _id('collection');
    final settlement = (await _dataSource.getSettlements()).firstWhere(
      (item) => item.id == settlementId,
      orElse: () => throw StateError('التسوية غير موجودة.'),
    );
    if (settlement.approvalStatus != 'approved') {
      throw StateError('يجب اعتماد التسوية قبل طلب التحصيل.');
    }
    final commissionMinor = settlement.grossMinor <= 0
        ? 0
        : (amountMinor * settlement.commissionMinor +
                  settlement.grossMinor ~/ 2) ~/
              settlement.grossMinor;
    final feeMinor = collectionType == 'normal'
        ? 0
        : FinanceMoney.instantCollectionFeeMinor(amountMinor);
    final netMinor = amountMinor - commissionMinor - feeMinor;
    if (netMinor < 0) throw StateError('صافي التحصيل لا يمكن أن يكون سالباً.');
    await _dataSource.addCollectionRequest(
      CollectionRequestModel(
        id: id,
        settlementId: settlementId,
        amountMinor: amountMinor,
        commissionMinor: commissionMinor,
        feeMinor: feeMinor,
        netMinor: netMinor,
        status: 'pending',
        confirmationReference: '',
        createdAtMillis: _now(),
        collectionType: collectionType,
      ),
    );
    await _notificationService.create(
      title: 'طلب تحصيل جديد',
      body: 'يوجد طلب تحصيل يحتاج إلى تأكيد بنكي يدوي.',
      category: 'collection',
      targetType: 'collection_request',
      targetId: id,
    );
  }

  @override
  Future<void> confirmCollectionRequest({
    required String requestId,
    required String confirmationReference,
  }) async {
    final allowed =
        await _authService.hasRole('manager') ||
        await _authService.hasPermission('settlements.review');
    if (!allowed) {
      throw StateError('تأكيد التحصيل متاح للمصرح لهم فقط.');
    }
    await _dataSource.confirmCollectionRequest(
      requestId: requestId,
      confirmationReference: confirmationReference.trim(),
    );
  }
}
