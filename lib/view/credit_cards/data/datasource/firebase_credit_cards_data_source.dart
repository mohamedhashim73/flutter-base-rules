import 'package:base/core/constants/constants.dart';
import 'package:base/core/services/services.dart';
import 'package:base/core/utils/finance_money.dart';
import 'package:base/model/domain/brand_model.dart';
import 'package:base/model/domain/credit_card_model.dart';
import 'package:base/model/domain/credit_deposit_model.dart';
import 'package:base/model/domain/credit_period_model.dart';
import 'package:base/model/domain/credit_purchase_model.dart';
import 'package:base/model/domain/payment_provider_model.dart';
import 'package:base/model/domain/bank_account_model.dart';
import 'package:base/model/domain/receiving_company_model.dart';
import 'package:base/model/domain/pos_machine_model.dart';
import 'credit_cards_data_source.dart';

class FirebaseCreditCardsDataSource implements CreditCardsDataSource {
  FirebaseCreditCardsDataSource(this._firebaseService, this._cacheService);

  final FirebaseService _firebaseService;
  final FirebaseCacheService _cacheService;

  @override
  String newDocumentId() => _firebaseService.newDocumentId();

  Future<List<Map<String, dynamic>>> _get(String collection) async {
    final cached = _cacheService.read(collection);
    final lastSyncAt = _cacheService.readLastSyncAt(collection);
    try {
      final data = await _firebaseService.getCollection(
        collectionName: collection,
        // A sync marker without its corresponding cache is not a usable
        // incremental-sync baseline. Fall back to a full read so a fresh
        // page/session never renders Firestore data as an empty collection.
        query: lastSyncAt == null || cached == null || cached.isEmpty
            ? null
            // A write can legitimately share the same millisecond as the
            // cache marker. Include the boundary value so an immediate
            // refresh cannot resurrect the stale cached document.
            : (ref) => ref.where(
                'updatedAtMillis',
                isGreaterThanOrEqualTo: lastSyncAt,
              ),
      );
      final merged = <String, Map<String, dynamic>>{
        for (final item
            in (lastSyncAt == null
                ? const <Map<String, dynamic>>[]
                : cached ?? const []))
          if (item['isDeleted'] != true && item['id'] != null)
            '${item['id']}': item,
      };
      for (final item in data) {
        final id = item['id'];
        if (id != null) merged['$id'] = item;
      }
      final result = lastSyncAt == null ? data : merged.values.toList();
      if (lastSyncAt == null || data.isNotEmpty) {
        await _cacheService.write(collection, result);
      }
      await _cacheService.writeLastSyncAt(
        collection,
        DateTime.now().millisecondsSinceEpoch,
      );
      return result.where((item) => item['isDeleted'] != true).toList();
    } catch (_) {
      if (cached != null && cached.isNotEmpty) {
        return cached.where((item) => item['isDeleted'] != true).toList();
      }
      rethrow;
    }
  }

  @override
  Future<List<CreditCardModel>> getCards() async {
    final data = await _get(FirebaseCollections.creditCards);
    return data
        .map(CreditCardModel.fromJson)
        .where((card) => card.active)
        .toList();
  }

  @override
  Future<List<CreditPurchaseModel>> getPurchases(String cardId) async {
    final data = await _get(FirebaseCollections.creditPurchases);
    return data
        .map(CreditPurchaseModel.fromJson)
        .where((item) => item.cardId == cardId)
        .where((item) => !item.isDeleted)
        .toList()
      ..sort((a, b) => b.purchaseDateMillis.compareTo(a.purchaseDateMillis));
  }

  @override
  Future<List<CreditPurchaseModel>> getAllPurchases() async {
    final data = await _get(FirebaseCollections.creditPurchases);
    return data
        .map(CreditPurchaseModel.fromJson)
        .where((item) => !item.isDeleted)
        .toList()
      ..sort((a, b) => b.purchaseDateMillis.compareTo(a.purchaseDateMillis));
  }

  @override
  Future<List<CreditDepositModel>> getDeposits(String cardId) async {
    final data = await _get(FirebaseCollections.creditDeposits);
    return data
        .map(CreditDepositModel.fromJson)
        .where((item) => item.cardId == cardId)
        .toList()
      ..sort((a, b) => b.depositDateMillis.compareTo(a.depositDateMillis));
  }

  @override
  Future<List<CreditDepositModel>> getAllDeposits() async {
    final data = await _get(FirebaseCollections.creditDeposits);
    return data.map(CreditDepositModel.fromJson).toList()
      ..sort((a, b) => b.depositDateMillis.compareTo(a.depositDateMillis));
  }

