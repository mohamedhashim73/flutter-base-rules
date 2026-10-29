import 'package:base/core/enums/enums.dart';
import 'package:base/model/base/request_state.dart';
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

class CreditCardsState extends RequestState {
  const CreditCardsState({
    super.status,
    super.message,
    this.cards = const [],
    this.purchases = const [],
    this.deposits = const [],
    this.allDeposits = const [],
    this.periods = const [],
    this.allPurchases = const [],
    this.bankAccounts = const [],
    this.receivingCompanies = const [],
    this.brandUsageSummaries = const [],
    this.providers = const [],
    this.brands = const [],
    this.posMachines = const [],
    this.selectedCard,
    this.actionStatus,
    this.actionMessage,
    this.selectedBrandWarning,
  });

  final List<CreditCardModel> cards;
  final List<CreditPurchaseModel> purchases;
  final List<CreditDepositModel> deposits;
  final List<CreditDepositModel> allDeposits;
  final List<CreditPeriodModel> periods;
  final List<CreditPurchaseModel> allPurchases;
  final List<BankAccountModel> bankAccounts;
  final List<ReceivingCompanyModel> receivingCompanies;
  final List<BrandUsageSummaryModel> brandUsageSummaries;
  final List<PaymentProviderModel> providers;
  final List<BrandModel> brands;
  final List<PosMachineModel> posMachines;
  final CreditCardModel? selectedCard;
  final RequestStatus? actionStatus;
  final String? actionMessage;
  final String? selectedBrandWarning;

  CreditCardsState copyWith({
    RequestStatus? status,
    String? message,
    List<CreditCardModel>? cards,
    List<CreditPurchaseModel>? purchases,
    List<CreditDepositModel>? deposits,
    List<CreditDepositModel>? allDeposits,
    List<CreditPeriodModel>? periods,
    List<CreditPurchaseModel>? allPurchases,
    List<BankAccountModel>? bankAccounts,
    List<ReceivingCompanyModel>? receivingCompanies,
    List<BrandUsageSummaryModel>? brandUsageSummaries,
    List<PaymentProviderModel>? providers,
    List<BrandModel>? brands,
    List<PosMachineModel>? posMachines,
    CreditCardModel? selectedCard,
    bool clearSelectedCard = false,
    RequestStatus? actionStatus,
    bool clearActionStatus = false,
    String? actionMessage,
    String? selectedBrandWarning,
    bool clearActionMessage = false,
  }) {
    return CreditCardsState(
      status: status ?? this.status,
      message: message,
      cards: cards ?? this.cards,
      purchases: purchases ?? this.purchases,
      deposits: deposits ?? this.deposits,
      allDeposits: allDeposits ?? this.allDeposits,
      periods: periods ?? this.periods,
      allPurchases: allPurchases ?? this.allPurchases,
      bankAccounts: bankAccounts ?? this.bankAccounts,
      receivingCompanies: receivingCompanies ?? this.receivingCompanies,
      brandUsageSummaries: brandUsageSummaries ?? this.brandUsageSummaries,
      providers: providers ?? this.providers,
      brands: brands ?? this.brands,
      posMachines: posMachines ?? this.posMachines,
      selectedCard: clearSelectedCard
          ? null
          : selectedCard ?? this.selectedCard,
      actionStatus: clearActionStatus
          ? null
          : actionStatus ?? this.actionStatus,
      actionMessage: clearActionMessage
          ? null
          : actionMessage ?? this.actionMessage,
      selectedBrandWarning: selectedBrandWarning,
    );
  }
}
