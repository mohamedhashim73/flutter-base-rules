import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:base/core/enums/enums.dart';
import 'package:base/core/services/services.dart';
import 'package:base/core/utils/finance_money.dart';
import 'package:base/model/domain/brand_model.dart';
import 'package:base/model/domain/credit_card_model.dart';
import 'package:base/model/domain/credit_purchase_model.dart';
import 'package:base/model/domain/credit_deposit_model.dart';
import 'package:base/model/domain/credit_period_model.dart';
import 'package:base/model/domain/payment_provider_model.dart';
import 'package:base/model/domain/bank_account_model.dart';
import 'package:base/model/domain/receiving_company_model.dart';
import 'package:base/model/domain/brand_usage_summary_model.dart';
import 'package:base/model/domain/pos_machine_model.dart';
import 'package:base/view/credit_cards/data/repository/credit_cards_repository.dart';
import 'credit_cards_states.dart';

class CreditCardsCubit extends Cubit<CreditCardsState> {
  CreditCardsCubit(this._repository) : super(const CreditCardsState());

  final CreditCardsRepository _repository;
  final cardFormKey = GlobalKey<FormState>();
  final depositFormKey = GlobalKey<FormState>();
  final purchaseFormKey = GlobalKey<FormState>();
  final cardTitleController = TextEditingController();
  final cardholderController = TextEditingController();
  final bankController = TextEditingController();
  final lastFourController = TextEditingController();
  final creditLimitController = TextEditingController();
  final openingBalanceController = TextEditingController();
  final dueDayController = TextEditingController(text: '1');
  final statementClosingDayController = TextEditingController(text: '1');
  final colorHexController = TextEditingController();
  final logoUrlController = TextEditingController();
  final notesController = TextEditingController();
  final depositAmountController = TextEditingController();
  final purchaseAmountController = TextEditingController();
  final providerFormKey = GlobalKey<FormState>();
  final brandFormKey = GlobalKey<FormState>();
  final routingFormKey = GlobalKey<FormState>();
  final providerNameController = TextEditingController();
  final posNameController = TextEditingController();
  final brandNameController = TextEditingController();
  final commissionController = TextEditingController(text: '2');
  BrandModel? selectedBrand;
  PaymentProviderModel? selectedProvider;
  PosMachineModel? selectedPosMachine;
  ReceivingCompanyModel? selectedReceivingCompany;
  BankAccountModel? selectedBankAccount;
  DateTime purchaseDate = DateTime.now();
  DateTime depositDate = DateTime.now();
  bool providerActive = true;
  bool brandActive = true;

  void setPurchaseDate(DateTime value) {
    purchaseDate = DateTime(value.year, value.month, value.day);
    emit(state.copyWith());
  }

  void setDepositDate(DateTime value) {
    depositDate = DateTime(value.year, value.month, value.day);
    emit(state.copyWith());
  }

  Future<void> load() async {
    emit(state.copyWith(status: RequestStatus.loading));
    try {
      final cards = await _repository.getCards();
      final providers = await _repository.getProviders();
      final brands = await _repository.getBrands();
      final bankAccounts = await _repository.getBankAccounts();
      final receivingCompanies = await _repository.getReceivingCompanies();
      final posMachines = await _repository.getPosMachines();
      final selected = state.selectedCard == null
          ? (cards.isEmpty ? null : cards.first)
          : cards
                .where((item) => item.id == state.selectedCard!.id)
                .firstOrNull;
      final purchases = selected == null
          ? <CreditPurchaseModel>[]
          : await _repository.getPurchases(selected.id);
      final deposits = selected == null
          ? <CreditDepositModel>[]
          : await _repository.getDeposits(selected.id);
      final periods = selected == null
          ? <CreditPeriodModel>[]
          : await _repository.getPeriods(selected.id);
      final allPurchases = await _repository.getAllPurchases();
      final allDeposits = await _repository.getAllDeposits();
      emit(
        CreditCardsState(
          status: RequestStatus.success,
          cards: cards,
          providers: providers,
          brands: brands,
          selectedCard: selected,
          purchases: purchases,
          deposits: deposits,
          allDeposits: allDeposits,
          periods: periods,
          allPurchases: allPurchases,
          bankAccounts: bankAccounts,
          receivingCompanies: receivingCompanies,
          posMachines: posMachines,
          brandUsageSummaries: _usageSummaries(purchases, brands),
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: RequestStatus.failure,
          message: _friendlyError(error),
        ),
      );
    }
  }

