import {createHash, randomBytes} from 'node:crypto';

import {initializeApp} from 'firebase-admin/app';
import {FieldPath, FieldValue, Timestamp, Transaction, getFirestore} from 'firebase-admin/firestore';
import {getStorage} from 'firebase-admin/storage';
import {HttpsError, onCall} from 'firebase-functions/v2/https';

import {createPublicProjection, projectionForModeration, publicationEligibility} from './projection';
import {validateSubmission} from './validation';
import {photoInput, processPrivateJpeg} from './photo';
import {uploadPrivatePhoto} from './photo_upload';
import {CALLABLE_RUNTIME, FUNCTIONS_REGION, PUBLIC_OFFSET_MINIMUM_METRES, PUBLIC_OFFSET_MAXIMUM_METRES} from './config';
import {admissionBuckets, consumeAdmission} from './admission';
import {isIncidentId, ownerReceiptPage} from './withdrawal';

initializeApp();
const db = getFirestore();
const minimumPublicOffsetMetres = PUBLIC_OFFSET_MINIMUM_METRES;
const maximumPublicOffsetMetres = PUBLIC_OFFSET_MAXIMUM_METRES;
const submissionCooldownMs = 5000;

// Only the Functions emulator may bypass App Check; production always enforces it.
const enforceAppCheck = process.env.FUNCTIONS_EMULATOR !== 'true';
export const submitIncident = onCall({region: FUNCTIONS_REGION, enforceAppCheck, ...CALLABLE_RUNTIME.submit}, async (request) => {
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
  const alreadyExists = await transact(async (transaction) => {
    const existing = await transaction.get(incidentRef);
    if (existing.exists) {
      if (existing.data()?.submissionFingerprint !== payloadHash) throw new HttpsError('failed-precondition', 'This request was already saved with different details.');
      return true;
    }
    const throttle = await transaction.get(throttleRef);
    const previous = throttle.data()?.lastSubmittedAt as Timestamp | undefined;
    const now = Date.now();
    if (previous && now - previous.toMillis() < submissionCooldownMs) {
      throw new HttpsError('resource-exhausted', 'Please wait before submitting another report.');
    }
    await consumeAdmission(transaction, db, admissionBuckets('submit', uid, undefined, now), now);
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
    return false;
  });
  return {incidentId, alreadyExists};
});

export const listOwnIncidents = onCall({region: FUNCTIONS_REGION, enforceAppCheck, ...CALLABLE_RUNTIME.listOwn}, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign-in is required to view your reports.');
  await transact(async transaction => {
    const now = Date.now();
    await consumeAdmission(transaction, db, admissionBuckets('listOwn', uid, undefined, now), now);
  });
  const snapshot = await db.collection('incidents')
      .where('reporterUid', '==', uid)
      .orderBy('createdAt', 'desc')
      .orderBy(FieldPath.documentId(), 'desc')
      .limit(501)
      .get();
  return ownerReceiptPage(snapshot.docs, 500);
});

export const withdrawIncident = onCall({region: FUNCTIONS_REGION, enforceAppCheck, ...CALLABLE_RUNTIME.withdraw}, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign-in is required to withdraw a report.');
  const data = request.data as Record<string, unknown> | null | undefined;
  if (!data || typeof data !== 'object' || Array.isArray(data) ||
      Object.keys(data).some(key => key !== 'incidentId') || !isIncidentId(data.incidentId)) {
    throw new HttpsError('invalid-argument', 'incidentId is invalid.');
  }
  const incidentRef = db.collection('incidents').doc(data.incidentId);
  const publicRef = db.collection('publicIncidents').doc(data.incidentId);
  const alreadyWithdrawn = await transact(async transaction => {
    const snapshot = await transaction.get(incidentRef);
    // Deliberately use the same response for missing and foreign records so the
    // callable never becomes an incident-ID oracle.
    if (!snapshot.exists || snapshot.data()?.reporterUid !== uid) {
      throw new HttpsError('permission-denied', 'This report cannot be withdrawn.');
    }
    const incident = snapshot.data()!;
    const now = Date.now();
    await consumeAdmission(transaction, db, admissionBuckets('withdraw', uid, undefined, now), now);
    if (incident.moderationStatus === 'withdrawn') {
      transaction.delete(publicRef);
      return true;
    }
    transaction.update(incidentRef, {
      moderationStatus: 'withdrawn',
      withdrawnAt: FieldValue.serverTimestamp(),
      withdrawnBy: uid,
    });
    transaction.delete(publicRef);
    return false;
  });
  return {incidentId: data.incidentId, withdrawn: true, alreadyWithdrawn};
});

