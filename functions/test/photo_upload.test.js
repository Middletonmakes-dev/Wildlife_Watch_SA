const assert = require('node:assert/strict');
const test = require('node:test');
const {createHash} = require('node:crypto');
const {Timestamp, FieldValue} = require('firebase-admin/firestore');
const sharp = require('sharp');
const {uploadPrivatePhoto} = require('../lib/photo_upload');
const {processPrivateJpeg} = require('../lib/photo');
const {admissionBuckets} = require('../lib/admission');

const id = 'a'.repeat(32);
const path = `incidentPhotos/${id}/photo.jpg`;
const sha = bytes => createHash('sha256').update(bytes).digest('hex');

// The SDK/storage seams let tests count real decoder calls and inject failures.
// Actual Firestore transactions and private objects are covered by the emulator.
function fixture(fields = {}) {
  const records = new Map([[`incidents/${id}`, {
    reporterUid: 'owner', moderationStatus: 'pending', photoReferences: [path], ...fields,
  }]]);
  const objects = new Map();
  let clock = Date.parse('2030-01-01T12:00:10Z');
  let lease = 0;
  let decodes = 0;
  let saves = 0;
  const ref = key => ({path: key});
  const snapshot = key => ({exists: records.has(key), data: () => records.get(key)});
  const db = {
    doc: ref, collection: name => ({doc: key => ref(`${name}/${key}`)}),
    async runTransaction(callback) {
      const writes = [];
      const read = key => {assert.equal(writes.length, 0, 'read after write'); return snapshot(key);};
      const value = await callback({
        get: async r => read(r.path), getAll: async (...refs) => refs.map(r => read(r.path)),
        set: (r, data) => writes.push([r.path, data, false]),
        update: (r, data) => writes.push([r.path, data, true]),
      });
      for (const [key, data, merge] of writes) {
        const next = {...(merge ? records.get(key) : {}), ...data};
        for (const [field, value] of Object.entries(next)) {
          if (value instanceof FieldValue && value.isEqual(FieldValue.delete())) delete next[field];
        }
        records.set(key, next);
      }
      return value;
    },
  };
  const dependencies = {
    db, nowMs: () => clock, newLeaseId: () => `lease-${++lease}`,
    async processJpeg(bytes) {decodes++; return processPrivateJpeg(bytes);},
    storage: {
      async readMetadata(key) {return objects.get(key)?.metadata ?? null;},
      async saveIfAbsent(key, bytes, canonicalHash) {
        saves++;
        if (objects.has(key)) throw Object.assign(new Error('precondition'), {code: 412});
        objects.set(key, {bytes, metadata: {photoSha256: canonicalHash}});
      },
    },
  };
  return {records, objects, dependencies, incident: () => records.get(`incidents/${id}`),
    counts: () => ({decodes, saves}),
    bucket: operation => admissionBuckets(operation, 'owner', id, clock)[0],
    advance: ms => {clock += ms;}};
}
const image = color => sharp({create: {width: 8, height: 8, channels: 3, background: color}}).jpeg().toBuffer();
const upload = (f, bytes, uid = 'owner') => uploadPrivatePhoto({uid, incidentId: id, bytes}, f.dependencies);

test('byte-identical stored retries verify metadata and skip Sharp', async () => {
  const f = fixture(); const bytes = await image('#174A3A');
  assert.deepEqual(await upload(f, bytes), {photoStored: true});
  assert.deepEqual(await upload(f, bytes), {photoStored: true});
  assert.deepEqual(f.counts(), {decodes: 1, saves: 1});
  assert.equal(f.incident().photoInputFingerprint, sha(bytes));
  assert.equal(f.incident().photoProcessorVersion, 'jpeg-v1');
  assert.equal(f.incident().photoLease, undefined);
  assert.equal(f.records.get(`_abuseCounters/${f.bucket('photoRequest').key}`).count, 2);
  assert.equal(f.records.get(`_abuseCounters/${f.bucket('photoDecode').key}`).count, 1);
});

test('a different image never gets stored success or changes the reservation', async () => {
  const f = fixture(); const bytes = await image('#174A3A');
  await upload(f, bytes); const hash = f.incident().photoFingerprint;
  await assert.rejects(upload(f, await image('#ff0000')), {code: 'already-exists'});
  assert.equal(f.incident().photoFingerprint, hash);
  assert.equal(f.incident().photoInputFingerprint, sha(bytes));
  assert.deepEqual(f.counts(), {decodes: 2, saves: 1});
  assert.equal(f.incident().photoLease, undefined);
});

