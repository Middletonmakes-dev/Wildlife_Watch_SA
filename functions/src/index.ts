import {createHash, randomBytes} from 'node:crypto';

import {initializeApp} from 'firebase-admin/app';
import {FieldValue, Timestamp, getFirestore} from 'firebase-admin/firestore';
import {getStorage} from 'firebase-admin/storage';
import {HttpsError, onCall} from 'firebase-functions/v2/https';

import {createPublicProjection, projectionForModeration} from './projection';
import {validateSubmission} from './validation';
import {photoInput, processPrivateJpeg} from './photo';
import {FUNCTIONS_REGION} from './config';

initializeApp();
const db = getFirestore();
const minimumPublicOffsetMetres = Number(process.env.PUBLIC_COORDINATE_RADIUS_MIN_METRES ?? 20);
const maximumPublicOffsetMetres = Number(process.env.PUBLIC_COORDINATE_RADIUS_MAX_METRES ?? 50);
const submissionCooldownMs = 5000;

// Only the Functions emulator may bypass App Check; production always enforces it.
const enforceAppCheck = process.env.FUNCTIONS_EMULATOR !== 'true';
export const submitIncident = onCall({region: FUNCTIONS_REGION, enforceAppCheck}, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign-in is required to submit a report.');
  const data = request.data as Record<string, unknown> | null | undefined;
  if (!data || typeof data !== 'object' || Array.isArray(data)) {
    throw new HttpsError('invalid-argument', 'Report data must be an object.');
  }
  const errors = validateSubmission(data);
  if (errors.length > 0) throw new HttpsError('invalid-argument', errors.join('; '));

  const requestId = data.requestId as string;
  const canonical = Object.fromEntries(Object.keys(data).sort().map(key => [key, data[key]]));
  const payloadHash = createHash('sha256').update(JSON.stringify(canonical)).digest('hex');
  const incidentId = createHash('sha256').update(`${uid}:${requestId}`).digest('hex').slice(0, 32);
  const incidentRef = db.collection('incidents').doc(incidentId);
  const throttleRef = db.collection('_submissionThrottle').doc(uid);
  let alreadyExists = false;
  await db.runTransaction(async (transaction) => {
    const existing = await transaction.get(incidentRef);
    if (existing.exists) {
      if (existing.data()?.submissionFingerprint !== payloadHash) throw new HttpsError('failed-precondition', 'This request was already saved with different details.');
      alreadyExists = true;
      return;
    }
    const throttle = await transaction.get(throttleRef);
    const previous = throttle.data()?.lastSubmittedAt as Timestamp | undefined;
    if (previous && Date.now() - previous.toMillis() < submissionCooldownMs) {
      throw new HttpsError('resource-exhausted', 'Please wait before submitting another report.');
    }
    transaction.create(incidentRef, {
      createdAt: FieldValue.serverTimestamp(),
      occurredAt: data!.occurredAt ? Timestamp.fromDate(new Date(data!.occurredAt as string)) : null,
      latitude: data!.latitude,
      longitude: data!.longitude,
      locationAccuracyMetres: data!.locationAccuracyMetres ?? null,
      locationSource: data!.locationSource,
      incidentType: data!.incidentType,
      directionBearing: data!.directionBearing ?? null,
      note: data!.note ?? null,
      photoReferences: [`incidentPhotos/${incidentId}/photo.jpg`],
      reporterUid: uid,
      moderationStatus: 'pending',
      requestId,
      submissionFingerprint: payloadHash,
      sourceVersion: 'v1',
      publicProjection: null,
    });
    transaction.set(throttleRef, {lastSubmittedAt: FieldValue.serverTimestamp()});
  });
  return {incidentId, alreadyExists};
});