export const uploadIncidentPhoto = onCall({region: FUNCTIONS_REGION, enforceAppCheck, ...CALLABLE_RUNTIME.photo}, async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign-in is required.');
  const {incidentId, bytes} = photoInput(request.data);
  const bucket = process.env.FUNCTIONS_EMULATOR === 'true' ? getStorage().bucket('demo-scarborough-tortoise-watch.appspot.com') : getStorage().bucket();
  return uploadPrivatePhoto({uid, incidentId, bytes}, {
    db, processJpeg: processPrivateJpeg, nowMs: Date.now,
    newLeaseId: () => randomBytes(16).toString('hex'),
    storage: {
      async readMetadata(path) {
        try {
          const [metadata] = await bucket.file(path).getMetadata();
          return {photoSha256: metadata.metadata?.photoSha256 as string | undefined,
            downloadTokens: metadata.metadata?.firebaseStorageDownloadTokens as string | undefined};
        } catch (error) {
          if ((error as {code?: number}).code === 404) return null;
          throw error;
        }
      },
      async saveIfAbsent(path, processed, photoHash) {
        // Admin GCS creates no Firebase bearer download token or signed URL.
        await bucket.file(path).save(processed, {resumable: false,
          preconditionOpts: {ifGenerationMatch: 0}, metadata: {contentType: 'image/jpeg',
            cacheControl: 'private, no-store', metadata: {photoSha256: photoHash}}});
      },
    },
  });
});

export const setIncidentModeration = onCall({region: FUNCTIONS_REGION, enforceAppCheck, ...CALLABLE_RUNTIME.moderate}, async (request) => {
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
  await transact(async (transaction) => {
    const snapshot = await transaction.get(incidentRef);
    if (!snapshot.exists) throw new HttpsError('not-found', 'Incident not found.');
    const incident = snapshot.data()!;
    if (incident.moderationStatus === 'withdrawn') throw new HttpsError('failed-precondition',
      'Withdrawn reports cannot be moderated.', {reason: 'incident-withdrawn'});
    const now = Date.now();
    if (status === 'accepted' && !incident.publicProjection) {
      if (!(incident.createdAt instanceof Timestamp)) {
        throw new HttpsError('failed-precondition', 'The report needs a server creation-time check.');
      }
      const eligibility = publicationEligibility(incident.createdAt.toDate(), new Date(now));
      if (!eligibility.eligible) throw new HttpsError('failed-precondition',
        'This report is not ready for public publication.',
        {reason: 'publication-not-ready', eligibleDate: eligibility.eligibleAt.toISOString().slice(0, 10)});
    }
    await consumeAdmission(transaction, db, admissionBuckets('moderate', request.auth!.uid, undefined, now), now);
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
      ...(nextProjection ? {publicProjectionVersion: incident.publicProjection ? (incident.publicProjectionVersion ?? 'v1') : 'v2'} : {}),
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

// Map commit/retry failures too, not only errors inside admission's callback.
async function transact<T>(callback: (transaction: Transaction) => Promise<T>): Promise<T> {
  try { return await db.runTransaction(callback); }
  catch (error) {
    if (error instanceof HttpsError) throw error;
    throw new HttpsError('unavailable', 'Report service is temporarily unavailable. Please try again.');
  }
}

function secureRandom(): number {
  return randomBytes(6).readUIntBE(0, 6) / 0x1000000000000;
}

function requireAdmin(auth: {uid: string; token: Record<string, unknown>} | undefined): void {
  const role = auth?.token.role;
  const allowed = auth?.token.admin === true || role === 'admin' || role === 'analyst';
  if (!auth || !allowed) throw new HttpsError('permission-denied', 'Authorised administration access is required.');
}
