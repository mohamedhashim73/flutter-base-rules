import 'package:base/core/services/services.dart';
import 'package:base/model/domain/brand_model.dart';
import 'package:base/model/domain/credit_card_model.dart';
import 'package:base/model/domain/credit_deposit_model.dart';
import 'package:base/model/domain/credit_period_model.dart';
import 'package:base/model/domain/credit_purchase_model.dart';
import 'package:base/model/domain/payment_provider_model.dart';
import 'package:base/model/domain/bank_account_model.dart';
import 'package:base/model/domain/receiving_company_model.dart';
import 'package:base/model/domain/pos_machine_model.dart';
import '../datasource/credit_cards_data_source.dart';
import 'credit_cards_repository.dart';
import 'credit_accounting_calculator.dart';

class CreditCardsRepositoryImpl implements CreditCardsRepository {
  CreditCardsRepositoryImpl(
    this._dataSource,
    this._authService,
    this._auditService,
    this._settingsService,
  );

  final CreditCardsDataSource _dataSource;
  final FirebaseAuthService _authService;
  final AuditService _auditService;
  final FinanceSettingsService _settingsService;

  @override
  Future<List<CreditCardModel>> getCards() => _dataSource.getCards();

  @override
  Future<List<CreditPurchaseModel>> getPurchases(String cardId) =>
      _dataSource.getPurchases(cardId);
  @override
  Future<List<CreditPurchaseModel>> getAllPurchases() =>
      _dataSource.getAllPurchases();
  @override
  Future<List<CreditDepositModel>> getDeposits(String cardId) =>
      _dataSource.getDeposits(cardId);

  @override
  Future<List<CreditDepositModel>> getAllDeposits() =>
      _dataSource.getAllDeposits();
  @override
  Future<List<CreditPeriodModel>> getPeriods(String cardId) =>
      _dataSource.getPeriods(cardId);

  @override
  Future<List<PaymentProviderModel>> getProviders() =>
      _dataSource.getProviders();

  @override
  Future<List<BrandModel>> getBrands() => _dataSource.getBrands();
  @override
  Future<List<BankAccountModel>> getBankAccounts() =>
      _dataSource.getBankAccounts();
  @override
  Future<List<ReceivingCompanyModel>> getReceivingCompanies() =>
      _dataSource.getReceivingCompanies();
  @override
  Future<List<PosMachineModel>> getPosMachines() =>
      _dataSource.getPosMachines();

  @override
  Future<void> createCard({
    required String title,
    required String cardholderName,
    required String bankName,
    required String lastFour,
    required int creditLimitMinor,
    required int openingBalanceMinor,
    required int dueDay,
    required String notes,
    String colorHex = '',
    String logoUrl = '',
    int statementClosingDay = 1,
  }) async {
    final id = _dataSource.newDocumentId();
    if (!RegExp(r'^\d{4}$').hasMatch(lastFour.trim())) {
      throw StateError('أدخل آخر أربعة أرقام صحيحة للبطاقة.');
    }
    if (creditLimitMinor <= 0 || dueDay < 1 || dueDay > 31) {
      throw StateError('بيانات حد البطاقة أو يوم الاستحقاق غير صحيحة.');
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final debt = CreditAccountingCalculator.monthlyDebt(
      creditLimitMinor: creditLimitMinor,
      openingBalanceMinor: openingBalanceMinor,
    );
    await _dataSource.createCard(
      CreditCardModel(
        id: id,
        title: title.trim(),
        cardholderName: cardholderName.trim(),
        bankName: bankName.trim(),
        maskedNumber: '•••• •••• •••• ${lastFour.trim()}',
        lastFour: lastFour.trim(),
        creditLimitMinor: creditLimitMinor,
        availableBalanceMinor: openingBalanceMinor,
        monthlyPaidMinor: 0,
        currentMonthlyDebtMinor: debt,
        dueDay: dueDay,
        active: true,
        notes: notes.trim(),
        createdAtMillis: now,
        updatedAtMillis: now,
        colorHex: colorHex.trim(),
        logoUrl: logoUrl.trim(),
        statementClosingDay: statementClosingDay,
      ),
    );
  }

  @override
  Future<void> updateCard(CreditCardModel card) async {
    final allowed =
        await _authService.hasRole('manager') ||
        await _authService.hasPermission('records.edit');
    if (!allowed) throw StateError('تعديل البطاقة متاح للمصرح لهم فقط.');
    await _dataSource.updateCard(card);
  }

  @override
  Future<void> createProvider(String name) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _dataSource.newDocumentId();
    await _dataSource.saveProvider(
      PaymentProviderModel(
        id: id,
        name: name.trim(),
        active: true,
        updatedAtMillis: now,
      ),
    );
    await _auditService.record(
      action: 'create',
      entityType: 'payment_provider',
      entityId: id,
    );
  }