  Future<void> selectCard(String id) async {
    final selected = state.cards.where((item) => item.id == id).firstOrNull;
    if (selected == null) return;
    emit(
      state.copyWith(
        selectedCard: selected,
        purchases: const [],
        deposits: const [],
        periods: const [],
        selectedBrandWarning: null,
      ),
    );
    try {
      final purchases = await _repository.getPurchases(id);
      final deposits = await _repository.getDeposits(id);
      final periods = await _repository.getPeriods(id);
      emit(
        state.copyWith(
          purchases: purchases,
          deposits: deposits,
          periods: periods,
          brandUsageSummaries: _usageSummaries(purchases, state.brands),
          status: RequestStatus.success,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: RequestStatus.failure,
          message: _friendlyError(error),
        ),
      );
    }
  }

  Future<void> approveDeposit(String depositId) async {
    await _runAction(
      () => _repository.approveDeposit(depositId),
      'تم اعتماد إيداع البطاقة وتحديث الرصيد.',
    );
  }

  Future<void> rejectDeposit({
    required String depositId,
    required String reason,
  }) async {
    await _runAction(
      () => _repository.rejectDeposit(depositId: depositId, reason: reason),
      'تم رفض إيداع البطاقة وتسجيل السبب.',
    );
  }

  void selectBrand(String? brandId) {
    selectedBrand = state.brands
        .where((item) => item.id == brandId)
        .firstOrNull;
    final summary = state.brandUsageSummaries
        .where((item) => item.brandId == brandId)
        .firstOrNull;
    emit(state.copyWith(selectedBrandWarning: _usageWarning(summary)));
  }

  List<BrandUsageSummaryModel> _usageSummaries(
    List<CreditPurchaseModel> purchases,
    List<BrandModel> brands,
  ) {
    final byBrand = <String, List<CreditPurchaseModel>>{};
    for (final purchase in purchases) {
      byBrand.putIfAbsent(purchase.brandId, () => []).add(purchase);
    }
    final summaries = brands
        .map(
          (brand) => BrandUsageSummaryModel(
            brandId: brand.id,
            brandName: brand.name,
            providerName: brand.providerName,
            usageCount: byBrand[brand.id]?.length ?? 0,
            lastUsedAtMillis: byBrand[brand.id]
                ?.map((item) => item.purchaseDateMillis)
                .fold<int?>(
                  null,
                  (latest, value) =>
                      latest == null || value > latest ? value : latest,
                ),
          ),
        )
        .toList();
    summaries.sort((a, b) {
      if (a.lastUsedAtMillis == null && b.lastUsedAtMillis != null) return -1;
      if (a.lastUsedAtMillis != null && b.lastUsedAtMillis == null) return 1;
      if (a.lastUsedAtMillis != null && b.lastUsedAtMillis != null) {
        final result = a.lastUsedAtMillis!.compareTo(b.lastUsedAtMillis!);
        if (result != 0) return result;
      }
      return a.usageCount.compareTo(b.usageCount);
    });
    return summaries;
  }

  String? _usageWarning(BrandUsageSummaryModel? summary) {
    final usedAt = summary?.lastUsedAtMillis;
    if (summary == null || usedAt == null) return null;
    final used = DateTime.fromMillisecondsSinceEpoch(usedAt);
    final now = DateTime.now();
    final currentMonth = used.year == now.year && used.month == now.month;
    final previous = DateTime(now.year, now.month - 1);
    final previousMonth =
        used.year == previous.year && used.month == previous.month;
    if (currentMonth) {
      return 'تحذير: تم استخدام هذه العلامة مع البطاقة خلال الشهر الحالي.';
    }
    if (previousMonth) {
      return 'تنبيه: تم استخدام هذه العلامة مع البطاقة خلال الشهر السابق.';
    }
    return summary.usageCount > 1
        ? 'تم استخدام هذه العلامة ${summary.usageCount} مرات مع هذه البطاقة.'
        : null;
  }

  void selectProvider(String providerId) {
    selectedProvider = state.providers
        .where((item) => item.id == providerId)
        .firstOrNull;
    if (selectedPosMachine?.providerId != providerId) {
      selectedPosMachine = null;
    }
    emit(state.copyWith());
  }

  void selectPosMachine(String? posMachineId) {
    selectedPosMachine = state.posMachines
        .where((item) => item.id == posMachineId)
        .firstOrNull;
    emit(state.copyWith());
  }

  void selectReceivingCompany(String? companyId) {
    selectedReceivingCompany = state.receivingCompanies
        .where((item) => item.id == companyId)
        .firstOrNull;
    selectedBankAccount = state.bankAccounts
        .where(
          (item) =>
              selectedReceivingCompany?.bankAccountIds.contains(item.id) ??
              false,
        )
        .firstOrNull;
    emit(state.copyWith());
  }

