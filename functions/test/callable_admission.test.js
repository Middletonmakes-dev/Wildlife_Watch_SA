const assert = require('node:assert/strict');
const test = require('node:test');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const {HttpsError} = require('firebase-functions/v2/https');
const functions = require('../lib/index');
const db = getFirestore();

test('first publication waits seven days while legacy projections and nonpublication stay usable', async () => {
  const transaction = db.runTransaction; const clock = Date.now;
  const now = Date.parse('2030-01-08T12:00:00Z'); Date.now = () => now;
  let record; let writes;
  db.runTransaction = async callback => {
    writes = [];
    return callback({get: async () => ({exists: true, data: () => record}),
      getAll: async (...refs) => refs.map(() => ({exists: false})),
      set: (ref, data) => writes.push([ref.path, data]),
      update: (ref, data) => writes.push([ref.path, data]),
      delete: ref => writes.push([ref.path, null])});
  };
  const moderate = status => functions.setIncidentModeration.run({auth: {uid: 'admin', token: {admin: true}},
    data: {incidentId: 'a'.repeat(32), status}});
  const fields = {latitude: -34.197, longitude: 18.375, incidentType: 'injured', moderationStatus: 'pending',
    occurredAt: Timestamp.fromDate(new Date('2000-01-01T00:00:00Z')), publicProjection: null};
  try {
    record = {...fields, createdAt: Timestamp.fromMillis(now - 604800000 + 1)};
    await assert.rejects(moderate('accepted'), error => error.code === 'failed-precondition' &&
      error.details.reason === 'publication-not-ready' && error.details.eligibleDate === '2030-01-08');
    assert.equal(writes.length, 0);
    await moderate('rejected');
    assert.ok(writes.some(([path,data]) => path.startsWith('incidents/') && data.moderationStatus === 'rejected'));
    for (const createdAt of [undefined, 'bad']) {
      record = {...fields, createdAt};
      await assert.rejects(moderate('accepted'), {code: 'failed-precondition'});
      assert.equal(writes.length, 0);
    }
    record = {...fields, createdAt: Timestamp.fromMillis(now - 604800000), publicProjectionVersion: 'v1'};
    await moderate('accepted');
    const projected = writes.find(([path]) => path.startsWith('publicIncidents/'))[1];
    assert.deepEqual(Object.keys(projected).sort(), ['date','displayLatitude','displayLongitude','id','incidentType']);
    assert.equal(writes.find(([path]) => path.startsWith('incidents/'))[1].publicProjectionVersion, 'v2');
    const {haversineMetres} = require('../lib/projection');
    const distance = haversineMetres(fields.latitude, fields.longitude, projected.displayLatitude, projected.displayLongitude);
    assert.ok(distance >= 100 && distance <= 250);
    const legacy = {...projected, displayLatitude: -34.1971, displayLongitude: 18.3751};
    record = {...fields, createdAt: Timestamp.fromMillis(now), publicProjection: legacy};
    await moderate('accepted');
    assert.equal(writes.find(([path]) => path.startsWith('publicIncidents/'))[1], legacy);
    assert.equal(writes.find(([path]) => path.startsWith('incidents/'))[1].publicProjectionVersion, 'v1');
    record = {...record, moderationStatus: 'withdrawn'};
    await assert.rejects(moderate('accepted'), error => error.details?.reason === 'incident-withdrawn');
  } finally {db.runTransaction = transaction; Date.now = clock;}
});

// Test the exported handler at its SDK seam; the existing emulator exercises
// actual transactions. No network or parallel tests run in this process.
test('exhausted owner-list admission stops before issuing the 501-document query', async () => {
  const transaction = db.runTransaction; const collection = db.collection;
  let queries = 0;
  db.runTransaction = async () => {throw new HttpsError('resource-exhausted', 'Please wait.');};
  const query = {where() {return this;}, orderBy() {return this;}, limit(size) {
    assert.equal(size, 501); return this;
  }, async get() {queries++; return {docs: []};}};
  db.collection = () => query;
  try {
    await assert.rejects(functions.listOwnIncidents.run({auth: {uid: 'owner'}, data: null}),
      {code: 'resource-exhausted'});
    assert.equal(queries, 0);
  } finally {db.runTransaction = transaction; db.collection = collection;}
});

test('outer callable transaction failures are unavailable without backend diagnostics', async () => {
  const transaction = db.runTransaction;
  db.runTransaction = async () => {throw new Error('private commit diagnostic');};
  const report = {requestId: 'task4', latitude: -34.197, longitude: 18.375,
    locationSource: 'manual_pin', incidentType: 'injured'};
  try {
    for (const [name, data] of [['submitIncident', report], ['withdrawIncident', {incidentId: 'a'.repeat(32)}],
      ['setIncidentModeration', {incidentId: 'a'.repeat(32), status: 'accepted'}]]) {
      await assert.rejects(functions[name].run({auth: {uid: 'owner', token: {admin: true}}, data}),
        error => error.code === 'unavailable' && !error.message.includes('private commit'), name);
    }
  } finally {db.runTransaction = transaction;}
});
