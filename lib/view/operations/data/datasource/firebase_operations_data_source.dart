import 'package:base/core/constants/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:base/core/services/services.dart';
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
import 'operations_data_source.dart';

class FirebaseOperationsDataSource implements OperationsDataSource {
  FirebaseOperationsDataSource(this._firebaseService, this._cacheService);
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
        // incremental-sync baseline. This can happen after browser storage
        // cleanup or when a new device/session restores preferences partially;
        // fall back to a full read so Firestore data is not shown as empty.
        query: lastSyncAt == null || cached == null || cached.isEmpty
            ? null
            // Include the sync boundary because a write and cache marker may
            // have the same millisecond timestamp.
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
  Future<List<TreasuryAccountModel>> getTreasuryAccounts() async => (await _get(
    FirebaseCollections.treasuryAccounts,
  )).map(TreasuryAccountModel.fromJson).where((e) => e.active).toList();
  @override
  Future<List<TreasuryMovementModel>> getTreasuryMovements() async =>
      (await _get(
        FirebaseCollections.treasuryMovements,
      )).map(TreasuryMovementModel.fromJson).toList();
  @override
  Future<List<TreasuryTransferModel>> getTreasuryTransfers() async =>
      (await _get(
        FirebaseCollections.treasuryTransfers,
      )).map(TreasuryTransferModel.fromJson).toList();
  @override
  Future<List<PersonalWithdrawalModel>> getPersonalWithdrawals() async =>
      (await _get(
        FirebaseCollections.personalWithdrawals,
      )).map(PersonalWithdrawalModel.fromJson).toList();
  @override
  Future<List<WithdrawalPersonModel>> getWithdrawalPeople() async =>
      (await _get(
        FirebaseCollections.withdrawalPeople,
      )).map(WithdrawalPersonModel.fromJson).toList();
  @override
  Future<List<TreasuryReconciliationModel>> getReconciliations() async =>
      (await _get(
        FirebaseCollections.treasuryReconciliations,
      )).map(TreasuryReconciliationModel.fromJson).toList();
  @override
  Future<List<ExpenseModel>> getExpenses() async => (await _get(
    FirebaseCollections.expenses,
  )).map(ExpenseModel.fromJson).toList();
  @override
  Future<List<ExpenseCategoryModel>> getExpenseCategories() async =>
      (await _get(
        FirebaseCollections.expenseCategories,
      )).map(ExpenseCategoryModel.fromJson).toList();
  @override
  Future<List<InstallmentAccountModel>> getInstallments() async => (await _get(
    FirebaseCollections.installmentAccounts,
  )).map(InstallmentAccountModel.fromJson).toList();
  @override
  Future<List<IssuedCheckModel>> getChecks() async => (await _get(
    FirebaseCollections.issuedChecks,
  )).map(IssuedCheckModel.fromJson).toList();
  @override
  Future<List<SettlementModel>> getSettlements() async => (await _get(
    FirebaseCollections.settlements,
  )).map(SettlementModel.fromJson).toList();
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
  Future<List<CollectionRequestModel>> getCollectionRequests() async =>
      (await _get(
        FirebaseCollections.collectionRequests,
      )).map(CollectionRequestModel.fromJson).toList();
  @override
  Future<List<BrandModel>> getBrands() async => (await _get(
    FirebaseCollections.brands,
  )).map(BrandModel.fromJson).where((e) => e.active).toList();
  @override
  Future<List<BankMovementModel>> getBankMovements() async => (await _get(
    FirebaseCollections.bankMovements,
  )).map(BankMovementModel.fromJson).toList();
  @override
  Future<List<InstallmentScheduleModel>> getInstallmentSchedules() async =>
      (await _get(
        FirebaseCollections.installmentSchedules,
      )).map(InstallmentScheduleModel.fromJson).toList();