test('equivalent JPEG bytes and legacy normalized hashes retain compatibility', async () => {
  const f = fixture(); const bytes = await image('#174A3A');
  const comment = Buffer.from([0xff, 0xfe, 0, 5, 65, 66, 67]);
  const equivalent = Buffer.concat([bytes.subarray(0, 2), comment, bytes.subarray(2)]);
  assert.notEqual(sha(bytes), sha(equivalent));
  assert.deepEqual(await processPrivateJpeg(bytes), await processPrivateJpeg(equivalent));
  await upload(f, bytes); await upload(f, equivalent);
  assert.equal(f.incident().photoInputFingerprint, sha(equivalent));
  delete f.incident().photoInputFingerprint; delete f.incident().photoProcessorVersion;
  await upload(f, bytes);
  assert.deepEqual(f.counts(), {decodes: 3, saves: 1});
  await upload(f, bytes);
  assert.deepEqual(f.counts(), {decodes: 3, saves: 1});
});

test('owner, withdrawal and exhausted decode admission deny work before Sharp', async () => {
  const bytes = await image('#174A3A');
  for (const [f, uid, code] of [[fixture(), 'foreign', 'permission-denied'],
    [fixture({moderationStatus: 'withdrawn'}), 'owner', 'failed-precondition']]) {
    await assert.rejects(upload(f, bytes, uid), {code});
    assert.equal(f.counts().decodes, 0); assert.equal(f.records.size, 1);
  }
  const f = fixture(); const bucket = f.bucket('photoDecode');
  f.records.set(`_abuseCounters/${bucket.key}`, {count: bucket.limit,
    windowEnd: Timestamp.fromMillis(bucket.windowEndMs)});
  await assert.rejects(upload(f, bytes), {code: 'resource-exhausted'});
  assert.equal(f.counts().decodes, 0); assert.equal(f.incident().photoLease, undefined);
  assert.equal(f.records.has(`_abuseCounters/${f.bucket('photoRequest').key}`), false);
});

test('an active lease commits request accounting without a decode allowance', async () => {
  const f = fixture({photoLease: {id: 'other', inputFingerprint: 'b'.repeat(64),
    expiresAt: Timestamp.fromMillis(Date.parse('2030-01-01T12:02:10Z'))}});
  await assert.rejects(upload(f, await image('#174A3A')), {code: 'unavailable'});
  assert.equal(f.counts().decodes, 0);
  assert.equal(f.records.get(`_abuseCounters/${f.bucket('photoRequest').key}`).count, 1);
  assert.equal(f.records.has(`_abuseCounters/${f.bucket('photoDecode').key}`), false);
  assert.equal(f.incident().photoLease.id, 'other');
});

test('stored retry fails closed for missing or tampered private object metadata', async () => {
  for (const metadata of [null, {photoSha256: 'b'.repeat(64)},
    {photoSha256: 'placeholder', downloadTokens: 'bearer-token'}]) {
    const f = fixture(); const bytes = await image('#174A3A'); await upload(f, bytes);
    if (metadata?.downloadTokens) metadata.photoSha256 = f.incident().photoFingerprint;
    if (metadata) f.objects.get(path).metadata = metadata; else f.objects.delete(path);
    await assert.rejects(upload(f, bytes), {code: 'failed-precondition'});
    assert.deepEqual(f.counts(), {decodes: 1, saves: 1});
  }
});

test('invalid decode releases only its lease and reserves no image', async () => {
  const f = fixture();
  await assert.rejects(upload(f, Buffer.from([0xff, 0xd8, 0xff, 0xd9])), {code: 'invalid-argument'});
  assert.equal(f.incident().photoLease, undefined);
  assert.equal(f.incident().photoFingerprint, undefined);
  assert.equal(f.records.get(`_abuseCounters/${f.bucket('photoDecode').key}`).count, 1);
  await upload(f, await image('#174A3A'));
  assert.equal(f.incident().photoStored, true);
});

test('outer transaction failures become unavailable without exposing backend details', async () => {
  const f = fixture();
  f.dependencies.db.runTransaction = async () => {throw new Error('private backend diagnostic');};
  await assert.rejects(upload(f, await image('#174A3A')), error =>
    error.code === 'unavailable' && !error.message.includes('diagnostic'));
  assert.equal(f.counts().decodes, 0);
});

