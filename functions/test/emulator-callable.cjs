const assert = require('node:assert/strict');
const {initializeApp, deleteApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
const {getAuth} = require('firebase-admin/auth');
const {getStorage} = require('firebase-admin/storage');
const sharp = require('sharp');
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
  const response = await fetch(`http://127.0.0.1:15001/${projectId}/us-central1/${name}`, {method: 'POST', headers: {'content-type': 'application/json', ...(token ? {authorization: `Bearer ${token}`} : {})}, body: JSON.stringify({data})});
  return response.json();
}
async function main() {
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
  const otherJpeg = await sharp({create: {width: 8, height: 8, channels: 3, background: '#ff0000'}}).jpeg().toBuffer();
  check((await call('uploadIncidentPhoto', {...photoInput, jpegBase64: otherJpeg.toString('base64')}, token)).error.status, 'ALREADY_EXISTS');
  check((await call('uploadIncidentPhoto', {...photoInput, jpegBase64: Buffer.alloc(2*1024*1024+1).toString('base64')}, token)).error.status, 'INVALID_ARGUMENT');
  check((await db.doc(`publicIncidents/${id}`).get()).exists, false);
  check((await call('setIncidentModeration', {incidentId: id, status: 'accepted'}, token)).error.status, 'PERMISSION_DENIED');
  const adminToken = await authToken(true);
  const accepted = await call('setIncidentModeration', {incidentId: id, status: 'accepted'}, adminToken);
  check(accepted.result.status, 'accepted');
  const published = (await db.doc(`publicIncidents/${id}`).get()).data();
  check(Object.keys(published).sort(), ['date','displayLatitude','displayLongitude','id','incidentType']);
  check(published.date, '2026-01-03');
  await call('setIncidentModeration', {incidentId: id, status: 'rejected'}, adminToken);
  check((await db.doc(`publicIncidents/${id}`).get()).exists, false);
  await call('setIncidentModeration', {incidentId: id, status: 'accepted'}, adminToken);
  check((await db.doc(`publicIncidents/${id}`).get()).data(), published);
  console.log(`PASS: ${count} callable/Auth/Firestore emulator assertions, concurrent idempotency and stable moderation projection.`);
  await deleteApp(app);
}
main().catch(error => {console.error(error); process.exitCode = 1;});
