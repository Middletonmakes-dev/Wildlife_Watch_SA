const assert = require('node:assert/strict');
const test = require('node:test');
const {Timestamp} = require('firebase-admin/firestore');
const {admissionBuckets, consumeAdmission} = require('../lib/admission');

const now = Date.parse('2030-01-01T12:00:10Z');

// Only the SDK transaction seam is simulated. Real concurrency is tested in
// emulator-callable.cjs; this spy enforces Firestore's read-before-write rule.
function transactionFor(records = new Map()) {
  const writes = [];
  const transaction = {
    async getAll(...refs) {
      assert.equal(writes.length, 0, 'read after write');
      return refs.map(ref => ({exists: records.has(ref.path), data: () => records.get(ref.path)}));
    },
    set(ref, data) { writes.push([ref.path, data]); },
  };
  const db = {collection: name => ({doc: key => ({path: `${name}/${key}`})})};
  return {transaction, db, writes, commit: () => writes.forEach(([path, value]) => records.set(path, value))};
}

async function admit(buckets, records, at = now) {
  const run = transactionFor(records);
  await consumeAdmission(run.transaction, run.db, buckets, at);
  run.commit();
  return run;
}

test('UIDs have independent buckets and share opaque bounded global counter keys', () => {
  const a = admissionBuckets('submit', 'one', undefined, now);
  const b = admissionBuckets('submit', 'two', undefined, now);
  assert.equal(a.length, 4);
  assert.deepEqual(a.filter(x => x.scope === 'global'), b.filter(x => x.scope === 'global'));
  assert.notDeepEqual(a.filter(x => x.scope === 'uid').map(x => x.key), b.filter(x => x.scope === 'uid').map(x => x.key));
  assert.ok(a.every(x => /^[a-f0-9]{64}$/.test(x.key)));
  assert.deepEqual(a.map(x => x.key), admissionBuckets('submit', 'one', undefined, now + 86400000).map(x => x.key));
  assert.equal(a.find(x => x.scope === 'uid' && x.window === 'minute').limit, 6);
  assert.equal(a.find(x => x.scope === 'global' && x.window === 'day').limit, 300);
});

test('admits the last allowance and denies the next without partial writes', async () => {
  const records = new Map();
  const buckets = admissionBuckets('submit', 'resident', undefined, now);
  for (let i = 0; i < 6; i++) await admit(buckets, records);
  const run = transactionFor(records);
  await assert.rejects(consumeAdmission(run.transaction, run.db, buckets, now), error =>
    error.code === 'resource-exhausted' && error.details.retryAfterSeconds === 50);
  assert.equal(run.writes.length, 0);
  assert.ok([...records.values()].every(record => Number.isInteger(record.count)));
  assert.equal(records.get(`_abuseCounters/${buckets.find(x => x.scope === 'global' && x.window === 'minute').key}`).count, 6);
});

test('resets fixed counter documents at the exact UTC window boundary', async () => {
  const records = new Map();
  const buckets = admissionBuckets('submit', 'resident', undefined, now);
  for (let i = 0; i < 6; i++) await admit(buckets, records);
  const boundary = Date.parse('2030-01-01T12:01:00Z');
  const next = admissionBuckets('submit', 'resident', undefined, boundary);
  await admit(next, records, boundary);
  assert.equal(records.size, 4);
  assert.equal(records.get(`_abuseCounters/${next.find(x => x.scope === 'uid' && x.window === 'minute').key}`).count, 1);
  const daily = records.get(`_abuseCounters/${next.find(x => x.scope === 'uid' && x.window === 'day').key}`);
  assert.equal(daily.count, 7);
  assert.equal(daily.expiresAt.toMillis(), daily.windowEnd.toMillis() + 48 * 60 * 60 * 1000);
});

test('combined photo request/decode budgets read first and charge duplicates only once', async () => {
  const buckets = [...admissionBuckets('photoRequest', 'resident', 'incident', now),
    ...admissionBuckets('photoDecode', 'resident', 'incident', now)];
  const records = new Map();
  const run = await admit([...buckets, ...buckets], records);
  assert.equal(run.writes.length, 12);
  assert.equal(records.size, 12);
  assert.ok([...records.values()].every(record => record.count === 1));
});

test('malformed or unexpected future counters fail closed without writes', async () => {
  const buckets = admissionBuckets('submit', 'resident', undefined, now);
  for (const data of [
    {count: '0', windowEnd: Timestamp.fromMillis(buckets[0].windowEndMs)},
    {count: -1, windowEnd: Timestamp.fromMillis(buckets[0].windowEndMs)},
    {count: 0, windowEnd: 'tomorrow'},
    {count: 0, windowEnd: Timestamp.fromMillis(buckets[0].windowEndMs + 86400000)},
  ]) {
    const records = new Map([[`_abuseCounters/${buckets[0].key}`, data]]);
    const run = transactionFor(records);
    await assert.rejects(consumeAdmission(run.transaction, run.db, buckets, now), {code: 'unavailable'});
    assert.equal(run.writes.length, 0);
  }
});

test('counter-store failure is unavailable and never admits work', async () => {
  const run = transactionFor();
  run.transaction.getAll = async () => { throw new Error('private backend details'); };
  await assert.rejects(consumeAdmission(run.transaction, run.db,
    admissionBuckets('submit', 'resident', undefined, now), now), error =>
    error.code === 'unavailable' && !error.message.includes('private backend details'));
  assert.equal(run.writes.length, 0);
});

test('anonymous UID churn cannot exceed aggregate admission, with independent withdrawal capacity', async () => {
  const records = new Map();
  for (let index = 0; index < 30; index++) {
    await admit(admissionBuckets('submit', `resident-${index}`, undefined, now), records);
  }
  const denied = transactionFor(records);
  await assert.rejects(consumeAdmission(denied.transaction, denied.db,
    admissionBuckets('submit', 'resident-31', undefined, now), now), {code: 'resource-exhausted'});
  assert.equal(denied.writes.length, 0);
  await admit(admissionBuckets('withdraw', 'resident-31', undefined, now), records);
  const nextMinute = now + 60_000;
  await admit(admissionBuckets('submit', 'resident-31', undefined, nextMinute), records, nextMinute);
});
