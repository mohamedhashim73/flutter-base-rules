import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { setGlobalOptions } from 'firebase-functions/v2';
import * as admin from 'firebase-admin';

admin.initializeApp();
setGlobalOptions({ region: 'europe-west1', maxInstances: 10 });

const db = admin.firestore();
const allowedRoles = new Set(['manager', 'accountant', 'employee']);

type AuthenticatedRequest = {
  auth?: {
    uid: string;
    token: Record<string, unknown>;
  };
  data?: Record<string, unknown>;
};

function requireManager(request: AuthenticatedRequest) {
  const auth = requireAuthenticated(request);
  if (auth.token.role !== 'manager') {
    throw new HttpsError('permission-denied', 'Manager role is required.');
  }
  return auth;
}

function requireAuthenticated(request: AuthenticatedRequest) {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Authentication is required.');
  }
  return request.auth;
}

function requireReviewer(request: AuthenticatedRequest) {
  const auth = requireAuthenticated(request);
  if (
    auth.token.role !== 'manager' &&
    !(auth.token.permissions as Record<string, unknown> | undefined)?.[
      'settlements.review'
    ]
  ) {
    throw new HttpsError('permission-denied', 'Reviewer permission is required.');
  }
  return auth;
}

function requireFinanceOperator(request: AuthenticatedRequest) {
  const auth = requireAuthenticated(request);
  if (!allowedRoles.has(String(auth.token.role))) {
    throw new HttpsError('permission-denied', 'A finance role is required.');
  }
  return auth;
}

function callerOrganization(request: { auth?: { token: Record<string, unknown> } }) {
  const organizationId = request.auth?.token.organizationId;
  if (typeof organizationId !== 'string' || organizationId.length === 0) {
    throw new HttpsError('failed-precondition', 'The caller has no organization claim.');
  }
  return organizationId;
}

function stringValue(value: unknown, field: string) {
  if (typeof value !== 'string' || value.trim().length === 0) {
    throw new HttpsError('invalid-argument', `${field} is required.`);
  }
  return value.trim();
}

function permissionsValue(value: unknown) {
  if (value == null) return {};
  if (typeof value !== 'object' || Array.isArray(value)) {
    throw new HttpsError('invalid-argument', 'permissions must be an object.');
  }
  return value as Record<string, boolean>;
}

function integerValue(value: unknown, field: string, options?: { positive?: boolean }) {
  if (!Number.isInteger(value) || (options?.positive && (value as number) <= 0)) {
    throw new HttpsError(
      'invalid-argument',
      `${field} must be ${options?.positive ? 'a positive' : 'an'} integer.`,
    );
  }
  return value as number;
}

function tenantCollection(request: AuthenticatedRequest, collection: string) {
  const auth = requireAuthenticated(request);
  const organizationId = auth.token.organizationId;
  if (typeof organizationId === 'string' && organizationId.length > 0) {
    return db.collection(`organizations/${organizationId}/${collection}`);
  }
  return db.collection(`users/${auth.uid}/${collection}`);
}

function auditReference(request: AuthenticatedRequest) {
  return tenantCollection(request, 'audit_logs').doc();
}

function auditData(
  request: AuthenticatedRequest,
  action: string,
  entityType: string,
  entityId: string,
  previousValues: Record<string, unknown> | null,
  newValues: Record<string, unknown> | null,
  reason: string,
) {
  return {
    id: auditReference(request).id,
    action,
    entityType,
    entityId,
    previousValues,
    newValues,
    reason,
    createdBy: request.auth?.uid ?? '',
    createdAtMillis: Date.now(),
    source: 'trusted_backend',
  };
}

function stringList(value: unknown, field: string) {
  if (!Array.isArray(value) || value.some((item) => typeof item !== 'string')) {
    throw new HttpsError('invalid-argument', `${field} must be a list of strings.`);
  }
  return value as string[];
}

async function financeApprovalThreshold(request: AuthenticatedRequest) {
  const auth = requireAuthenticated(request);
  const organizationId = auth.token.organizationId;
  const path = typeof organizationId === 'string' && organizationId.length > 0
    ? `organizations/${organizationId}/system_settings/finance`
    : `users/${auth.uid}/system_settings/finance`;
  const snapshot = await db.doc(path).get();
  return Number(snapshot.data()?.approvalThresholdMinor ?? 500000);
}

function financialAccountCollection(type: unknown) {
  return type === 'bank' ? 'bank_accounts' : 'treasury_accounts';
}

export const recordTreasuryMovement = onCall(async (request) => {
  const auth = requireFinanceOperator(request);
  const movementId = stringValue(request.data?.movementId, 'movementId');
  const accountId = stringValue(request.data?.accountId, 'accountId');
  const type = request.data?.type === 'outflow' ? 'outflow' : 'inflow';
  const amount = integerValue(request.data?.amountMinor, 'amountMinor', { positive: true });
  const note = typeof request.data?.note === 'string' ? request.data.note.trim() : '';
  const relatedParty = typeof request.data?.relatedParty === 'string' ? request.data.relatedParty.trim() : '';
  const movementRef = tenantCollection(request, 'treasury_movements').doc(movementId);
  const accountRef = tenantCollection(request, 'treasury_accounts').doc(accountId);
  const threshold = await financeApprovalThreshold(request);
  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(movementRef);
    if (existing.exists) return;
    const accountSnapshot = await transaction.get(accountRef);
    if (!accountSnapshot.exists || !accountSnapshot.data()) throw new HttpsError('not-found', 'Treasury account was not found.');
    const manager = auth.token.role === 'manager';
    const approvalStatus = manager || amount <= threshold ? 'approved' : 'pending';
    const now = Date.now();
    const data = {
      id: movementId,
      accountId,
      type,
      amountMinor: amount,
      note,
      relatedParty,
      transactionDateMillis: Number(request.data?.transactionDateMillis ?? now),
      createdBy: auth.uid,
      createdAtMillis: now,
      updatedAtMillis: now,
      approvalStatus,
      ...(approvalStatus === 'approved' ? { approvedBy: auth.uid, approvedAtMillis: now } : {}),
    };
    if (approvalStatus === 'approved') {
      const balance = integerValue(accountSnapshot.data()!.balanceMinor ?? 0, 'balanceMinor');
      const delta = type === 'outflow' ? -amount : amount;
      if (balance + delta < 0) throw new HttpsError('failed-precondition', 'The treasury balance cannot become negative.');
      transaction.update(accountRef, { balanceMinor: balance + delta, updatedAtMillis: now });
    }
    transaction.set(movementRef, data);
    const audit = auditData(request, 'create', 'treasury_movement', movementId, null, data, approvalStatus === 'pending' ? 'Treasury movement submitted for approval.' : 'Treasury movement posted by trusted backend.');
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { movementId };
});

export const createTreasuryReconciliation = onCall(async (request) => {
  const auth = requireAuthenticated(request);
  const permissions = (auth.token.permissions as Record<string, unknown> | undefined) ?? {};
  if (auth.token.role !== 'manager' && permissions['treasury.reconcile'] !== true) {
    throw new HttpsError('permission-denied', 'Treasury reconciliation permission is required.');
  }
  const reconciliationId = stringValue(request.data?.reconciliationId, 'reconciliationId');
  const accountId = stringValue(request.data?.accountId, 'accountId');
  const expectedMinor = integerValue(request.data?.expectedMinor, 'expectedMinor');
  const actualMinor = integerValue(request.data?.actualMinor, 'actualMinor');
  if (actualMinor < 0) throw new HttpsError('invalid-argument', 'actualMinor cannot be negative.');
  const reason = stringValue(request.data?.reason, 'reason');
  const reconciliationRef = tenantCollection(request, 'treasury_reconciliations').doc(reconciliationId);
  const accountRef = tenantCollection(request, 'treasury_accounts').doc(accountId);
  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(reconciliationRef);
    if (existing.exists) return;
    const accountSnapshot = await transaction.get(accountRef);
    if (!accountSnapshot.exists || !accountSnapshot.data()) {
      throw new HttpsError('not-found', 'Treasury account was not found.');
    }
    const beforeBalanceMinor = integerValue(accountSnapshot.data()!.balanceMinor ?? 0, 'balanceMinor');
    const differenceMinor = actualMinor - expectedMinor;
    const adjustmentMinor = actualMinor - beforeBalanceMinor;
    const now = Date.now();
    let adjustmentMovementId = '';
    if (adjustmentMinor !== 0) {
      adjustmentMovementId = `${reconciliationId}_adjustment`;
      const movementRef = tenantCollection(request, 'treasury_movements').doc(adjustmentMovementId);
      const movement = {
        id: adjustmentMovementId,
        accountId,
        type: adjustmentMinor > 0 ? 'inflow' : 'outflow',
        amountMinor: Math.abs(adjustmentMinor),
        note: `Reconciliation adjustment: ${reason}`,
        createdBy: auth.uid,
        createdAtMillis: now,
        updatedAtMillis: now,
        approvalStatus: 'approved',
        approvedBy: auth.uid,
        approvedAtMillis: now,
      };
      transaction.set(movementRef, movement);
      const movementAudit = auditData(request, 'create', 'treasury_movement', adjustmentMovementId, null, movement, 'Reconciliation adjustment posted by trusted backend.');
      transaction.set(tenantCollection(request, 'audit_logs').doc(movementAudit.id as string), movementAudit);
    }
    transaction.update(accountRef, { balanceMinor: actualMinor, updatedAtMillis: now });
    const reconciliation = {
      id: reconciliationId,
      accountId,
      expectedMinor,
      actualMinor,
      differenceMinor,
      reason,
      createdBy: auth.uid,
      createdAtMillis: now,
      beforeBalanceMinor,
      afterBalanceMinor: actualMinor,
      adjustmentMovementId,
    };
    transaction.set(reconciliationRef, reconciliation);
    const audit = auditData(request, 'create', 'treasury_reconciliation', reconciliationId, { balanceMinor: beforeBalanceMinor }, reconciliation, 'Treasury reconciliation posted by trusted backend.');
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { reconciliationId };
});

export const recordBankMovement = onCall(async (request) => {
  const auth = requireFinanceOperator(request);
  const movementId = stringValue(request.data?.movementId, 'movementId');
  const accountId = stringValue(request.data?.accountId, 'accountId');
  const type = request.data?.type === 'withdrawal' ? 'withdrawal' : 'deposit';
  const amount = integerValue(request.data?.amountMinor, 'amountMinor', { positive: true });
  const note = typeof request.data?.note === 'string' ? request.data.note.trim() : '';
  const relatedParty = typeof request.data?.relatedParty === 'string' ? request.data.relatedParty.trim() : '';
  const movementRef = tenantCollection(request, 'bank_movements').doc(movementId);
  const accountRef = tenantCollection(request, 'bank_accounts').doc(accountId);
  const threshold = await financeApprovalThreshold(request);
  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(movementRef);
    if (existing.exists) return;
    const accountSnapshot = await transaction.get(accountRef);
    if (!accountSnapshot.exists || !accountSnapshot.data()) throw new HttpsError('not-found', 'Bank account was not found.');
    const manager = auth.token.role === 'manager';
    const approvalStatus = manager || amount <= threshold ? 'approved' : 'pending';
    const now = Date.now();
    const data = {
      id: movementId,
      accountId,
      type,
      amountMinor: amount,
      referenceType: 'manual',
      referenceId: movementId,
      note,
      relatedParty,
      createdBy: auth.uid,
      createdAtMillis: now,
      updatedAtMillis: now,
      approvalStatus,
      ...(approvalStatus === 'approved' ? { approvedBy: auth.uid, approvedAtMillis: now } : {}),
    };
    if (approvalStatus === 'approved') {
      const balance = integerValue(accountSnapshot.data()!.balanceMinor ?? 0, 'balanceMinor');
      if (type === 'withdrawal' && balance < amount) throw new HttpsError('failed-precondition', 'The bank balance cannot become negative.');
      transaction.update(accountRef, { balanceMinor: type === 'withdrawal' ? balance - amount : balance + amount, updatedAtMillis: now });
    }
    transaction.set(movementRef, data);
    const audit = auditData(request, 'create', 'bank_movement', movementId, null, data, approvalStatus === 'pending' ? 'Bank movement submitted for approval.' : 'Bank movement posted by trusted backend.');
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { movementId };
});

