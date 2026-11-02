const assert = require('node:assert/strict');
const {initializeApp, deleteApp} = require('firebase-admin/app');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const {getAuth} = require('firebase-admin/auth');
const {getStorage} = require('firebase-admin/storage');
const sharp = require('sharp');
const {createHash} = require('node:crypto');
const {FUNCTIONS_REGION} = require('../lib/config');
const {admissionBuckets, consumeAdmission} = require('../lib/admission');
const {uploadPrivatePhoto} = require('../lib/photo_upload');
const {processPrivateJpeg} = require('../lib/photo');
const projectId = 'demo-scarborough-tortoise-watch';
// Hard fail before touching any SDK unless the local suite supplied all emulators.
for (const name of ['FIRESTORE_EMULATOR_HOST', 'FIREBASE_AUTH_EMULATOR_HOST', 'FIREBASE_STORAGE_EMULATOR_HOST']) {
  if (!process.env[name]?.startsWith('127.0.0.1:')) throw new Error(`Local ${name} is required`);
}
const app = initializeApp({projectId});
const db = getFirestore();
let count = 0;
function check(actual, expected) {assert.deepEqual(actual, expected); count++;}
async function authToken(adminRole = false) {
  if (adminRole) {
    const token = await getAuth().createCustomToken('emulator-review-admin', {admin: true});
    const response = await fetch('http://127.0.0.1:19099/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=emulator-only', {method: 'POST', headers: {'content-type': 'application/json'}, body: JSON.stringify({token, returnSecureToken: true})});
    return (await response.json()).idToken;
  }
  const response = await fetch('http://127.0.0.1:19099/identitytoolkit.googleapis.com/v1/accounts:signUp?key=emulator-only', {method: 'POST', headers: {'content-type': 'application/json'}, body: JSON.stringify({returnSecureToken: true})});
  return (await response.json()).idToken;
}
async function call(name, data, token) {
  const response = await fetch(`http://127.0.0.1:15001/${projectId}/${FUNCTIONS_REGION}/${name}`, {method: 'POST', headers: {'content-type': 'application/json', ...(token ? {authorization: `Bearer ${token}`} : {})}, body: JSON.stringify({data})});
  return response.json();
}
async function admissionProof() {
  const clock = Date.parse('2030-01-01T12:00:10Z');
  const a = admissionBuckets('submit', 'admission-a', undefined, clock);
  const b = admissionBuckets('submit', 'admission-b', undefined, clock);
  const lists = ['admission-a', 'admission-b'].map(uid => admissionBuckets('listOwn', uid, undefined, clock));
  const all = new Map([...a, ...b, ...lists.flat()].map(bucket => [bucket.key, bucket]));
  const shared = a.find(bucket => bucket.scope === 'global' && bucket.window === 'minute');
  try {
    // One shared allowance remains: different identities must race for it,
    // and the transaction loser must not consume any of its own allowance.
    await db.doc(`_abuseCounters/${shared.key}`).set({count: 29,
      windowEnd: Timestamp.fromMillis(shared.windowEndMs),
      expiresAt: Timestamp.fromMillis(shared.windowEndMs + 172800000)});
    const outcomes = await Promise.allSettled([a, b].map(buckets =>
      db.runTransaction(transaction => consumeAdmission(transaction, db, buckets, clock))));
    check(outcomes.filter(result => result.status === 'fulfilled').length, 1);
    check(outcomes.find(result => result.status === 'rejected').reason.code, 'resource-exhausted');
    check((await db.doc(`_abuseCounters/${shared.key}`).get()).data().count, 30);
    for (let i = 0; i < outcomes.length; i++) {
      const own = [a, b][i].find(bucket => bucket.scope === 'uid' && bucket.window === 'minute');
      const record = await db.doc(`_abuseCounters/${own.key}`).get();
      check(record.exists, outcomes[i].status === 'fulfilled');
    }
    for (const buckets of lists) await db.runTransaction(transaction => consumeAdmission(transaction, db, buckets, clock));
    for (const buckets of lists) {
      const own = buckets.find(bucket => bucket.scope === 'uid' && bucket.window === 'minute');
      check((await db.doc(`_abuseCounters/${own.key}`).get()).data().count, 1);
    }
    const globalDay = a.find(bucket => bucket.scope === 'global' && bucket.window === 'day');
    check((await db.doc(`_abuseCounters/${globalDay.key}`).get()).data().count, 1);
  } finally {
    // These are synthetic local counters only. Do not leave a future test
    // window behind to interfere with later endpoint-integration tests.
    const cleanup = db.batch();
    for (const key of all.keys()) cleanup.delete(db.doc(`_abuseCounters/${key}`));
    await cleanup.commit();
  }
}
async function photoRaceProof() {
  const uid = 'photo-race-proof'; const id = 'c'.repeat(32);
  const incidentRef = db.doc(`incidents/${id}`); const path = `incidentPhotos/${id}/photo.jpg`;
  await incidentRef.set({reporterUid: uid, moderationStatus: 'pending', photoReferences: [path]});
  const bytes = await sharp({create: {width: 8, height: 8, channels: 3, background: '#174A3A'}}).jpeg().toBuffer();
  const objects = new Map(); let decodes = 0; let lease = 0; let entered, release;
  const started = new Promise(resolve => {entered = resolve;});
  const paused = new Promise(resolve => {release = resolve;});
  const dependencies = {db, nowMs: Date.now, newLeaseId: () => `proof-${++lease}`,
    async processJpeg(input) {decodes++; entered(); await paused; return processPrivateJpeg(input);},
    storage: {
      async readMetadata(key) {return objects.get(key) ?? null;},
      async saveIfAbsent(key, _, hash) {
        if (objects.has(key)) throw Object.assign(new Error('precondition'), {code: 412});
        objects.set(key, {photoSha256: hash});
      },
    },
  };
  const upload = () => uploadPrivatePhoto({uid, incidentId: id, bytes}, dependencies);
  // Real Firestore transactions race for one lease. Only the winner reaches
  // the blocked decoder; its opponent must commit a request-only busy result.
  const settled = [upload(), upload()].map(result => result.then(
    value => ({value}), error => ({error})));
  let timer;
  try {
    const deadline = new Promise((_, reject) => {timer = setTimeout(() => reject(new Error('photo race stalled')), 15000);});
    await Promise.race([started, deadline]);
    const loser = await Promise.race([...settled, deadline]);
    check(loser.error?.code, 'unavailable');
  } finally {clearTimeout(timer); release();}
  const results = await Promise.all(settled);
  check(results.filter(result => result.value?.photoStored === true).length, 1);
  check(decodes, 1);
  check((await incidentRef.get()).data().photoLease, undefined);
  const requestDay = admissionBuckets('photoRequest', uid, id, Date.now()).find(bucket => bucket.scope === 'incident' && bucket.window === 'day');
  const decodeDay = admissionBuckets('photoDecode', uid, id, Date.now()).find(bucket => bucket.scope === 'incident' && bucket.window === 'day');
  check((await db.doc(`_abuseCounters/${requestDay.key}`).get()).data().count, 2);
  check((await db.doc(`_abuseCounters/${decodeDay.key}`).get()).data().count, 1);
  check((await upload()).photoStored, true); check(decodes, 1);
  const read = dependencies.storage.readMetadata;
  dependencies.storage.readMetadata = async key => {
    const metadata = await read(key);
    await incidentRef.update({moderationStatus: 'withdrawn'});
    return metadata;
  };
  await assert.rejects(upload(), {code: 'failed-precondition'}); count++;
  check((await incidentRef.get()).data().moderationStatus, 'withdrawn');
  check((await db.doc(`publicIncidents/${id}`).get()).exists, false);
  check(decodes, 1); check(objects.size, 1);
}