test('stored retries recheck withdrawal, ownership and canonical state after metadata', async () => {
  const bytes = await image('#174A3A');
  for (const [drift, code] of [
    [{moderationStatus: 'withdrawn'}, 'failed-precondition'],
    [{reporterUid: 'foreign'}, 'permission-denied'],
    [{photoFingerprint: 'b'.repeat(64)}, 'failed-precondition'],
    [{photoStored: false}, 'failed-precondition'],
  ]) {
    const f = fixture(); await upload(f, bytes);
    const read = f.dependencies.storage.readMetadata;
    f.dependencies.storage.readMetadata = async key => {
      const metadata = await read(key); Object.assign(f.incident(), drift); return metadata;
    };
    await assert.rejects(upload(f, bytes), {code});
    assert.deepEqual(f.counts(), {decodes: 1, saves: 1});
    assert.equal(f.records.get(`_abuseCounters/${f.bucket('photoRequest').key}`).count, 2);
  }
});

test('interrupted processing resumes safely before reservation, before save and after commit', async () => {
  const bytes = await image('#174A3A');
  const hash = sha(await processPrivateJpeg(bytes));
  for (const stage of ['before-reservation', 'before-save', 'after-save', 'after-finalize']) {
    const f = fixture(); const dbRun = f.dependencies.db.runTransaction;
    const read = f.dependencies.storage.readMetadata; const save = f.dependencies.storage.saveIfAbsent;
    let transaction = 0;
    f.dependencies.db.runTransaction = async callback => {
      transaction++;
      if (stage === 'before-reservation' && transaction === 2) throw new Error('interrupted');
      const result = await dbRun(callback);
      if (stage === 'after-finalize' && transaction === 4) throw new Error('response lost');
      return result;
    };
    f.dependencies.storage.readMetadata = async key => {
      if (stage === 'before-save') throw new Error('storage unavailable');
      return read(key);
    };
    f.dependencies.storage.saveIfAbsent = async (...args) => {
      await save(...args);
      if (stage === 'after-save') throw new Error('save response lost');
    };
    await assert.rejects(upload(f, bytes), {code: 'unavailable'});
    assert.equal(f.incident().photoFingerprint, stage === 'before-reservation' ? undefined : hash);
    assert.equal(f.incident().photoStored === true, stage === 'after-finalize');
    assert.equal(f.incident().photoLease, undefined);
    f.dependencies.db.runTransaction = dbRun;
    f.dependencies.storage.readMetadata = read; f.dependencies.storage.saveIfAbsent = save;
    assert.deepEqual(await upload(f, bytes), {photoStored: true});
    assert.equal(f.incident().photoFingerprint, hash);
    assert.deepEqual(f.counts(), {decodes: stage === 'after-finalize' ? 1 : 2, saves: 1});
    assert.deepEqual([...f.objects.keys()], [path]);
    assert.equal((await sharp(f.objects.get(path).bytes).metadata()).exif, undefined);
    assert.deepEqual(Object.keys(f.objects.get(path).metadata), ['photoSha256']);
  }
});

test('expired abandoned leases recover only the immutable canonical image', async () => {
  const bytes = await image('#174A3A'); const different = await image('#ff0000');
  const hash = sha(await processPrivateJpeg(bytes));
  for (const reserved of [false, true]) {
    const f = fixture({photoLease: {id: 'abandoned', inputFingerprint: sha(bytes),
      expiresAt: Timestamp.fromMillis(Date.parse('2030-01-01T12:00:10Z'))},
      ...(reserved ? {photoFingerprint: hash} : {})});
    if (reserved) {
      await assert.rejects(upload(f, different), {code: 'already-exists'});
      assert.equal(f.incident().photoFingerprint, hash);
    }
    assert.deepEqual(await upload(f, bytes), {photoStored: true});
    assert.equal(f.incident().photoFingerprint, hash); assert.equal(f.incident().photoLease, undefined);
  }
});

test('same, different and equivalent requests serialize around one live decoder', async () => {
  const bytes = await image('#174A3A');
  const equivalent = Buffer.concat([bytes.subarray(0, 2), Buffer.from([255, 254, 0, 5, 65, 66, 67]), bytes.subarray(2)]);
  for (const [other, replacement] of [[bytes, false], [await image('#ff0000'), true], [equivalent, false]]) {
    const f = fixture(); const process = f.dependencies.processJpeg;
    let entered, release;
    const started = new Promise(resolve => {entered = resolve;});
    const paused = new Promise(resolve => {release = resolve;});
    f.dependencies.processJpeg = async input => {entered(); await paused; return process(input);};
    const first = upload(f, bytes); await started;
    await assert.rejects(upload(f, other), {code: 'unavailable'});
    release(); await first; f.dependencies.processJpeg = process;
    const hash = f.incident().photoFingerprint;
    if (replacement) await assert.rejects(upload(f, other), {code: 'already-exists'});
    else assert.deepEqual(await upload(f, other), {photoStored: true});
    assert.equal(f.incident().photoFingerprint, hash);
    assert.deepEqual(f.counts(), {decodes: other === bytes ? 1 : 2, saves: 1});
    assert.equal(f.records.get(`_abuseCounters/${f.bucket('photoRequest').key}`).count, 3);
  }
});