  void selectBankAccount(String? accountId) {
    selectedBankAccount = state.bankAccounts
        .where((item) => item.id == accountId)
        .firstOrNull;
    emit(state.copyWith());
  }

  void prepareBrandRouting(BrandModel brand) {
    selectedBrand = brand;
    selectedReceivingCompany = state.receivingCompanies
        .where((item) => item.id == brand.receivingCompanyId)
        .firstOrNull;
    selectedBankAccount = state.bankAccounts
        .where((item) => item.id == brand.settlementBankAccountId)
        .firstOrNull;
    selectedPosMachine = state.posMachines
        .where((item) => item.id == brand.posMachineId)
        .firstOrNull;
    emit(state.copyWith());
  }

  void prepareBrandEdit(BrandModel brand) {
    prepareBrandRouting(brand);
    selectedProvider = state.providers
        .where((item) => item.id == brand.providerId)
        .firstOrNull;
    brandActive = brand.active;
    brandNameController.text = brand.name;
    commissionController.text = (brand.commissionBps / 100).toString();
    emit(state.copyWith());
  }

  void setBrandActive(bool value) {
    brandActive = value;
    emit(state.copyWith());
  }

  Future<void> updateBrand() async {
    if (brandFormKey.currentState?.validate() != true ||
        selectedBrand == null) {
      return;
    }
    final commission = double.tryParse(commissionController.text.trim());
    if (commission == null || commission < 0 || commission > 100) {
      _emitAction(RequestStatus.failure, 'أدخل نسبة عمولة بين 0 و100.');
      return;
    }
    await _runAction(
      () => _repository.updateBrand(
        selectedBrand!.copyWith(
          name: brandNameController.text.trim(),
          commissionBps: (commission * 100).round(),
          active: brandActive,
        ),
      ),
      'تم تحديث العلامة التجارية.',
    );
    brandNameController.clear();
  }

  Future<void> updateBrandRecord(BrandModel brand) async {
    await _runAction(
      () => _repository.updateBrand(brand),
      'تم تحديث العلامة التجارية.',
    );
  }

  Future<void> updateBrandRouting() async {
    if (routingFormKey.currentState?.validate() != true ||
        selectedBrand == null ||
        selectedReceivingCompany == null ||
        selectedBankAccount == null) {
      _emitAction(RequestStatus.failure, 'اختر شركة التحصيل والحساب البنكي.');
      return;
    }
    await _runAction(
      () => _repository.updateBrandRouting(
        brandId: selectedBrand!.id,
        receivingCompany: selectedReceivingCompany!,
        bankAccount: selectedBankAccount!,
      ),
      'تم تحديث مسار تسوية العلامة.',
    );
  }

  Future<void> createProvider() async {
    if (providerFormKey.currentState?.validate() != true) return;
    await _runAction(
      () => _repository.createProvider(providerNameController.text),
      'تمت إضافة مزود الدفع.',
    );
    providerNameController.clear();
  }

  void prepareProviderEdit(PaymentProviderModel provider) {
    selectedProvider = provider;
    providerActive = provider.active;
    providerNameController.text = provider.name;
    emit(state.copyWith());
  }

  void setProviderActive(bool value) {
    providerActive = value;
    emit(state.copyWith());
  }

  Future<void> updateProvider() async {
    if (providerFormKey.currentState?.validate() != true ||
        selectedProvider == null) {
      return;
    }
    await _runAction(
      () => _repository.updateProvider(
        selectedProvider!.copyWith(
          name: providerNameController.text.trim(),
          active: providerActive,
        ),
      ),
      'تم تحديث مزود الدفع.',
    );
    providerNameController.clear();
  }

  Future<void> updateProviderRecord(PaymentProviderModel provider) async {
    await _runAction(
      () => _repository.updateProvider(provider),
      'تم تحديث مزود الدفع.',
    );
  }

  Future<void> createPosMachine() async {
    if (providerFormKey.currentState?.validate() != true ||
        selectedProvider == null) {
      if (selectedProvider == null) {
        _emitAction(RequestStatus.failure, 'اختر مزود الدفع أولاً.');
      }
      return;
    }
    await _runAction(
      () => _repository.createPosMachine(
        name: posNameController.text,
        provider: selectedProvider!,
      ),
      'تمت إضافة جهاز POS.',
    );
    posNameController.clear();
  }