  @override
  Future<List<CreditPeriodModel>> getPeriods(String cardId) async {
    final data = await _get(FirebaseCollections.creditPeriods);
    return data
        .map(CreditPeriodModel.fromJson)
        .where((item) => item.cardId == cardId)
        .toList()
      ..sort((a, b) {
        final year = b.year.compareTo(a.year);
        return year == 0 ? b.month.compareTo(a.month) : year;
      });
  }

  @override
  Future<List<PaymentProviderModel>> getProviders() async {
    final data = await _get(FirebaseCollections.paymentProviders);
    return data.map(PaymentProviderModel.fromJson).toList();
  }

  @override
  Future<List<BrandModel>> getBrands() async {
    final data = await _get(FirebaseCollections.brands);
    return data.map(BrandModel.fromJson).toList();
  }

  @override
  Future<List<PosMachineModel>> getPosMachines() async => (await _get(
    FirebaseCollections.posMachines,
  )).map(PosMachineModel.fromJson).toList();

  @override
  Future<List<BankAccountModel>> getBankAccounts() async => (await _get(
    FirebaseCollections.bankAccounts,
  )).map(BankAccountModel.fromJson).toList();

  @override
  Future<List<ReceivingCompanyModel>> getReceivingCompanies() async =>
      (await _get(
        FirebaseCollections.receivingCompanies,
      )).map(ReceivingCompanyModel.fromJson).toList();

  @override
  Future<CreditPeriodModel?> getPeriod({
    required String cardId,
    required DateTime date,
  }) async {
    final data = await _firebaseService.getDocument(
      collectionName: FirebaseCollections.creditPeriods,
      documentId: '${cardId}_${date.year}_${date.month}',
    );
    return data == null ? null : CreditPeriodModel.fromJson(data);
  }

  @override
  Future<CreditPeriodModel?> getLatestPeriod(String cardId) async {
    final data = await _firebaseService.getCollection(
      collectionName: FirebaseCollections.creditPeriods,
      query: (ref) => ref
          .where('cardId', isEqualTo: cardId)
          .orderBy('updatedAtMillis', descending: true)
          .limit(1),
    );
    return data.isEmpty ? null : CreditPeriodModel.fromJson(data.first);
  }

  @override
  Future<void> saveCard(CreditCardModel card) {
    return _firebaseService.setDocument(
      collectionName: FirebaseCollections.creditCards,
      documentId: card.id,
      data: card.toJson(),
    );
  }

  String _periodId(String cardId, int year, int month) =>
      '${cardId}_${year}_$month';

