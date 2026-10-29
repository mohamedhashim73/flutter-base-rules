const assert = require('node:assert/strict');
const admin = require('firebase-admin');

const projectId = 'credixa-422a1';
const organizationId = `integration_${Date.now()}`;
const functionsBase = `http://127.0.0.1:5001/${projectId}/europe-west1`;
const authBase = 'http://127.0.0.1:9099';
const testPassword = process.env.CREDEXA_TEST_PASSWORD;
if (!testPassword) {
  throw new Error('Set CREDEXA_TEST_PASSWORD before running integration tests.');
}

process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= '127.0.0.1:9099';
admin.initializeApp({ projectId });
const db = admin.firestore();
const auth = admin.auth();

async function ensureUser(email, role, permissions) {
  let user;
  try {
    user = await auth.createUser({ email, password: testPassword });
  } catch (error) {
    if (error.code !== 'auth/email-already-exists') throw error;
    user = await auth.getUserByEmail(email);
  }
  await auth.setCustomUserClaims(user.uid, {
    role,
    permissions,
    organizationId,
  });
  return user;
}

async function tokenFor(email) {
  const response = await fetch(
    `${authBase}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`,
    {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email, password: testPassword, returnSecureToken: true }),
    },
  );
  const body = await response.json();
  if (!response.ok) throw new Error(`Auth sign-in failed: ${JSON.stringify(body)}`);
  return body.idToken;
}

async function call(name, token, data) {
  const response = await fetch(`${functionsBase}/${name}`, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${token}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify({ data }),
  });
  const body = await response.json();
  if (!response.ok || body.error) {
    throw new Error(`${name} failed: ${JSON.stringify(body)}`);
  }
  return body.data;
}

async function expectFailure(name, token, data) {
  await assert.rejects(() => call(name, token, data));
}

function tenant(collection) {
  return db.collection('organizations').doc(organizationId).collection(collection);
}