  Future<void> updatePosMachine(PosMachineModel machine) async {
    await _runAction(
      () => _repository.updatePosMachine(machine),
      'تم تحديث جهاز POS.',
    );
  }

  Future<void> createBrand() async {
    if (brandFormKey.currentState?.validate() != true ||
        selectedProvider == null ||
        selectedReceivingCompany == null ||
        selectedBankAccount == null ||
        selectedPosMachine == null) {
      if (selectedProvider == null) {
        _emitAction(RequestStatus.failure, 'اختر مزود الدفع أولاً.');
      } else if (selectedReceivingCompany == null ||
          selectedBankAccount == null) {
        _emitAction(RequestStatus.failure, 'اختر شركة التحصيل والحساب البنكي.');
      } else if (selectedPosMachine == null) {
        _emitAction(RequestStatus.failure, 'اختر جهاز POS.');
      }
      return;
    }
    final commission = double.tryParse(commissionController.text.trim());
    if (commission == null || commission < 0 || commission > 100) {
      _emitAction(RequestStatus.failure, 'أدخل نسبة عمولة بين 0 و100.');
      return;
    }
    await _runAction(
      () => _repository.createBrand(
        name: brandNameController.text,
        provider: selectedProvider!,
        commissionBps: (commission * 100).round(),
        receivingCompany: selectedReceivingCompany!,
        bankAccount: selectedBankAccount!,
        posMachine: selectedPosMachine!,
      ),
      'تمت إضافة العلامة التجارية.',
    );
    brandNameController.clear();
  }

  Future<void> createCard() async {
    if (cardFormKey.currentState?.validate() != true) return;
    final limit = FinanceMoney.parseToMinor(creditLimitController.text);
    final opening = FinanceMoney.parseToMinor(openingBalanceController.text);
    final dueDay = int.tryParse(dueDayController.text.trim()) ?? 1;
    final statementClosingDay =
        int.tryParse(statementClosingDayController.text.trim()) ?? 1;
    if (limit <= 0 ||
        opening < 0 ||
        opening > limit ||
        dueDay < 1 ||
        dueDay > 31) {
      _emitAction(RequestStatus.failure, 'أدخل حدود البطاقة وقيمها بشكل صحيح.');
      return;
    }
    if (statementClosingDay < 1 || statementClosingDay > 31) {
      _emitAction(
        RequestStatus.failure,
        'أدخل يوم إغلاق كشف صحيح من 1 إلى 31.',
      );
      return;
    }
    final saved = await _runAction(
      () => _repository.createCard(
        title: cardTitleController.text,
        cardholderName: cardholderController.text,
        bankName: bankController.text,
        lastFour: lastFourController.text,
        creditLimitMinor: limit,
        openingBalanceMinor: opening,
        dueDay: dueDay,
        notes: notesController.text,
        colorHex: colorHexController.text,
        logoUrl: logoUrlController.text,
        statementClosingDay:
            int.tryParse(statementClosingDayController.text.trim()) ?? 1,
      ),
      'تم حفظ البطاقة.',
    );
    if (saved) clearCardForm();
  }

  void prepareCardEdit(CreditCardModel card) {
    cardTitleController.text = card.title;
    cardholderController.text = card.cardholderName;
    bankController.text = card.bankName;
    lastFourController.text = card.lastFour;
    creditLimitController.text = (card.creditLimitMinor / 100).toStringAsFixed(
      2,
    );
    openingBalanceController.text = (card.availableBalanceMinor / 100)
        .toStringAsFixed(2);
    dueDayController.text = '${card.dueDay}';
    statementClosingDayController.text = '${card.statementClosingDay}';
    colorHexController.text = card.colorHex;
    logoUrlController.text = card.logoUrl;
    notesController.text = card.notes;
    emit(state.copyWith(selectedCard: card));
  }

  Future<void> updateCard() async {
    if (cardFormKey.currentState?.validate() != true ||
        state.selectedCard == null) {
      return;
    }
    final limit = FinanceMoney.parseToMinor(creditLimitController.text);
    final dueDay = int.tryParse(dueDayController.text.trim()) ?? 1;
    final statementClosingDay =
        int.tryParse(statementClosingDayController.text.trim()) ?? 1;
    if (limit <= 0 || dueDay < 1 || dueDay > 31) {
      _emitAction(RequestStatus.failure, 'أدخل حدود البطاقة وقيمها بشكل صحيح.');
      return;
    }
    if (statementClosingDay < 1 || statementClosingDay > 31) {
      _emitAction(
        RequestStatus.failure,
        'أدخل يوم إغلاق كشف صحيح من 1 إلى 31.',
      );
      return;
    }
    final updatedCard = state.selectedCard!.copyWith(
      title: cardTitleController.text.trim(),
      cardholderName: cardholderController.text.trim(),
      bankName: bankController.text.trim(),
      lastFour: lastFourController.text.trim(),
      maskedNumber: '•••• •••• •••• ${lastFourController.text.trim()}',
      creditLimitMinor: limit,
      dueDay: dueDay,
      statementClosingDay: statementClosingDay,
      colorHex: colorHexController.text.trim(),
      logoUrl: logoUrlController.text.trim(),
      notes: notesController.text.trim(),
    );
    final saved = await _runAction(
      () => _repository.updateCard(updatedCard),
      'تم تحديث بيانات البطاقة.',
    );
    if (saved) clearCardForm();
  }

