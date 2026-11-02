const assert = require('node:assert/strict');
const test = require('node:test');

const {ownerReceipt, ownerReceiptPage, isIncidentId} = require('../lib/withdrawal');

test('owner receipt is an exact minimal allowlist', () => {
  const receipt = ownerReceipt('abc123', {
    incidentType: 'injured',
    moderationStatus: 'pending',
    createdAt: {toDate: () => new Date('2026-10-04T08:00:00.000Z')},
    latitude: -34.197,
    reporterUid: 'private-user',
  });
  assert.deepEqual(receipt, {
    id: 'abc123',
    incidentType: 'injured',
    moderationStatus: 'pending',
    createdAt: '2026-10-04T08:00:00.000Z',
  });
  assert.equal(Object.hasOwn(receipt, 'latitude'), false);
  assert.equal(Object.hasOwn(receipt, 'reporterUid'), false);
});

test('incident ids are bounded before a callable reads Firestore', () => {
  assert.equal(isIncidentId('a'.repeat(32)), true);
  assert.equal(isIncidentId('A'.repeat(32)), false);
  assert.equal(isIncidentId('too-short'), false);
});

test('owner receipt pages keep deterministic ties and report an extra page', () => {
  const documents = ['b', 'a', '9'].map(id => ({
    id,
    data: () => ({
      incidentType: 'alive',
      moderationStatus: 'pending',
      createdAt: {toDate: () => new Date('2026-10-04T08:00:00.000Z')},
    }),
  }));
  assert.deepEqual(ownerReceiptPage(documents, 2), {
    reports: [
      {id: 'b', incidentType: 'alive', moderationStatus: 'pending', createdAt: '2026-10-04T08:00:00.000Z'},
      {id: 'a', incidentType: 'alive', moderationStatus: 'pending', createdAt: '2026-10-04T08:00:00.000Z'},
    ],
    hasMore: true,
  });
  assert.equal(ownerReceiptPage(documents.slice(0, 2), 2).hasMore, false);
});
