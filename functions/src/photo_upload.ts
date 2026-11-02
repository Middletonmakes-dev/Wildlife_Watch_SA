import {createHash} from 'node:crypto';
import {DocumentData, DocumentSnapshot, FieldValue, Firestore, Timestamp, Transaction} from 'firebase-admin/firestore';
import {HttpsError} from 'firebase-functions/v2/https';

import {admissionBuckets, consumeAdmission} from './admission';

export interface PrivatePhotoMetadata {
  photoSha256?: string;
  downloadTokens?: string;
}

export interface PhotoUploadDependencies {
  db: Firestore;
  storage: {
    readMetadata(path: string): Promise<PrivatePhotoMetadata | null>;
    saveIfAbsent(path: string, bytes: Buffer, canonicalHash: string): Promise<void>;
  };
  processJpeg(bytes: Buffer): Promise<Buffer>;
  nowMs(): number;
  newLeaseId(): string;
}

const leaseDurationMs = 120_000;
const processorVersion = 'jpeg-v1';
const fingerprint = /^[a-f0-9]{64}$/;
const sha256 = (bytes: Buffer): string => createHash('sha256').update(bytes).digest('hex');
const unavailable = (): HttpsError => new HttpsError('unavailable', 'Photo storage is temporarily unavailable. Please try again.');
const invalidStorage = (): HttpsError => new HttpsError('failed-precondition', 'The private photo needs an administrator check.');

async function transact<T>(db: Firestore, callback: (transaction: Transaction) => Promise<T>): Promise<T> {
  try { return await db.runTransaction(callback); }
  catch (error) { if (error instanceof HttpsError) throw error; throw unavailable(); }
}

function ownedIncident(snapshot: DocumentSnapshot, uid: string, path: string): DocumentData {
  const incident = snapshot.data();
  if (!incident || incident.reporterUid !== uid) {
    throw new HttpsError('permission-denied', 'The incident does not belong to this reporter.');
  }
  if (incident.moderationStatus === 'withdrawn') {
    throw new HttpsError('failed-precondition', 'Withdrawn reports cannot receive a photo.');
  }
  if (!Array.isArray(incident.photoReferences) || !incident.photoReferences.includes(path)) {
    throw new HttpsError('failed-precondition', 'No photo slot is reserved.');
  }
  if ((incident.photoFingerprint !== undefined && !fingerprint.test(incident.photoFingerprint)) ||
      (incident.photoStored === true && !incident.photoFingerprint) ||
      (incident.photoProcessorVersion !== undefined && incident.photoProcessorVersion !== processorVersion)) {
    throw invalidStorage();
  }
  return incident;
}

function activeLease(incident: DocumentData, nowMs: number): boolean {
  const lease = incident.photoLease;
  if (lease == null) return false;
  if (typeof lease.id !== 'string' || !lease.id || !fingerprint.test(lease.inputFingerprint) ||
      !(lease.expiresAt instanceof Timestamp)) throw invalidStorage();
  return lease.expiresAt.toMillis() > nowMs;
}

function requireLease(incident: DocumentData, leaseId: string, nowMs: number): void {
  if (!activeLease(incident, nowMs) || incident.photoLease.id !== leaseId) throw unavailable();
}

function verifyMetadata(metadata: PrivatePhotoMetadata | null, hash: string): void {
  if (!metadata || metadata.photoSha256 !== hash || metadata.downloadTokens) throw invalidStorage();
}