  int _number(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString().trim() ?? '') ?? 0;
  }

  bool _boolean(Object? value) {
    if (value is bool) return value;
    return value?.toString().trim().toLowerCase() == 'true';
  }

  Map<String, dynamic> _periodData({
    required String cardId,
    required int year,
    required int month,
    required Map<String, dynamic> card,
    required Map<String, dynamic>? existing,
    int depositDelta = 0,
    int purchaseDelta = 0,
  }) {
    final openingBalance =
        existing != null && existing.containsKey('openingBalanceMinor')
        ? _number(existing['openingBalanceMinor'])
        : _number(card['availableBalanceMinor']);
    final effectiveLimit =
        existing != null && existing.containsKey('effectiveLimitMinor')
        ? _number(existing['effectiveLimitMinor'])
        : _number(card['nextCreditLimitMinor']) > 0
        ? _number(card['nextCreditLimitMinor'])
        : _number(card['creditLimitMinor']);
    final openingDebt =
        existing != null && existing.containsKey('openingDebtMinor')
        ? _number(existing['openingDebtMinor'])
        : (effectiveLimit - openingBalance).clamp(0, 1 << 62).toInt();
    final qualifyingDeposits =
        _number(existing?['qualifyingDepositsMinor']) + depositDelta;
    final remainingDebt = (openingDebt - qualifyingDeposits)
        .clamp(0, 1 << 62)
        .toInt();
    final closingBalance =
        _number(existing?['closingBalanceMinor']) -
        purchaseDelta +
        depositDelta +
        (existing == null ? _number(card['availableBalanceMinor']) : 0);
    final now = DateTime.now().millisecondsSinceEpoch;
    return {
      'id': _periodId(cardId, year, month),
      'cardId': cardId,
      'year': year,
      'month': month,
      'openingBalanceMinor': openingBalance,
      'openingDebtMinor': openingDebt,
      'qualifyingDepositsMinor': qualifyingDeposits,
      'remainingDebtMinor': remainingDebt,
      'closingBalanceMinor': closingBalance,
      'fullyPaid': remainingDebt == 0,
      'effectiveLimitMinor': effectiveLimit,
      'updatedAtMillis': now,
    };
  }

  Map<String, dynamic> _audit({
    required String action,
    required String entityType,
    required String entityId,
    Map<String, dynamic> metadata = const {},
    String reason = '',
  }) => {
    'id': _firebaseService.newDocumentId(),
    'action': action,
    'entityType': entityType,
    'entityId': entityId,
    'metadata': metadata,
    'reason': reason,
    'source': 'client',
    'createdBy': _firebaseService.currentUserId,
    'createdAtMillis': DateTime.now().millisecondsSinceEpoch,
  };

  @override
  Future<void> createCard(CreditCardModel card) async {
    final cardRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditCards)
        .doc(card.id);
    final now = DateTime.now().millisecondsSinceEpoch;
    final date = DateTime.fromMillisecondsSinceEpoch(now);
    final periodRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditPeriods)
        .doc(_periodId(card.id, date.year, date.month));
    final openingDepositRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditDeposits)
        .doc('${card.id}_opening');
    final auditRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.auditLogs)
        .doc();
    await _firebaseService.runTransaction((transaction) async {
      final existing = await transaction.get(cardRef);
      if (existing.exists) return;
      final period = _periodData(
        cardId: card.id,
        year: date.year,
        month: date.month,
        card: card.toJson(),
        existing: null,
      );
      transaction.set(cardRef, card.toJson());
      transaction.set(openingDepositRef, {
        'id': openingDepositRef.id,
        'cardId': card.id,
        'amountMinor': 0,
        'depositDateMillis': now,
        'qualifiesForMonthlyDebt': false,
        'approvalStatus': 'approved',
        'createdBy': _firebaseService.currentUserId,
        'createdAtMillis': now,
        'updatedAtMillis': now,
      });
      transaction.set(periodRef, period);
      transaction.set(
        auditRef,
        _audit(
          action: 'create',
          entityType: 'credit_card',
          entityId: card.id,
          metadata: {
            'creditLimitMinor': card.creditLimitMinor,
            'openingBalanceMinor': card.availableBalanceMinor,
          },
        ),
      );
    });
  }

  @override
  Future<void> updateCard(CreditCardModel card) async {
    final cardRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditCards)
        .doc(card.id);
    final now = DateTime.now().millisecondsSinceEpoch;
    final date = DateTime.fromMillisecondsSinceEpoch(now);
    final periodRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditPeriods)
        .doc(_periodId(card.id, date.year, date.month));
    final auditRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.auditLogs)
        .doc();
    await _firebaseService.runTransaction((transaction) async {
      final snapshot = await transaction.get(cardRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('Credit card was not found.');
      }
      final period = await transaction.get(periodRef);
      final data = <String, dynamic>{
        'title': card.title,
        'cardholderName': card.cardholderName,
        'bankName': card.bankName,
        'maskedNumber': card.maskedNumber,
        'lastFour': card.lastFour,
        'dueDay': card.dueDay,
        'statementClosingDay': card.statementClosingDay,
        'notes': card.notes,
        'colorHex': card.colorHex,
        'logoUrl': card.logoUrl,
        'updatedAtMillis': now,
      };
      if (period.exists) {
        data['nextCreditLimitMinor'] = card.creditLimitMinor;
      } else {
        data['creditLimitMinor'] = card.creditLimitMinor;
        data['nextCreditLimitMinor'] = null;
      }
      transaction.update(cardRef, data);
      transaction.set(
        auditRef,
        _audit(
          action: 'update',
          entityType: 'credit_card',
          entityId: card.id,
          metadata: {'creditLimitMinor': card.creditLimitMinor},
        ),
      );
    });
  }

  @override
  Future<void> recordDeposit({
    required String cardId,
    required String depositId,
    required int amountMinor,
    required int depositDateMillis,
    required bool qualifiesForMonthlyDebt,
    String approvalStatus = 'approved',
  }) async {
    if (amountMinor < 0) throw StateError('Deposit amount cannot be negative.');
    if (approvalStatus != 'approved' && approvalStatus != 'pending') {
      throw StateError('Invalid deposit approval status.');
    }
    final cardRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditCards)
        .doc(cardId);
    final depositRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditDeposits)
        .doc(depositId);
    final date = DateTime.fromMillisecondsSinceEpoch(depositDateMillis);
    final periodRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditPeriods)
        .doc(_periodId(cardId, date.year, date.month));
    final auditRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.auditLogs)
        .doc();
    await _firebaseService.runTransaction((transaction) async {
      final cardSnapshot = await transaction.get(cardRef);
      final existingDeposit = await transaction.get(depositRef);
      final existingPeriod = await transaction.get(periodRef);
      if (existingDeposit.exists) return;
      final card = cardSnapshot.data();
      if (!cardSnapshot.exists || card == null) {
        throw StateError('Credit card was not found.');
      }
      if (!_boolean(card['active']))
        throw StateError('The credit card is inactive.');
      final now = DateTime.now().millisecondsSinceEpoch;
      final approved = approvalStatus == 'approved';
      if (approved) {
        final period = _periodData(
          cardId: cardId,
          year: date.year,
          month: date.month,
          card: card,
          existing: existingPeriod.data(),
          depositDelta: qualifiesForMonthlyDebt ? amountMinor : 0,
        );
        transaction.update(cardRef, {
          'availableBalanceMinor':
              _number(card['availableBalanceMinor']) + amountMinor,
          'currentMonthlyDebtMinor': _number(period['remainingDebtMinor']),
          'monthlyPaidMinor': _number(period['qualifyingDepositsMinor']),
          'updatedAtMillis': now,
        });
        transaction.set(periodRef, period);
      }
      transaction.set(depositRef, {
        'id': depositId,
        'cardId': cardId,
        'amountMinor': amountMinor,
        'depositDateMillis': depositDateMillis,
        'qualifiesForMonthlyDebt': qualifiesForMonthlyDebt,
        'approvalStatus': approvalStatus,
        'createdBy': _firebaseService.currentUserId,
        'createdAtMillis': now,
        'updatedAtMillis': now,
        if (approved) 'approvedBy': _firebaseService.currentUserId,
        if (approved) 'approvedAtMillis': now,
      });
      transaction.set(
        auditRef,
        _audit(
          action: 'create',
          entityType: 'credit_deposit',
          entityId: depositId,
          metadata: {
            'amountMinor': amountMinor,
            'approvalStatus': approvalStatus,
            'qualifiesForMonthlyDebt': qualifiesForMonthlyDebt,
          },
        ),
      );
    });
  }

  @override
  Future<void> approveDeposit(String depositId) async {
    final depositRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditDeposits)
        .doc(depositId);
    await _firebaseService.runTransaction((transaction) async {
      final depositSnapshot = await transaction.get(depositRef);
      final deposit = depositSnapshot.data();
      if (!depositSnapshot.exists || deposit == null) {
        throw StateError('Deposit was not found.');
      }
      if (deposit['approvalStatus'] == 'approved') return;
      if (deposit['approvalStatus'] != 'pending') {
        throw StateError('Only pending deposits can be approved.');
      }
      final cardId = '${deposit['cardId'] ?? ''}';
      final cardRef = _firebaseService
          .scopedCollectionRef(FirebaseCollections.creditCards)
          .doc(cardId);
      final cardSnapshot = await transaction.get(cardRef);
      final card = cardSnapshot.data();
      if (!cardSnapshot.exists || card == null) {
        throw StateError('Credit card was not found.');
      }
      final date = DateTime.fromMillisecondsSinceEpoch(
        _number(deposit['depositDateMillis']),
      );
      final periodRef = _firebaseService
          .scopedCollectionRef(FirebaseCollections.creditPeriods)
          .doc(_periodId(cardId, date.year, date.month));
      final periodSnapshot = await transaction.get(periodRef);
      if (!periodSnapshot.exists || periodSnapshot.data() == null) {
        throw StateError('The deposit accounting period is missing.');
      }
      final amount = _number(deposit['amountMinor']);
      final period = _periodData(
        cardId: cardId,
        year: date.year,
        month: date.month,
        card: card,
        existing: periodSnapshot.data(),
        depositDelta: deposit['qualifiesForMonthlyDebt'] == true ? amount : 0,
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      transaction.update(cardRef, {
        'availableBalanceMinor':
            _number(card['availableBalanceMinor']) + amount,
        'currentMonthlyDebtMinor': _number(period['remainingDebtMinor']),
        'monthlyPaidMinor': _number(period['qualifyingDepositsMinor']),
        'updatedAtMillis': now,
      });
      transaction.update(periodRef, period);
      transaction.update(depositRef, {
        'approvalStatus': 'approved',
        'approvedBy': _firebaseService.currentUserId,
        'approvedAtMillis': now,
        'updatedAtMillis': now,
      });
      transaction.set(
        _firebaseService
            .scopedCollectionRef(FirebaseCollections.auditLogs)
            .doc(),
        _audit(
          action: 'approve',
          entityType: 'credit_deposit',
          entityId: depositId,
          metadata: {'amountMinor': amount},
        ),
      );
    });
  }

  @override
  Future<void> rejectDeposit({
    required String depositId,
    required String reason,
  }) async {
    if (reason.trim().isEmpty)
      throw StateError('A rejection reason is required.');
    final ref = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditDeposits)
        .doc(depositId);
    await _firebaseService.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (!snapshot.exists || data == null)
        throw StateError('Deposit was not found.');
      if (data['approvalStatus'] == 'approved') {
        throw StateError('An approved deposit cannot be rejected.');
      }
      if (data['approvalStatus'] == 'rejected') return;
      if (data['approvalStatus'] != 'pending') {
        throw StateError('Only pending deposits can be rejected.');
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      transaction.update(ref, {
        'approvalStatus': 'rejected',
        'rejectionReason': reason.trim(),
        'rejectedBy': _firebaseService.currentUserId,
        'rejectedAtMillis': now,
        'updatedAtMillis': now,
      });
      transaction.set(
        _firebaseService
            .scopedCollectionRef(FirebaseCollections.auditLogs)
            .doc(),
        _audit(
          action: 'reject',
          entityType: 'credit_deposit',
          entityId: depositId,
          metadata: {'reason': reason.trim()},
        ),
      );
    });
  }

  @override
  Future<void> recordPurchase({
    required String cardId,
    required String brandId,
    required String purchaseId,
    required int amountMinor,
    required int purchaseDateMillis,
  }) async {
    if (amountMinor <= 0) throw StateError('Purchase amount must be positive.');
    final cardRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditCards)
        .doc(cardId);
    final brandRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.brands)
        .doc(brandId);
    final purchaseRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditPurchases)
        .doc(purchaseId);
    final date = DateTime.fromMillisecondsSinceEpoch(purchaseDateMillis);
    final periodRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditPeriods)
        .doc(_periodId(cardId, date.year, date.month));
    await _firebaseService.runTransaction((transaction) async {
      final cardSnapshot = await transaction.get(cardRef);
      final brandSnapshot = await transaction.get(brandRef);
      final purchaseSnapshot = await transaction.get(purchaseRef);
      final periodSnapshot = await transaction.get(periodRef);
      if (purchaseSnapshot.exists) return;
      final card = cardSnapshot.data();
      final brand = brandSnapshot.data();
      if (!cardSnapshot.exists || card == null) {
        throw StateError('Credit card was not found.');
      }
      if (!brandSnapshot.exists ||
          brand == null ||
          !_boolean(brand['active'])) {
        throw StateError('The selected brand is not active.');
      }
      if (!_boolean(card['active'])) {
        throw StateError('The credit card is inactive.');
      }
      final commissionBps = _number(brand['commissionBps']);
      if (commissionBps < 0 || commissionBps > 10000) {
        throw StateError('The brand commission is invalid.');
      }
      final commission = FinanceMoney.commissionMinor(
        amountMinor: amountMinor,
        commissionBps: commissionBps,
      );
      final period = _periodData(
        cardId: cardId,
        year: date.year,
        month: date.month,
        card: card,
        existing: periodSnapshot.data(),
        purchaseDelta: amountMinor,
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      transaction.update(cardRef, {
        'availableBalanceMinor':
            _number(card['availableBalanceMinor']) - amountMinor,
        'currentMonthlyDebtMinor': _number(period['remainingDebtMinor']),
        'monthlyPaidMinor': _number(period['qualifyingDepositsMinor']),
        'updatedAtMillis': now,
      });
      transaction.set(purchaseRef, {
        'id': purchaseId,
        'cardId': cardId,
        'brandId': brandId,
        'brandName': '${brand['name'] ?? ''}',
        'providerId': '${brand['providerId'] ?? ''}',
        'providerName': '${brand['providerName'] ?? ''}',
        'amountMinor': amountMinor,
        'commissionMinor': commission,
        'commissionBps': commissionBps,
        'expectedNetMinor': amountMinor - commission,
        'purchaseDateMillis': purchaseDateMillis,
        'createdBy': _firebaseService.currentUserId,
        'createdAtMillis': now,
        'updatedAtMillis': now,
        'isDeleted': false,
        'posMachineId': '${brand['posMachineId'] ?? ''}',
        'posMachineName': '${brand['posMachineName'] ?? ''}',
      });
      transaction.set(periodRef, period);
      transaction.set(
        _firebaseService
            .scopedCollectionRef(FirebaseCollections.auditLogs)
            .doc(),
        _audit(
          action: 'create',
          entityType: 'credit_purchase',
          entityId: purchaseId,
          metadata: {
            'amountMinor': amountMinor,
            'commissionMinor': commission,
            'brandId': brandId,
          },
        ),
      );
    });
  }

  Future<void> _assertPurchaseNotSettled(String purchaseId) async {
    final settlements = await _firebaseService.getCollection(
      collectionName: FirebaseCollections.settlements,
      query: (ref) =>
          ref.where('includedTransactionIds', arrayContains: purchaseId),
    );
    if (settlements.any(
      (item) =>
          item['approvalStatus'] == 'approved' ||
          _number(item['collectedMinor']) > 0,
    )) {
      throw StateError(
        'A purchase in an approved or collected settlement cannot be corrected.',
      );
    }
  }

  Future<Map<String, dynamic>> _purchase(String purchaseId) async {
    final data = await _firebaseService.getDocument(
      collectionName: FirebaseCollections.creditPurchases,
      documentId: purchaseId,
    );
    if (data == null) throw StateError('Purchase was not found.');
    return data;
  }

  @override
  Future<void> updatePurchaseAmount({
    required String purchaseId,
    required int amountMinor,
    required String reason,
  }) async {
    if (amountMinor <= 0) throw StateError('Purchase amount must be positive.');
    await _assertPurchaseNotSettled(purchaseId);
    final purchase = await _purchase(purchaseId);
    if (purchase['isDeleted'] == true) {
      throw StateError('A deleted purchase cannot be corrected.');
    }
    final cardId = '${purchase['cardId'] ?? ''}';
    final cardRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditCards)
        .doc(cardId);
    final purchaseRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditPurchases)
        .doc(purchaseId);
    final purchaseDate = DateTime.fromMillisecondsSinceEpoch(
      _number(purchase['purchaseDateMillis']),
    );
    final targetPeriodRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditPeriods)
        .doc(_periodId(cardId, purchaseDate.year, purchaseDate.month));
    final today = DateTime.now();
    final currentPeriodRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditPeriods)
        .doc(_periodId(cardId, today.year, today.month));
    await _firebaseService.runTransaction((transaction) async {
      final cardSnapshot = await transaction.get(cardRef);
      final purchaseSnapshot = await transaction.get(purchaseRef);
      final targetPeriodSnapshot = await transaction.get(targetPeriodRef);
      final currentPeriodSnapshot =
          targetPeriodRef.path == currentPeriodRef.path
          ? targetPeriodSnapshot
          : await transaction.get(currentPeriodRef);
      final card = cardSnapshot.data();
      final currentPurchase = purchaseSnapshot.data();
      final targetPeriod = targetPeriodSnapshot.data();
      if (!cardSnapshot.exists ||
          card == null ||
          currentPurchase == null ||
          targetPeriod == null) {
        throw StateError('The purchase accounting data is incomplete.');
      }
      final oldAmount = _number(currentPurchase['amountMinor']);
      final commissionBps = _number(currentPurchase['commissionBps']);
      final commission = FinanceMoney.commissionMinor(
        amountMinor: amountMinor,
        commissionBps: commissionBps,
      );
      final difference = oldAmount - amountMinor;
      final now = DateTime.now().millisecondsSinceEpoch;
      transaction.update(cardRef, {
        'availableBalanceMinor':
            _number(card['availableBalanceMinor']) + difference,
        'updatedAtMillis': now,
      });
      if (purchaseDate.year == today.year &&
          purchaseDate.month == today.month) {
        transaction.update(targetPeriodRef, {
          'closingBalanceMinor':
              _number(targetPeriod['closingBalanceMinor']) + difference,
          'updatedAtMillis': now,
        });
      } else {
        final currentPeriod =
            currentPeriodSnapshot.data() ??
            _periodData(
              cardId: cardId,
              year: today.year,
              month: today.month,
              card: card,
              existing: null,
            );
        transaction.set(currentPeriodRef, {
          ...currentPeriod,
          'closingBalanceMinor':
              _number(currentPeriod['closingBalanceMinor']) + difference,
          'correctionMinor':
              _number(currentPeriod['correctionMinor']) + difference,
          'updatedAtMillis': now,
        });
      }
      transaction.update(purchaseRef, {
        'amountMinor': amountMinor,
        'commissionMinor': commission,
        'expectedNetMinor': amountMinor - commission,
        'updatedAtMillis': now,
      });
      final correctionRef = _firebaseService
          .scopedCollectionRef(FirebaseCollections.creditCorrections)
          .doc();
      transaction.set(correctionRef, {
        'id': correctionRef.id,
        'sourceType': 'credit_purchase',
        'sourceId': purchaseId,
        'previousAmountMinor': oldAmount,
        'newAmountMinor': amountMinor,
        'differenceMinor': difference,
        'sourcePeriodId': targetPeriodRef.id,
        'correctionPeriodId': currentPeriodRef.id,
        'reason': reason.trim(),
        'createdBy': _firebaseService.currentUserId,
        'createdAtMillis': now,
        'updatedAtMillis': now,
      });
      transaction.set(
        _firebaseService
            .scopedCollectionRef(FirebaseCollections.auditLogs)
            .doc(),
        _audit(
          action: 'update_amount',
          entityType: 'credit_purchase',
          entityId: purchaseId,
          metadata: {
            'previousAmountMinor': oldAmount,
            'newAmountMinor': amountMinor,
            'reason': reason.trim(),
          },
        ),
      );
    });
  }

  @override
  Future<void> correctDeposit({
    required String depositId,
    required int amountMinor,
    required String reason,
  }) async {
    if (amountMinor < 0) throw StateError('Deposit amount cannot be negative.');
    final depositRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditDeposits)
        .doc(depositId);
    final deposit = await _firebaseService.getDocument(
      collectionName: FirebaseCollections.creditDeposits,
      documentId: depositId,
    );
    if (deposit == null) throw StateError('Deposit was not found.');
    if (deposit['approvalStatus'] == 'pending') {
      throw StateError('A pending deposit must be approved before correction.');
    }
    final cardId = '${deposit['cardId'] ?? ''}';
    final cardRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditCards)
        .doc(cardId);
    final date = DateTime.fromMillisecondsSinceEpoch(
      _number(deposit['depositDateMillis']),
    );
    final periodRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditPeriods)
        .doc(_periodId(cardId, date.year, date.month));
    final today = DateTime.now();
    final currentPeriodRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditPeriods)
        .doc(_periodId(cardId, today.year, today.month));
    await _firebaseService.runTransaction((transaction) async {
      final cardSnapshot = await transaction.get(cardRef);
      final depositSnapshot = await transaction.get(depositRef);
      final periodSnapshot = await transaction.get(periodRef);
      final currentPeriodSnapshot = periodRef.path == currentPeriodRef.path
          ? periodSnapshot
          : await transaction.get(currentPeriodRef);
      final card = cardSnapshot.data();
      final currentDeposit = depositSnapshot.data();
      final period = periodSnapshot.data();
      if (!cardSnapshot.exists ||
          card == null ||
          currentDeposit == null ||
          period == null) {
        throw StateError('The deposit accounting data is incomplete.');
      }
      final oldAmount = _number(currentDeposit['amountMinor']);
      final difference = amountMinor - oldAmount;
      final qualifies = currentDeposit['qualifiesForMonthlyDebt'] == true;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (date.year == today.year && date.month == today.month) {
        final paid =
            _number(period['qualifyingDepositsMinor']) +
            (qualifies ? difference : 0);
        final remaining = (_number(period['openingDebtMinor']) - paid).clamp(
          0,
          1 << 62,
        );
        transaction.update(periodRef, {
          'qualifyingDepositsMinor': paid,
          'remainingDebtMinor': remaining,
          'closingBalanceMinor':
              _number(period['closingBalanceMinor']) + difference,
          'fullyPaid': remaining == 0,
          'updatedAtMillis': now,
        });
        transaction.update(cardRef, {
          'availableBalanceMinor':
              _number(card['availableBalanceMinor']) + difference,
          'currentMonthlyDebtMinor': remaining,
          'monthlyPaidMinor': paid,
          'updatedAtMillis': now,
        });
      } else {
        final currentPeriod =
            currentPeriodSnapshot.data() ??
            _periodData(
              cardId: cardId,
              year: today.year,
              month: today.month,
              card: card,
              existing: null,
            );
        transaction.set(currentPeriodRef, {
          ...currentPeriod,
          'closingBalanceMinor':
              _number(currentPeriod['closingBalanceMinor']) + difference,
          'correctionMinor':
              _number(currentPeriod['correctionMinor']) + difference,
          'updatedAtMillis': now,
        });
        transaction.update(cardRef, {
          'availableBalanceMinor':
              _number(card['availableBalanceMinor']) + difference,
          'updatedAtMillis': now,
        });
      }
      transaction.update(depositRef, {
        'amountMinor': amountMinor,
        'updatedAtMillis': now,
      });
      final correctionRef = _firebaseService
          .scopedCollectionRef(FirebaseCollections.creditCorrections)
          .doc();
      transaction.set(correctionRef, {
        'id': correctionRef.id,
        'sourceType': 'credit_deposit',
        'sourceId': depositId,
        'previousAmountMinor': oldAmount,
        'newAmountMinor': amountMinor,
        'differenceMinor': difference,
        'sourcePeriodId': periodRef.id,
        'correctionPeriodId': currentPeriodRef.id,
        'reason': reason.trim(),
        'createdBy': _firebaseService.currentUserId,
        'createdAtMillis': now,
        'updatedAtMillis': now,
      });
      transaction.set(
        _firebaseService
            .scopedCollectionRef(FirebaseCollections.auditLogs)
            .doc(),
        _audit(
          action: 'correct',
          entityType: 'credit_deposit',
          entityId: depositId,
          metadata: {
            'previousAmountMinor': oldAmount,
            'newAmountMinor': amountMinor,
            'reason': reason.trim(),
          },
        ),
      );
    });
  }

  @override
  Future<void> deletePurchase(String purchaseId) async {
    await _assertPurchaseNotSettled(purchaseId);
    final purchase = await _purchase(purchaseId);
    if (purchase['isDeleted'] == true) return;
    final cardId = '${purchase['cardId'] ?? ''}';
    final cardRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditCards)
        .doc(cardId);
    final purchaseRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditPurchases)
        .doc(purchaseId);
    final date = DateTime.fromMillisecondsSinceEpoch(
      _number(purchase['purchaseDateMillis']),
    );
    final periodRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditPeriods)
        .doc(_periodId(cardId, date.year, date.month));
    final today = DateTime.now();
    final currentPeriodRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.creditPeriods)
        .doc(_periodId(cardId, today.year, today.month));
    await _firebaseService.runTransaction((transaction) async {
      final cardSnapshot = await transaction.get(cardRef);
      final purchaseSnapshot = await transaction.get(purchaseRef);
      final periodSnapshot = await transaction.get(periodRef);
      final currentPeriodSnapshot = periodRef.path == currentPeriodRef.path
          ? periodSnapshot
          : await transaction.get(currentPeriodRef);
      final card = cardSnapshot.data();
      final currentPurchase = purchaseSnapshot.data();
      final period = periodSnapshot.data();
      if (!cardSnapshot.exists ||
          card == null ||
          currentPurchase == null ||
          period == null) {
        throw StateError('The purchase accounting data is incomplete.');
      }
      final amount = _number(currentPurchase['amountMinor']);
      final now = DateTime.now().millisecondsSinceEpoch;
      transaction.update(cardRef, {
        'availableBalanceMinor':
            _number(card['availableBalanceMinor']) + amount,
        'updatedAtMillis': now,
      });
      if (date.year == today.year && date.month == today.month) {
        transaction.update(periodRef, {
          'closingBalanceMinor':
              _number(period['closingBalanceMinor']) + amount,
          'updatedAtMillis': now,
        });
      } else {
        final currentPeriod =
            currentPeriodSnapshot.data() ??
            _periodData(
              cardId: cardId,
              year: today.year,
              month: today.month,
              card: card,
              existing: null,
            );
        transaction.set(currentPeriodRef, {
          ...currentPeriod,
          'closingBalanceMinor':
              _number(currentPeriod['closingBalanceMinor']) + amount,
          'correctionMinor': _number(currentPeriod['correctionMinor']) + amount,
          'updatedAtMillis': now,
        });
      }
      transaction.update(purchaseRef, {
        'isDeleted': true,
        'deletedBy': _firebaseService.currentUserId,
        'updatedAtMillis': now,
      });
      final correctionRef = _firebaseService
          .scopedCollectionRef(FirebaseCollections.creditCorrections)
          .doc();
      transaction.set(correctionRef, {
        'id': correctionRef.id,
        'sourceType': 'credit_purchase_delete',
        'sourceId': purchaseId,
        'sourcePeriodId': periodRef.id,
        'correctionPeriodId': currentPeriodRef.id,
        'differenceMinor': amount,
        'reason': 'Authorized credit purchase deletion',
        'createdBy': _firebaseService.currentUserId,
        'createdAtMillis': now,
        'updatedAtMillis': now,
      });
      transaction.set(
        _firebaseService
            .scopedCollectionRef(FirebaseCollections.auditLogs)
            .doc(),
        _audit(
          action: 'delete',
          entityType: 'credit_purchase',
          entityId: purchaseId,
          metadata: {'amountMinor': amount},
        ),
      );
    });
  }

  @override
  Future<void> saveProvider(PaymentProviderModel provider) {
    return _firebaseService.setDocument(
      collectionName: FirebaseCollections.paymentProviders,
      documentId: provider.id,
      data: provider.toJson(),
    );
  }

  @override
  Future<void> saveBrand(BrandModel brand) {
    return _firebaseService.setDocument(
      collectionName: FirebaseCollections.brands,
      documentId: brand.id,
      data: brand.toJson(),
    );
  }

  @override
  Future<void> savePosMachine(PosMachineModel machine) {
    return _firebaseService.setDocument(
      collectionName: FirebaseCollections.posMachines,
      documentId: machine.id,
      data: machine.toJson(),
    );
  }
}
