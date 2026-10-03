// Integration suite: run only through Firebase emulators:exec. No production access.
const {readFileSync} = require('node:fs');
const {resolve} = require('node:path');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDoc, getDocs, collection} = require('firebase/firestore');
const {ref, uploadBytes, getBytes, listAll, deleteObject} = require('firebase/storage');

async function main() {
  const projectId = 'demo-scarborough-tortoise-watch';
  const env = await initializeTestEnvironment({projectId,
    firestore: {host: '127.0.0.1', port: 18080, rules: readFileSync(resolve(__dirname, '../../firestore.rules'), 'utf8')},
    storage: {host: '127.0.0.1', port: 19199, rules: readFileSync(resolve(__dirname, '../../storage.rules'), 'utf8')},
  });
  let count = 0;
  const pass = async (promise) => {await assertSucceeds(promise); count++;};
  const deny = async (promise) => {await assertFails(promise); count++;};
  try {
    await env.clearFirestore(); await env.clearStorage();
    const path = 'incidentPhotos/owned/photo.jpg';
    await env.withSecurityRulesDisabled(async ctx => {
      await setDoc(doc(ctx.firestore(), 'incidents', 'owned'), {reporterUid: 'owner', latitude: -34.197, photoReferences: [path]});
      await setDoc(doc(ctx.firestore(), 'incidents', 'foreign'), {reporterUid: 'other', photoReferences: ['incidentPhotos/foreign/photo.jpg']});
      await setDoc(doc(ctx.firestore(), 'incidents', 'unreserved'), {reporterUid: 'owner', photoReferences: []});
      await setDoc(doc(ctx.firestore(), 'publicIncidents', 'public'), {id: 'public', date: '2026-10-03', displayLatitude: -34.1973, displayLongitude: 18.375, incidentType: 'injured'});
    });
    const anonymous = env.unauthenticatedContext();
    const owner = env.authenticatedContext('owner');
    const admin = env.authenticatedContext('admin-user', {admin: true});
    const analyst = env.authenticatedContext('analyst-user', {role: 'analyst'});
    for (const ctx of [anonymous, owner]) {
      await deny(getDoc(doc(ctx.firestore(), 'incidents', 'owned')));
      await deny(getDocs(collection(ctx.firestore(), 'incidents')));
      await deny(setDoc(doc(ctx.firestore(), 'incidents', 'forged'), {reporterUid: 'owner'}));
      await deny(setDoc(doc(ctx.firestore(), 'publicIncidents', 'forged'), {latitude: 0}));
      await deny(getDoc(doc(ctx.firestore(), '_submissionThrottle', 'owner')));
      await pass(getDoc(doc(ctx.firestore(), 'publicIncidents', 'public')));
    }
    for (const ctx of [admin, analyst]) {
      await pass(getDoc(doc(ctx.firestore(), 'incidents', 'owned')));
      await deny(setDoc(doc(ctx.firestore(), 'incidents', 'owned'), {latitude: 0}));
    }
    const jpeg = new Uint8Array([0xff, 0xd8, 0xff, 0xd9]);
    await deny(uploadBytes(ref(anonymous.storage(), path), jpeg, {contentType: 'image/jpeg'}));
    await deny(uploadBytes(ref(owner.storage(), 'incidentPhotos/foreign/photo.jpg'), jpeg, {contentType: 'image/jpeg'}));
    await deny(uploadBytes(ref(owner.storage(), 'incidentPhotos/missing/photo.jpg'), jpeg, {contentType: 'image/jpeg'}));
    await deny(uploadBytes(ref(owner.storage(), 'incidentPhotos/unreserved/photo.jpg'), jpeg, {contentType: 'image/jpeg'}));
    await deny(uploadBytes(ref(owner.storage(), 'incidentPhotos/owned/extra.jpg'), jpeg, {contentType: 'image/jpeg'}));
    await deny(uploadBytes(ref(owner.storage(), path), jpeg, {contentType: 'text/plain'}));
    await deny(uploadBytes(ref(owner.storage(), path), new Uint8Array(2 * 1024 * 1024 + 1), {contentType: 'image/jpeg'}));
    await deny(uploadBytes(ref(owner.storage(), path), jpeg, {contentType: 'image/jpeg'}));
    await env.withSecurityRulesDisabled(async ctx => { await uploadBytes(ref(ctx.storage(), path), jpeg, {contentType: 'image/jpeg'}); });
    await deny(uploadBytes(ref(owner.storage(), path), jpeg, {contentType: 'image/jpeg'}));
    for (const ctx of [anonymous, owner]) {
      await deny(getBytes(ref(ctx.storage(), path)));
      await deny(listAll(ref(ctx.storage(), 'incidentPhotos/owned')));
      await deny(deleteObject(ref(ctx.storage(), path)));
    }
    await pass(getBytes(ref(admin.storage(), path)));
    await pass(getBytes(ref(analyst.storage(), path)));
    await deny(listAll(ref(admin.storage(), 'incidentPhotos')));
    await pass(deleteObject(ref(admin.storage(), path)));
    console.log(`PASS: ${count} real Firestore/Storage emulator assertions.`);
  } finally { await env.cleanup(); }
}
main().catch(error => {console.error(error); process.exitCode = 1;});