/** Immutable canonical slot; byte-identical retries bypass Sharp, never ownership or admission. */
export async function uploadPrivatePhoto(
  input: {uid: string; incidentId: string; bytes: Buffer},
  dependencies: PhotoUploadDependencies,
): Promise<{photoStored: true}> {
  const {uid, incidentId, bytes} = input;
  const {db, storage, nowMs} = dependencies;
  const path = `incidentPhotos/${incidentId}/photo.jpg`;
  const incidentRef = db.doc(`incidents/${incidentId}`);
  const inputHash = sha256(bytes);
  const leaseId = dependencies.newLeaseId();
  let leased = false;
  try {
    const admission = await transact(db, async transaction => {
      const incident = ownedIncident(await transaction.get(incidentRef), uid, path);
      const now = nowMs();
      const fast = incident.photoStored === true && incident.photoInputFingerprint === inputHash;
      const busy = activeLease(incident, now);
      const decode = !fast && !busy;
      const buckets = admissionBuckets('photoRequest', uid, incidentId, now);
      if (decode) buckets.push(...admissionBuckets('photoDecode', uid, incidentId, now));
      // One union call: all state/counter reads finish before any queued write.
      await consumeAdmission(transaction, db, buckets, now);
      if (fast) return {kind: 'stored' as const, hash: incident.photoFingerprint as string};
      // Return then throw outside the transaction, retaining request accounting.
      if (busy) return {kind: 'busy' as const};
      transaction.update(incidentRef, {photoLease: {
        id: leaseId, inputFingerprint: inputHash, expiresAt: Timestamp.fromMillis(now + leaseDurationMs),
      }});
      return {kind: 'decode' as const};
    });
    if (admission.kind === 'busy') throw unavailable();
    if (admission.kind === 'stored') {
      verifyMetadata(await storage.readMetadata(path), admission.hash);
      // Metadata I/O can overlap withdrawal or administrative state changes.
      // Recheck at the response boundary without decoding or charging again.
      await transact(db, async transaction => {
        const incident = ownedIncident(await transaction.get(incidentRef), uid, path);
        if (incident.photoStored !== true || incident.photoFingerprint !== admission.hash) throw invalidStorage();
      });
      return {photoStored: true};
    }
    leased = true;
    const processed = await dependencies.processJpeg(bytes);
    const hash = sha256(processed);
    const wasStored = await transact(db, async transaction => {
      const incident = ownedIncident(await transaction.get(incidentRef), uid, path);
      requireLease(incident, leaseId, nowMs());
      if (incident.photoFingerprint && incident.photoFingerprint !== hash) {
        throw new HttpsError('already-exists', 'A different photo is already reserved for this report.');
      }
      transaction.update(incidentRef, {photoFingerprint: hash});
      return incident.photoStored === true;
    });
    const metadata = await storage.readMetadata(path);
    if (metadata) {
      verifyMetadata(metadata, hash);
    } else {
      if (wasStored) throw invalidStorage();
      // Recheck just before GCS; a withdrawal in the cross-service gap may leave
      // a private object, but finalization can never reactivate the incident.
      await transact(db, async transaction => {
        const incident = ownedIncident(await transaction.get(incidentRef), uid, path);
        requireLease(incident, leaseId, nowMs());
        if (incident.photoFingerprint !== hash) throw invalidStorage();
      });
      try { await storage.saveIfAbsent(path, processed, hash); }
      catch (error) {
        if ((error as {code?: number}).code !== 412) throw error;
        verifyMetadata(await storage.readMetadata(path), hash);
      }
    }
    await transact(db, async transaction => {
      const incident = ownedIncident(await transaction.get(incidentRef), uid, path);
      requireLease(incident, leaseId, nowMs());
      if (incident.photoFingerprint !== hash) throw invalidStorage();
      transaction.update(incidentRef, {photoStored: true, photoInputFingerprint: inputHash,
        photoProcessorVersion: processorVersion, photoLease: FieldValue.delete()});
    });
    return {photoStored: true};
  } catch (error) {
    if (leased) {
      // Never clear another worker's lease or the immutable reservation. A failed
      // cleanup leaves a bounded lease that can be recovered after expiration.
      try {
        await transact(db, async transaction => {
          const snapshot = await transaction.get(incidentRef);
          if (snapshot.data()?.photoLease?.id === leaseId) {
            transaction.update(incidentRef, {photoLease: FieldValue.delete()});
          }
        });
      } catch (_) { /* Preserve the original failure; expiry remains the fallback. */ }
    }
    if (error instanceof HttpsError) throw error;
    throw unavailable();
  }
}
