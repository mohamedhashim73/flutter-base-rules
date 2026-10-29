import 'package:base/model/domain/brand_model.dart';
import 'package:base/model/domain/credit_card_model.dart';
import 'package:base/model/domain/credit_purchase_model.dart';
import 'package:base/model/domain/credit_deposit_model.dart';
import 'package:base/model/domain/credit_period_model.dart';
import 'package:base/model/domain/payment_provider_model.dart';
import 'package:base/model/domain/bank_account_model.dart';
import 'package:base/model/domain/receiving_company_model.dart';
import 'package:base/model/domain/pos_machine_model.dart';

abstract interface class CreditCardsRepository {
  Future<List<CreditCardModel>> getCards();

  Future<List<CreditPurchaseModel>> getPurchases(String cardId);
  Future<List<CreditPurchaseModel>> getAllPurchases();
  Future<List<CreditDepositModel>> getDeposits(String cardId);
  Future<List<CreditDepositModel>> getAllDeposits();
  Future<List<CreditPeriodModel>> getPeriods(String cardId);

  Future<List<PaymentProviderModel>> getProviders();

  Future<List<BrandModel>> getBrands();
  Future<List<BankAccountModel>> getBankAccounts();
  Future<List<ReceivingCompanyModel>> getReceivingCompanies();
  Future<List<PosMachineModel>> getPosMachines();

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
  });

  Future<void> updateCard(CreditCardModel card);

  Future<void> createProvider(String name);

  Future<void> updateProvider(PaymentProviderModel provider);

  Future<void> createBrand({
    required String name,
    required PaymentProviderModel provider,
    required int commissionBps,
    required ReceivingCompanyModel receivingCompany,
    required BankAccountModel bankAccount,
    required PosMachineModel posMachine,
  });
  Future<void> createPosMachine({
    required String name,
    required PaymentProviderModel provider,
  });
  Future<void> updatePosMachine(PosMachineModel machine);

  Future<void> updateBrand(BrandModel brand);
  Future<void> updateBrandRouting({
    required String brandId,
    required ReceivingCompanyModel receivingCompany,
    required BankAccountModel bankAccount,
  });

  Future<void> recordDeposit({
    required String cardId,
    required int amountMinor,
    required DateTime date,
    required bool qualifiesForMonthlyDebt,
  });

  Future<void> recordPurchase({
    required String cardId,
    required BrandModel brand,
    required int amountMinor,
    required DateTime date,
  });

  Future<void> updatePurchaseAmount({
    required CreditPurchaseModel purchase,
    required int amountMinor,
    String reason = 'Authorized credit purchase correction',
  });

  Future<void> correctDeposit({
    required CreditDepositModel deposit,
    required int amountMinor,
    required String reason,
  });

  Future<void> approveDeposit(String depositId);
  Future<void> rejectDeposit({
    required String depositId,
    required String reason,
  });

  Future<void> deletePurchase(CreditPurchaseModel purchase);
}