  @override
  Future<void> saveTreasuryAccount(TreasuryAccountModel account) async {
    final accountRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.treasuryAccounts)
        .doc(account.id);
    final movementRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.treasuryMovements)
        .doc('${account.id}_opening');
    await _firebaseService.runTransaction((transaction) async {
      transaction.set(accountRef, account.toJson());
      if (account.openingBalanceMinor != 0) {
        transaction.set(movementRef, {
          'id': '${account.id}_opening',
          'accountId': account.id,
          'type': 'inflow',
          'amountMinor': account.openingBalanceMinor.abs(),
          'note': 'الرصيد الافتتاحي للخزينة',
          'createdBy': _firebaseService.currentUserId,
          'createdAtMillis': account.updatedAtMillis,
          'approvalStatus': 'approved',
          'approvedBy': _firebaseService.currentUserId,
          'approvedAtMillis': account.updatedAtMillis,
        });
      }
    });
  }

  @override
  Future<void> addTreasuryMovement(TreasuryMovementModel movement) async {
    final accountRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.treasuryAccounts)
        .doc(movement.accountId);
    final movementRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.treasuryMovements)
        .doc(movement.id);
    final delta = movement.type == 'outflow'
        ? -movement.amountMinor
        : movement.amountMinor;
    if (movement.approvalStatus == 'pending') {
      await movementRef.set(movement.toJson());
      return;
    }
    await _firebaseService.runTransaction((transaction) async {
      final snapshot = await transaction.get(accountRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('حساب الخزينة غير موجود.');
      }
      final balance = (snapshot.data()!['balanceMinor'] as num? ?? 0).toInt();
      if (movement.amountMinor <= 0 || balance + delta < 0) {
        throw StateError('لا يكفي رصيد الخزينة لتنفيذ الحركة.');
      }
      transaction.update(accountRef, {
        'balanceMinor': balance + delta,
        'updatedAtMillis': movement.createdAtMillis,
      });
      transaction.set(movementRef, movement.toJson());
    });
  }

  @override
  Future<void> approveTreasuryMovement(String movementId) async {
    final movementRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.treasuryMovements)
        .doc(movementId);
    await _firebaseService.runTransaction((transaction) async {
      final movementSnapshot = await transaction.get(movementRef);
      if (!movementSnapshot.exists || movementSnapshot.data() == null) {
        throw StateError('حركة الخزينة غير موجودة.');
      }
      final movement = movementSnapshot.data()!;
      if (movement['approvalStatus'] == 'approved') return;
      final accountId = movement['accountId'] as String? ?? '';
      final accountRef = _firebaseService
          .scopedCollectionRef(FirebaseCollections.treasuryAccounts)
          .doc(accountId);
      final accountSnapshot = await transaction.get(accountRef);
      if (!accountSnapshot.exists || accountSnapshot.data() == null) {
        throw StateError('حساب الخزينة غير موجود.');
      }
      final balance = (accountSnapshot.data()!['balanceMinor'] as num? ?? 0)
          .toInt();
      final amount = (movement['amountMinor'] as num? ?? 0).toInt();
      final type = movement['type'] as String? ?? 'inflow';
      final delta = type == 'outflow' ? -amount : amount;
      if (amount <= 0 || balance + delta < 0) {
        throw StateError('لا يكفي رصيد الخزينة لاعتماد الحركة.');
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      transaction.update(accountRef, {
        'balanceMinor': balance + delta,
        'updatedAtMillis': now,
      });
      transaction.update(movementRef, {
        'approvalStatus': 'approved',
        'approvedBy': _firebaseService.currentUserId,
        'approvedAtMillis': now,
      });
    });
  }

  @override
  Future<void> addBankMovement(BankMovementModel movement) async {
    final accountRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.bankAccounts)
        .doc(movement.accountId);
    final movementRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.bankMovements)
        .doc(movement.id);
    if (movement.approvalStatus == 'pending') {
      await movementRef.set(movement.toJson());
      return;
    }
    await _firebaseService.runTransaction((transaction) async {
      final accountSnapshot = await transaction.get(accountRef);
      if (!accountSnapshot.exists || accountSnapshot.data() == null) {
        throw StateError('الحساب البنكي غير موجود.');
      }
      final balance = (accountSnapshot.data()!['balanceMinor'] as num? ?? 0)
          .toInt();
      if (movement.amountMinor <= 0) {
        throw StateError('مبلغ الحركة البنكية يجب أن يكون موجباً.');
      }
      final isOutflow =
          movement.type.endsWith('outflow') || movement.type == 'withdrawal';
      final nextBalance = isOutflow
          ? balance - movement.amountMinor
          : balance + movement.amountMinor;
      if (nextBalance < 0) {
        throw StateError('لا يمكن أن يصبح رصيد الحساب البنكي سالباً.');
      }
      transaction.update(accountRef, {
        'balanceMinor': nextBalance,
        'updatedAtMillis': movement.updatedAtMillis ?? movement.createdAtMillis,
      });
      transaction.set(movementRef, movement.toJson());
    });
  }

  @override
  Future<void> approveBankMovement(String movementId) async {
    final movementRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.bankMovements)
        .doc(movementId);
    await _firebaseService.runTransaction((transaction) async {
      final movementSnapshot = await transaction.get(movementRef);
      if (!movementSnapshot.exists || movementSnapshot.data() == null) {
        throw StateError('الحركة البنكية غير موجودة.');
      }
      final movement = BankMovementModel.fromJson({
        'id': movementSnapshot.id,
        ...movementSnapshot.data()!,
      });
      if (movement.approvalStatus == 'approved') return;
      if (movement.approvalStatus != 'pending') {
        throw StateError('يمكن اعتماد الحركات البنكية المعلقة فقط.');
      }
      final accountRef = _firebaseService
          .scopedCollectionRef(FirebaseCollections.bankAccounts)
          .doc(movement.accountId);
      final accountSnapshot = await transaction.get(accountRef);
      if (!accountSnapshot.exists || accountSnapshot.data() == null) {
        throw StateError('الحساب البنكي غير موجود.');
      }
      final balance = (accountSnapshot.data()!['balanceMinor'] as num? ?? 0)
          .toInt();
      final isOutflow =
          movement.type.endsWith('outflow') || movement.type == 'withdrawal';
      final nextBalance = isOutflow
          ? balance - movement.amountMinor
          : balance + movement.amountMinor;
      if (nextBalance < 0) {
        throw StateError('لا يمكن أن يصبح رصيد الحساب البنكي سالباً.');
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      transaction.update(accountRef, {
        'balanceMinor': nextBalance,
        'updatedAtMillis': now,
      });
      transaction.update(movementRef, {
        'approvalStatus': 'approved',
        'approvedBy': _firebaseService.currentUserId,
        'approvedAtMillis': now,
        'updatedAtMillis': now,
      });
    });
  }

  @override
  Future<void> rejectPendingOperation({
    required String entityType,
    required String entityId,
    required String reason,
  }) async {
    const definitions = <String, (String, String)>{
      'credit_deposit': (FirebaseCollections.creditDeposits, 'approvalStatus'),
      'bank_movement': (FirebaseCollections.bankMovements, 'approvalStatus'),
      'treasury_movement': (
        FirebaseCollections.treasuryMovements,
        'approvalStatus',
      ),
      'expense': (FirebaseCollections.expenses, 'status'),
      'personal_withdrawal': (
        FirebaseCollections.personalWithdrawals,
        'status',
      ),
      'treasury_transfer': (FirebaseCollections.treasuryTransfers, 'status'),
    };
    final definition = definitions[entityType];
    if (definition == null || reason.trim().isEmpty) {
      throw StateError('نوع المعاملة أو سبب الرفض غير صحيح.');
    }
    final reference = _firebaseService
        .scopedCollectionRef(definition.$1)
        .doc(entityId);
    await _firebaseService.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('المعاملة المعلقة غير موجودة.');
      }
      final data = snapshot.data()!;
      final currentStatus = data[definition.$2];
      if (currentStatus == 'approved' || currentStatus == 'rejected') return;
      if (currentStatus != 'pending') {
        throw StateError('يمكن رفض المعاملات المعلقة فقط.');
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      transaction.update(reference, {
        definition.$2: 'rejected',
        'rejectionReason': reason.trim(),
        'rejectedBy': _firebaseService.currentUserId,
        'rejectedAtMillis': now,
        'updatedAtMillis': now,
      });
    });
  }

  @override
  Future<void> addTreasuryTransfer(TreasuryTransferModel transfer) async {
    CollectionReference<Map<String, dynamic>> accounts(String type) =>
        _firebaseService.scopedCollectionRef(
          type == 'bank'
              ? FirebaseCollections.bankAccounts
              : FirebaseCollections.treasuryAccounts,
        );
    final sourceRef = accounts(
      transfer.sourceAccountType,
    ).doc(transfer.sourceAccountId);
    final destinationRef = accounts(
      transfer.destinationAccountType,
    ).doc(transfer.destinationAccountId);
    final transferRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.treasuryTransfers)
        .doc(transfer.id);
    if (transfer.status == 'pending') {
      await transferRef.set(transfer.toJson());
      return;
    }
    await _firebaseService.runTransaction((transaction) async {
      final source = await transaction.get(sourceRef);
      final destination = await transaction.get(destinationRef);
      if (!source.exists ||
          source.data() == null ||
          !destination.exists ||
          destination.data() == null) {
        throw StateError('حسابات التحويل غير موجودة.');
      }
      final sourceBalance = (source.data()!['balanceMinor'] as num? ?? 0)
          .toInt();
      final destinationBalance =
          (destination.data()!['balanceMinor'] as num? ?? 0).toInt();
      final nextSource =
          sourceBalance - transfer.amountMinor - transfer.feeMinor;
      if (nextSource < 0) {
        throw StateError('لا يكفي رصيد الحساب لتنفيذ التحويل.');
      }
      transaction.update(sourceRef, {
        'balanceMinor': nextSource,
        'updatedAtMillis': transfer.createdAtMillis,
      });
      transaction.update(destinationRef, {
        'balanceMinor': destinationBalance + transfer.amountMinor,
        'updatedAtMillis': transfer.createdAtMillis,
      });
      final now = DateTime.now().millisecondsSinceEpoch;
      if (transfer.sourceAccountType == 'bank') {
        final movementRef = _firebaseService
            .scopedCollectionRef(FirebaseCollections.bankMovements)
            .doc('${transfer.id}_source');
        transaction.set(movementRef, {
          'id': movementRef.id,
          'accountId': transfer.sourceAccountId,
          'type': 'transfer_outflow',
          'amountMinor': transfer.amountMinor + transfer.feeMinor,
          'referenceType': 'treasury_transfer',
          'referenceId': transfer.id,
          'note': 'تحويل داخلي صادر',
          'createdBy': _firebaseService.currentUserId,
          'createdAtMillis': now,
          'updatedAtMillis': now,
          'approvalStatus': 'approved',
          'approvedBy': _firebaseService.currentUserId,
          'approvedAtMillis': now,
        });
      }
      if (transfer.destinationAccountType == 'bank') {
        final movementRef = _firebaseService
            .scopedCollectionRef(FirebaseCollections.bankMovements)
            .doc('${transfer.id}_destination');
        transaction.set(movementRef, {
          'id': movementRef.id,
          'accountId': transfer.destinationAccountId,
          'type': 'transfer_inflow',
          'amountMinor': transfer.amountMinor,
          'referenceType': 'treasury_transfer',
          'referenceId': transfer.id,
          'note': 'تحويل داخلي وارد',
          'createdBy': _firebaseService.currentUserId,
          'createdAtMillis': now,
          'updatedAtMillis': now,
          'approvalStatus': 'approved',
          'approvedBy': _firebaseService.currentUserId,
          'approvedAtMillis': now,
        });
      }
      transaction.set(transferRef, transfer.toJson());
    });
  }

  @override
  Future<void> approveTreasuryTransfer(String transferId) async {
    final transferRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.treasuryTransfers)
        .doc(transferId);
    await _firebaseService.runTransaction((transaction) async {
      final transferSnapshot = await transaction.get(transferRef);
      if (!transferSnapshot.exists || transferSnapshot.data() == null) {
        throw StateError('حركة التحويل غير موجودة.');
      }
      final transfer = TreasuryTransferModel.fromJson({
        'id': transferSnapshot.id,
        ...transferSnapshot.data()!,
      });
      if (transfer.status == 'approved') return;
      CollectionReference<Map<String, dynamic>> accounts(String type) =>
          _firebaseService.scopedCollectionRef(
            type == 'bank'
                ? FirebaseCollections.bankAccounts
                : FirebaseCollections.treasuryAccounts,
          );
      final sourceRef = accounts(
        transfer.sourceAccountType,
      ).doc(transfer.sourceAccountId);
      final destinationRef = accounts(
        transfer.destinationAccountType,
      ).doc(transfer.destinationAccountId);
      final source = await transaction.get(sourceRef);
      final destination = await transaction.get(destinationRef);
      if (!source.exists ||
          source.data() == null ||
          !destination.exists ||
          destination.data() == null) {
        throw StateError('حسابات التحويل غير موجودة.');
      }
      final sourceBalance = (source.data()!['balanceMinor'] as num? ?? 0)
          .toInt();
      final destinationBalance =
          (destination.data()!['balanceMinor'] as num? ?? 0).toInt();
      final nextSource =
          sourceBalance - transfer.amountMinor - transfer.feeMinor;
      if (nextSource < 0) {
        throw StateError('لا يكفي رصيد الحساب لتنفيذ التحويل.');
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      transaction.update(sourceRef, {
        'balanceMinor': nextSource,
        'updatedAtMillis': now,
      });
      transaction.update(destinationRef, {
        'balanceMinor': destinationBalance + transfer.amountMinor,
        'updatedAtMillis': now,
      });
      transaction.update(transferRef, {
        'status': 'approved',
        'approvedBy': _firebaseService.currentUserId,
        'approvedAtMillis': now,
      });
      if (transfer.sourceAccountType == 'bank') {
        final movementRef = _firebaseService
            .scopedCollectionRef(FirebaseCollections.bankMovements)
            .doc('${transfer.id}_source');
        transaction.set(movementRef, {
          'id': movementRef.id,
          'accountId': transfer.sourceAccountId,
          'type': 'transfer_outflow',
          'amountMinor': transfer.amountMinor + transfer.feeMinor,
          'referenceType': 'treasury_transfer',
          'referenceId': transfer.id,
          'note': 'تحويل داخلي صادر',
          'createdBy': _firebaseService.currentUserId,
          'createdAtMillis': now,
          'updatedAtMillis': now,
          'approvalStatus': 'approved',
          'approvedBy': _firebaseService.currentUserId,
          'approvedAtMillis': now,
        });
      }
      if (transfer.destinationAccountType == 'bank') {
        final movementRef = _firebaseService
            .scopedCollectionRef(FirebaseCollections.bankMovements)
            .doc('${transfer.id}_destination');
        transaction.set(movementRef, {
          'id': movementRef.id,
          'accountId': transfer.destinationAccountId,
          'type': 'transfer_inflow',
          'amountMinor': transfer.amountMinor,
          'referenceType': 'treasury_transfer',
          'referenceId': transfer.id,
          'note': 'تحويل داخلي وارد',
          'createdBy': _firebaseService.currentUserId,
          'createdAtMillis': now,
          'updatedAtMillis': now,
          'approvalStatus': 'approved',
          'approvedBy': _firebaseService.currentUserId,
          'approvedAtMillis': now,
        });
      }
    });
  }

  @override
  Future<void> addPersonalWithdrawal(PersonalWithdrawalModel withdrawal) async {
    final accountRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.treasuryAccounts)
        .doc(withdrawal.accountId);
    final withdrawalRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.personalWithdrawals)
        .doc(withdrawal.id);
    if (withdrawal.status == 'pending') {
      await withdrawalRef.set(withdrawal.toJson());
      return;
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    await _firebaseService.runTransaction((transaction) async {
      final account = await transaction.get(accountRef);
      if (!account.exists || account.data() == null) {
        throw StateError('حساب الخزينة غير موجود.');
      }
      final balance = (account.data()!['balanceMinor'] as num? ?? 0).toInt();
      if (withdrawal.amountMinor <= 0 || balance < withdrawal.amountMinor) {
        throw StateError('لا يكفي رصيد الخزينة لتنفيذ السحب.');
      }
      transaction.update(accountRef, {
        'balanceMinor': balance - withdrawal.amountMinor,
        'updatedAtMillis': now,
      });
      transaction.set(withdrawalRef, {
        ...withdrawal.toJson(),
        'approvedBy': _firebaseService.currentUserId,
        'approvedAtMillis': now,
        'updatedAtMillis': now,
      });
    });
  }

  @override
  Future<void> approvePersonalWithdrawal(String withdrawalId) async {
    final withdrawalRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.personalWithdrawals)
        .doc(withdrawalId);
    await _firebaseService.runTransaction((transaction) async {
      final snapshot = await transaction.get(withdrawalRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('السحب الشخصي غير موجود.');
      }
      final withdrawal = PersonalWithdrawalModel.fromJson({
        'id': snapshot.id,
        ...snapshot.data()!,
      });
      if (withdrawal.status == 'approved') return;
      final accountRef = _firebaseService
          .scopedCollectionRef(FirebaseCollections.treasuryAccounts)
          .doc(withdrawal.accountId);
      final account = await transaction.get(accountRef);
      if (!account.exists || account.data() == null) {
        throw StateError('حساب الخزينة غير موجود.');
      }
      final balance = (account.data()!['balanceMinor'] as num? ?? 0).toInt();
      if (withdrawal.amountMinor <= 0 || balance < withdrawal.amountMinor) {
        throw StateError('لا يكفي رصيد الخزينة لاعتماد السحب.');
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      transaction.update(accountRef, {
        'balanceMinor': balance - withdrawal.amountMinor,
        'updatedAtMillis': now,
      });
      transaction.update(withdrawalRef, {
        'status': 'approved',
        'approvedBy': _firebaseService.currentUserId,
        'approvedAtMillis': now,
      });
    });
  }

  @override
  Future<void> addReconciliation(
    TreasuryReconciliationModel reconciliation,
  ) async {
    final accountRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.treasuryAccounts)
        .doc(reconciliation.accountId);
    final reconciliationRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.treasuryReconciliations)
        .doc(reconciliation.id);
    await _firebaseService.runTransaction((transaction) async {
      final accountSnapshot = await transaction.get(accountRef);
      if (!accountSnapshot.exists || accountSnapshot.data() == null) {
        throw StateError('حساب الخزينة غير موجود.');
      }
      final current = (accountSnapshot.data()!['balanceMinor'] as num? ?? 0)
          .toInt();
      final adjustment = reconciliation.actualMinor - current;
      final now = DateTime.now().millisecondsSinceEpoch;
      final movementId = '${reconciliation.id}_adjustment';
      if (adjustment != 0) {
        final movementRef = _firebaseService
            .scopedCollectionRef(FirebaseCollections.treasuryMovements)
            .doc(movementId);
        transaction.set(movementRef, {
          'id': movementId,
          'accountId': reconciliation.accountId,
          'type': adjustment > 0 ? 'inflow' : 'outflow',
          'amountMinor': adjustment.abs(),
          'referenceType': 'reconciliation',
          'referenceId': reconciliation.id,
          'note': 'تعديل مطابقة: ${reconciliation.reason}',
          'createdBy': reconciliation.createdBy,
          'createdAtMillis': now,
          'approvalStatus': 'approved',
          'approvedBy': reconciliation.createdBy,
          'approvedAtMillis': now,
        });
      }
      transaction.update(accountRef, {
        'balanceMinor': reconciliation.actualMinor,
        'updatedAtMillis': now,
      });
      transaction.set(reconciliationRef, {
        ...reconciliation.toJson(),
        'beforeBalanceMinor': current,
        'afterBalanceMinor': reconciliation.actualMinor,
        'adjustmentMovementId': adjustment == 0 ? '' : movementId,
      });
    });
  }

  @override
  Future<void> addExpense(ExpenseModel expense) async {
    final expenseRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.expenses)
        .doc(expense.id);
    if (expense.status == 'pending') {
      await expenseRef.set(expense.toJson());
      return;
    }
    final accountRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.treasuryAccounts)
        .doc(expense.accountId);
    await _firebaseService.runTransaction((transaction) async {
      final accountSnapshot = await transaction.get(accountRef);
      if (!accountSnapshot.exists || accountSnapshot.data() == null) {
        throw StateError('حساب الخزينة غير موجود.');
      }
      final balance = (accountSnapshot.data()!['balanceMinor'] as num? ?? 0)
          .toInt();
      if (expense.amountMinor <= 0 || balance < expense.amountMinor) {
        throw StateError('لا يكفي رصيد الخزينة لتسجيل المصروف.');
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      transaction.update(accountRef, {
        'balanceMinor': balance - expense.amountMinor,
        'updatedAtMillis': now,
      });
      transaction.set(expenseRef, expense.toJson());
    });
  }

  @override
  Future<void> saveExpenseCategory(ExpenseCategoryModel category) =>
      _firebaseService.setDocument(
        collectionName: FirebaseCollections.expenseCategories,
        documentId: category.id,
        data: category.toJson(),
      );

  @override
  Future<void> saveWithdrawalPerson(WithdrawalPersonModel person) =>
      _firebaseService.setDocument(
        collectionName: FirebaseCollections.withdrawalPeople,
        documentId: person.id,
        data: person.toJson(),
      );

  @override
  Future<void> approveExpense(String expenseId) async {
    final expenseRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.expenses)
        .doc(expenseId);
    await _firebaseService.runTransaction((transaction) async {
      final expenseSnapshot = await transaction.get(expenseRef);
      if (!expenseSnapshot.exists || expenseSnapshot.data() == null) {
        throw StateError('المصروف غير موجود.');
      }
      final expense = expenseSnapshot.data()!;
      if (expense['status'] == 'approved') return;
      final accountId = expense['accountId'] as String? ?? '';
      final accountRef = _firebaseService
          .scopedCollectionRef(FirebaseCollections.treasuryAccounts)
          .doc(accountId);
      final accountSnapshot = await transaction.get(accountRef);
      if (!accountSnapshot.exists || accountSnapshot.data() == null) {
        throw StateError('حساب الخزينة غير موجود.');
      }
      final balance = (accountSnapshot.data()!['balanceMinor'] as num? ?? 0)
          .toInt();
      final amount = (expense['amountMinor'] as num? ?? 0).toInt();
      if (expense['status'] != 'pending') {
        throw StateError('يمكن اعتماد المصروفات المعلقة فقط.');
      }
      if (amount <= 0 || balance < amount) {
        throw StateError('لا يكفي رصيد الخزينة لاعتماد المصروف.');
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      transaction.update(accountRef, {
        'balanceMinor': balance - amount,
        'updatedAtMillis': now,
      });
      transaction.update(expenseRef, {
        'status': 'approved',
        'approvedAtMillis': now,
        'updatedAtMillis': now,
      });
    });
  }

  @override
  Future<void> saveInstallment(InstallmentAccountModel account) async {
    final accountRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.installmentAccounts)
        .doc(account.id);
    final scheduleRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.installmentSchedules)
        .doc('${account.id}_schedule');
    await _firebaseService.runTransaction((transaction) async {
      transaction.set(accountRef, account.toJson());
      transaction.set(scheduleRef, {
        'id': '${account.id}_schedule',
        'accountId': account.id,
        'description': account.reference,
        'principalMinor': account.principalMinor,
        'totalDueMinor': account.totalDueMinor,
        'monthlyAmountMinor': account.monthlyInstallmentMinor,
        'totalInstallments': account.totalInstallments,
        'paidInstallments': account.paidInstallments,
        'nextDueMillis': account.nextDueMillis,
        'status': account.status,
        'createdAtMillis': account.createdAtMillis,
      });
    });
  }

  @override
  Future<void> updateInstallmentAccount({
    required String accountId,
    required String customerName,
    required String reference,
    String? status,
  }) async {
    final accountRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.installmentAccounts)
        .doc(accountId);
    final scheduleRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.installmentSchedules)
        .doc('${accountId}_schedule');
    await _firebaseService.runTransaction((transaction) async {
      final snapshot = await transaction.get(accountRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('حساب التقسيط غير موجود.');
      }
      final current = snapshot.data()!;
      final currentStatus = current['status'] as String? ?? 'active';
      final nextStatus = status ?? currentStatus;
      if (!{'active', 'archived', 'settled'}.contains(nextStatus)) {
        throw StateError('حالة حساب التقسيط غير صحيحة.');
      }
      if (currentStatus == 'settled' && nextStatus == 'active') {
        throw StateError('لا يمكن إعادة فتح حساب تقسيط مكتمل.');
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      transaction.update(accountRef, {
        'customerName': customerName.trim(),
        'reference': reference.trim(),
        'status': nextStatus,
        'updatedAtMillis': now,
      });
      final scheduleSnapshot = await transaction.get(scheduleRef);
      if (scheduleSnapshot.exists) {
        transaction.update(scheduleRef, {
          'status': nextStatus,
          'updatedAtMillis': now,
        });
      }
    });
  }

  @override
  Future<void> saveInstallmentSchedule(
    InstallmentScheduleModel schedule,
  ) async {
    final accountRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.installmentAccounts)
        .doc(schedule.accountId);
    final scheduleRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.installmentSchedules)
        .doc(schedule.id);
    await _firebaseService.runTransaction((transaction) async {
      final accountSnapshot = await transaction.get(accountRef);
      if (!accountSnapshot.exists || accountSnapshot.data() == null) {
        throw StateError('حساب التقسيط غير موجود.');
      }
      final data = accountSnapshot.data()!;
      final totalDue = (data['totalDueMinor'] as num? ?? 0).toInt();
      final monthly = (data['monthlyInstallmentMinor'] as num? ?? 0).toInt();
      final installments = (data['totalInstallments'] as num? ?? 0).toInt();
      transaction.update(accountRef, {
        'totalDueMinor': totalDue + schedule.totalDueMinor,
        'monthlyInstallmentMinor': monthly + schedule.monthlyAmountMinor,
        'totalInstallments': installments + schedule.totalInstallments,
        'status': 'active',
      });
      transaction.set(scheduleRef, schedule.toJson());
    });
  }

  @override
  Future<void> addInstallmentPayment({
    required String id,
    required String accountId,
    required int amountMinor,
    required int nextDueMillis,
    String? scheduleId,
  }) async {
    final ref = _firebaseService
        .scopedCollectionRef(FirebaseCollections.installmentAccounts)
        .doc(id);
    final treasuryRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.treasuryAccounts)
        .doc(accountId);
    await _firebaseService.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('حساب التقسيط غير موجود.');
      }
      final treasurySnapshot = await transaction.get(treasuryRef);
      if (!treasurySnapshot.exists || treasurySnapshot.data() == null) {
        throw StateError('حساب مصدر دفع القسط غير موجود.');
      }
      final data = snapshot.data()!;
      if (amountMinor <= 0 ||
          data['status'] == 'settled' ||
          data['status'] == 'archived') {
        throw StateError('لا يمكن تسجيل دفعة لهذا الحساب.');
      }
      final treasuryBalance =
          (treasurySnapshot.data()!['balanceMinor'] as num? ?? 0).toInt();
      if (treasuryBalance < amountMinor) {
        throw StateError('الرصيد المتاح لا يكفي لتسجيل دفعة القسط.');
      }
      final paid = (data['paidMinor'] as num? ?? 0).toInt() + amountMinor;
      final total = (data['totalDueMinor'] as num? ?? 0).toInt();
      if (paid > total) {
        throw StateError('قيمة الدفعة تتجاوز المتبقي على الحساب.');
      }
      final paidInstallments =
          (data['paidInstallments'] as num? ?? 0).toInt() + 1;
      final paymentId = '${id}_${DateTime.now().millisecondsSinceEpoch}';
      final paymentRef = _firebaseService
          .scopedCollectionRef(FirebaseCollections.installmentPayments)
          .doc(paymentId);
      final scheduleRef = _firebaseService
          .scopedCollectionRef(FirebaseCollections.installmentSchedules)
          .doc(scheduleId ?? '${id}_schedule');
      final scheduleSnapshot = await transaction.get(scheduleRef);
      transaction.update(ref, {
        'paidMinor': paid,
        'nextDueMillis': nextDueMillis,
        'status': paid >= total ? 'settled' : 'active',
        'paidInstallments': paidInstallments,
        'availableMinor':
            (data['availableMinor'] as num? ?? 0).toInt() + amountMinor,
      });
      transaction.update(treasuryRef, {
        'balanceMinor': treasuryBalance - amountMinor,
        'updatedAtMillis': DateTime.now().millisecondsSinceEpoch,
      });
      final movementId = '${paymentId}_treasury_payment';
      final movementRef = _firebaseService
          .scopedCollectionRef(FirebaseCollections.treasuryMovements)
          .doc(movementId);
      transaction.set(movementRef, {
        'id': movementId,
        'accountId': accountId,
        'type': 'outflow',
        'amountMinor': amountMinor,
        'referenceType': 'installment_payment',
        'referenceId': paymentId,
        'note': 'دفعة تقسيط للحساب $id',
        'createdBy': _firebaseService.currentUserId,
        'createdAtMillis': DateTime.now().millisecondsSinceEpoch,
        'approvalStatus': 'approved',
        'approvedBy': _firebaseService.currentUserId,
        'approvedAtMillis': DateTime.now().millisecondsSinceEpoch,
      });
      transaction.set(paymentRef, {
        'id': paymentId,
        'installmentAccountId': id,
        'amountMinor': amountMinor,
        'paidAtMillis': DateTime.now().millisecondsSinceEpoch,
        'nextDueMillis': nextDueMillis,
        'createdBy': _firebaseService.currentUserId,
      });
      if (scheduleSnapshot.exists && scheduleSnapshot.data() != null) {
        final schedule = scheduleSnapshot.data()!;
        final schedulePaid =
            (schedule['paidInstallments'] as num? ?? 0).toInt() + 1;
        final scheduleTotal = (schedule['totalInstallments'] as num? ?? 0)
            .toInt();
        transaction.update(scheduleRef, {
          'paidInstallments': schedulePaid,
          'nextDueMillis': nextDueMillis,
          'status': scheduleTotal > 0 && schedulePaid >= scheduleTotal
              ? 'settled'
              : 'active',
        });
      }
    });
  }

  @override
  Future<void> saveCheck(IssuedCheckModel check) =>
      _firebaseService.setDocument(
        collectionName: FirebaseCollections.issuedChecks,
        documentId: check.id,
        data: check.toJson(),
      );

  @override
  Future<void> updateCheckStatus({
    required String checkId,
    required String status,
  }) async {
    final checkRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.issuedChecks)
        .doc(checkId);
    await _firebaseService.runTransaction((transaction) async {
      final checkSnapshot = await transaction.get(checkRef);
      if (!checkSnapshot.exists || checkSnapshot.data() == null) {
        throw StateError('الشيك غير موجود.');
      }
      final check = IssuedCheckModel.fromJson({
        'id': checkSnapshot.id,
        ...checkSnapshot.data()!,
      });
      if (check.status == status || check.status == 'archived') return;
      final now = DateTime.now().millisecondsSinceEpoch;
      if (status == 'deducted' && check.status != 'deducted') {
        final bankRef = _firebaseService
            .scopedCollectionRef(FirebaseCollections.bankAccounts)
            .doc(check.accountId);
        final bankSnapshot = await transaction.get(bankRef);
        if (!bankSnapshot.exists || bankSnapshot.data() == null) {
          throw StateError('الحساب البنكي المصدر للشيك غير موجود.');
        }
        final balance = (bankSnapshot.data()!['balanceMinor'] as num? ?? 0)
            .toInt();
        if (check.amountMinor <= 0 || balance < check.amountMinor) {
          throw StateError('لا يكفي رصيد الحساب البنكي لخصم الشيك.');
        }
        transaction.update(bankRef, {
          'balanceMinor': balance - check.amountMinor,
          'updatedAtMillis': now,
        });
        transaction.update(checkRef, {
          'status': 'deducted',
          'deductionDateMillis': now,
        });
        final movementId = '${checkId}_bank_deduction';
        final movementRef = _firebaseService
            .scopedCollectionRef(FirebaseCollections.bankMovements)
            .doc(movementId);
        transaction.set(movementRef, {
          'id': movementId,
          'accountId': check.accountId,
          'type': 'check_outflow',
          'amountMinor': check.amountMinor,
          'referenceType': 'issued_check',
          'referenceId': checkId,
          'note': 'خصم شيك صادر',
          'createdBy': _firebaseService.currentUserId,
          'createdAtMillis': now,
          'approvalStatus': 'approved',
        });
        return;
      }
      transaction.update(checkRef, {'status': status});
    });
  }

  @override
  Future<void> saveSettlement(SettlementModel settlement) =>
      _firebaseService.setDocument(
        collectionName: FirebaseCollections.settlements,
        documentId: settlement.id,
        data: settlement.toJson(),
      );

  @override
  Future<void> createSettlement({
    required String settlementId,
    required String brandId,
    required String periodLabel,
    required List<String> includedTransactionIds,
  }) async {
    if (includedTransactionIds.isEmpty ||
        includedTransactionIds.toSet().length !=
            includedTransactionIds.length) {
      throw StateError('يجب اختيار معاملات شراء فريدة للتسوية.');
    }
    final settlementRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.settlements)
        .doc(settlementId);
    final brandRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.brands)
        .doc(brandId);
    final purchaseRefs = includedTransactionIds
        .map(
          (id) => _firebaseService
              .scopedCollectionRef(FirebaseCollections.creditPurchases)
              .doc(id),
        )
        .toList();
    final allocationRefs = includedTransactionIds
        .map(
          (id) => _firebaseService
              .scopedCollectionRef(FirebaseCollections.settlementAllocations)
              .doc(id),
        )
        .toList();
    await _firebaseService.runTransaction((transaction) async {
      final existing = await transaction.get(settlementRef);
      if (existing.exists) return;
      final brandSnapshot = await transaction.get(brandRef);
      if (!brandSnapshot.exists || brandSnapshot.data()?['active'] != true) {
        throw StateError('العلامة التجارية غير نشطة.');
      }
      final purchaseSnapshots = <DocumentSnapshot<Map<String, dynamic>>>[];
      final allocationSnapshots = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final ref in purchaseRefs) {
        purchaseSnapshots.add(await transaction.get(ref));
      }
      for (final ref in allocationRefs) {
        allocationSnapshots.add(await transaction.get(ref));
      }
      var grossMinor = 0;
      var commissionMinor = 0;
      final sourceAllocations = <Map<String, dynamic>>[];
      for (var index = 0; index < purchaseSnapshots.length; index++) {
        final purchase = purchaseSnapshots[index];
        if (!purchase.exists || purchase.data() == null) {
          throw StateError('معاملة شراء التسوية غير موجودة.');
        }
        final data = purchase.data()!;
        if (data['isDeleted'] == true || data['brandId'] != brandId) {
          throw StateError('معاملة الشراء غير صالحة لهذه العلامة.');
        }
        if (allocationSnapshots[index].exists) {
          throw StateError('معاملة الشراء مخصصة لتسوية أخرى.');
        }
        final sourceGross = (data['amountMinor'] as num? ?? 0).toInt();
        final sourceCommission = (data['commissionMinor'] as num? ?? 0).toInt();
        if (sourceGross <= 0 || sourceCommission < 0) {
          throw StateError('قيم معاملة الشراء غير صحيحة.');
        }
        grossMinor += sourceGross;
        commissionMinor += sourceCommission;
        sourceAllocations.add({
          'purchaseId': includedTransactionIds[index],
          'grossMinor': sourceGross,
          'commissionMinor': sourceCommission,
        });
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      final expectedDate = DateTime.fromMillisecondsSinceEpoch(now);
      final expectedCollectionDateMillis = DateTime(
        expectedDate.year,
        expectedDate.month,
        expectedDate.day + 1,
        11,
      ).millisecondsSinceEpoch;
      final brand = brandSnapshot.data()!;
      final settlement = {
        'id': settlementId,
        'providerId': brand['providerId'] ?? '',
        'providerName': brand['providerName'] ?? '',
        'brandId': brandId,
        'brandName': brand['name'] ?? '',
        'posMachineId': brand['posMachineId'] ?? '',
        'posMachineName': brand['posMachineName'] ?? '',
        'receivingCompanyId': brand['receivingCompanyId'] ?? '',
        'receivingCompanyName': brand['receivingCompanyName'] ?? '',
        'destinationBankAccountId': brand['settlementBankAccountId'] ?? '',
        'destinationBankAccountName': brand['settlementBankAccountName'] ?? '',
        'periodLabel': periodLabel.trim(),
        'grossMinor': grossMinor,
        'commissionMinor': commissionMinor,
        'netMinor': grossMinor - commissionMinor,
        'collectedMinor': 0,
        'requestedMinor': 0,
        'includedTransactionIds': includedTransactionIds,
        'sourceAllocations': sourceAllocations,
        'status': 'open',
        'approvalStatus': 'pending',
        'evidenceStatus': 'unavailable',
        'createdBy': _firebaseService.currentUserId,
        'createdAtMillis': now,
        'settlementDateMillis': now,
        'expectedCollectionDateMillis': expectedCollectionDateMillis,
        'updatedAtMillis': now,
      };
      transaction.set(settlementRef, settlement);
      for (var index = 0; index < allocationRefs.length; index++) {
        transaction.set(allocationRefs[index], {
          'id': allocationRefs[index].id,
          'settlementId': settlementId,
          'purchaseId': includedTransactionIds[index],
          ...sourceAllocations[index],
          'createdAtMillis': now,
          'createdBy': _firebaseService.currentUserId,
        });
      }
    });
  }

  @override
  Future<void> approveSettlement(String settlementId) async {
    final settlementRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.settlements)
        .doc(settlementId);
    await _firebaseService.runTransaction((transaction) async {
      final snapshot = await transaction.get(settlementRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('التسوية غير موجودة.');
      }
      final data = snapshot.data()!;
      if (data['createdBy'] == _firebaseService.currentUserId) {
        throw StateError('لا يمكن لمنشئ التسوية اعتمادها.');
      }
      if (data['approvalStatus'] == 'rejected') {
        throw StateError('لا يمكن اعتماد تسوية مرفوضة.');
      }
      if (data['approvalStatus'] == 'approved') return;
      transaction.update(settlementRef, {
        'approvalStatus': 'approved',
        'approvedBy': _firebaseService.currentUserId,
        'approvedAtMillis': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  @override
  Future<void> rejectSettlement({
    required String settlementId,
    required String reason,
  }) async {
    final settlementRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.settlements)
        .doc(settlementId);
    await _firebaseService.runTransaction((transaction) async {
      final snapshot = await transaction.get(settlementRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('التسوية غير موجودة.');
      }
      final data = snapshot.data()!;
      if (data['createdBy'] == _firebaseService.currentUserId) {
        throw StateError('لا يمكن لمنشئ التسوية رفضها.');
      }
      if (data['approvalStatus'] == 'approved') {
        throw StateError('لا يمكن رفض تسوية معتمدة.');
      }
      transaction.update(settlementRef, {
        'approvalStatus': 'rejected',
        'rejectionReason': reason.trim(),
        'rejectedBy': _firebaseService.currentUserId,
        'rejectedAtMillis': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  @override
  Future<void> saveBankAccount(BankAccountModel account) async {
    final accountRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.bankAccounts)
        .doc(account.id);
    final movementRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.bankMovements)
        .doc('${account.id}_opening');
    await _firebaseService.runTransaction((transaction) async {
      transaction.set(accountRef, account.toJson());
      if (account.openingBalanceMinor != 0) {
        transaction.set(movementRef, {
          'id': '${account.id}_opening',
          'accountId': account.id,
          'type': 'opening_balance',
          'amountMinor': account.openingBalanceMinor.abs(),
          'referenceType': 'bank_account',
          'referenceId': account.id,
          'note': 'الرصيد الافتتاحي للحساب البنكي',
          'createdBy': _firebaseService.currentUserId,
          'createdAtMillis': account.updatedAtMillis,
          'approvalStatus': 'approved',
          'approvedBy': _firebaseService.currentUserId,
          'approvedAtMillis': account.updatedAtMillis,
        });
      }
    });
  }

  @override
  Future<void> saveReceivingCompany(ReceivingCompanyModel company) =>
      _firebaseService.setDocument(
        collectionName: FirebaseCollections.receivingCompanies,
        documentId: company.id,
        data: company.toJson(),
      );

  @override
  Future<void> addBankAccountToReceivingCompany({
    required String companyId,
    required String bankAccountId,
  }) async {
    final companyRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.receivingCompanies)
        .doc(companyId);
    await _firebaseService.runTransaction((transaction) async {
      final snapshot = await transaction.get(companyRef);
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('شركة التحصيل غير موجودة.');
      }
      final data = snapshot.data()!;
      final existing = ((data['bankAccountIds'] as List?) ?? const [])
          .whereType<String>()
          .toSet();
      existing.add(bankAccountId);
      transaction.update(companyRef, {
        'bankAccountIds': existing.toList(),
        'updatedAtMillis': DateTime.now().millisecondsSinceEpoch,
      });
    });
  }

  @override
  Future<void> addCollectionRequest(CollectionRequestModel request) async {
    final settlementRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.settlements)
        .doc(request.settlementId);
    final requestRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.collectionRequests)
        .doc(request.id);
    await _firebaseService.runTransaction((transaction) async {
      final snapshot = await transaction.get(settlementRef);
      final existingRequest = await transaction.get(requestRef);
      if (existingRequest.exists) return;
      if (!snapshot.exists || snapshot.data() == null) {
        throw StateError('التسوية غير موجودة.');
      }
      final data = snapshot.data()!;
      if (data['approvalStatus'] != 'approved') {
        throw StateError('يجب اعتماد التسوية قبل طلب التحصيل.');
      }
      final collected = (data['collectedMinor'] as num? ?? 0).toInt();
      final requested = (data['requestedMinor'] as num? ?? 0).toInt();
      final gross = (data['grossMinor'] as num? ?? 0).toInt();
      if (collected + requested + request.amountMinor > gross) {
        throw StateError('قيمة التحصيل تتجاوز إجمالي التسوية.');
      }
      transaction.set(requestRef, request.toJson());
      transaction.update(settlementRef, {
        'requestedMinor': requested + request.amountMinor,
      });
    });
  }

  @override
  Future<void> confirmCollectionRequest({
    required String requestId,
    required String confirmationReference,
  }) async {
    final requestRef = _firebaseService
        .scopedCollectionRef(FirebaseCollections.collectionRequests)
        .doc(requestId);
    await _firebaseService.runTransaction((transaction) async {
      final requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists || requestSnapshot.data() == null) {
        throw StateError('طلب التحصيل غير موجود.');
      }
      final request = requestSnapshot.data()!;
      if (request['status'] == 'confirmed') return;
      if (request['status'] != 'pending') {
        throw StateError('يمكن تأكيد طلبات التحصيل المعلقة فقط.');
      }
      final settlementId = request['settlementId'] as String? ?? '';
      final settlementRef = _firebaseService
          .scopedCollectionRef(FirebaseCollections.settlements)
          .doc(settlementId);
      final settlementSnapshot = await transaction.get(settlementRef);
      if (!settlementSnapshot.exists || settlementSnapshot.data() == null) {
        throw StateError('التسوية غير موجودة.');
      }
      final settlement = settlementSnapshot.data()!;
      final collected = (settlement['collectedMinor'] as num? ?? 0).toInt();
      final requested = (settlement['requestedMinor'] as num? ?? 0).toInt();
      final amount = (request['amountMinor'] as num? ?? 0).toInt();
      final gross = (settlement['grossMinor'] as num? ?? 0).toInt();
      if (settlement['approvalStatus'] != 'approved' ||
          amount <= 0 ||
          amount > requested ||
          collected + amount > gross) {
        throw StateError('طلب التحصيل يتجاوز الرصيد المتاح للتسوية.');
      }
      final now = DateTime.now().millisecondsSinceEpoch;
      final destinationBankAccountId =
          settlement['destinationBankAccountId'] as String? ?? '';
      DocumentReference<Map<String, dynamic>>? bankAccountRef;
      DocumentSnapshot<Map<String, dynamic>>? bankAccountSnapshot;
      if (destinationBankAccountId.isNotEmpty) {
        bankAccountRef = _firebaseService
            .scopedCollectionRef(FirebaseCollections.bankAccounts)
            .doc(destinationBankAccountId);
        bankAccountSnapshot = await transaction.get(bankAccountRef);
      }
      transaction.update(requestRef, {
        'status': 'confirmed',
        'confirmationReference': confirmationReference.trim(),
        'confirmedBy': _firebaseService.currentUserId,
        'confirmedAtMillis': now,
        'updatedAtMillis': now,
      });
      transaction.update(settlementRef, {
        'collectedMinor': collected + amount,
        'requestedMinor': (requested - amount).clamp(0, requested),
        'status': collected + amount >= gross ? 'settled' : 'partial',
        'actualCollectionDateMillis': now,
      });
      if (bankAccountRef != null &&
          bankAccountSnapshot != null &&
          bankAccountSnapshot.exists) {
        final bankBalance =
            (bankAccountSnapshot.data()?['balanceMinor'] as num? ?? 0).toInt();
        final received = (request['netMinor'] as num? ?? amount).toInt();
        transaction.update(bankAccountRef, {
          'balanceMinor': bankBalance + received,
          'updatedAtMillis': DateTime.now().millisecondsSinceEpoch,
        });
        final movementId = '${requestId}_bank_collection';
        final movementRef = _firebaseService
            .scopedCollectionRef(FirebaseCollections.bankMovements)
            .doc(movementId);
        transaction.set(movementRef, {
          'id': movementId,
          'accountId': destinationBankAccountId,
          'type': 'collection_inflow',
          'amountMinor': received,
          'referenceType': 'collection_request',
          'referenceId': requestId,
          'note': 'تحصيل تسوية مؤكد',
          'createdBy': _firebaseService.currentUserId,
          'createdAtMillis': DateTime.now().millisecondsSinceEpoch,
          'approvalStatus': 'approved',
        });
      }
    });
  }
}