export const uploadIncidentPhoto = onCall({region: FUNCTIONS_REGION, enforceAppCheck, memory: '256MiB', concurrency: 4}, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign-in is required.');
  const {incidentId, bytes} = photoInput(request.data);
  const incidentRef = db.doc(`incidents/${incidentId}`);
  const incident = await incidentRef.get();
  if (!incident.exists || incident.data()?.reporterUid !== uid) throw new HttpsError('permission-denied', 'The incident does not belong to this reporter.');
  const path = `incidentPhotos/${incidentId}/photo.jpg`;
  if (!incident.data()?.photoReferences?.includes(path)) throw new HttpsError('failed-precondition', 'No photo slot is reserved.');
  const processed = await processPrivateJpeg(bytes);
  const photoHash = createHash('sha256').update(processed).digest('hex');
  const alreadyStored = await db.runTransaction(async transaction => {
    const current = await transaction.get(incidentRef);
    if (current.data()?.reporterUid !== uid) throw new HttpsError('permission-denied', 'The incident does not belong to this reporter.');
    const existingHash = current.data()?.photoFingerprint;
    if (existingHash && existingHash !== photoHash) throw new HttpsError('already-exists', 'A different photo is already reserved for this report.');
    if (existingHash === photoHash && current.data()?.photoStored === true) return true;
    transaction.update(incidentRef, {photoFingerprint: photoHash});
    return false;
  });
  if (alreadyStored) return {photoStored: true};
  const bucket = process.env.FUNCTIONS_EMULATOR === 'true' ? getStorage().bucket('demo-scarborough-tortoise-watch.appspot.com') : getStorage().bucket();
  try {
    // GCS API bypasses the Firebase SDK token creation path. Never issue signed/download URLs.
    await bucket.file(path).save(processed, {resumable: false, preconditionOpts: {ifGenerationMatch: 0}, metadata: {contentType: 'image/jpeg', cacheControl: 'private, no-store', metadata: {photoSha256: photoHash}}});
  } catch (error) {
    if ((error as {code?: number}).code === 412) {
      const [existing] = await bucket.file(path).getMetadata();
      if (existing.metadata?.photoSha256 !== photoHash) throw new HttpsError('already-exists', 'A different photo already exists for this report.');
    } else {
      throw new HttpsError('unavailable', 'Photo storage is temporarily unavailable.');
    }
  }
  await incidentRef.update({photoStored: true});
  return {photoStored: true};
});

export const setIncidentModeration = onCall({region: FUNCTIONS_REGION, enforceAppCheck}, async (request) => {
  requireAdmin(request.auth);
  const data = request.data as Record<string, unknown> | null | undefined;
  if (!data || typeof data !== 'object' || Array.isArray(data)) {
    throw new HttpsError('invalid-argument', 'Moderation data must be an object.');
  }
  const incidentId = data.incidentId;
  const status = data.status;
  if (typeof incidentId !== 'string' || !/^[a-f0-9]{32}$/.test(incidentId)) {
    throw new HttpsError('invalid-argument', 'incidentId is invalid.');
  }
  if (!['accepted', 'rejected', 'duplicate'].includes(status as string)) {
    throw new HttpsError('invalid-argument', 'status is invalid.');
  }

  const incidentRef = db.collection('incidents').doc(incidentId);
  const publicRef = db.collection('publicIncidents').doc(incidentId);
  await db.runTransaction(async (transaction) => {
    const snapshot = await transaction.get(incidentRef);
    if (!snapshot.exists) throw new HttpsError('not-found', 'Incident not found.');
    const incident = snapshot.data()!;
    const nextProjection = projectionForModeration(status as 'accepted' | 'rejected' | 'duplicate', incident.publicProjection, () => createPublicProjection({
        id: incidentId,
        incidentType: incident.incidentType,
        latitude: incident.latitude,
        longitude: incident.longitude,
        occurredAt: (incident.occurredAt ?? incident.createdAt)?.toDate?.(),
        random: secureRandom,
        minimumMetres: minimumPublicOffsetMetres,
        maximumMetres: maximumPublicOffsetMetres,
      }));
    transaction.update(incidentRef, {
      moderationStatus: status,
      publicProjection: incident.publicProjection ?? nextProjection,
      moderatedAt: FieldValue.serverTimestamp(),
      moderatedBy: request.auth!.uid,
    });
    if (status === 'accepted' && nextProjection) {
      transaction.set(publicRef, nextProjection);
    } else {
      transaction.delete(publicRef);
    }
  });
  return {incidentId, status};
});

function secureRandom(): number {
  return randomBytes(6).readUIntBE(0, 6) / 0x1000000000000;
}

function requireAdmin(auth: {uid: string; token: Record<string, unknown>} | undefined): void {
  const role = auth?.token.role;
  const allowed = auth?.token.admin === true || role === 'admin' || role === 'analyst';
  if (!auth || !allowed) throw new HttpsError('permission-denied', 'Authorised administration access is required.');
}