  @override
  Future<void> updateProvider(PaymentProviderModel provider) async {
    final allowed =
        await _authService.hasRole('manager') ||
        await _authService.hasPermission('records.edit');
    if (!allowed) throw StateError('تعديل مزود الدفع متاح للمصرح لهم فقط.');
    final updated = provider.copyWith(
      updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
    );
    await _dataSource.saveProvider(updated);
    await _auditService.record(
      action: 'update',
      entityType: 'payment_provider',
      entityId: provider.id,
    );
  }

  @override
  Future<void> createBrand({
    required String name,
    required PaymentProviderModel provider,
    required int commissionBps,
    required ReceivingCompanyModel receivingCompany,
    required BankAccountModel bankAccount,
    required PosMachineModel posMachine,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _dataSource.newDocumentId();
    await _dataSource.saveBrand(
      BrandModel(
        id: id,
        name: name.trim(),
        providerId: provider.id,
        providerName: provider.name,
        commissionBps: commissionBps,
        active: true,
        updatedAtMillis: now,
        receivingCompanyId: receivingCompany.id,
        receivingCompanyName: receivingCompany.name,
        settlementBankAccountId: bankAccount.id,
        settlementBankAccountName:
            '${bankAccount.bankName} · •••• ${bankAccount.lastFour}',
        posMachineId: posMachine.id,
        posMachineName: posMachine.name,
      ),
    );
    await _auditService.record(
      action: 'create',
      entityType: 'brand',
      entityId: id,
    );
  }

  @override
  Future<void> createPosMachine({
    required String name,
    required PaymentProviderModel provider,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _dataSource.newDocumentId();
    await _dataSource.savePosMachine(
      PosMachineModel(
        id: id,
        name: name.trim(),
        providerId: provider.id,
        providerName: provider.name,
        active: true,
        updatedAtMillis: now,
      ),
    );
    await _auditService.record(
      action: 'create',
      entityType: 'pos_machine',
      entityId: id,
    );
  }

  @override
  Future<void> updatePosMachine(PosMachineModel machine) async {
    final allowed =
        await _authService.hasRole('manager') ||
        await _authService.hasPermission('records.edit');
    if (!allowed) throw StateError('تعديل أجهزة POS متاح للمصرح لهم فقط.');
    await _dataSource.savePosMachine(
      machine.copyWith(updatedAtMillis: DateTime.now().millisecondsSinceEpoch),
    );
    await _auditService.record(
      action: 'update',
      entityType: 'pos_machine',
      entityId: machine.id,
    );
  }

  @override
  Future<void> updateBrand(BrandModel brand) async {
    final allowed =
        await _authService.hasRole('manager') ||
        await _authService.hasPermission('records.edit');
    if (!allowed) throw StateError('تعديل العلامات متاح للمصرح لهم فقط.');
    await _dataSource.saveBrand(
      brand.copyWith(updatedAtMillis: DateTime.now().millisecondsSinceEpoch),
    );
    await _auditService.record(
      action: 'update',
      entityType: 'brand',
      entityId: brand.id,
    );
  }

  @override
  Future<void> updateBrandRouting({
    required String brandId,
    required ReceivingCompanyModel receivingCompany,
    required BankAccountModel bankAccount,
  }) async {
    final brand = (await _dataSource.getBrands()).firstWhere(
      (item) => item.id == brandId,
      orElse: () => throw StateError('Brand was not found.'),
    );
    await _dataSource.saveBrand(
      brand.copyWith(
        receivingCompanyId: receivingCompany.id,
        receivingCompanyName: receivingCompany.name,
        settlementBankAccountId: bankAccount.id,
        settlementBankAccountName:
            '${bankAccount.bankName} · •••• ${bankAccount.lastFour}',
        updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await _auditService.record(
      action: 'update_routing',
      entityType: 'brand',
      entityId: brandId,
      metadata: {
        'receivingCompanyId': receivingCompany.id,
        'bankAccountId': bankAccount.id,
      },
    );
  }

  @override
  Future<void> recordDeposit({
    required String cardId,
    required int amountMinor,
    required DateTime date,
    required bool qualifiesForMonthlyDebt,
  }) async {
    final card = await _findCard(cardId);
    final id = _dataSource.newDocumentId();
    final threshold = await _settingsService.getApprovalThresholdMinor();
    final approved =
        await _authService.hasRole('manager') || amountMinor <= threshold;
    await _dataSource.recordDeposit(
      cardId: card.id,
      depositId: id,
      amountMinor: amountMinor,
      depositDateMillis: date.millisecondsSinceEpoch,
      qualifiesForMonthlyDebt: qualifiesForMonthlyDebt,
      approvalStatus: approved ? 'approved' : 'pending',
    );
  }

  @override
  Future<void> recordPurchase({
    required String cardId,
    required BrandModel brand,
    required int amountMinor,
    required DateTime date,
  }) async {
    final card = await _findCard(cardId);
    final id = _dataSource.newDocumentId();
    await _dataSource.recordPurchase(
      cardId: card.id,
      brandId: brand.id,
      purchaseId: id,
      amountMinor: amountMinor,
      purchaseDateMillis: date.millisecondsSinceEpoch,
    );
  }

  @override
  Future<void> updatePurchaseAmount({
    required CreditPurchaseModel purchase,
    required int amountMinor,
    String reason = 'Authorized credit purchase correction',
  }) async {
    final allowed =
        await _authService.hasRole('manager') ||
        await _authService.hasPermission('records.edit');
    if (!allowed) throw StateError('تصحيح المشتريات متاح للمصرح لهم فقط.');
    if (amountMinor <= 0) throw StateError('أدخل مبلغ شراء صحيح.');
    await _dataSource.updatePurchaseAmount(
      purchaseId: purchase.id,
      amountMinor: amountMinor,
      reason: reason,
    );
  }

  @override
  Future<void> correctDeposit({
    required CreditDepositModel deposit,
    required int amountMinor,
    required String reason,
  }) async {
    if (!await _authService.hasRole('manager')) {
      throw StateError('تصحيح الإيداع متاح للمدير الرئيسي فقط.');
    }
    await _dataSource.correctDeposit(
      depositId: deposit.id,
      amountMinor: amountMinor,
      reason: reason,
    );
  }

  @override
  Future<void> approveDeposit(String depositId) async {
    if (!await _authService.hasRole('manager')) {
      throw StateError('اعتماد إيداع البطاقة متاح للمدير الرئيسي فقط.');
    }
    await _dataSource.approveDeposit(depositId);
  }

  @override
  Future<void> rejectDeposit({
    required String depositId,
    required String reason,
  }) async {
    if (!await _authService.hasRole('manager') || reason.trim().isEmpty) {
      throw StateError('رفض إيداع البطاقة يحتاج إلى المدير وسبب واضح.');
    }
    await _dataSource.rejectDeposit(
      depositId: depositId,
      reason: reason.trim(),
    );
  }

  @override
  Future<void> deletePurchase(CreditPurchaseModel purchase) async {
    final allowed =
        await _authService.hasRole('manager') ||
        await _authService.hasPermission('records.delete');
    if (!allowed) throw StateError('حذف المشتريات متاح للمصرح لهم فقط.');
    await _dataSource.deletePurchase(purchase.id);
  }

  Future<CreditCardModel> _findCard(String id) async {
    final cards = await _dataSource.getCards();
    return cards.firstWhere(
      (card) => card.id == id,
      orElse: () => throw StateError('Credit card was not found.'),
    );
  }
}
