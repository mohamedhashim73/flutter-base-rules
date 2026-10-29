import 'package:base/model/domain/brand_model.dart';
import 'package:base/model/domain/credit_card_model.dart';
import 'package:base/model/domain/credit_deposit_model.dart';
import 'package:base/model/domain/credit_period_model.dart';
import 'package:base/model/domain/credit_purchase_model.dart';
import 'package:base/model/domain/payment_provider_model.dart';
import 'package:base/model/domain/bank_account_model.dart';
import 'package:base/model/domain/receiving_company_model.dart';
import 'package:base/model/domain/pos_machine_model.dart';

abstract interface class CreditCardsDataSource {
  String newDocumentId();
  Future<List<CreditCardModel>> getCards();

  Future<List<CreditPurchaseModel>> getPurchases(String cardId);
  Future<List<CreditPurchaseModel>> getAllPurchases();

  Future<List<CreditDepositModel>> getDeposits(String cardId);
  Future<List<CreditDepositModel>> getAllDeposits();
  Future<List<CreditPeriodModel>> getPeriods(String cardId);

  Future<List<PaymentProviderModel>> getProviders();

  Future<List<BrandModel>> getBrands();

  Future<List<PosMachineModel>> getPosMachines();

  Future<List<BankAccountModel>> getBankAccounts();

  Future<List<ReceivingCompanyModel>> getReceivingCompanies();

  Future<CreditPeriodModel?> getPeriod({
    required String cardId,
    required DateTime date,
  });

  Future<CreditPeriodModel?> getLatestPeriod(String cardId);

  Future<void> saveCard(CreditCardModel card);
  Future<void> createCard(CreditCardModel card);
  Future<void> updateCard(CreditCardModel card);
  Future<void> recordDeposit({
    required String cardId,
    required String depositId,
    required int amountMinor,
    required int depositDateMillis,
    required bool qualifiesForMonthlyDebt,
    String approvalStatus = 'approved',
  });
  Future<void> recordPurchase({
    required String cardId,
    required String brandId,
    required String purchaseId,
    required int amountMinor,
    required int purchaseDateMillis,
  });
  Future<void> updatePurchaseAmount({
    required String purchaseId,
    required int amountMinor,
    required String reason,
  });
  Future<void> correctDeposit({
    required String depositId,
    required int amountMinor,
    required String reason,
  });
  Future<void> approveDeposit(String depositId);
  Future<void> rejectDeposit({
    required String depositId,
    required String reason,
  });
  Future<void> deletePurchase(String purchaseId);

  Future<void> saveProvider(PaymentProviderModel provider);

  Future<void> saveBrand(BrandModel brand);

  Future<void> savePosMachine(PosMachineModel machine);
}