async function main() {
  const managerEmail = `${organizationId}_manager@example.com`;
  const employeeEmail = `${organizationId}_employee@example.com`;
  await ensureUser(managerEmail, 'manager', {
    'records.edit': true,
    'settlements.review': true,
    'treasury.reconcile': true,
  });
  await ensureUser(employeeEmail, 'accountant', { 'settlements.review': true });
  const managerToken = await tokenFor(managerEmail);
  const employeeToken = await tokenFor(employeeEmail);

  const brandId = `${organizationId}_brand`;
  const bankId = `${organizationId}_bank`;
  const raceBankId = `${organizationId}_race_bank`;
  const treasuryId = `${organizationId}_treasury`;
  const cardId = `${organizationId}_card`;
  const now = Date.now();
  await tenant('brands').doc(brandId).set({
    id: brandId,
    name: 'Integration Brand',
    providerId: 'integration_provider',
    providerName: 'Integration Provider',
    commissionBps: 200,
    active: true,
    receivingCompanyId: 'integration_company',
    receivingCompanyName: 'Integration Company',
    settlementBankAccountId: bankId,
    settlementBankAccountName: 'Integration Bank',
    posMachineId: 'integration_pos',
    posMachineName: 'Integration POS',
    updatedAtMillis: now,
  });
  await tenant('bank_accounts').doc(bankId).set({
    id: bankId,
    bankName: 'Integration Bank',
    accountName: 'Primary',
    lastFour: '4242',
    active: true,
    openingBalanceMinor: 10000000,
    balanceMinor: 10000000,
    updatedAtMillis: now,
  });
  await tenant('bank_accounts').doc(raceBankId).set({
    id: raceBankId,
    bankName: 'Race Bank',
    accountName: 'Concurrency Test',
    lastFour: '0001',
    active: true,
    openingBalanceMinor: 1000,
    balanceMinor: 1000,
    updatedAtMillis: now,
  });
  await tenant('treasury_accounts').doc(treasuryId).set({
    id: treasuryId,
    name: 'Integration Treasury',
    active: true,
    openingBalanceMinor: 5000000,
    balanceMinor: 5000000,
    updatedAtMillis: now,
  });

  await call('createCreditCard', managerToken, {
    cardId,
    title: 'Integration Card',
    cardholderName: 'Integration User',
    bankName: 'Integration Bank',
    lastFour: '1111',
    creditLimitMinor: 4000000,
    openingBalanceMinor: -100000,
    dueDay: 1,
    statementClosingDay: 1,
  });
  let card = (await tenant('credit_cards').doc(cardId).get()).data();
  assert.equal(card.currentMonthlyDebtMinor, 4100000);

  const approvedDepositId = `${organizationId}_deposit_approved`;
  await call('recordCreditDeposit', managerToken, {
    cardId,
    depositId: approvedDepositId,
    amountMinor: 1000000,
    depositDateMillis: now,
    year: new Date(now).getUTCFullYear(),
    month: new Date(now).getUTCMonth() + 1,
  });
  card = (await tenant('credit_cards').doc(cardId).get()).data();
  assert.equal(card.currentMonthlyDebtMinor, 3100000);
  assert.equal(card.availableBalanceMinor, 900000);

  const pendingDepositId = `${organizationId}_deposit_pending`;
  await call('recordCreditDeposit', employeeToken, {
    cardId,
    depositId: pendingDepositId,
    amountMinor: 600000,
    depositDateMillis: now,
    year: new Date(now).getUTCFullYear(),
    month: new Date(now).getUTCMonth() + 1,
  });
  let pendingDeposit = (await tenant('credit_deposits').doc(pendingDepositId).get()).data();
  assert.equal(pendingDeposit.approvalStatus, 'pending');
  card = (await tenant('credit_cards').doc(cardId).get()).data();
  assert.equal(card.availableBalanceMinor, 900000);
  await call('approveCreditDeposit', managerToken, { depositId: pendingDepositId });
  pendingDeposit = (await tenant('credit_deposits').doc(pendingDepositId).get()).data();
  assert.equal(pendingDeposit.approvalStatus, 'approved');

  const duplicateDepositId = `${organizationId}_deposit_duplicate`;
  const beforeDuplicate = (await tenant('credit_cards').doc(cardId).get()).data();
  await Promise.all([
    call('recordCreditDeposit', managerToken, {
      cardId,
      depositId: duplicateDepositId,
      amountMinor: 100000,
      depositDateMillis: now,
      year: new Date(now).getUTCFullYear(),
      month: new Date(now).getUTCMonth() + 1,
    }),
    call('recordCreditDeposit', managerToken, {
      cardId,
      depositId: duplicateDepositId,
      amountMinor: 100000,
      depositDateMillis: now,
      year: new Date(now).getUTCFullYear(),
      month: new Date(now).getUTCMonth() + 1,
    }),
  ]);
  const afterDuplicate = (await tenant('credit_cards').doc(cardId).get()).data();
  assert.equal(
    afterDuplicate.availableBalanceMinor,
    beforeDuplicate.availableBalanceMinor + 100000,
  );

  const rejectedDepositId = `${organizationId}_deposit_rejected`;
  await call('recordCreditDeposit', employeeToken, {
    cardId,
    depositId: rejectedDepositId,
    amountMinor: 700000,
    depositDateMillis: now,
    year: new Date(now).getUTCFullYear(),
    month: new Date(now).getUTCMonth() + 1,
  });
  await call('rejectPendingOperation', managerToken, {
    entityType: 'credit_deposit',
    entityId: rejectedDepositId,
    reason: 'Integration rejection',
  });
  const rejectedDeposit = (await tenant('credit_deposits').doc(rejectedDepositId).get()).data();
  assert.equal(rejectedDeposit.approvalStatus, 'rejected');

  const purchaseId = `${organizationId}_purchase`;
  await call('recordCreditPurchase', managerToken, {
    cardId,
    brandId,
    purchaseId,
    amountMinor: 2000000,
    purchaseDateMillis: now,
    year: new Date(now).getUTCFullYear(),
    month: new Date(now).getUTCMonth() + 1,
  });
  const settlementId = `${organizationId}_settlement`;
  await call('createSettlement', managerToken, {
    settlementId,
    brandId,
    periodLabel: 'integration',
    includedTransactionIds: [purchaseId],
  });
  await call('approveSettlement', employeeToken, { settlementId });
  const requestId = `${organizationId}_collection`;
  await call('createCollectionRequest', employeeToken, {
    requestId,
    settlementId,
    amountMinor: 2000000,
    collectionType: 'instant',
  });
  const request = (await tenant('collection_requests').doc(requestId).get()).data();
  assert.equal(request.feeMinor, 2000);
  assert.equal(request.commissionMinor, 40000);
  assert.equal(request.netMinor, 1958000);
  await call('confirmCollectionRequest', managerToken, {
    requestId,
    confirmationReference: 'integration-bank-reference',
  });
  const confirmedRequest = (await tenant('collection_requests').doc(requestId).get()).data();
  assert.equal(confirmedRequest.status, 'confirmed');
  await expectFailure('correctCreditPurchase', managerToken, {
    purchaseId,
    amountMinor: 1900000,
    year: new Date(now).getUTCFullYear(),
    month: new Date(now).getUTCMonth() + 1,
    reason: 'Must not alter finalized settlement source',
  });

  const bankMovementId = `${organizationId}_bank_movement`;
  await call('recordBankMovement', employeeToken, {
    movementId: bankMovementId,
    accountId: bankId,
    type: 'deposit',
    amountMinor: 600000,
    note: 'Integration deposit',
  });
  let bank = (await tenant('bank_accounts').doc(bankId).get()).data();
  assert.equal(bank.balanceMinor, 11958000);
  await call('approveBankMovement', managerToken, { movementId: bankMovementId });
  bank = (await tenant('bank_accounts').doc(bankId).get()).data();
  assert.equal(bank.balanceMinor, 12558000);
  const bankWithdrawalId = `${organizationId}_bank_withdrawal`;
  await call('recordBankMovement', employeeToken, {
    movementId: bankWithdrawalId,
    accountId: bankId,
    type: 'withdrawal',
    amountMinor: 600000,
    note: 'Integration withdrawal',
  });
  bank = (await tenant('bank_accounts').doc(bankId).get()).data();
  assert.equal(bank.balanceMinor, 12558000);
  await call('approveBankMovement', managerToken, { movementId: bankWithdrawalId });
  bank = (await tenant('bank_accounts').doc(bankId).get()).data();
  assert.equal(bank.balanceMinor, 11958000);
  const raceResults = await Promise.allSettled([
    call('recordBankMovement', managerToken, {
      movementId: `${organizationId}_race_1`,
      accountId: raceBankId,
      type: 'withdrawal',
      amountMinor: 700,
      note: 'Concurrent withdrawal 1',
    }),
    call('recordBankMovement', managerToken, {
      movementId: `${organizationId}_race_2`,
      accountId: raceBankId,
      type: 'withdrawal',
      amountMinor: 700,
      note: 'Concurrent withdrawal 2',
    }),
  ]);
  assert.equal(raceResults.filter((result) => result.status === 'fulfilled').length, 1);
  const raceBank = (await tenant('bank_accounts').doc(raceBankId).get()).data();
  assert.equal(raceBank.balanceMinor, 300);
  await call('createTreasuryTransfer', managerToken, {
    transferId: `${organizationId}_transfer`,
    sourceAccountId: bankId,
    destinationAccountId: treasuryId,
    sourceAccountType: 'bank',
    destinationAccountType: 'treasury',
    amountMinor: 1000000,
    feeMinor: 10000,
  });
  bank = (await tenant('bank_accounts').doc(bankId).get()).data();
  const treasury = (await tenant('treasury_accounts').doc(treasuryId).get()).data();
  assert.equal(bank.balanceMinor, 10948000);
  assert.equal(treasury.balanceMinor, 6000000);

  const expenseId = `${organizationId}_expense`;
  await call('createExpense', employeeToken, {
    expenseId,
    accountId: treasuryId,
    category: 'Operations',
    description: 'Integration expense',
    amountMinor: 600000,
  });
  let expense = (await tenant('expenses').doc(expenseId).get()).data();
  assert.equal(expense.status, 'pending');
  await call('approveExpense', managerToken, { expenseId });
  expense = (await tenant('expenses').doc(expenseId).get()).data();
  assert.equal(expense.status, 'approved');
  const withdrawalId = `${organizationId}_withdrawal`;
  await call('createPersonalWithdrawal', employeeToken, {
    withdrawalId,
    accountId: treasuryId,
    personName: 'Integration Owner',
    amountMinor: 600000,
    reason: 'Integration withdrawal',
  });
  let withdrawal = (await tenant('personal_withdrawals').doc(withdrawalId).get()).data();
  assert.equal(withdrawal.status, 'pending');
  await call('approvePersonalWithdrawal', managerToken, { withdrawalId });
  withdrawal = (await tenant('personal_withdrawals').doc(withdrawalId).get()).data();
  assert.equal(withdrawal.status, 'approved');

  const installmentId = `${organizationId}_installment`;
  await call('createInstallmentAccount', employeeToken, {
    accountId: installmentId,
    customerName: 'Integration Customer',
    reference: 'INT-001',
    principalMinor: 1000000,
    totalDueMinor: 1200000,
    totalLimitMinor: 1500000,
    availableMinor: 500000,
    nextDueMillis: now + 2592000000,
    monthlyInstallmentMinor: 200000,
    totalInstallments: 6,
  });
  await call('recordInstallmentPayment', employeeToken, {
    installmentAccountId: installmentId,
    treasuryAccountId: treasuryId,
    paymentId: `${organizationId}_installment_payment`,
    amountMinor: 200000,
    nextDueMillis: now + 2592000000,
  });
  const installment = (await tenant('installment_accounts').doc(installmentId).get()).data();
  assert.equal(installment.paidMinor, 200000);
  assert.equal(installment.availableMinor, 700000);
  const treasuryAfterPayment = (await tenant('treasury_accounts').doc(treasuryId).get()).data();
  assert.equal(treasuryAfterPayment.balanceMinor, 4600000);
  await call('updateInstallmentAccount', managerToken, {
    accountId: installmentId,
    customerName: 'Updated Customer',
    reference: 'INT-UPDATED',
    status: 'archived',
  });
  assert.equal((await tenant('installment_accounts').doc(installmentId).get()).data().status, 'archived');
  await expectFailure('recordInstallmentPayment', employeeToken, {
    installmentAccountId: installmentId,
    treasuryAccountId: treasuryId,
    paymentId: `${organizationId}_archived_payment`,
    amountMinor: 100000,
    nextDueMillis: now + 2592000000,
  });
  await call('updateInstallmentAccount', managerToken, {
    accountId: installmentId,
    customerName: 'Updated Customer',
    reference: 'INT-UPDATED',
    status: 'active',
  });

  const checkId = `${organizationId}_check`;
  await call('createIssuedCheck', employeeToken, {
    checkId,
    payee: 'Integration Payee',
    reference: 'CHK-001',
    amountMinor: 300000,
    dueDateMillis: now + 86400000,
    accountId: bankId,
    bankName: 'Integration Bank',
    notes: 'Integration check',
  });
  await call('deductIssuedCheck', managerToken, { checkId });
  const bankAfterCheck = (await tenant('bank_accounts').doc(bankId).get()).data();
  assert.equal(bankAfterCheck.balanceMinor, 10648000);
  const checkMovement = (await tenant('bank_movements').doc(`${checkId}_bank_deduction`).get()).data();
  assert.equal(checkMovement.approvalStatus, 'approved');
  await call('updateIssuedCheckStatus', managerToken, { checkId, status: 'archived' });
  assert.equal((await tenant('issued_checks').doc(checkId).get()).data().status, 'archived');

  const statusCheckId = `${organizationId}_status_check`;
  await call('createIssuedCheck', employeeToken, {
    checkId: statusCheckId,
    payee: 'Status Payee',
    reference: 'CHK-STATUS',
    amountMinor: 100000,
    dueDateMillis: now + 86400000,
    accountId: bankId,
  });
  await call('updateIssuedCheckStatus', managerToken, { checkId: statusCheckId, status: 'returned' });
  assert.equal((await tenant('issued_checks').doc(statusCheckId).get()).data().status, 'returned');

  console.log('Credexa integration assertions passed.');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
