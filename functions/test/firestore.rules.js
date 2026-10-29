const assert = require('node:assert/strict');
const admin = require('firebase-admin');

const projectId = 'credixa-422a1';
const organizationId = `rules_${Date.now()}`;
const otherOrganizationId = `${organizationId}_other`;
const authBase = 'http://127.0.0.1:9099';
const firestoreBase = `http://127.0.0.1:8080/v1/projects/${projectId}/databases/(default)/documents`;
const testPassword = process.env.CREDEXA_TEST_PASSWORD;
if (!testPassword) {
  throw new Error('Set CREDEXA_TEST_PASSWORD before running Firestore rules tests.');
}
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= '127.0.0.1:9099';
admin.initializeApp({ projectId });

async function tokenFor(email, organization = organizationId, role = 'accountant') {
  const auth = admin.auth();
  const user = await auth.createUser({ email, password: testPassword });
  await auth.setCustomUserClaims(user.uid, {
    role,
    permissions: {},
    organizationId: organization,
  });
  const response = await fetch(
    `${authBase}/identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=fake-api-key`,
    {
      method: 'POST',
      headers: { 'content-type': 'application/json' },
      body: JSON.stringify({ email, password: testPassword, returnSecureToken: true }),
    },
  );
  const body = await response.json();
  if (!response.ok) throw new Error(JSON.stringify(body));
  return body.idToken;
}

async function read(token, organization, collection, id) {
  const response = await fetch(
    `${firestoreBase}/organizations/${organization}/${collection}/${id}`,
    { headers: { authorization: `Bearer ${token}` } },
  );
  return response.status;
}

async function create(token, collection, id) {
  const response = await fetch(
    `${firestoreBase}/organizations/${organizationId}/${collection}?documentId=${id}`,
    {
      method: 'POST',
      headers: {
        authorization: `Bearer ${token}`,
        'content-type': 'application/json',
      },
      body: JSON.stringify({
        fields: {
          id: { stringValue: id },
          amountMinor: { integerValue: '100' },
          createdBy: { stringValue: 'employee' },
          status: { stringValue: 'pending' },
        },
      }),
    },
  );
  return response.status;
}

async function main() {
  const token = await tokenFor(`${organizationId}@example.com`);
  assert.equal(await create(token, 'expenses', 'expense_1'), 403);
  assert.equal(await create(token, 'treasury_movements', 'movement_1'), 403);
  assert.equal(await create(token, 'bank_movements', 'bank_movement_1'), 403);
  assert.equal(await create(token, 'installment_accounts', 'installment_1'), 403);
  assert.equal(await create(token, 'installment_schedules', 'schedule_1'), 403);
  assert.equal(await create(token, 'issued_checks', 'check_1'), 403);
  assert.equal(await create(token, 'withdrawal_people', 'person_1'), 200);
  assert.equal(await create(token, 'notification_preferences', 'preferences'), 200);
  await admin.firestore().doc(`organizations/${organizationId}/notifications/tenant_probe`).set({
    id: 'tenant_probe',
    createdAtMillis: Date.now(),
  });
  const otherToken = await tokenFor(
    `${otherOrganizationId}@example.com`,
    otherOrganizationId,
  );
  assert.equal(await read(token, organizationId, 'notifications', 'tenant_probe'), 200);
  assert.equal(await read(otherToken, organizationId, 'notifications', 'tenant_probe'), 403);
  console.log('Credexa Firestore rules assertions passed.');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