  Future<void> recordDeposit() async {
    if (depositFormKey.currentState?.validate() != true ||
        state.selectedCard == null) {
      return;
    }
    final amount = FinanceMoney.parseToMinor(depositAmountController.text);
    if (amount <= 0) {
      _emitAction(RequestStatus.failure, 'أدخل مبلغ إيداع صحيح.');
      return;
    }
    await _runAction(
      () => _repository.recordDeposit(
        cardId: state.selectedCard!.id,
        amountMinor: amount,
        date: depositDate,
        qualifiesForMonthlyDebt: true,
      ),
      'تم تسجيل الإيداع وتحديث الدين الشهري.',
    );
    depositAmountController.clear();
  }

  Future<void> recordPurchase() async {
    if (purchaseFormKey.currentState?.validate() != true ||
        state.selectedCard == null ||
        selectedBrand == null) {
      if (selectedBrand == null) {
        _emitAction(RequestStatus.failure, 'اختر العلامة التجارية أولاً.');
      }
      return;
    }
    final amount = FinanceMoney.parseToMinor(purchaseAmountController.text);
    if (amount <= 0) {
      _emitAction(RequestStatus.failure, 'أدخل مبلغ شراء صحيح.');
      return;
    }
    await _runAction(
      () => _repository.recordPurchase(
        cardId: state.selectedCard!.id,
        brand: selectedBrand!,
        amountMinor: amount,
        date: purchaseDate,
      ),
      'تم تسجيل الشراء وتحديث الرصيد.',
    );
    purchaseAmountController.clear();
  }

  Future<void> updatePurchaseAmount({
    required CreditPurchaseModel purchase,
  }) async {
    final amount = FinanceMoney.parseToMinor(purchaseAmountController.text);
    if (amount <= 0) {
      _emitAction(RequestStatus.failure, 'أدخل مبلغ شراء صحيح.');
      return;
    }
    await _runAction(
      () => _repository.updatePurchaseAmount(
        purchase: purchase,
        amountMinor: amount,
      ),
      'تم تصحيح مبلغ الشراء وتحديث الرصيد.',
    );
    purchaseAmountController.clear();
  }

  Future<void> deletePurchase(CreditPurchaseModel purchase) async {
    await _runAction(
      () => _repository.deletePurchase(purchase),
      'تم حذف الشراء وعكس أثره المالي.',
    );
  }

  void clearCardForm() {
    for (final controller in [
      cardTitleController,
      cardholderController,
      bankController,
      lastFourController,
      creditLimitController,
      openingBalanceController,
      notesController,
      colorHexController,
      logoUrlController,
    ]) {
      controller.clear();
    }
    dueDayController.text = '1';
    statementClosingDayController.text = '1';
  }

  Future<bool> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    _emitAction(RequestStatus.loading, null);
    try {
      await action();
      await sl<FirebaseCacheService>().clearCurrentScope();
      await load();
      _emitAction(RequestStatus.success, successMessage);
      return true;
    } catch (error) {
      _emitAction(RequestStatus.failure, _friendlyError(error));
      return false;
    }
  }

  void _emitAction(RequestStatus status, String? message) {
    emit(state.copyWith(actionStatus: status, actionMessage: message));
  }

  String _friendlyError(Object error) {
    if (error is FirebaseException) {
      return error.message ?? 'حدث خطأ في الاتصال.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  @override
  Future<void> close() {
    for (final controller in [
      cardTitleController,
      cardholderController,
      bankController,
      lastFourController,
      creditLimitController,
      openingBalanceController,
      dueDayController,
      statementClosingDayController,
      colorHexController,
      logoUrlController,
      notesController,
      depositAmountController,
      purchaseAmountController,
      providerNameController,
      posNameController,
      brandNameController,
      commissionController,
    ]) {
      controller.dispose();
    }
    return super.close();
  }
}