async function callableQuotaProof(token, input, originalId, foreign, adminToken) {
  const uid = (await getAuth().verifyIdToken(token)).uid;
  const adminUid = (await getAuth().verifyIdToken(adminToken)).uid;
  const foreignUid = (await getAuth().verifyIdToken(foreign)).uid;
  const counter = async (operation, actor, scope, amount) => {
    // Seed daily boundaries to keep real endpoint checks independent of which
    // minute the emulator started. Fixed minute/UID-churn boundaries are unit tested.
    const bucket = admissionBuckets(operation, actor, undefined, Date.now())
      .find(value => value.scope === scope && value.window === 'day');
    const ref = db.doc(`_abuseCounters/${bucket.key}`);
    await ref.set({count: amount, windowEnd: Timestamp.fromMillis(bucket.windowEndMs),
      expiresAt: Timestamp.fromMillis(bucket.windowEndMs + 172800000)});
    return ref;
  };
  const submissionCount = await counter('submit', uid, 'uid', 29);
  await db.doc(`_submissionThrottle/${uid}`).set({lastSubmittedAt: Timestamp.fromMillis(Date.now() - 5001)});
  const lastInput = {...input, requestId: 'task4-final-submission'};
  const last = await call('submitIncident', lastInput, token);
  assert.ok(last.result?.incidentId, JSON.stringify(last)); count++;
  check((await submissionCount.get()).data().count, 30);
  await db.doc(`_submissionThrottle/${uid}`).set({lastSubmittedAt: Timestamp.fromMillis(Date.now() - 5001)});
  const deniedInput = {...input, requestId: 'task4-denied-submission'};
  check((await call('submitIncident', deniedInput, token)).error.status, 'RESOURCE_EXHAUSTED');
  const deniedId = createHash('sha256').update(`${uid}:${deniedInput.requestId}`).digest('hex').slice(0, 32);
  check((await db.doc(`incidents/${deniedId}`).get()).exists, false);
  check((await submissionCount.get()).data().count, 30);
  const repeated = await call('submitIncident', input, token);
  check(repeated.result.incidentId, originalId); check(repeated.result.alreadyExists, true);
  check((await submissionCount.get()).data().count, 30);
  check((await call('submitIncident', {...input, note: 'changed'}, token)).error.status, 'FAILED_PRECONDITION');

  // Submission exhaustion never spends or blocks the separate withdrawal pool.
  await counter('submit', uid, 'global', 300);
  const withdrawalCount = await counter('withdraw', uid, 'uid', 0);
  check((await call('withdrawIncident', {incidentId: originalId}, token)).result.alreadyWithdrawn, true);
  check((await withdrawalCount.get()).data().count, 1);
  await counter('withdraw', uid, 'uid', 119);
  check((await call('withdrawIncident', {incidentId: last.result.incidentId}, token)).result.withdrawn, true);
  check((await withdrawalCount.get()).data().count, 120);
  check((await call('withdrawIncident', {incidentId: last.result.incidentId}, token)).error.status, 'RESOURCE_EXHAUSTED');
  await counter('withdraw', foreignUid, 'uid', 120);
  check((await call('withdrawIncident', {incidentId: originalId}, foreign)).error.status, 'PERMISSION_DENIED');

  const listCount = await counter('listOwn', uid, 'uid', 59);
  const listed = await call('listOwnIncidents', null, token);
  check(listed.result.reports.length, 500); check(listed.result.hasMore, true);
  check((await listCount.get()).data().count, 60);
  check((await call('listOwnIncidents', null, token)).error.status, 'RESOURCE_EXHAUSTED');
  check((await listCount.get()).data().count, 60);
  await counter('listOwn', uid, 'global', 600);
  check((await call('listOwnIncidents', null, foreign)).error.status, 'RESOURCE_EXHAUSTED');

  const moderationId = 'f'.repeat(32);
  await db.doc(`incidents/${moderationId}`).set({reporterUid: uid, createdAt: Timestamp.fromMillis(Date.now() - 604800001),
    incidentType: 'injured', moderationStatus: 'pending', latitude: -34.197, longitude: 18.375,
    publicProjection: null});
  const moderationCount = await counter('moderate', adminUid, 'uid', 499);
  check((await call('setIncidentModeration', {incidentId: moderationId, status: 'accepted'}, adminToken)).result.status, 'accepted');
  check((await moderationCount.get()).data().count, 500);
  check((await call('setIncidentModeration', {incidentId: moderationId, status: 'rejected'}, adminToken)).error.status, 'RESOURCE_EXHAUSTED');
  check((await db.doc(`incidents/${moderationId}`).get()).data().moderationStatus, 'accepted');
  check((await db.doc(`publicIncidents/${moderationId}`).get()).exists, true);
  await counter('moderate', uid, 'global', 1000);
  check((await call('setIncidentModeration', {incidentId: moderationId, status: 'accepted'}, token)).error.status, 'PERMISSION_DENIED');
}
async function main() {
  await admissionProof();
  await photoRaceProof();
  const token = await authToken();
  const input = {requestId: 'local-idempotent', latitude: -34.197, longitude: 18.375, incidentType: 'injured', locationSource: 'manual_pin', occurredAt: '2026-01-03T08:00:00Z'};
  check((await call('submitIncident', input)).error.status, 'UNAUTHENTICATED');
  check((await call('submitIncident', null, token)).error.status, 'INVALID_ARGUMENT');
  check((await call('submitIncident', [], token)).error.status, 'INVALID_ARGUMENT');
  check((await call('submitIncident', {...input, moderationStatus: 'accepted'}, token)).error.status, 'INVALID_ARGUMENT');
  const [first, retry] = await Promise.all([call('submitIncident', input, token), call('submitIncident', input, token)]);
  assert.ok(first.result?.incidentId, JSON.stringify(first)); count++;
  check(first.result.incidentId, retry.result.incidentId);
  const id = first.result.incidentId;
  const incident = (await db.doc(`incidents/${id}`).get()).data();
  check(incident.moderationStatus, 'pending');
  check(incident.photoReferences, [`incidentPhotos/${id}/photo.jpg`]);
  check((await call('submitIncident', {...input, note: 'changed after timeout'}, token)).error.status, 'FAILED_PRECONDITION');
  check((await call('submitIncident', {...input, requestId: 'new-too-soon'}, token)).error.status, 'RESOURCE_EXHAUSTED');
  const jpeg = await sharp({create: {width: 8, height: 8, channels: 3, background: '#174A3A'}}).withMetadata({orientation: 3}).jpeg().toBuffer();
  const photoInput = {incidentId: id, jpegBase64: jpeg.toString('base64')};
  check((await call('uploadIncidentPhoto', photoInput)).error.status, 'UNAUTHENTICATED');
  check((await call('uploadIncidentPhoto', {...photoInput, jpegBase64: 'not an image'}, token)).error.status, 'INVALID_ARGUMENT');
  const png = await sharp({create: {width: 1, height: 1, channels: 3, background: '#174A3A'}}).png().toBuffer();
  check((await call('uploadIncidentPhoto', {...photoInput, jpegBase64: png.toString('base64')}, token)).error.status, 'INVALID_ARGUMENT');
  const hugeJpeg = await sharp({create: {width: 3000, height: 3000, channels: 3, background: '#174A3A'}}).jpeg().toBuffer();
  check((await call('uploadIncidentPhoto', {...photoInput, jpegBase64: hugeJpeg.toString('base64')}, token)).error.status, 'INVALID_ARGUMENT');
  const foreign = await authToken();
  check((await call('uploadIncidentPhoto', photoInput, foreign)).error.status, 'PERMISSION_DENIED');
  const uploaded = await call('uploadIncidentPhoto', photoInput, token);
  check(uploaded.result.photoStored, true);
  const file = getStorage().bucket(`${projectId}.appspot.com`).file(`incidentPhotos/${id}/photo.jpg`);
  const [metadata] = await file.getMetadata();
  check(metadata.metadata?.firebaseStorageDownloadTokens, undefined);
  const [savedBytes] = await file.download();
  check((await sharp(savedBytes).metadata()).exif, undefined);
  const media = await fetch(`http://127.0.0.1:19199/v0/b/${projectId}.appspot.com/o/${encodeURIComponent(file.name)}?alt=media`);
  check([401, 403].includes(media.status), true);
  const fakeTokenMedia = await fetch(`http://127.0.0.1:19199/v0/b/${projectId}.appspot.com/o/${encodeURIComponent(file.name)}?alt=media&token=guessed-token`);
  check([401, 403].includes(fakeTokenMedia.status), true);
  check((await call('uploadIncidentPhoto', photoInput, token)).result.photoStored, true);
  const photoOwnerUid = (await getAuth().verifyIdToken(token)).uid;
  const storedPhoto = (await db.doc(`incidents/${id}`).get()).data();
  check(storedPhoto.photoProcessorVersion, 'jpeg-v1');
  check(/^[a-f0-9]{64}$/.test(storedPhoto.photoInputFingerprint), true);
  check(storedPhoto.photoLease, undefined);
  const decodeDay = admissionBuckets('photoDecode', photoOwnerUid, id, Date.now())
    .find(bucket => bucket.scope === 'incident' && bucket.window === 'day');
  // One invalid oversized-pixel decode plus one valid decode; stored retry adds none.
  check((await db.doc(`_abuseCounters/${decodeDay.key}`).get()).data().count, 2);
  const otherJpeg = await sharp({create: {width: 8, height: 8, channels: 3, background: '#ff0000'}}).jpeg().toBuffer();
  check((await call('uploadIncidentPhoto', {...photoInput, jpegBase64: otherJpeg.toString('base64')}, token)).error.status, 'ALREADY_EXISTS');
  // A repeated replacement attempt must be denied before another expensive decode.
  // Seed the day allowance so a minute boundary cannot make this assertion flaky.
  await db.doc(`_abuseCounters/${decodeDay.key}`).update({count: decodeDay.limit});
  check((await call('uploadIncidentPhoto', {...photoInput, jpegBase64: otherJpeg.toString('base64')}, token)).error.status, 'RESOURCE_EXHAUSTED');
  check((await call('uploadIncidentPhoto', {...photoInput, jpegBase64: Buffer.alloc(2*1024*1024+1).toString('base64')}, token)).error.status, 'INVALID_ARGUMENT');
  check((await db.doc(`publicIncidents/${id}`).get()).exists, false);
  check((await call('setIncidentModeration', {incidentId: id, status: 'accepted'}, token)).error.status, 'PERMISSION_DENIED');
  const adminToken = await authToken(true);
  const premature = await call('setIncidentModeration', {incidentId: id, status: 'accepted'}, adminToken);
  check(premature.error.status, 'FAILED_PRECONDITION');
  check(premature.error.details.reason, 'publication-not-ready');
  check((await db.doc(`incidents/${id}`).get()).data().moderationStatus, 'pending');
  check((await db.doc(`publicIncidents/${id}`).get()).exists, false);
  // Only synthetic emulator server creation is aged. The old occurredAt above
  // deliberately did not bypass the gate, and no production data is touched.
  await db.doc(`incidents/${id}`).update({createdAt: Timestamp.fromMillis(Date.now() - 604800001)});
  const accepted = await call('setIncidentModeration', {incidentId: id, status: 'accepted'}, adminToken);
  check(accepted.result.status, 'accepted');
  const published = (await db.doc(`publicIncidents/${id}`).get()).data();
  check(Object.keys(published).sort(), ['date','displayLatitude','displayLongitude','id','incidentType']);
  check(published.date, '2026-01-03');
  check((await db.doc(`incidents/${id}`).get()).data().publicProjectionVersion, 'v2');
  const {haversineMetres} = require('../lib/projection');
  const publicDistance = haversineMetres(input.latitude, input.longitude, published.displayLatitude, published.displayLongitude);
  check(publicDistance >= 100 && publicDistance <= 250, true);
  await call('setIncidentModeration', {incidentId: id, status: 'rejected'}, adminToken);
  check((await db.doc(`publicIncidents/${id}`).get()).exists, false);
  await call('setIncidentModeration', {incidentId: id, status: 'accepted'}, adminToken);
  check((await db.doc(`publicIncidents/${id}`).get()).data(), published);
  // Stored legacy points are reused without applying new delay/radius or adding
  // private version metadata to the public allowlist.
  const legacyId = 'b'.repeat(32);
  const legacy = {...published, id: legacyId, displayLatitude: -34.1971, displayLongitude: 18.3751};
  await db.doc(`incidents/${legacyId}`).set({reporterUid: 'legacy-test', createdAt: Timestamp.now(),
    latitude: input.latitude, longitude: input.longitude, incidentType: 'injured',
    moderationStatus: 'rejected', publicProjection: legacy});
  check((await call('setIncidentModeration', {incidentId: legacyId, status: 'accepted'}, adminToken)).result.status, 'accepted');
  check((await db.doc(`publicIncidents/${legacyId}`).get()).data(), legacy);
  check((await db.doc(`incidents/${legacyId}`).get()).data().publicProjectionVersion, 'v1');
  await call('setIncidentModeration', {incidentId: legacyId, status: 'rejected'}, adminToken);
  await call('setIncidentModeration', {incidentId: legacyId, status: 'accepted'}, adminToken);
  check((await db.doc(`publicIncidents/${legacyId}`).get()).data(), legacy);
  check((await call('listOwnIncidents', null)).error.status, 'UNAUTHENTICATED');
  const ownReceipts = await call('listOwnIncidents', null, token);
  assert.equal(ownReceipts.result.reports.length, 1); count++;
  check(Object.keys(ownReceipts.result.reports[0]).sort(), ['createdAt','id','incidentType','moderationStatus']);
  check((await call('withdrawIncident', {incidentId: id}, foreign)).error.status, 'PERMISSION_DENIED');
  check((await call('withdrawIncident', {incidentId: id}, adminToken)).error.status, 'PERMISSION_DENIED');
  const withdrawn = await call('withdrawIncident', {incidentId: id}, token);
  check(withdrawn.result.withdrawn, true);
  check((await db.doc(`incidents/${id}`).get()).data().moderationStatus, 'withdrawn');
  check((await db.doc(`publicIncidents/${id}`).get()).exists, false);
  check((await call('withdrawIncident', {incidentId: id}, token)).result.alreadyWithdrawn, true);
  check((await call('uploadIncidentPhoto', photoInput, token)).error.status, 'FAILED_PRECONDITION');
  check((await call('setIncidentModeration', {incidentId: id, status: 'accepted'}, adminToken)).error.status, 'FAILED_PRECONDITION');

  // The owner query reads one extra document, orders equal timestamps by ID,
  // and never exposes another reporter's records.
  const ownerUid = (await getAuth().verifyIdToken(token)).uid;
  const foreignUid = (await getAuth().verifyIdToken(foreign)).uid;
  const tiedCreatedAt = new Date('2099-02-01T12:00:00.000Z');
  const seed = async (uid, id, type = 'alive') => db.doc(`incidents/${id}`).set({
    reporterUid: uid,
    createdAt: tiedCreatedAt,
    incidentType: type,
    moderationStatus: 'pending',
    latitude: -34.197,
    longitude: 18.375,
    photoReferences: [],
    publicProjection: null,
  });
  const tiedIds = Array.from({length: 501}, (_, index) => index.toString(16).padStart(32, '0'));
  for (let offset = 0; offset < tiedIds.length; offset += 400) {
    await Promise.all(tiedIds.slice(offset, offset + 400).map(id => seed(ownerUid, id)));
  }
  const foreignId = 'e'.repeat(32);
  await seed(foreignUid, foreignId);
  const cappedPage = await call('listOwnIncidents', null, token);
  check(cappedPage.result.reports.length, 500);
  check(cappedPage.result.hasMore, true);
  check(cappedPage.result.reports[0].id, '000000000000000000000000000001f4');
  check(cappedPage.result.reports.at(-1).id, '00000000000000000000000000000001');
  const foreignPage = await call('listOwnIncidents', null, foreign);
  check(foreignPage.result.reports.length, 1);
  check(foreignPage.result.reports[0].id, foreignId);
  check(foreignPage.result.hasMore, false);

  // Moderation and withdrawal may arrive together; withdrawal is terminal and
  // the public projection is absent in either transaction order.
  const raceId = 'd'.repeat(32);
  await seed(ownerUid, raceId, 'injured');
  await db.doc(`incidents/${raceId}`).update({createdAt: Timestamp.fromMillis(Date.now() - 604800001)});
  const [raceModeration, raceWithdrawal] = await Promise.all([
    call('setIncidentModeration', {incidentId: raceId, status: 'accepted'}, adminToken),
    call('withdrawIncident', {incidentId: raceId}, token),
  ]);
  assert.ok(raceModeration.result?.status === 'accepted' || raceModeration.error?.status === 'FAILED_PRECONDITION'); count++;
  assert.ok(raceWithdrawal.result?.withdrawn === true || raceWithdrawal.error?.status === 'FAILED_PRECONDITION'); count++;
  check((await db.doc(`incidents/${raceId}`).get()).data().moderationStatus, 'withdrawn');
  check((await db.doc(`publicIncidents/${raceId}`).get()).exists, false);
  await callableQuotaProof(token, input, id, foreign, adminToken);
  console.log(`PASS: ${count} callable/Auth/Firestore emulator assertions, concurrent idempotency and stable moderation projection.`);
  await deleteApp(app);
}
main().catch(error => {console.error(error); process.exitCode = 1;});
