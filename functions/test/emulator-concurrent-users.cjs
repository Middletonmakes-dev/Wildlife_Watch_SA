// Integration suite: run only through Firebase emulators:exec. No production access.
'use strict';

const assert = require('node:assert/strict');
const {initializeApp, deleteApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
const {FUNCTIONS_REGION} = require('../lib/config');

const projectId = 'demo-scarborough-tortoise-watch';
const userCount = 20;
const authHost = process.env.FIREBASE_AUTH_EMULATOR_HOST;
const firestoreHost = process.env.FIRESTORE_EMULATOR_HOST;
const functionsHost = process.env.FIREBASE_FUNCTIONS_EMULATOR_HOST ?? '127.0.0.1:15001';

function requireLoopback(name, value) {
  if (!value?.startsWith('127.0.0.1:')) {
    throw new Error(`Local ${name} is required; refusing non-loopback endpoint.`);
  }
}

if (process.env.FUNCTIONS_EMULATOR !== 'true') {
  throw new Error('FUNCTIONS_EMULATOR=true is required; refusing to call a deployed Function.');
}
requireLoopback('FIREBASE_AUTH_EMULATOR_HOST', authHost);
requireLoopback('FIRESTORE_EMULATOR_HOST', firestoreHost);
requireLoopback('FIREBASE_FUNCTIONS_EMULATOR_HOST', functionsHost);

const app = initializeApp({projectId});
const db = getFirestore(app);
let assertions = 0;

function check(actual, expected) {
  assert.deepEqual(actual, expected);
  assertions++;
}

function checkOk(value, message) {
  assert.ok(value, message);
  assertions++;
}

async function createAnonymousAccount() {
  const response = await fetch(`http://${authHost}/identitytoolkit.googleapis.com/v1/accounts:signUp?key=emulator-only`, {
    method: 'POST',
    headers: {'content-type': 'application/json'},
    body: JSON.stringify({returnSecureToken: true}),
  });
  const body = await response.json();
  checkOk(response.ok, `anonymous sign-up failed: ${JSON.stringify(body)}`);
  checkOk(body.idToken, 'anonymous sign-up did not return an ID token');
  checkOk(body.localId, 'anonymous sign-up did not return a UID');
  return {token: body.idToken, uid: body.localId};
}

async function call(name, data, token) {
  const response = await fetch(`http://${functionsHost}/${projectId}/${FUNCTIONS_REGION}/${name}`, {
    method: 'POST',
    headers: {
      'content-type': 'application/json',
      authorization: `Bearer ${token}`,
    },
    body: JSON.stringify({data}),
  });
  const body = await response.json();
  checkOk(response.ok, `${name} HTTP request failed: ${JSON.stringify(body)}`);
  return body;
}

function resultOf(body, name) {
  check(body.error, undefined);
  checkOk(body.result, `${name} did not return a result: ${JSON.stringify(body)}`);
  return body.result;
}

async function main() {
  const initialIncidents = await db.collection('incidents').get();
  const initialPublic = await db.collection('publicIncidents').get();
  check(initialIncidents.size, 0);
  check(initialPublic.size, 0);

  const accounts = await Promise.all(
    Array.from({length: userCount}, () => createAnonymousAccount()),
  );
  check(new Set(accounts.map(account => account.uid)).size, userCount);

  // The report payload, including its idempotency key, is identical for every
  // reporter. The UID remains part of the server-side incident ID namespace.
  const input = {
    requestId: 'same-tortoise-report',
    latitude: -34.197123,
    longitude: 18.375456,
    incidentType: 'injured',
    locationSource: 'manual_pin',
    occurredAt: '2026-10-05T08:00:00.000Z',
  };

  // Race two identical calls for every account. Each account should receive
  // one stable incident ID, regardless of which retry wins the transaction.
  const responsePairs = await Promise.all(accounts.map(account => Promise.all([
    call('submitIncident', input, account.token),
    call('submitIncident', input, account.token),
  ])));
  const incidentIds = new Map();
  for (let index = 0; index < accounts.length; index++) {
    const [firstBody, retryBody] = responsePairs[index];
    const first = resultOf(firstBody, 'submitIncident');
    const retry = resultOf(retryBody, 'submitIncident');
    checkOk(/^[a-f0-9]{32}$/.test(first.incidentId), 'invalid incident ID');
    check(first.incidentId, retry.incidentId);
    checkOk(!incidentIds.has(first.incidentId), 'duplicate incident ID across distinct users');
    incidentIds.set(first.incidentId, accounts[index].uid);
  }
  check(incidentIds.size, userCount);

  const incidents = await db.collection('incidents').get();
  check(incidents.size, userCount);
  for (const document of incidents.docs) {
    const incident = document.data();
    const expectedUid = incidentIds.get(document.id);
    checkOk(expectedUid, `unexpected incident document ${document.id}`);
    check(incident.reporterUid, expectedUid);
    check(incident.latitude, input.latitude);
    check(incident.longitude, input.longitude);
    check(incident.incidentType, input.incidentType);
    check(incident.moderationStatus, 'pending');
    check(incident.publicProjection, null);
  }

  // Owner receipts are UID-scoped and must expose exactly that user's report.
  const ownerPages = await Promise.all(accounts.map(account => call('listOwnIncidents', null, account.token)));
  for (const [index, body] of ownerPages.entries()) {
    const page = resultOf(body, 'listOwnIncidents');
    check(page.reports.length, 1);
    check(page.hasMore, false);
    check(page.reports[0].id, [...incidentIds.entries()].find(([, uid]) => uid === accounts[index].uid)[0]);
    check(page.reports[0].incidentType, input.incidentType);
    check(page.reports[0].moderationStatus, 'pending');
    checkOk(page.reports[0].createdAt, 'owner receipt is missing its creation timestamp');
  }

  const publicIncidents = await db.collection('publicIncidents').get();
  check(publicIncidents.size, 0);
  console.log(`PASS: ${assertions} concurrent multi-user emulator assertions; ${userCount} unique pending private reports, stable retry IDs, UID-isolated owner pages, and empty publicIncidents.`);
  await deleteApp(app);
}

main().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