test('stale workers cannot clear a successor lease or finalize after successor recovery', async () => {
  const bytes = await image('#174A3A');
  const f = fixture(); const process = f.dependencies.processJpeg;
  f.dependencies.processJpeg = async input => {
    const output = await process(input);
    f.incident().photoLease = {id: 'successor', inputFingerprint: sha(bytes),
      expiresAt: Timestamp.fromMillis(Date.parse('2030-01-01T12:05:00Z'))};
    return output;
  };
  await assert.rejects(upload(f, bytes), {code: 'unavailable'});
  assert.equal(f.incident().photoLease.id, 'successor');
  assert.equal(f.incident().photoFingerprint, undefined); assert.equal(f.counts().saves, 0);

  const g = fixture(); const save = g.dependencies.storage.saveIfAbsent;
  let entered, release;
  const started = new Promise(resolve => {entered = resolve;});
  const paused = new Promise(resolve => {release = resolve;});
  g.dependencies.storage.saveIfAbsent = async (...args) => {entered(); await paused; return save(...args);};
  const stale = upload(g, bytes); await started; g.advance(120_000);
  g.dependencies.storage.saveIfAbsent = save;
  assert.deepEqual(await upload(g, bytes), {photoStored: true});
  release(); await assert.rejects(stale, {code: 'unavailable'});
  assert.equal(g.incident().photoStored, true); assert.equal(g.incident().photoLease, undefined);
  assert.equal(g.incident().photoFingerprint, sha(await processPrivateJpeg(bytes)));
  assert.equal(g.objects.size, 1);
});

test('generation precondition reconciliation accepts only matching token-free metadata', async () => {
  const bytes = await image('#174A3A');
  for (const variant of ['matching', 'different', 'missing-hash', 'token']) {
    const f = fixture(); const save = f.dependencies.storage.saveIfAbsent;
    f.dependencies.storage.saveIfAbsent = async (key, processed, hash) => {
      const metadata = variant === 'missing-hash' ? {} : {photoSha256: variant === 'different' ? 'b'.repeat(64) : hash};
      if (variant === 'token') metadata.downloadTokens = 'forbidden';
      f.objects.set(key, {bytes: processed, metadata});
      return save(key, processed, hash);
    };
    if (variant === 'matching') assert.deepEqual(await upload(f, bytes), {photoStored: true});
    else await assert.rejects(upload(f, bytes), {code: 'failed-precondition'});
    assert.equal(f.incident().photoStored === true, variant === 'matching');
    assert.equal(f.incident().photoFingerprint, sha(await processPrivateJpeg(bytes)));
    assert.equal(f.incident().photoLease, undefined); assert.equal(f.objects.size, 1);
  }
});

test('withdrawal at decode, metadata and save seams never finalizes or reactivates', async () => {
  const bytes = await image('#174A3A');
  for (const seam of ['decode', 'metadata', 'save']) {
    const f = fixture(); const process = f.dependencies.processJpeg;
    const read = f.dependencies.storage.readMetadata; const save = f.dependencies.storage.saveIfAbsent;
    f.dependencies.processJpeg = async input => {
      const output = await process(input); if (seam === 'decode') f.incident().moderationStatus = 'withdrawn'; return output;
    };
    f.dependencies.storage.readMetadata = async key => {
      const result = await read(key); if (seam === 'metadata') f.incident().moderationStatus = 'withdrawn'; return result;
    };
    f.dependencies.storage.saveIfAbsent = async (...args) => {
      await save(...args); if (seam === 'save') f.incident().moderationStatus = 'withdrawn';
    };
    await assert.rejects(upload(f, bytes), {code: 'failed-precondition'});
    assert.equal(f.incident().moderationStatus, 'withdrawn');
    assert.notEqual(f.incident().photoStored, true); assert.equal(f.incident().photoLease, undefined);
    assert.equal(f.objects.size, seam === 'save' ? 1 : 0);
    assert.equal(f.incident().publicProjection, undefined);
    if (f.objects.size) assert.deepEqual(Object.keys(f.objects.get(path).metadata), ['photoSha256']);
  }
});