export const approveBankMovement = onCall(async (request) => {
  const auth = requireManager(request);
  const movementId = stringValue(request.data?.movementId, 'movementId');
  const movementRef = tenantCollection(request, 'bank_movements').doc(movementId);
  await db.runTransaction(async (transaction) => {
    const movementSnapshot = await transaction.get(movementRef);
    if (!movementSnapshot.exists || !movementSnapshot.data()) throw new HttpsError('not-found', 'Bank movement was not found.');
    const movement = movementSnapshot.data()!;
    if (movement.approvalStatus === 'approved') return;
    if (movement.approvalStatus !== 'pending') throw new HttpsError('failed-precondition', 'Only pending bank movements can be approved.');
    const accountRef = tenantCollection(request, 'bank_accounts').doc(stringValue(movement.accountId, 'accountId'));
    const accountSnapshot = await transaction.get(accountRef);
    if (!accountSnapshot.exists || !accountSnapshot.data()) throw new HttpsError('not-found', 'Bank account was not found.');
    const amount = integerValue(movement.amountMinor, 'amountMinor', { positive: true });
    const balance = integerValue(accountSnapshot.data()!.balanceMinor ?? 0, 'balanceMinor');
    if (movement.type === 'withdrawal' && balance < amount) throw new HttpsError('failed-precondition', 'The bank balance cannot become negative.');
    const now = Date.now();
    transaction.update(accountRef, { balanceMinor: movement.type === 'withdrawal' ? balance - amount : balance + amount, updatedAtMillis: now });
    transaction.update(movementRef, { approvalStatus: 'approved', approvedBy: auth.uid, approvedAtMillis: now, updatedAtMillis: now });
    const audit = auditData(request, 'approve', 'bank_movement', movementId, { approvalStatus: movement.approvalStatus, balanceMinor: balance }, { approvalStatus: 'approved', balanceMinor: movement.type === 'withdrawal' ? balance - amount : balance + amount }, 'Bank movement approved by manager.');
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { movementId, status: 'approved' };
});

export const createTreasuryTransfer = onCall(async (request) => {
  const auth = requireFinanceOperator(request);
  const transferId = stringValue(request.data?.transferId, 'transferId');
  const sourceId = stringValue(request.data?.sourceAccountId, 'sourceAccountId');
  const destinationId = stringValue(request.data?.destinationAccountId, 'destinationAccountId');
  const sourceType = request.data?.sourceAccountType === 'bank' ? 'bank' : 'treasury';
  const destinationType = request.data?.destinationAccountType === 'bank' ? 'bank' : 'treasury';
  if (sourceId === destinationId) throw new HttpsError('invalid-argument', 'Source and destination must differ.');
  const amount = integerValue(request.data?.amountMinor, 'amountMinor', { positive: true });
  const fee = integerValue(request.data?.feeMinor ?? 0, 'feeMinor');
  if (fee < 0) throw new HttpsError('invalid-argument', 'feeMinor cannot be negative.');
  const transferRef = tenantCollection(request, 'treasury_transfers').doc(transferId);
  const sourceRef = tenantCollection(request, financialAccountCollection(sourceType)).doc(sourceId);
  const destinationRef = tenantCollection(request, financialAccountCollection(destinationType)).doc(destinationId);
  const threshold = await financeApprovalThreshold(request);
  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(transferRef);
    if (existing.exists) return;
    const source = await transaction.get(sourceRef);
    const destination = await transaction.get(destinationRef);
    if (!source.exists || !source.data() || !destination.exists || !destination.data()) throw new HttpsError('not-found', 'Transfer accounts were not found.');
    const manager = auth.token.role === 'manager';
    const status = manager || amount <= threshold ? 'approved' : 'pending';
    const now = Date.now();
    if (status === 'approved') {
      const sourceBalance = integerValue(source.data()!.balanceMinor ?? 0, 'sourceBalance');
      if (sourceBalance < amount + fee) throw new HttpsError('failed-precondition', 'The source balance cannot cover the transfer.');
      const destinationBalance = integerValue(destination.data()!.balanceMinor ?? 0, 'destinationBalance');
      transaction.update(sourceRef, { balanceMinor: sourceBalance - amount - fee, updatedAtMillis: now });
      transaction.update(destinationRef, { balanceMinor: destinationBalance + amount, updatedAtMillis: now });
      if (sourceType === 'bank') {
        const movementRef = tenantCollection(request, 'bank_movements').doc(`${transferId}_source`);
        transaction.set(movementRef, { id: movementRef.id, accountId: sourceId, type: 'transfer_outflow', amountMinor: amount + fee, referenceType: 'treasury_transfer', referenceId: transferId, note: 'Internal transfer out', createdBy: auth.uid, createdAtMillis: now, updatedAtMillis: now, approvalStatus: 'approved', approvedBy: auth.uid, approvedAtMillis: now });
      }
      if (destinationType === 'bank') {
        const movementRef = tenantCollection(request, 'bank_movements').doc(`${transferId}_destination`);
        transaction.set(movementRef, { id: movementRef.id, accountId: destinationId, type: 'transfer_inflow', amountMinor: amount, referenceType: 'treasury_transfer', referenceId: transferId, note: 'Internal transfer in', createdBy: auth.uid, createdAtMillis: now, updatedAtMillis: now, approvalStatus: 'approved', approvedBy: auth.uid, approvedAtMillis: now });
      }
    }
    const data = { id: transferId, sourceAccountId: sourceId, destinationAccountId: destinationId, sourceAccountType: sourceType, destinationAccountType: destinationType, amountMinor: amount, feeMinor: fee, status, createdBy: auth.uid, createdAtMillis: now, updatedAtMillis: now, ...(status === 'approved' ? { approvedBy: auth.uid, approvedAtMillis: now } : {}) };
    transaction.set(transferRef, data);
    const audit = auditData(request, 'create', 'treasury_transfer', transferId, null, data, 'Treasury transfer processed by trusted backend.');
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { transferId };
});

export const approveTreasuryTransfer = onCall(async (request) => {
  const auth = requireManager(request);
  const transferId = stringValue(request.data?.transferId, 'transferId');
  const transferRef = tenantCollection(request, 'treasury_transfers').doc(transferId);
  await db.runTransaction(async (transaction) => {
    const transferSnapshot = await transaction.get(transferRef);
    if (!transferSnapshot.exists || !transferSnapshot.data()) throw new HttpsError('not-found', 'Treasury transfer was not found.');
    const transfer = transferSnapshot.data()!;
    if (transfer.status === 'approved') return;
    if (transfer.status !== 'pending') throw new HttpsError('failed-precondition', 'Only pending transfers can be approved.');
    const sourceRef = tenantCollection(request, financialAccountCollection(transfer.sourceAccountType)).doc(stringValue(transfer.sourceAccountId, 'sourceAccountId'));
    const destinationRef = tenantCollection(request, financialAccountCollection(transfer.destinationAccountType)).doc(stringValue(transfer.destinationAccountId, 'destinationAccountId'));
    const source = await transaction.get(sourceRef);
    const destination = await transaction.get(destinationRef);
    if (!source.exists || !source.data() || !destination.exists || !destination.data()) throw new HttpsError('not-found', 'Transfer accounts were not found.');
    const amount = integerValue(transfer.amountMinor, 'amountMinor', { positive: true });
    const fee = integerValue(transfer.feeMinor ?? 0, 'feeMinor');
    const sourceBalance = integerValue(source.data()!.balanceMinor ?? 0, 'sourceBalance');
    if (sourceBalance < amount + fee) throw new HttpsError('failed-precondition', 'The source balance cannot cover the transfer.');
    const destinationBalance = integerValue(destination.data()!.balanceMinor ?? 0, 'destinationBalance');
    const now = Date.now();
    transaction.update(sourceRef, { balanceMinor: sourceBalance - amount - fee, updatedAtMillis: now });
    transaction.update(destinationRef, { balanceMinor: destinationBalance + amount, updatedAtMillis: now });
    if (transfer.sourceAccountType === 'bank') {
      const movementRef = tenantCollection(request, 'bank_movements').doc(`${transferId}_source`);
      transaction.set(movementRef, { id: movementRef.id, accountId: transfer.sourceAccountId, type: 'transfer_outflow', amountMinor: amount + fee, referenceType: 'treasury_transfer', referenceId: transferId, note: 'Internal transfer out', createdBy: auth.uid, createdAtMillis: now, updatedAtMillis: now, approvalStatus: 'approved', approvedBy: auth.uid, approvedAtMillis: now });
    }
    if (transfer.destinationAccountType === 'bank') {
      const movementRef = tenantCollection(request, 'bank_movements').doc(`${transferId}_destination`);
      transaction.set(movementRef, { id: movementRef.id, accountId: transfer.destinationAccountId, type: 'transfer_inflow', amountMinor: amount, referenceType: 'treasury_transfer', referenceId: transferId, note: 'Internal transfer in', createdBy: auth.uid, createdAtMillis: now, updatedAtMillis: now, approvalStatus: 'approved', approvedBy: auth.uid, approvedAtMillis: now });
    }
    transaction.update(transferRef, { status: 'approved', approvedBy: auth.uid, approvedAtMillis: now, updatedAtMillis: now });
    const audit = auditData(request, 'approve', 'treasury_transfer', transferId, { status: transfer.status, sourceBalance }, { status: 'approved', sourceBalance: sourceBalance - amount - fee, destinationBalance: destinationBalance + amount }, 'Treasury transfer approved by manager.');
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { transferId, status: 'approved' };
});

export const createExpense = onCall(async (request) => {
  const auth = requireFinanceOperator(request);
  const expenseId = stringValue(request.data?.expenseId, 'expenseId');
  const accountId = stringValue(request.data?.accountId, 'accountId');
  const category = stringValue(request.data?.category, 'category');
  const description = stringValue(request.data?.description, 'description');
  const amount = integerValue(request.data?.amountMinor, 'amountMinor', { positive: true });
  const expenseRef = tenantCollection(request, 'expenses').doc(expenseId);
  const accountRef = tenantCollection(request, 'treasury_accounts').doc(accountId);
  const threshold = await financeApprovalThreshold(request);
  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(expenseRef);
    if (existing.exists) return;
    const account = await transaction.get(accountRef);
    if (!account.exists || !account.data()) throw new HttpsError('not-found', 'Treasury account was not found.');
    const manager = auth.token.role === 'manager';
    const status = manager || amount <= threshold ? 'approved' : 'pending';
    const now = Date.now();
    if (status === 'approved') {
      const balance = integerValue(account.data()!.balanceMinor ?? 0, 'balanceMinor');
      if (balance < amount) throw new HttpsError('failed-precondition', 'The treasury balance cannot cover the expense.');
      transaction.update(accountRef, { balanceMinor: balance - amount, updatedAtMillis: now });
    }
    const data = {
      id: expenseId,
      category,
      description,
      amountMinor: amount,
      accountId,
      status,
      createdBy: auth.uid,
      createdAtMillis: now,
      updatedAtMillis: now,
      beneficiary: typeof request.data?.beneficiary === 'string' ? request.data.beneficiary.trim() : '',
      notes: typeof request.data?.notes === 'string' ? request.data.notes.trim() : '',
      expenseDateMillis: Number(request.data?.expenseDateMillis ?? now),
      ...(status === 'approved' ? { approvedBy: auth.uid, approvedAtMillis: now } : {}),
    };
    transaction.set(expenseRef, data);
    const audit = auditData(request, 'create', 'expense', expenseId, null, data, 'Expense posted by trusted backend.');
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { expenseId };
});

export const approveExpense = onCall(async (request) => {
  const auth = requireManager(request);
  const expenseId = stringValue(request.data?.expenseId, 'expenseId');
  const expenseRef = tenantCollection(request, 'expenses').doc(expenseId);
  await db.runTransaction(async (transaction) => {
    const expenseSnapshot = await transaction.get(expenseRef);
    if (!expenseSnapshot.exists || !expenseSnapshot.data()) throw new HttpsError('not-found', 'Expense was not found.');
    const expense = expenseSnapshot.data()!;
    if (expense.status === 'approved') return;
    if (expense.status !== 'pending') throw new HttpsError('failed-precondition', 'Only pending expenses can be approved.');
    const accountRef = tenantCollection(request, 'treasury_accounts').doc(stringValue(expense.accountId, 'accountId'));
    const accountSnapshot = await transaction.get(accountRef);
    if (!accountSnapshot.exists || !accountSnapshot.data()) throw new HttpsError('not-found', 'Treasury account was not found.');
    const amount = integerValue(expense.amountMinor, 'amountMinor', { positive: true });
    const balance = integerValue(accountSnapshot.data()!.balanceMinor ?? 0, 'balanceMinor');
    if (balance < amount) throw new HttpsError('failed-precondition', 'The treasury balance cannot cover the expense.');
    const now = Date.now();
    transaction.update(accountRef, { balanceMinor: balance - amount, updatedAtMillis: now });
    transaction.update(expenseRef, { status: 'approved', approvedBy: auth.uid, approvedAtMillis: now, updatedAtMillis: now });
    const audit = auditData(request, 'approve', 'expense', expenseId, { status: expense.status, balanceMinor: balance }, { status: 'approved', balanceMinor: balance - amount }, 'Expense approved by manager.');
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { expenseId, status: 'approved' };
});

export const createInstallmentAccount = onCall(async (request) => {
  const auth = requireFinanceOperator(request);
  const accountId = stringValue(request.data?.accountId, 'accountId');
  const customerName = stringValue(request.data?.customerName, 'customerName');
  const reference = stringValue(request.data?.reference, 'reference');
  const principal = integerValue(request.data?.principalMinor, 'principalMinor', { positive: true });
  const totalDue = integerValue(request.data?.totalDueMinor, 'totalDueMinor', { positive: true });
  const totalLimit = integerValue(request.data?.totalLimitMinor ?? principal, 'totalLimitMinor', { positive: true });
  const available = integerValue(request.data?.availableMinor ?? totalLimit - principal, 'availableMinor');
  const nextDueMillis = integerValue(request.data?.nextDueMillis, 'nextDueMillis', { positive: true });
  const monthly = integerValue(request.data?.monthlyInstallmentMinor ?? 0, 'monthlyInstallmentMinor');
  const totalInstallments = integerValue(request.data?.totalInstallments ?? 0, 'totalInstallments');
  if (totalDue < principal || totalLimit < principal || available < 0 || monthly < 0 || totalInstallments < 0) {
    throw new HttpsError('invalid-argument', 'The installment amounts are inconsistent.');
  }
  const accountRef = tenantCollection(request, 'installment_accounts').doc(accountId);
  const scheduleRef = tenantCollection(request, 'installment_schedules').doc(`${accountId}_schedule`);
  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(accountRef);
    if (existing.exists) return;
    const now = Date.now();
    const account = {
      id: accountId,
      customerName,
      reference,
      principalMinor: principal,
      totalDueMinor: totalDue,
      paidMinor: 0,
      nextDueMillis,
      status: 'active',
      createdBy: auth.uid,
      createdAtMillis: now,
      updatedAtMillis: now,
      monthlyInstallmentMinor: monthly,
      totalInstallments,
      paidInstallments: 0,
      applicationName: reference,
      associatedPerson: customerName,
      totalLimitMinor: totalLimit,
      availableMinor: available,
    };
    transaction.set(accountRef, account);
    transaction.set(scheduleRef, {
      id: scheduleRef.id,
      accountId,
      description: reference,
      principalMinor: principal,
      totalDueMinor: totalDue,
      monthlyAmountMinor: monthly,
      totalInstallments,
      paidInstallments: 0,
      nextDueMillis,
      status: 'active',
      createdBy: auth.uid,
      createdAtMillis: now,
      updatedAtMillis: now,
    });
    const audit = auditData(request, 'create', 'installment_account', accountId, null, account, 'Installment account created by trusted backend.');
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { accountId, status: 'created' };
});

export const updateInstallmentAccount = onCall(async (request) => {
  const auth = requireFinanceOperator(request);
  if (auth.token.role !== 'manager' &&
      !(auth.token.permissions as Record<string, unknown> | undefined)?.['records.edit']) {
    throw new HttpsError('permission-denied', 'Installment account editing permission is required.');
  }
  const accountId = stringValue(request.data?.accountId, 'accountId');
  const status = typeof request.data?.status === 'string'
    ? request.data.status.trim()
    : undefined;
  if (status != null && !['active', 'archived', 'settled'].includes(status)) {
    throw new HttpsError('invalid-argument', 'Unsupported installment account status.');
  }
  const accountRef = tenantCollection(request, 'installment_accounts').doc(accountId);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(accountRef);
    if (!snapshot.exists || !snapshot.data()) {
      throw new HttpsError('not-found', 'Installment account was not found.');
    }
    const current = snapshot.data()!;
    const next = {
      customerName: typeof request.data?.customerName === 'string'
        ? request.data.customerName.trim()
        : String(current.customerName ?? ''),
      reference: typeof request.data?.reference === 'string'
        ? request.data.reference.trim()
        : String(current.reference ?? ''),
      ...(status == null ? {} : { status }),
      updatedAtMillis: Date.now(),
    };
    if (!next.customerName || !next.reference) {
      throw new HttpsError('invalid-argument', 'customerName and reference are required.');
    }
    transaction.update(accountRef, next);
    const audit = auditData(
      request,
      'update',
      'installment_account',
      accountId,
      { customerName: current.customerName, reference: current.reference, status: current.status },
      next,
      'Installment account updated by an authorized user.',
    );
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { accountId, status: status ?? 'unchanged' };
});

export const createInstallmentSchedule = onCall(async (request) => {
  const auth = requireFinanceOperator(request);
  const scheduleId = stringValue(request.data?.scheduleId, 'scheduleId');
  const accountId = stringValue(request.data?.accountId, 'accountId');
  const description = stringValue(request.data?.description, 'description');
  const principal = integerValue(request.data?.principalMinor, 'principalMinor', { positive: true });
  const totalDue = integerValue(request.data?.totalDueMinor, 'totalDueMinor', { positive: true });
  const monthly = integerValue(request.data?.monthlyAmountMinor, 'monthlyAmountMinor', { positive: true });
  const totalInstallments = integerValue(request.data?.totalInstallments, 'totalInstallments', { positive: true });
  const nextDueMillis = integerValue(request.data?.nextDueMillis, 'nextDueMillis', { positive: true });
  if (totalDue < principal) throw new HttpsError('invalid-argument', 'totalDueMinor must cover principalMinor.');
  const accountRef = tenantCollection(request, 'installment_accounts').doc(accountId);
  const scheduleRef = tenantCollection(request, 'installment_schedules').doc(scheduleId);
  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(scheduleRef);
    if (existing.exists) return;
    const accountSnapshot = await transaction.get(accountRef);
    if (!accountSnapshot.exists || !accountSnapshot.data()) throw new HttpsError('not-found', 'Installment account was not found.');
    const account = accountSnapshot.data()!;
    const now = Date.now();
    const schedule = {
      id: scheduleId,
      accountId,
      description,
      principalMinor: principal,
      totalDueMinor: totalDue,
      monthlyAmountMinor: monthly,
      totalInstallments,
      paidInstallments: 0,
      nextDueMillis,
      status: 'active',
      createdBy: auth.uid,
      createdAtMillis: now,
      updatedAtMillis: now,
    };
    transaction.update(accountRef, {
      totalDueMinor: integerValue(account.totalDueMinor ?? 0, 'account.totalDueMinor') + totalDue,
      monthlyInstallmentMinor: integerValue(account.monthlyInstallmentMinor ?? 0, 'account.monthlyInstallmentMinor') + monthly,
      totalInstallments: integerValue(account.totalInstallments ?? 0, 'account.totalInstallments') + totalInstallments,
      status: 'active',
      updatedAtMillis: now,
    });
    transaction.set(scheduleRef, schedule);
    const audit = auditData(request, 'create', 'installment_schedule', scheduleId, null, schedule, 'Installment schedule created by trusted backend.');
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { scheduleId, status: 'created' };
});

export const createIssuedCheck = onCall(async (request) => {
  const auth = requireFinanceOperator(request);
  const checkId = stringValue(request.data?.checkId, 'checkId');
  const payee = stringValue(request.data?.payee, 'payee');
  const reference = stringValue(request.data?.reference, 'reference');
  const amount = integerValue(request.data?.amountMinor, 'amountMinor', { positive: true });
  const dueDateMillis = integerValue(request.data?.dueDateMillis, 'dueDateMillis', { positive: true });
  const accountId = stringValue(request.data?.accountId, 'accountId');
  const checkRef = tenantCollection(request, 'issued_checks').doc(checkId);
  const accountRef = tenantCollection(request, 'bank_accounts').doc(accountId);
  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(checkRef);
    if (existing.exists) return;
    const accountSnapshot = await transaction.get(accountRef);
    if (!accountSnapshot.exists || !accountSnapshot.data()) throw new HttpsError('not-found', 'The check bank account was not found.');
    const now = Date.now();
    const check = {
      id: checkId,
      payee,
      reference,
      amountMinor: amount,
      dueDateMillis,
      status: 'issued',
      accountId,
      createdBy: auth.uid,
      createdAtMillis: now,
      updatedAtMillis: now,
      bankName: typeof request.data?.bankName === 'string' ? request.data.bankName.trim() : '',
      notes: typeof request.data?.notes === 'string' ? request.data.notes.trim() : '',
    };
    transaction.set(checkRef, check);
    const audit = auditData(request, 'create', 'issued_check', checkId, null, check, 'Issued check created by trusted backend.');
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { checkId, status: 'issued' };
});

export const updateIssuedCheckStatus = onCall(async (request) => {
  const auth = requireReviewer(request);
  const checkId = stringValue(request.data?.checkId, 'checkId');
  const status = stringValue(request.data?.status, 'status');
  if (!['issued', 'cancelled', 'cleared', 'returned', 'overdue', 'archived'].includes(status)) {
    throw new HttpsError('invalid-argument', 'Unsupported issued-check status.');
  }
  const checkRef = tenantCollection(request, 'issued_checks').doc(checkId);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(checkRef);
    if (!snapshot.exists || !snapshot.data()) throw new HttpsError('not-found', 'Issued check was not found.');
    const check = snapshot.data()!;
    if (check.status === 'deducted' && status !== 'archived') {
      throw new HttpsError('failed-precondition', 'A deducted check can only be archived.');
    }
    if (status === 'archived' && check.status !== 'deducted') {
      throw new HttpsError('failed-precondition', 'Only a deducted check can be archived.');
    }
    if (check.status === status) return;
    const now = Date.now();
    transaction.update(checkRef, { status, updatedAtMillis: now });
    const audit = auditData(request, 'update_status', 'issued_check', checkId, { status: check.status }, { status }, 'Issued check status updated by an authorized reviewer.');
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { checkId, status };
});

export const createPersonalWithdrawal = onCall(async (request) => {
  const auth = requireFinanceOperator(request);
  const withdrawalId = stringValue(request.data?.withdrawalId, 'withdrawalId');
  const accountId = stringValue(request.data?.accountId, 'accountId');
  const personName = stringValue(request.data?.personName, 'personName');
  const reason = stringValue(request.data?.reason, 'reason');
  const amount = integerValue(request.data?.amountMinor, 'amountMinor', { positive: true });
  const withdrawalDateMillis = integerValue(
    request.data?.withdrawalDateMillis ?? Date.now(),
    'withdrawalDateMillis',
    { positive: true },
  );
  const withdrawalRef = tenantCollection(request, 'personal_withdrawals').doc(withdrawalId);
  const accountRef = tenantCollection(request, 'treasury_accounts').doc(accountId);
  const threshold = await financeApprovalThreshold(request);
  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(withdrawalRef);
    if (existing.exists) return;
    const account = await transaction.get(accountRef);
    if (!account.exists || !account.data()) throw new HttpsError('not-found', 'Treasury account was not found.');
    const manager = auth.token.role === 'manager';
    const status = manager || amount <= threshold ? 'approved' : 'pending';
    const now = Date.now();
    if (status === 'approved') {
      const balance = integerValue(account.data()!.balanceMinor ?? 0, 'balanceMinor');
      if (balance < amount) throw new HttpsError('failed-precondition', 'The treasury balance cannot cover the withdrawal.');
      transaction.update(accountRef, { balanceMinor: balance - amount, updatedAtMillis: now });
    }
    const data = {
      id: withdrawalId,
      personName,
      accountId,
      amountMinor: amount,
      reason,
      status,
      withdrawalDateMillis,
      createdBy: auth.uid,
      createdAtMillis: now,
      updatedAtMillis: now,
      ...(status === 'approved' ? { approvedBy: auth.uid, approvedAtMillis: now } : {}),
    };
    transaction.set(withdrawalRef, data);
    const audit = auditData(request, 'create', 'personal_withdrawal', withdrawalId, null, data, 'Personal withdrawal posted by trusted backend.');
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { withdrawalId };
});

export const approvePersonalWithdrawal = onCall(async (request) => {
  const auth = requireManager(request);
  const withdrawalId = stringValue(request.data?.withdrawalId, 'withdrawalId');
  const withdrawalRef = tenantCollection(request, 'personal_withdrawals').doc(withdrawalId);
  await db.runTransaction(async (transaction) => {
    const withdrawalSnapshot = await transaction.get(withdrawalRef);
    if (!withdrawalSnapshot.exists || !withdrawalSnapshot.data()) throw new HttpsError('not-found', 'Personal withdrawal was not found.');
    const withdrawal = withdrawalSnapshot.data()!;
    if (withdrawal.status === 'approved') return;
    const accountRef = tenantCollection(request, 'treasury_accounts').doc(stringValue(withdrawal.accountId, 'accountId'));
    const accountSnapshot = await transaction.get(accountRef);
    if (!accountSnapshot.exists || !accountSnapshot.data()) throw new HttpsError('not-found', 'Treasury account was not found.');
    const amount = integerValue(withdrawal.amountMinor, 'amountMinor', { positive: true });
    const balance = integerValue(accountSnapshot.data()!.balanceMinor ?? 0, 'balanceMinor');
    if (balance < amount) throw new HttpsError('failed-precondition', 'The treasury balance cannot cover the withdrawal.');
    const now = Date.now();
    transaction.update(accountRef, { balanceMinor: balance - amount, updatedAtMillis: now });
    transaction.update(withdrawalRef, { status: 'approved', approvedBy: auth.uid, approvedAtMillis: now, updatedAtMillis: now });
    const audit = auditData(request, 'approve', 'personal_withdrawal', withdrawalId, { status: withdrawal.status, balanceMinor: balance }, { status: 'approved', balanceMinor: balance - amount }, 'Personal withdrawal approved by manager.');
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { withdrawalId, status: 'approved' };
});

export const createManagedUser = onCall(async (request) => {
  requireManager(request);
  const organizationId = callerOrganization(request);
  const email = stringValue(request.data?.email, 'email').toLowerCase();
  const password = stringValue(request.data?.temporaryPassword, 'temporaryPassword');
  const displayName = stringValue(request.data?.displayName, 'displayName');
  const role = stringValue(request.data?.role, 'role');
  if (!allowedRoles.has(role)) throw new HttpsError('invalid-argument', 'Unsupported role.');
  const permissions = permissionsValue(request.data?.permissions);
  const user = await admin.auth().createUser({ email, password, displayName });
  await admin.auth().setCustomUserClaims(user.uid, { role, organizationId, permissions });
  await db.doc(`organizations/${organizationId}/users/${user.uid}`).set({
    id: user.uid,
    email,
    displayName,
    role,
    permissions,
    active: true,
    createdBy: request.auth?.uid ?? '',
    createdAtMillis: Date.now(),
  });
  return { uid: user.uid };
});

export const setUserAccess = onCall(async (request) => {
  requireManager(request);
  const organizationId = callerOrganization(request);
  const uid = stringValue(request.data?.uid, 'uid');
  const role = stringValue(request.data?.role, 'role');
  if (!allowedRoles.has(role)) throw new HttpsError('invalid-argument', 'Unsupported role.');
  const permissions = permissionsValue(request.data?.permissions);
  const user = await admin.auth().getUser(uid);
  const existingClaims = user.customClaims ?? {};
  if (existingClaims.organizationId !== organizationId) {
    throw new HttpsError('permission-denied', 'User is outside the manager organization.');
  }
  await admin.auth().setCustomUserClaims(uid, { ...existingClaims, role, organizationId, permissions });
  await db.doc(`organizations/${organizationId}/users/${uid}`).set({
    role,
    permissions,
    updatedBy: request.auth?.uid ?? '',
    updatedAtMillis: Date.now(),
  }, { merge: true });
  return { uid };
});

export const listOrganizationUsers = onCall(async (request) => {
  requireManager(request);
  const organizationId = callerOrganization(request);
  const snapshot = await db.collection(`organizations/${organizationId}/users`).orderBy('createdAtMillis', 'desc').get();
  return { users: snapshot.docs.map((doc) => ({ id: doc.id, ...doc.data() })) };
});

export const setFinanceApprovalThreshold = onCall(async (request) => {
  requireManager(request);
  const organizationId = callerOrganization(request);
  const value = request.data?.approvalThresholdMinor;
  if (!Number.isInteger(value) || value < 0) {
    throw new HttpsError('invalid-argument', 'approvalThresholdMinor must be a non-negative integer.');
  }
  await db.doc(`organizations/${organizationId}/system_settings/finance`).set({
    approvalThresholdMinor: value,
    updatedBy: request.auth?.uid ?? '',
    updatedAtMillis: Date.now(),
  }, { merge: true });
  return { approvalThresholdMinor: value };
});

export const registerOrganizationOwner = onCall(async (request) => {
  const auth = requireAuthenticated(request);
  if (auth.token.organizationId || auth.token.role) {
    throw new HttpsError('already-exists', 'This account already belongs to an organization.');
  }
  const displayName = typeof request.data?.displayName === 'string'
    ? request.data.displayName.trim()
    : '';
  const organizationName = typeof request.data?.organizationName === 'string'
    ? request.data.organizationName.trim()
    : '';
  const organizationId = typeof auth.token.organizationId === 'string' && auth.token.organizationId.length > 0
    ? auth.token.organizationId
    : `org_${auth.uid}`;
  const permissions = {
    'records.edit': true,
    'records.delete': true,
    'settlements.review': true,
    'treasury.accounts.manage': true,
    'treasury.reconcile': true,
    'expenses.categories.manage': true,
  };
  await admin.auth().setCustomUserClaims(auth.uid, {
    ...auth.token,
    role: 'manager',
    organizationId,
    permissions,
  });
  const now = Date.now();
  await db.doc(`organizations/${organizationId}`).set({
    id: organizationId,
    name: organizationName || 'Credexa Organization',
    ownerUid: auth.uid,
    updatedAtMillis: now,
    createdAtMillis: now,
  }, { merge: true });
  await db.doc(`organizations/${organizationId}/users/${auth.uid}`).set({
    id: auth.uid,
    email: auth.token.email ?? '',
    displayName,
    role: 'manager',
    permissions,
    active: true,
    createdAtMillis: now,
    updatedAtMillis: now,
  }, { merge: true });
  return { organizationId };
});

export const scheduleFinancialReminders = onSchedule(
  {
    schedule: 'every day 08:00',
    timeZone: 'Africa/Cairo',
    region: 'europe-west1',
  },
  async () => {
    const now = new Date();
    const today = Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate());
    const [installments, checks] = await Promise.all([
      db.collectionGroup('installment_accounts').get(),
      db.collectionGroup('issued_checks').get(),
    ]);
    const writes: Promise<FirebaseFirestore.WriteResult>[] = [];
    const addReminder = async (
      document: FirebaseFirestore.QueryDocumentSnapshot,
      type: 'installment' | 'check',
      dueMillis: number,
      label: string,
      targetType: string,
    ) => {
      const data = document.data();
      if (type === 'installment' && data.status !== 'active') return;
      if (type === 'check' && data.status !== 'issued') return;
      const due = new Date(dueMillis);
      const dueDay = Date.UTC(due.getUTCFullYear(), due.getUTCMonth(), due.getUTCDate());
      const daysUntilDue = Math.round((dueDay - today) / 86400000);
      const overdue = type === 'installment' && daysUntilDue < 0;
      if (type === 'check' && ![0, 1, 3].includes(daysUntilDue)) return;
      if (type === 'installment' && !(daysUntilDue <= 3)) return;
      const phase = overdue ? `overdue_${Math.abs(daysUntilDue)}` : `before_${daysUntilDue}`;
      const scope = document.ref.parent.parent;
      if (!scope) return;
      const notificationRef = scope.collection('notifications').doc(`${type}_${document.id}_${phase}_${today}`);
      const existing = await notificationRef.get();
      if (existing.exists) return;
      writes.push(notificationRef.set({
        id: notificationRef.id,
        title: overdue ? `${label} متأخر` : `تذكير ${label}`,
        body: String(data.reference ?? data.payee ?? document.id),
        category: overdue ? `${type}_overdue` : `${type}_due`,
        targetType,
        targetId: document.id,
        read: false,
        createdAtMillis: Date.now(),
        updatedAtMillis: Date.now(),
        source: 'scheduled_backend',
      }));
    };
    await Promise.all([
      ...installments.docs.map((doc) => addReminder(doc, 'installment', Number(doc.data().nextDueMillis ?? 0), 'قسط', 'installment_account')),
      ...checks.docs.map((doc) => addReminder(doc, 'check', Number(doc.data().dueDateMillis ?? 0), 'شيك', 'issued_check')),
    ]);
    await Promise.all(writes);
  },
);

export const rolloverCreditCardPeriods = onSchedule(
  {
    schedule: 'every day 00:05',
    timeZone: 'Africa/Cairo',
    region: 'europe-west1',
  },
  async () => {
    const cards = await db.collectionGroup('credit_cards').get();
    const current = new Date();
    const year = current.getUTCFullYear();
    const month = current.getUTCMonth() + 1;
    await Promise.all(cards.docs.map(async (cardDocument) => {
      const scope = cardDocument.ref.parent.parent;
      if (!scope || cardDocument.data().active !== true) return;
      const periodRef = scope.collection('credit_periods').doc(
        creditPeriodId(cardDocument.id, year, month),
      );
      await db.runTransaction(async (transaction) => {
        const cardSnapshot = await transaction.get(cardDocument.ref);
        const periodSnapshot = await transaction.get(periodRef);
        if (!cardSnapshot.exists || !cardSnapshot.data() || periodSnapshot.exists) return;
        const card = cardSnapshot.data()!;
        const openingBalance = integerValue(
          card.availableBalanceMinor ?? 0,
          'availableBalanceMinor',
        );
        const effectiveLimit = integerValue(
          card.nextCreditLimitMinor ?? card.creditLimitMinor ?? 0,
          'creditLimitMinor',
        );
        const openingDebt = Math.max(0, effectiveLimit - openingBalance);
        const timestamp = Date.now();
        transaction.set(periodRef, {
          id: periodRef.id,
          cardId: cardDocument.id,
          year,
          month,
          openingBalanceMinor: openingBalance,
          openingDebtMinor: openingDebt,
          qualifyingDepositsMinor: 0,
          remainingDebtMinor: openingDebt,
          closingBalanceMinor: openingBalance,
          fullyPaid: openingDebt === 0,
          effectiveLimitMinor: effectiveLimit,
          updatedAtMillis: timestamp,
        });
        transaction.update(cardDocument.ref, {
          creditLimitMinor: effectiveLimit,
          nextCreditLimitMinor: null,
          currentMonthlyDebtMinor: openingDebt,
          monthlyPaidMinor: 0,
          updatedAtMillis: timestamp,
        });
      });
    }));
  },
);

export const approveSettlement = onCall(async (request) => {
  const auth = requireReviewer(request);
  const settlementId = stringValue(request.data?.settlementId, 'settlementId');
  const settlementRef = tenantCollection(request, 'settlements').doc(settlementId);
  const audit = auditData(
    request,
    'approve',
    'settlement',
    settlementId,
    null,
    { approvalStatus: 'approved', approvedBy: auth.uid },
    'Settlement approved by a trusted backend transaction.',
  );
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(settlementRef);
    if (!snapshot.exists || !snapshot.data()) {
      throw new HttpsError('not-found', 'Settlement was not found.');
    }
    const current = snapshot.data()!;
    if (current.createdBy === auth.uid) {
      throw new HttpsError('failed-precondition', 'The creator cannot approve the settlement.');
    }
    if (current.approvalStatus === 'rejected') {
      throw new HttpsError('failed-precondition', 'A rejected settlement cannot be approved.');
    }
    if (current.approvalStatus === 'approved') return;
    const now = Date.now();
    transaction.update(settlementRef, {
      approvalStatus: 'approved',
      approvedBy: auth.uid,
      approvedAtMillis: now,
      updatedAtMillis: now,
    });
    transaction.set(
      tenantCollection(request, 'audit_logs').doc(audit.id as string),
      { ...audit, previousValues: { approvalStatus: current.approvalStatus }, newValues: { approvalStatus: 'approved', approvedBy: auth.uid }, createdAtMillis: now },
    );
  });
  return { settlementId, status: 'approved' };
});

export const rejectSettlement = onCall(async (request) => {
  const auth = requireReviewer(request);
  const settlementId = stringValue(request.data?.settlementId, 'settlementId');
  const reason = stringValue(request.data?.reason, 'reason');
  const settlementRef = tenantCollection(request, 'settlements').doc(settlementId);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(settlementRef);
    if (!snapshot.exists || !snapshot.data()) {
      throw new HttpsError('not-found', 'Settlement was not found.');
    }
    const current = snapshot.data()!;
    if (current.createdBy === auth.uid) {
      throw new HttpsError('failed-precondition', 'The creator cannot reject the settlement.');
    }
    if (current.approvalStatus === 'approved') {
      throw new HttpsError('failed-precondition', 'An approved settlement cannot be rejected.');
    }
    if (current.approvalStatus === 'rejected' && current.rejectionReason === reason) return;
    const now = Date.now();
    transaction.update(settlementRef, {
      approvalStatus: 'rejected',
      rejectionReason: reason,
      rejectedBy: auth.uid,
      rejectedAtMillis: now,
      updatedAtMillis: now,
    });
    const audit = auditData(
      request,
      'reject',
      'settlement',
      settlementId,
      { approvalStatus: current.approvalStatus },
      { approvalStatus: 'rejected', rejectionReason: reason },
      reason,
    );
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { settlementId, status: 'rejected' };
});

export const confirmCollectionRequest = onCall(async (request) => {
  const auth = requireReviewer(request);
  const requestId = stringValue(request.data?.requestId, 'requestId');
  const confirmationReference = stringValue(
    request.data?.confirmationReference,
    'confirmationReference',
  );
  const requestRef = tenantCollection(request, 'collection_requests').doc(requestId);
  await db.runTransaction(async (transaction) => {
    const requestSnapshot = await transaction.get(requestRef);
    if (!requestSnapshot.exists || !requestSnapshot.data()) {
      throw new HttpsError('not-found', 'Collection request was not found.');
    }
    const collection = requestSnapshot.data()!;
    if (collection.status === 'confirmed') return;
    if (collection.status !== 'pending') {
      throw new HttpsError('failed-precondition', 'Only pending collection requests can be confirmed.');
    }
    const settlementId = stringValue(collection.settlementId, 'settlementId');
    const settlementRef = tenantCollection(request, 'settlements').doc(settlementId);
    const settlementSnapshot = await transaction.get(settlementRef);
    if (!settlementSnapshot.exists || !settlementSnapshot.data()) {
      throw new HttpsError('failed-precondition', 'The collection settlement was not found.');
    }
    const settlement = settlementSnapshot.data()!;
    if (settlement.approvalStatus !== 'approved') {
      throw new HttpsError('failed-precondition', 'The settlement must be approved first.');
    }
    const amount = integerValue(collection.amountMinor, 'amountMinor', { positive: true });
    const commission = integerValue(collection.commissionMinor ?? 0, 'commissionMinor');
    const fee = integerValue(collection.feeMinor ?? 0, 'feeMinor');
    const net = integerValue(collection.netMinor, 'netMinor');
    if (commission < 0 || fee < 0 || net !== amount - commission - fee || net < 0) {
      throw new HttpsError('failed-precondition', 'The collection fee and net amount are inconsistent.');
    }
    const collected = integerValue(settlement.collectedMinor ?? 0, 'collectedMinor');
    const settlementGross = integerValue(settlement.grossMinor, 'settlement.grossMinor');
    if (collected + amount > settlementGross) {
      throw new HttpsError('failed-precondition', 'The collection exceeds the settlement balance.');
    }
    const requested = integerValue(settlement.requestedMinor ?? 0, 'requestedMinor');
    if (amount > requested) {
      throw new HttpsError('failed-precondition', 'The collection exceeds the requested amount.');
    }
    const bankId = typeof settlement.destinationBankAccountId === 'string'
      ? settlement.destinationBankAccountId
      : '';
    const bankRef = bankId.length > 0
      ? tenantCollection(request, 'bank_accounts').doc(bankId)
      : null;
    const bankSnapshot = bankRef == null ? null : await transaction.get(bankRef);
    if (bankRef != null && (!bankSnapshot?.exists || !bankSnapshot.data())) {
      throw new HttpsError('failed-precondition', 'The destination bank account was not found.');
    }
    const now = Date.now();
    transaction.update(requestRef, {
      status: 'confirmed',
      confirmationReference,
      confirmedBy: auth.uid,
      confirmedAtMillis: now,
      updatedAtMillis: now,
    });
    transaction.update(settlementRef, {
      collectedMinor: collected + amount,
      requestedMinor: requested - amount,
      status: collected + amount >= settlementGross ? 'settled' : 'partial',
      actualCollectionDateMillis: now,
      updatedAtMillis: now,
    });
    if (bankRef != null && bankSnapshot?.data()) {
      const bankBalance = integerValue(bankSnapshot.data()!.balanceMinor ?? 0, 'bankBalance');
      transaction.update(bankRef, {
        balanceMinor: bankBalance + net,
        updatedAtMillis: now,
      });
      const movementRef = tenantCollection(request, 'bank_movements').doc(`${requestId}_collection`);
      transaction.set(movementRef, {
        id: movementRef.id,
        accountId: bankId,
        type: 'collection_inflow',
        amountMinor: net,
        referenceType: 'collection_request',
        referenceId: requestId,
        note: 'Confirmed settlement collection',
        createdBy: auth.uid,
        createdAtMillis: now,
        updatedAtMillis: now,
        approvalStatus: 'approved',
        approvedBy: auth.uid,
        approvedAtMillis: now,
      });
    }
    const audit = auditData(
      request,
      'confirm',
      'collection_request',
      requestId,
      { status: collection.status, settlementCollectedMinor: collected },
      { status: 'confirmed', settlementCollectedMinor: collected + amount, netMinor: net },
      'Collection confirmed by a trusted backend transaction.',
    );
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { requestId, status: 'confirmed' };
});

export const createCollectionRequest = onCall(async (request) => {
  const auth = requireFinanceOperator(request);
  const requestId = stringValue(request.data?.requestId, 'requestId');
  const settlementId = stringValue(request.data?.settlementId, 'settlementId');
  const amount = integerValue(request.data?.amountMinor, 'amountMinor', { positive: true });
  const collectionType = request.data?.collectionType === 'normal' ? 'normal' : 'instant';
  const requestRef = tenantCollection(request, 'collection_requests').doc(requestId);
  const settlementRef = tenantCollection(request, 'settlements').doc(settlementId);
  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(requestRef);
    if (existing.exists) return;
    const settlementSnapshot = await transaction.get(settlementRef);
    if (!settlementSnapshot.exists || !settlementSnapshot.data()) {
      throw new HttpsError('not-found', 'Settlement was not found.');
    }
    const settlement = settlementSnapshot.data()!;
    if (settlement.approvalStatus !== 'approved') {
      throw new HttpsError('failed-precondition', 'The settlement must be approved first.');
    }
    const gross = integerValue(settlement.grossMinor, 'settlement.grossMinor', { positive: true });
    const collected = integerValue(settlement.collectedMinor ?? 0, 'settlement.collectedMinor');
    const reserved = integerValue(settlement.requestedMinor ?? 0, 'settlement.requestedMinor');
    if (amount > gross - collected - reserved) {
      throw new HttpsError('failed-precondition', 'The collection exceeds the remaining eligible gross amount.');
    }
    const settlementCommission = integerValue(settlement.commissionMinor ?? 0, 'settlement.commissionMinor');
    const commission = Math.floor((amount * settlementCommission + Math.floor(gross / 2)) / gross);
    const fee = collectionType === 'instant' ? Math.floor((amount * 10 + 5000) / 10000) : 0;
    const net = amount - commission - fee;
    if (net < 0) throw new HttpsError('failed-precondition', 'The collection net cannot be negative.');
    const now = Date.now();
    transaction.set(requestRef, {
      id: requestId,
      settlementId,
      amountMinor: amount,
      commissionMinor: commission,
      feeMinor: fee,
      netMinor: net,
      collectionType,
      status: 'pending',
      confirmationReference: '',
      createdBy: auth.uid,
      createdAtMillis: now,
      updatedAtMillis: now,
    });
    transaction.update(settlementRef, {
      requestedMinor: reserved + amount,
      updatedAtMillis: now,
    });
    const audit = auditData(
      request,
      'create',
      'collection_request',
      requestId,
      { requestedMinor: reserved },
      { requestedMinor: reserved + amount, amountMinor: amount, commissionMinor: commission, feeMinor: fee, netMinor: net },
      'Collection request reserved by a trusted backend transaction.',
    );
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { requestId, status: 'pending' };
});

export const createSettlement = onCall(async (request) => {
  const auth = requireFinanceOperator(request);
  const settlementId = stringValue(request.data?.settlementId, 'settlementId');
  const brandId = stringValue(request.data?.brandId, 'brandId');
  const includedIds = stringList(request.data?.includedTransactionIds, 'includedTransactionIds');
  if (includedIds.length === 0 || new Set(includedIds).size !== includedIds.length) {
    throw new HttpsError('invalid-argument', 'A settlement needs unique source purchases.');
  }
  const settlementRef = tenantCollection(request, 'settlements').doc(settlementId);
  const brandRef = tenantCollection(request, 'brands').doc(brandId);
  const purchaseRefs = includedIds.map((id) => tenantCollection(request, 'credit_purchases').doc(id));
  const allocationRefs = includedIds.map((id) => tenantCollection(request, 'settlement_allocations').doc(id));
  const priorSettlements = await Promise.all(
    includedIds.map((id) => tenantCollection(request, 'settlements').where('includedTransactionIds', 'array-contains', id).limit(1).get()),
  );
  if (priorSettlements.some((snapshot) => snapshot.docs.length > 0)) {
    throw new HttpsError('failed-precondition', 'A source purchase is already allocated to a settlement.');
  }
  await db.runTransaction(async (transaction) => {
    const existingSettlement = await transaction.get(settlementRef);
    if (existingSettlement.exists) return;
    const brandSnapshot = await transaction.get(brandRef);
    if (!brandSnapshot.exists || !brandSnapshot.data() || brandSnapshot.data()!.active !== true) {
      throw new HttpsError('failed-precondition', 'The settlement brand is not active.');
    }
    const brand = brandSnapshot.data()!;
    const purchaseSnapshots = await Promise.all(purchaseRefs.map((ref) => transaction.get(ref)));
    const allocationSnapshots = await Promise.all(allocationRefs.map((ref) => transaction.get(ref)));
    let gross = 0;
    let commission = 0;
    const sourceRows: Array<Record<string, unknown>> = [];
    for (let index = 0; index < purchaseSnapshots.length; index++) {
      const snapshot = purchaseSnapshots[index];
      if (!snapshot.exists || !snapshot.data()) throw new HttpsError('not-found', 'A settlement source purchase was not found.');
      const purchase = snapshot.data()!;
      if (purchase.isDeleted === true || purchase.brandId !== brandId) throw new HttpsError('failed-precondition', 'A source purchase is invalid for this brand.');
      if (allocationSnapshots[index].exists) throw new HttpsError('failed-precondition', 'A source purchase is already allocated to a settlement.');
      const sourceGross = integerValue(purchase.amountMinor, 'purchase.amountMinor', { positive: true });
      const sourceCommission = integerValue(purchase.commissionMinor ?? 0, 'purchase.commissionMinor');
      gross += sourceGross;
      commission += sourceCommission;
      sourceRows.push({ purchaseId: includedIds[index], grossMinor: sourceGross, commissionMinor: sourceCommission });
    }
    const now = Date.now();
    const expectedDate = new Date(now);
    expectedDate.setUTCDate(expectedDate.getUTCDate() + 1);
    expectedDate.setUTCHours(11, 0, 0, 0);
    const settlement = {
      id: settlementId,
      providerId: String(brand.providerId ?? ''),
      providerName: String(brand.providerName ?? ''),
      brandId,
      brandName: String(brand.name ?? ''),
      posMachineId: String(brand.posMachineId ?? ''),
      posMachineName: String(brand.posMachineName ?? ''),
      receivingCompanyId: String(brand.receivingCompanyId ?? ''),
      receivingCompanyName: String(brand.receivingCompanyName ?? ''),
      destinationBankAccountId: String(brand.settlementBankAccountId ?? ''),
      destinationBankAccountName: String(brand.settlementBankAccountName ?? ''),
      periodLabel: typeof request.data?.periodLabel === 'string' ? request.data.periodLabel.trim() : '',
      grossMinor: gross,
      commissionMinor: commission,
      netMinor: gross - commission,
      collectedMinor: 0,
      requestedMinor: 0,
      includedTransactionIds: includedIds,
      sourceAllocations: sourceRows,
      status: 'open',
      approvalStatus: 'pending',
      evidenceStatus: 'unavailable',
      createdBy: auth.uid,
      createdAtMillis: now,
      settlementDateMillis: now,
      expectedCollectionDateMillis: expectedDate.getTime(),
      updatedAtMillis: now,
    };
    transaction.set(settlementRef, settlement);
    for (let index = 0; index < allocationRefs.length; index++) {
      transaction.set(allocationRefs[index], {
        id: allocationRefs[index].id,
        settlementId,
        purchaseId: includedIds[index],
        grossMinor: sourceRows[index].grossMinor,
        commissionMinor: sourceRows[index].commissionMinor,
        createdAtMillis: now,
        createdBy: auth.uid,
      });
    }
    const audit = auditData(request, 'create', 'settlement', settlementId, null, settlement, 'Settlement created from validated purchase sources.');
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { settlementId, status: 'pending' };
});

export const approveTreasuryMovement = onCall(async (request) => {
  const auth = requireManager(request);
  const movementId = stringValue(request.data?.movementId, 'movementId');
  const movementRef = tenantCollection(request, 'treasury_movements').doc(movementId);
  await db.runTransaction(async (transaction) => {
    const movementSnapshot = await transaction.get(movementRef);
    if (!movementSnapshot.exists || !movementSnapshot.data()) {
      throw new HttpsError('not-found', 'Treasury movement was not found.');
    }
    const movement = movementSnapshot.data()!;
    if (movement.approvalStatus === 'approved') return;
    if (movement.approvalStatus !== 'pending') {
      throw new HttpsError('failed-precondition', 'Only pending treasury movements can be approved.');
    }
    const accountId = stringValue(movement.accountId, 'accountId');
    const accountRef = tenantCollection(request, 'treasury_accounts').doc(accountId);
    const accountSnapshot = await transaction.get(accountRef);
    if (!accountSnapshot.exists || !accountSnapshot.data()) {
      throw new HttpsError('failed-precondition', 'Treasury account was not found.');
    }
    const amount = integerValue(movement.amountMinor, 'amountMinor', { positive: true });
    const balance = integerValue(accountSnapshot.data()!.balanceMinor ?? 0, 'balanceMinor');
    const delta = movement.type === 'outflow' ? -amount : amount;
    if (balance + delta < 0) {
      throw new HttpsError('failed-precondition', 'The treasury balance cannot become negative.');
    }
    const now = Date.now();
    transaction.update(accountRef, { balanceMinor: balance + delta, updatedAtMillis: now });
    transaction.update(movementRef, {
      approvalStatus: 'approved',
      approvedBy: auth.uid,
      approvedAtMillis: now,
      updatedAtMillis: now,
    });
    const audit = auditData(
      request,
      'approve',
      'treasury_movement',
      movementId,
      { approvalStatus: movement.approvalStatus, balanceMinor: balance },
      { approvalStatus: 'approved', balanceMinor: balance + delta },
      'Treasury movement approved by a trusted backend transaction.',
    );
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { movementId, status: 'approved' };
});

export const deductIssuedCheck = onCall(async (request) => {
  const auth = requireReviewer(request);
  const checkId = stringValue(request.data?.checkId, 'checkId');
  const checkRef = tenantCollection(request, 'issued_checks').doc(checkId);
  await db.runTransaction(async (transaction) => {
    const checkSnapshot = await transaction.get(checkRef);
    if (!checkSnapshot.exists || !checkSnapshot.data()) {
      throw new HttpsError('not-found', 'Issued check was not found.');
    }
    const check = checkSnapshot.data()!;
    if (check.status === 'deducted') return;
    if (check.status !== 'issued') {
      throw new HttpsError('failed-precondition', 'Only issued checks can be deducted.');
    }
    const accountId = stringValue(check.accountId, 'accountId');
    const amount = integerValue(check.amountMinor, 'amountMinor', { positive: true });
    const bankRef = tenantCollection(request, 'bank_accounts').doc(accountId);
    const bankSnapshot = await transaction.get(bankRef);
    if (!bankSnapshot.exists || !bankSnapshot.data()) {
      throw new HttpsError('failed-precondition', 'The check bank account was not found.');
    }
    const balance = integerValue(bankSnapshot.data()!.balanceMinor ?? 0, 'balanceMinor');
    if (balance < amount) {
      throw new HttpsError('failed-precondition', 'The bank balance cannot cover the check.');
    }
    const now = Date.now();
    transaction.update(bankRef, { balanceMinor: balance - amount, updatedAtMillis: now });
    transaction.update(checkRef, { status: 'deducted', deductionDateMillis: now, updatedAtMillis: now });
    const movementRef = tenantCollection(request, 'bank_movements').doc(`${checkId}_bank_deduction`);
    transaction.set(movementRef, {
      id: movementRef.id,
      accountId,
      type: 'check_outflow',
      amountMinor: amount,
      referenceType: 'issued_check',
      referenceId: checkId,
      note: 'Issued check deduction',
      createdBy: auth.uid,
      createdAtMillis: now,
      updatedAtMillis: now,
        approvalStatus: 'approved',
        approvedBy: auth.uid,
        approvedAtMillis: now,
    });
    const audit = auditData(
      request,
      'deduct',
      'issued_check',
      checkId,
      { status: check.status, balanceMinor: balance },
      { status: 'deducted', balanceMinor: balance - amount },
      'Issued check deducted by a trusted backend transaction.',
    );
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { checkId, status: 'deducted' };
});

export const recordInstallmentPayment = onCall(async (request) => {
  const auth = requireFinanceOperator(request);
  const accountId = stringValue(request.data?.installmentAccountId, 'installmentAccountId');
  const treasuryAccountId = stringValue(request.data?.treasuryAccountId, 'treasuryAccountId');
  const paymentId = stringValue(request.data?.paymentId, 'paymentId');
  const amount = integerValue(request.data?.amountMinor, 'amountMinor', { positive: true });
  const nextDueMillis = integerValue(request.data?.nextDueMillis, 'nextDueMillis', { positive: true });
  const scheduleId = typeof request.data?.scheduleId === 'string' && request.data.scheduleId.length > 0
    ? request.data.scheduleId
    : `${accountId}_schedule`;
  const paymentRef = tenantCollection(request, 'installment_payments').doc(paymentId);
  const accountRef = tenantCollection(request, 'installment_accounts').doc(accountId);
  const treasuryRef = tenantCollection(request, 'treasury_accounts').doc(treasuryAccountId);
  await db.runTransaction(async (transaction) => {
    const existingPayment = await transaction.get(paymentRef);
    if (existingPayment.exists) return;
    const accountSnapshot = await transaction.get(accountRef);
    const treasurySnapshot = await transaction.get(treasuryRef);
    if (!accountSnapshot.exists || !accountSnapshot.data()) {
      throw new HttpsError('not-found', 'Installment account was not found.');
    }
    if (!treasurySnapshot.exists || !treasurySnapshot.data()) {
      throw new HttpsError('not-found', 'Treasury account was not found.');
    }
    const scheduleRef = tenantCollection(request, 'installment_schedules').doc(scheduleId);
    const scheduleSnapshot = await transaction.get(scheduleRef);
    const account = accountSnapshot.data()!;
    const treasury = treasurySnapshot.data()!;
    if (account.status !== 'active') {
      throw new HttpsError('failed-precondition', 'Only an active installment account can receive payments.');
    }
    const paid = integerValue(account.paidMinor ?? 0, 'paidMinor');
    const totalDue = integerValue(account.totalDueMinor, 'totalDueMinor');
    const totalLimit = integerValue(account.totalLimitMinor ?? 0, 'totalLimitMinor');
    const available = integerValue(account.availableMinor ?? 0, 'availableMinor');
    const balance = integerValue(treasury.balanceMinor ?? 0, 'balanceMinor');
    if (paid + amount > totalDue) {
      throw new HttpsError('failed-precondition', 'The installment payment exceeds the remaining balance.');
    }
    if (balance < amount) {
      throw new HttpsError('failed-precondition', 'The treasury balance cannot cover the installment payment.');
    }
    const now = Date.now();
    const settled = paid + amount >= totalDue;
    transaction.update(accountRef, {
      paidMinor: paid + amount,
      nextDueMillis,
      paidInstallments: Math.min(
        integerValue(account.totalInstallments ?? 0, 'totalInstallments'),
        settled
          ? integerValue(account.totalInstallments ?? 0, 'totalInstallments')
          : integerValue(account.paidInstallments ?? 0, 'paidInstallments') + (
              integerValue(account.monthlyInstallmentMinor ?? 0, 'monthlyInstallmentMinor') > 0
                  ? Math.floor(amount / integerValue(account.monthlyInstallmentMinor ?? 0, 'monthlyInstallmentMinor'))
                  : 0),
      ),
      availableMinor: totalLimit > 0
        ? Math.min(totalLimit, available + amount)
        : available,
      status: settled ? 'settled' : 'active',
      updatedAtMillis: now,
    });
    transaction.update(treasuryRef, { balanceMinor: balance - amount, updatedAtMillis: now });
    transaction.set(paymentRef, {
      id: paymentId,
      installmentAccountId: accountId,
      amountMinor: amount,
      paidAtMillis: now,
      nextDueMillis,
      createdBy: auth.uid,
      createdAtMillis: now,
      updatedAtMillis: now,
    });
    const movementRef = tenantCollection(request, 'treasury_movements').doc(`${paymentId}_treasury_payment`);
    transaction.set(movementRef, {
      id: movementRef.id,
      accountId: treasuryAccountId,
      type: 'outflow',
      amountMinor: amount,
      note: `Installment payment ${accountId}`,
      createdBy: auth.uid,
      createdAtMillis: now,
      updatedAtMillis: now,
      approvalStatus: 'approved',
      approvedBy: auth.uid,
      approvedAtMillis: now,
    });
    if (scheduleSnapshot.exists && scheduleSnapshot.data()) {
      const schedule = scheduleSnapshot.data()!;
      const totalInstallments = integerValue(schedule.totalInstallments ?? 0, 'schedule.totalInstallments');
      const schedulePaid = integerValue(schedule.paidInstallments ?? 0, 'schedule.paidInstallments');
      const monthlyAmount = integerValue(
        schedule.monthlyAmountMinor ?? account.monthlyInstallmentMinor ?? 0,
        'schedule.monthlyAmountMinor',
      );
      const paidInstallments = Math.min(
        totalInstallments,
        settled
          ? totalInstallments
          : schedulePaid + (monthlyAmount > 0 ? Math.floor(amount / monthlyAmount) : 0),
      );
      transaction.update(scheduleRef, {
        paidInstallments,
        nextDueMillis,
        status: totalInstallments > 0 && paidInstallments >= totalInstallments ? 'settled' : 'active',
        updatedAtMillis: now,
      });
    }
    const audit = auditData(
      request,
      'create',
      'installment_payment',
      paymentId,
      { paidMinor: paid, balanceMinor: balance },
      { paidMinor: paid + amount, balanceMinor: balance - amount },
      'Installment payment recorded by a trusted backend transaction.',
    );
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { paymentId, status: 'recorded' };
});

function commissionMinor(amountMinor: number, commissionBps: number) {
  return Math.floor((amountMinor * commissionBps + 5000) / 10000);
}

function creditPeriodId(cardId: string, year: number, month: number) {
  return `${cardId}_${year}_${month}`;
}

function creditPeriodData(
  card: Record<string, any>,
  cardId: string,
  year: number,
  month: number,
  existing: Record<string, any> | undefined,
  depositDelta: number,
  purchaseDelta: number,
) {
  const openingBalance = existing?.openingBalanceMinor ?? Number(card.availableBalanceMinor ?? 0);
  const effectiveLimit = Number(card.nextCreditLimitMinor ?? card.creditLimitMinor ?? 0);
  const openingDebt = existing?.openingDebtMinor ?? Math.max(0, effectiveLimit - openingBalance);
  const qualifyingDeposits = Number(existing?.qualifyingDepositsMinor ?? 0) + depositDelta;
  const remainingDebt = Math.max(0, openingDebt - qualifyingDeposits);
  const closingBalance =
    Number(existing?.closingBalanceMinor ?? card.availableBalanceMinor ?? 0) -
    purchaseDelta +
    depositDelta;
  return {
    id: creditPeriodId(cardId, year, month),
    cardId,
    year,
    month,
    openingBalanceMinor: openingBalance,
    openingDebtMinor: openingDebt,
    qualifyingDepositsMinor: qualifyingDeposits,
    remainingDebtMinor: remainingDebt,
    closingBalanceMinor: closingBalance,
    fullyPaid: remainingDebt === 0,
    effectiveLimitMinor: effectiveLimit,
    updatedAtMillis: Date.now(),
  };
}

export const createCreditCard = onCall(async (request) => {
  const auth = requireFinanceOperator(request);
  const cardId = stringValue(request.data?.cardId, 'cardId');
  const title = stringValue(request.data?.title, 'title');
  const cardholderName = stringValue(request.data?.cardholderName, 'cardholderName');
  const bankName = stringValue(request.data?.bankName, 'bankName');
  const lastFour = stringValue(request.data?.lastFour, 'lastFour');
  if (!/^\d{4}$/.test(lastFour)) throw new HttpsError('invalid-argument', 'lastFour must contain four digits.');
  const creditLimit = integerValue(request.data?.creditLimitMinor, 'creditLimitMinor', { positive: true });
  const openingBalance = integerValue(request.data?.openingBalanceMinor, 'openingBalanceMinor');
  const dueDay = integerValue(request.data?.dueDay, 'dueDay', { positive: true });
  const statementClosingDay = integerValue(request.data?.statementClosingDay ?? 1, 'statementClosingDay', { positive: true });
  if (dueDay > 31 || statementClosingDay > 31) {
    throw new HttpsError('invalid-argument', 'Statement and due days must be between 1 and 31.');
  }
  const now = Date.now();
  const date = new Date(now);
  const cardRef = tenantCollection(request, 'credit_cards').doc(cardId);
  const depositRef = tenantCollection(request, 'credit_deposits').doc(`${cardId}_opening`);
  const periodRef = tenantCollection(request, 'credit_periods').doc(creditPeriodId(cardId, date.getUTCFullYear(), date.getUTCMonth() + 1));
  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(cardRef);
    if (existing.exists) return;
    const debt = Math.max(0, creditLimit - openingBalance);
    transaction.set(cardRef, {
      id: cardId,
      title,
      cardholderName,
      bankName,
      maskedNumber: `•••• •••• •••• ${lastFour}`,
      lastFour,
      creditLimitMinor: creditLimit,
      availableBalanceMinor: openingBalance,
      monthlyPaidMinor: 0,
      currentMonthlyDebtMinor: debt,
      dueDay,
      statementClosingDay,
      active: true,
      notes: typeof request.data?.notes === 'string' ? request.data.notes.trim() : '',
      colorHex: typeof request.data?.colorHex === 'string' ? request.data.colorHex.trim() : '',
      logoUrl: typeof request.data?.logoUrl === 'string' ? request.data.logoUrl.trim() : '',
      createdAtMillis: now,
      updatedAtMillis: now,
    });
    transaction.set(depositRef, {
      id: depositRef.id,
      cardId,
      amountMinor: 0,
      depositDateMillis: now,
      qualifiesForMonthlyDebt: false,
      createdBy: auth.uid,
      createdAtMillis: now,
      updatedAtMillis: now,
    });
    transaction.set(periodRef, {
      id: periodRef.id,
      cardId,
      year: date.getUTCFullYear(),
      month: date.getUTCMonth() + 1,
      openingBalanceMinor: openingBalance,
      openingDebtMinor: debt,
      qualifyingDepositsMinor: 0,
      remainingDebtMinor: debt,
      closingBalanceMinor: openingBalance,
      fullyPaid: debt === 0,
      updatedAtMillis: now,
    });
    const audit = auditData(
      request,
      'create',
      'credit_card',
      cardId,
      null,
      { creditLimitMinor: creditLimit, openingBalanceMinor: openingBalance },
      'Credit card created by a trusted backend transaction.',
    );
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { cardId };
});

export const updateCreditCard = onCall(async (request) => {
  const auth = requireFinanceOperator(request);
  if (auth.token.role !== 'manager' && !(auth.token.permissions as Record<string, unknown> | undefined)?.['records.edit']) {
    throw new HttpsError('permission-denied', 'Card editing permission is required.');
  }
  const cardId = stringValue(request.data?.cardId, 'cardId');
  const lastFour = stringValue(request.data?.lastFour, 'lastFour');
  if (!/^\d{4}$/.test(lastFour)) throw new HttpsError('invalid-argument', 'lastFour must contain four digits.');
  const creditLimit = integerValue(request.data?.creditLimitMinor, 'creditLimitMinor', { positive: true });
  const dueDay = integerValue(request.data?.dueDay, 'dueDay', { positive: true });
  const statementClosingDay = integerValue(request.data?.statementClosingDay ?? 1, 'statementClosingDay', { positive: true });
  if (dueDay > 31 || statementClosingDay > 31) throw new HttpsError('invalid-argument', 'Statement and due days must be between 1 and 31.');
  const cardRef = tenantCollection(request, 'credit_cards').doc(cardId);
  const now = Date.now();
  const date = new Date(now);
  const periodRef = tenantCollection(request, 'credit_periods').doc(creditPeriodId(cardId, date.getUTCFullYear(), date.getUTCMonth() + 1));
  await db.runTransaction(async (transaction) => {
    const cardSnapshot = await transaction.get(cardRef);
    if (!cardSnapshot.exists || !cardSnapshot.data()) throw new HttpsError('not-found', 'Credit card was not found.');
    const periodSnapshot = await transaction.get(periodRef);
    const current = cardSnapshot.data()!;
    const data = {
      title: stringValue(request.data?.title, 'title'),
      cardholderName: stringValue(request.data?.cardholderName, 'cardholderName'),
      bankName: stringValue(request.data?.bankName, 'bankName'),
      lastFour,
      maskedNumber: `•••• •••• •••• ${lastFour}`,
      dueDay,
      statementClosingDay,
      notes: typeof request.data?.notes === 'string' ? request.data.notes.trim() : '',
      colorHex: typeof request.data?.colorHex === 'string' ? request.data.colorHex.trim() : '',
      logoUrl: typeof request.data?.logoUrl === 'string' ? request.data.logoUrl.trim() : '',
      updatedAtMillis: now,
    };
    if (periodSnapshot.exists && periodSnapshot.data()?.year === date.getUTCFullYear() && periodSnapshot.data()?.month === date.getUTCMonth() + 1) {
      transaction.update(cardRef, { ...data, nextCreditLimitMinor: creditLimit });
    } else {
      transaction.update(cardRef, { ...data, creditLimitMinor: creditLimit, nextCreditLimitMinor: null });
    }
    const audit = auditData(request, 'update', 'credit_card', cardId, { creditLimitMinor: current.creditLimitMinor }, { ...data, creditLimitMinor: creditLimit, effectiveNextPeriod: periodSnapshot.exists }, 'Credit card updated by trusted backend.');
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { cardId };
});

export const recordCreditPurchase = onCall(async (request) => {
  const auth = requireFinanceOperator(request);
  const cardId = stringValue(request.data?.cardId, 'cardId');
  const brandId = stringValue(request.data?.brandId, 'brandId');
  const purchaseId = stringValue(request.data?.purchaseId, 'purchaseId');
  const amount = integerValue(request.data?.amountMinor, 'amountMinor', { positive: true });
  const purchaseDateMillis = integerValue(request.data?.purchaseDateMillis, 'purchaseDateMillis', { positive: true });
  const year = integerValue(request.data?.year, 'year', { positive: true });
  const month = integerValue(request.data?.month, 'month', { positive: true });
  if (month > 12) throw new HttpsError('invalid-argument', 'month must be between 1 and 12.');
  const cardRef = tenantCollection(request, 'credit_cards').doc(cardId);
  const brandRef = tenantCollection(request, 'brands').doc(brandId);
  const purchaseRef = tenantCollection(request, 'credit_purchases').doc(purchaseId);
  const periodRef = tenantCollection(request, 'credit_periods').doc(creditPeriodId(cardId, year, month));
  await db.runTransaction(async (transaction) => {
    const cardSnapshot = await transaction.get(cardRef);
    const brandSnapshot = await transaction.get(brandRef);
    const existingPurchase = await transaction.get(purchaseRef);
    const existingPeriod = await transaction.get(periodRef);
    if (existingPurchase.exists) return;
    if (!cardSnapshot.exists || !cardSnapshot.data()) {
      throw new HttpsError('not-found', 'Credit card was not found.');
    }
    if (!brandSnapshot.exists || !brandSnapshot.data() || brandSnapshot.data()!.active !== true) {
      throw new HttpsError('failed-precondition', 'The selected brand is not active.');
    }
    const card = cardSnapshot.data()!;
    const brand = brandSnapshot.data()!;
    if (card.active !== true) throw new HttpsError('failed-precondition', 'The credit card is inactive.');
    const bps = integerValue(brand.commissionBps, 'commissionBps');
    if (bps < 0 || bps > 10000) throw new HttpsError('failed-precondition', 'The brand commission is invalid.');
    const commission = commissionMinor(amount, bps);
    const period = creditPeriodData(card, cardId, year, month, existingPeriod.data(), 0, amount);
    const now = Date.now();
    transaction.update(cardRef, {
      availableBalanceMinor: Number(card.availableBalanceMinor ?? 0) - amount,
      currentMonthlyDebtMinor: period.remainingDebtMinor,
      monthlyPaidMinor: period.qualifyingDepositsMinor,
      updatedAtMillis: now,
      ...(existingPeriod.exists ? {} : {
        creditLimitMinor: period.effectiveLimitMinor,
        nextCreditLimitMinor: null,
      }),
    });
    transaction.set(purchaseRef, {
      id: purchaseId,
      cardId,
      brandId,
      brandName: String(brand.name ?? ''),
      providerId: String(brand.providerId ?? ''),
      providerName: String(brand.providerName ?? ''),
      amountMinor: amount,
      commissionMinor: commission,
      commissionBps: bps,
      expectedNetMinor: amount - commission,
      purchaseDateMillis,
      createdBy: auth.uid,
      createdAtMillis: now,
      updatedAtMillis: now,
      isDeleted: false,
      posMachineId: String(brand.posMachineId ?? ''),
      posMachineName: String(brand.posMachineName ?? ''),
    });
    transaction.set(periodRef, period);
    const audit = auditData(
      request,
      'create',
      'credit_purchase',
      purchaseId,
      null,
      { amountMinor: amount, commissionMinor: commission, commissionBps: bps },
      'Credit purchase posted by a trusted backend transaction.',
    );
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { purchaseId };
});

export const recordCreditDeposit = onCall(async (request) => {
  const auth = requireFinanceOperator(request);
  const cardId = stringValue(request.data?.cardId, 'cardId');
  const depositId = stringValue(request.data?.depositId, 'depositId');
  const amount = integerValue(request.data?.amountMinor, 'amountMinor');
  if (amount < 0) throw new HttpsError('invalid-argument', 'amountMinor cannot be negative.');
  const depositDateMillis = integerValue(request.data?.depositDateMillis, 'depositDateMillis', { positive: true });
  const year = integerValue(request.data?.year, 'year', { positive: true });
  const month = integerValue(request.data?.month, 'month', { positive: true });
  if (month > 12) throw new HttpsError('invalid-argument', 'month must be between 1 and 12.');
  const cardRef = tenantCollection(request, 'credit_cards').doc(cardId);
  const depositRef = tenantCollection(request, 'credit_deposits').doc(depositId);
  const periodRef = tenantCollection(request, 'credit_periods').doc(creditPeriodId(cardId, year, month));
  const threshold = await financeApprovalThreshold(request);
  await db.runTransaction(async (transaction) => {
    const cardSnapshot = await transaction.get(cardRef);
    const existingDeposit = await transaction.get(depositRef);
    const existingPeriod = await transaction.get(periodRef);
    if (existingDeposit.exists) return;
    if (!cardSnapshot.exists || !cardSnapshot.data()) {
      throw new HttpsError('not-found', 'Credit card was not found.');
    }
    const card = cardSnapshot.data()!;
    if (card.active !== true) throw new HttpsError('failed-precondition', 'The credit card is inactive.');
    const manager = auth.token.role === 'manager';
    const approvalStatus = manager || amount <= threshold ? 'approved' : 'pending';
    const now = Date.now();
    if (approvalStatus === 'approved') {
      const period = creditPeriodData(card, cardId, year, month, existingPeriod.data(), amount, 0);
      transaction.update(cardRef, {
        availableBalanceMinor: Number(card.availableBalanceMinor ?? 0) + amount,
        currentMonthlyDebtMinor: period.remainingDebtMinor,
        monthlyPaidMinor: period.qualifyingDepositsMinor,
        updatedAtMillis: now,
        ...(existingPeriod.exists ? {} : {
          creditLimitMinor: period.effectiveLimitMinor,
          nextCreditLimitMinor: null,
        }),
      });
      transaction.set(periodRef, period);
    }
    const depositData = {
      id: depositId,
      cardId,
      amountMinor: amount,
      depositDateMillis,
      qualifiesForMonthlyDebt: true,
      approvalStatus,
      createdBy: auth.uid,
      createdAtMillis: now,
      updatedAtMillis: now,
      ...(approvalStatus === 'approved' ? { approvedBy: auth.uid, approvedAtMillis: now } : {}),
    };
    transaction.set(depositRef, depositData);
    const audit = auditData(
      request,
      'create',
      'credit_deposit',
      depositId,
      null,
      { amountMinor: amount, qualifiesForMonthlyDebt: true, approvalStatus },
      approvalStatus === 'pending'
        ? 'Credit deposit submitted for manager approval.'
        : 'Credit deposit posted by a trusted backend transaction.',
    );
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { depositId };
});

export const approveCreditDeposit = onCall(async (request) => {
  const auth = requireManager(request);
  const depositId = stringValue(request.data?.depositId, 'depositId');
  const depositRef = tenantCollection(request, 'credit_deposits').doc(depositId);
  await db.runTransaction(async (transaction) => {
    const depositSnapshot = await transaction.get(depositRef);
    if (!depositSnapshot.exists || !depositSnapshot.data()) throw new HttpsError('not-found', 'Deposit was not found.');
    const deposit = depositSnapshot.data()!;
    if (deposit.approvalStatus === 'approved') return;
    if (deposit.approvalStatus !== 'pending') throw new HttpsError('failed-precondition', 'Only pending deposits can be approved.');
    const cardId = stringValue(deposit.cardId, 'cardId');
    const cardRef = tenantCollection(request, 'credit_cards').doc(cardId);
    const cardSnapshot = await transaction.get(cardRef);
    if (!cardSnapshot.exists || !cardSnapshot.data()) throw new HttpsError('not-found', 'Credit card was not found.');
    const date = new Date(integerValue(deposit.depositDateMillis, 'depositDateMillis', { positive: true }));
    const year = date.getUTCFullYear();
    const month = date.getUTCMonth() + 1;
    const periodRef = tenantCollection(request, 'credit_periods').doc(creditPeriodId(cardId, year, month));
    const periodSnapshot = await transaction.get(periodRef);
    if (!periodSnapshot.exists || !periodSnapshot.data()) throw new HttpsError('failed-precondition', 'The deposit accounting period is missing.');
    const amount = integerValue(deposit.amountMinor, 'amountMinor');
    const period = creditPeriodData(cardSnapshot.data()!, cardId, year, month, periodSnapshot.data(), amount, 0);
    const now = Date.now();
    transaction.update(cardRef, {
      availableBalanceMinor: Number(cardSnapshot.data()!.availableBalanceMinor ?? 0) + amount,
      currentMonthlyDebtMinor: period.remainingDebtMinor,
      monthlyPaidMinor: period.qualifyingDepositsMinor,
      updatedAtMillis: now,
    });
    transaction.update(periodRef, period);
    transaction.update(depositRef, {
      approvalStatus: 'approved',
      approvedBy: auth.uid,
      approvedAtMillis: now,
      updatedAtMillis: now,
    });
    const audit = auditData(request, 'approve', 'credit_deposit', depositId, { approvalStatus: 'pending' }, { approvalStatus: 'approved', amountMinor: amount }, 'Credit deposit approved by manager.');
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { depositId, status: 'approved' };
});

export const rejectPendingOperation = onCall(async (request) => {
  const auth = requireManager(request);
  const entityType = stringValue(request.data?.entityType, 'entityType');
  const entityId = stringValue(request.data?.entityId, 'entityId');
  const reason = stringValue(request.data?.reason, 'reason');
  const definitions: Record<string, { collection: string; statusField: string }> = {
    credit_deposit: { collection: 'credit_deposits', statusField: 'approvalStatus' },
    bank_movement: { collection: 'bank_movements', statusField: 'approvalStatus' },
    treasury_movement: { collection: 'treasury_movements', statusField: 'approvalStatus' },
    expense: { collection: 'expenses', statusField: 'status' },
    personal_withdrawal: { collection: 'personal_withdrawals', statusField: 'status' },
    treasury_transfer: { collection: 'treasury_transfers', statusField: 'status' },
  };
  const definition = definitions[entityType];
  if (!definition) throw new HttpsError('invalid-argument', 'Unsupported pending operation type.');
  const ref = tenantCollection(request, definition.collection).doc(entityId);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(ref);
    if (!snapshot.exists || !snapshot.data()) throw new HttpsError('not-found', 'The pending operation was not found.');
    const current = snapshot.data()!;
    const currentStatus = current[definition.statusField];
    if (currentStatus === 'approved') throw new HttpsError('failed-precondition', 'An approved operation cannot be rejected.');
    if (currentStatus === 'rejected') return;
    if (currentStatus !== 'pending') throw new HttpsError('failed-precondition', 'Only pending operations can be rejected.');
    const now = Date.now();
    transaction.update(ref, {
      [definition.statusField]: 'rejected',
      rejectionReason: reason,
      rejectedBy: auth.uid,
      rejectedAtMillis: now,
      updatedAtMillis: now,
    });
    const audit = auditData(
      request,
      'reject',
      entityType,
      entityId,
      { [definition.statusField]: currentStatus },
      { [definition.statusField]: 'rejected', rejectionReason: reason },
      reason,
    );
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { entityType, entityId, status: 'rejected' };
});

async function assertCreditPurchaseNotSettled(request: AuthenticatedRequest, purchaseId: string) {
  const settlements = await tenantCollection(request, 'settlements')
    .where('includedTransactionIds', 'array-contains', purchaseId)
    .limit(10)
    .get();
  if (settlements.docs.some((item) => item.data().approvalStatus === 'approved' || Number(item.data().collectedMinor ?? 0) > 0)) {
    throw new HttpsError('failed-precondition', 'A purchase in an approved or collected settlement cannot be corrected.');
  }
}

export const correctCreditPurchase = onCall(async (request) => {
  const auth = requireFinanceOperator(request);
  const purchaseId = stringValue(request.data?.purchaseId, 'purchaseId');
  const amount = integerValue(request.data?.amountMinor, 'amountMinor', { positive: true });
  const reason = typeof request.data?.reason === 'string' && request.data.reason.trim().length > 0
    ? request.data.reason.trim()
    : 'Authorized credit purchase correction';
  const year = integerValue(request.data?.year, 'year', { positive: true });
  const month = integerValue(request.data?.month, 'month', { positive: true });
  if (month > 12) throw new HttpsError('invalid-argument', 'month must be between 1 and 12.');
  await assertCreditPurchaseNotSettled(request, purchaseId);
  const purchaseRef = tenantCollection(request, 'credit_purchases').doc(purchaseId);
  await db.runTransaction(async (transaction) => {
    const purchaseSnapshot = await transaction.get(purchaseRef);
    if (!purchaseSnapshot.exists || !purchaseSnapshot.data()) throw new HttpsError('not-found', 'Purchase was not found.');
    const purchase = purchaseSnapshot.data()!;
    if (purchase.isDeleted === true) throw new HttpsError('failed-precondition', 'A deleted purchase cannot be corrected.');
    const cardRef = tenantCollection(request, 'credit_cards').doc(stringValue(purchase.cardId, 'cardId'));
    const cardId = stringValue(purchase.cardId, 'cardId');
    const targetPeriodRef = tenantCollection(request, 'credit_periods').doc(creditPeriodId(cardId, year, month));
    const nowDate = new Date();
    const currentYear = nowDate.getUTCFullYear();
    const currentMonth = nowDate.getUTCMonth() + 1;
    const currentPeriodRef = tenantCollection(request, 'credit_periods').doc(creditPeriodId(cardId, currentYear, currentMonth));
    const cardSnapshot = await transaction.get(cardRef);
    const targetPeriodSnapshot = await transaction.get(targetPeriodRef);
    const currentPeriodSnapshot = targetPeriodRef.path === currentPeriodRef.path
      ? targetPeriodSnapshot
      : await transaction.get(currentPeriodRef);
    if (!cardSnapshot.exists || !cardSnapshot.data() || !targetPeriodSnapshot.exists || !targetPeriodSnapshot.data()) {
      throw new HttpsError('failed-precondition', 'The purchase accounting period is missing.');
    }
    const bps = integerValue(purchase.commissionBps, 'commissionBps');
    const commission = commissionMinor(amount, bps);
    const oldAmount = integerValue(purchase.amountMinor, 'previousAmountMinor', { positive: true });
    const now = Date.now();
    transaction.update(cardRef, {
      availableBalanceMinor: Number(cardSnapshot.data()!.availableBalanceMinor ?? 0) + oldAmount - amount,
      updatedAtMillis: now,
    });
    const difference = oldAmount - amount;
    const isCurrentPeriod = year === currentYear && month === currentMonth;
    if (isCurrentPeriod) {
      transaction.update(targetPeriodRef, {
        closingBalanceMinor: Number(targetPeriodSnapshot.data()!.closingBalanceMinor ?? 0) + difference,
        updatedAtMillis: now,
      });
    } else {
      const currentPeriod = currentPeriodSnapshot.exists && currentPeriodSnapshot.data()
        ? currentPeriodSnapshot.data()!
        : creditPeriodData(cardSnapshot.data()!, cardId, currentYear, currentMonth, undefined, 0, 0);
      transaction.set(currentPeriodRef, {
        ...currentPeriod,
        closingBalanceMinor: Number(currentPeriod.closingBalanceMinor ?? 0) + difference,
        correctionMinor: Number((currentPeriod as Record<string, any>).correctionMinor ?? 0) + difference,
        updatedAtMillis: now,
      });
    }
    const correctionRef = tenantCollection(request, 'credit_corrections').doc();
    transaction.set(correctionRef, {
      id: correctionRef.id,
      sourceType: 'credit_purchase',
      sourceId: purchaseId,
      sourcePeriodId: creditPeriodId(cardId, year, month),
      correctionPeriodId: creditPeriodId(cardId, currentYear, currentMonth),
      previousAmountMinor: oldAmount,
      newAmountMinor: amount,
      differenceMinor: difference,
      reason,
      createdBy: auth.uid,
      createdAtMillis: now,
      updatedAtMillis: now,
    });
    const audit = auditData(
      request,
      'update_amount',
      'credit_purchase',
      purchaseId,
      { amountMinor: oldAmount, commissionMinor: purchase.commissionMinor },
      { amountMinor: amount, commissionMinor: commission },
      reason,
    );
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { purchaseId, status: 'corrected' };
});

export const correctCreditDeposit = onCall(async (request) => {
  const auth = requireManager(request);
  const depositId = stringValue(request.data?.depositId, 'depositId');
  const amount = integerValue(request.data?.amountMinor, 'amountMinor');
  if (amount < 0) throw new HttpsError('invalid-argument', 'amountMinor cannot be negative.');
  const year = integerValue(request.data?.year, 'year', { positive: true });
  const month = integerValue(request.data?.month, 'month', { positive: true });
  const reason = stringValue(request.data?.reason, 'reason');
  if (month > 12) throw new HttpsError('invalid-argument', 'month must be between 1 and 12.');
  const depositRef = tenantCollection(request, 'credit_deposits').doc(depositId);
  await db.runTransaction(async (transaction) => {
    const depositSnapshot = await transaction.get(depositRef);
    if (!depositSnapshot.exists || !depositSnapshot.data()) throw new HttpsError('not-found', 'Deposit was not found.');
    const deposit = depositSnapshot.data()!;
    if (deposit.approvalStatus === 'pending') throw new HttpsError('failed-precondition', 'A pending deposit must be approved before correction.');
    const cardId = stringValue(deposit.cardId, 'cardId');
    const cardRef = tenantCollection(request, 'credit_cards').doc(cardId);
    const targetPeriodRef = tenantCollection(request, 'credit_periods').doc(creditPeriodId(cardId, year, month));
    const today = new Date();
    const currentYear = today.getUTCFullYear();
    const currentMonth = today.getUTCMonth() + 1;
    const currentPeriodRef = tenantCollection(request, 'credit_periods').doc(creditPeriodId(cardId, currentYear, currentMonth));
    const cardSnapshot = await transaction.get(cardRef);
    const targetPeriodSnapshot = await transaction.get(targetPeriodRef);
    const currentPeriodSnapshot = targetPeriodRef.path === currentPeriodRef.path
      ? targetPeriodSnapshot
      : await transaction.get(currentPeriodRef);
    if (!cardSnapshot.exists || !cardSnapshot.data() || !targetPeriodSnapshot.exists || !targetPeriodSnapshot.data()) {
      throw new HttpsError('failed-precondition', 'The deposit accounting period is missing.');
    }
    const oldAmount = integerValue(deposit.amountMinor, 'previousAmountMinor');
    const difference = amount - oldAmount;
    const now = Date.now();
    if (year === currentYear && month === currentMonth) {
      const period = targetPeriodSnapshot.data()!;
      const paid = Number(period.qualifyingDepositsMinor ?? 0) + difference;
      transaction.update(targetPeriodRef, {
        qualifyingDepositsMinor: paid,
        remainingDebtMinor: Math.max(0, Number(period.openingDebtMinor ?? 0) - paid),
        closingBalanceMinor: Number(period.closingBalanceMinor ?? 0) + difference,
        updatedAtMillis: now,
      });
      transaction.update(cardRef, {
        availableBalanceMinor: Number(cardSnapshot.data()!.availableBalanceMinor ?? 0) + difference,
        currentMonthlyDebtMinor: Math.max(0, Number(period.openingDebtMinor ?? 0) - paid),
        monthlyPaidMinor: paid,
        updatedAtMillis: now,
      });
    } else {
      transaction.update(cardRef, {
        availableBalanceMinor: Number(cardSnapshot.data()!.availableBalanceMinor ?? 0) + difference,
        updatedAtMillis: now,
      });
      const currentPeriod = currentPeriodSnapshot.exists && currentPeriodSnapshot.data()
        ? currentPeriodSnapshot.data()!
        : creditPeriodData(cardSnapshot.data()!, cardId, currentYear, currentMonth, undefined, 0, 0);
      transaction.set(currentPeriodRef, {
        ...currentPeriod,
        closingBalanceMinor: Number(currentPeriod.closingBalanceMinor ?? 0) + difference,
        correctionMinor: Number((currentPeriod as Record<string, any>).correctionMinor ?? 0) + difference,
        updatedAtMillis: now,
      });
    }
    const correctionRef = tenantCollection(request, 'credit_corrections').doc();
    transaction.set(correctionRef, {
      id: correctionRef.id,
      sourceType: 'credit_deposit',
      sourceId: depositId,
      sourcePeriodId: creditPeriodId(cardId, year, month),
      correctionPeriodId: creditPeriodId(cardId, currentYear, currentMonth),
      previousAmountMinor: oldAmount,
      newAmountMinor: amount,
      differenceMinor: difference,
      reason,
      createdBy: auth.uid,
      createdAtMillis: now,
      updatedAtMillis: now,
    });
    const audit = auditData(
      request,
      'correct',
      'credit_deposit',
      depositId,
      { amountMinor: oldAmount },
      { amountMinor: amount, differenceMinor: difference },
      reason,
    );
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { depositId, status: 'corrected' };
});

export const deleteCreditPurchase = onCall(async (request) => {
  const auth = requireFinanceOperator(request);
  const purchaseId = stringValue(request.data?.purchaseId, 'purchaseId');
  const year = integerValue(request.data?.year, 'year', { positive: true });
  const month = integerValue(request.data?.month, 'month', { positive: true });
  if (month > 12) throw new HttpsError('invalid-argument', 'month must be between 1 and 12.');
  await assertCreditPurchaseNotSettled(request, purchaseId);
  const purchaseRef = tenantCollection(request, 'credit_purchases').doc(purchaseId);
  await db.runTransaction(async (transaction) => {
    const purchaseSnapshot = await transaction.get(purchaseRef);
    if (!purchaseSnapshot.exists || !purchaseSnapshot.data()) throw new HttpsError('not-found', 'Purchase was not found.');
    const purchase = purchaseSnapshot.data()!;
    if (purchase.isDeleted === true) return;
    const cardId = stringValue(purchase.cardId, 'cardId');
    const targetPeriodRef = tenantCollection(request, 'credit_periods').doc(creditPeriodId(cardId, year, month));
    const today = new Date();
    const currentYear = today.getUTCFullYear();
    const currentMonth = today.getUTCMonth() + 1;
    const currentPeriodRef = tenantCollection(request, 'credit_periods').doc(creditPeriodId(cardId, currentYear, currentMonth));
    const cardRef = tenantCollection(request, 'credit_cards').doc(cardId);
    const cardSnapshot = await transaction.get(cardRef);
    const targetPeriodSnapshot = await transaction.get(targetPeriodRef);
    const currentPeriodSnapshot = targetPeriodRef.path === currentPeriodRef.path
      ? targetPeriodSnapshot
      : await transaction.get(currentPeriodRef);
    if (!cardSnapshot.exists || !cardSnapshot.data() || !targetPeriodSnapshot.exists || !targetPeriodSnapshot.data()) {
      throw new HttpsError('failed-precondition', 'The purchase accounting period is missing.');
    }
    const amount = integerValue(purchase.amountMinor, 'amountMinor', { positive: true });
    const now = Date.now();
    transaction.update(cardRef, {
      availableBalanceMinor: Number(cardSnapshot.data()!.availableBalanceMinor ?? 0) + amount,
      updatedAtMillis: now,
    });
    if (year === currentYear && month === currentMonth) {
      transaction.update(targetPeriodRef, {
        closingBalanceMinor: Number(targetPeriodSnapshot.data()!.closingBalanceMinor ?? 0) + amount,
        updatedAtMillis: now,
      });
    } else {
      const currentPeriod = currentPeriodSnapshot.exists && currentPeriodSnapshot.data()
        ? currentPeriodSnapshot.data()!
        : creditPeriodData(cardSnapshot.data()!, cardId, currentYear, currentMonth, undefined, 0, 0);
      transaction.set(currentPeriodRef, {
        ...currentPeriod,
        closingBalanceMinor: Number(currentPeriod.closingBalanceMinor ?? 0) + amount,
        correctionMinor: Number((currentPeriod as Record<string, any>).correctionMinor ?? 0) + amount,
        updatedAtMillis: now,
      });
      const correctionRef = tenantCollection(request, 'credit_corrections').doc();
      transaction.set(correctionRef, {
        id: correctionRef.id,
        sourceType: 'credit_purchase_delete',
        sourceId: purchaseId,
        sourcePeriodId: creditPeriodId(cardId, year, month),
        correctionPeriodId: creditPeriodId(cardId, currentYear, currentMonth),
        differenceMinor: amount,
        reason: 'Authorized credit purchase deletion',
        createdBy: auth.uid,
        createdAtMillis: now,
        updatedAtMillis: now,
      });
    }
    transaction.update(purchaseRef, {
      isDeleted: true,
      deletedBy: auth.uid,
      updatedAtMillis: now,
    });
    const audit = auditData(
      request,
      'delete',
      'credit_purchase',
      purchaseId,
      { isDeleted: false, amountMinor: amount },
      { isDeleted: true },
      'Credit purchase deleted by a trusted backend transaction.',
    );
    transaction.set(tenantCollection(request, 'audit_logs').doc(audit.id as string), audit);
  });
  return { purchaseId, status: 'deleted' };
});
