import {createHash} from 'node:crypto';
import {Firestore, Timestamp, Transaction} from 'firebase-admin/firestore';
import {HttpsError} from 'firebase-functions/v2/https';

import {ADMISSION_LIMITS} from './config';

export type AdmissionOperation = keyof typeof ADMISSION_LIMITS;
export interface AdmissionBucket {
  key: string;
  scope: 'uid' | 'incident' | 'global';
  window: 'minute' | 'day';
  limit: number;
  windowStartMs: number;
  windowEndMs: number;
}

const windows = [['minute', 60_000], ['day', 86_400_000]] as const;
const counterRetentionMs = 48 * 60 * 60 * 1000;

function unavailable(): HttpsError {
  return new HttpsError('unavailable', 'Report service is temporarily unavailable. Please try again.');
}

/** Stable keys reset in place; identities and payloads are not stored. */
export function admissionBuckets(
  operation: AdmissionOperation,
  uid: string,
  incidentId: string | undefined,
  nowMs: number,
): AdmissionBucket[] {
  if (!Number.isSafeInteger(nowMs) || nowMs < 0 || !uid || !ADMISSION_LIMITS[operation]) throw unavailable();
  const policy = ADMISSION_LIMITS[operation];
  const buckets: AdmissionBucket[] = [];
  for (const [scope, limits] of Object.entries(policy)) {
    const actor = scope === 'uid' ? uid : scope === 'incident' ? incidentId : '';
    if (scope === 'incident' && !actor) throw unavailable();
    windows.forEach(([window, duration], index) => {
      const windowStartMs = Math.floor(nowMs / duration) * duration;
      buckets.push({
        key: createHash('sha256').update(JSON.stringify([operation, scope, actor, window])).digest('hex'),
        scope: scope as AdmissionBucket['scope'],
        window,
        limit: limits[index],
        windowStartMs,
        windowEndMs: windowStartMs + duration,
      });
    });
  }
  return buckets;
}

/**
 * Call once with the union of all applicable operation buckets. Finish other
 * transaction reads first; append incident/lease writes only after this returns.
 * SDK transaction retries reread counts, so no allowance is consumed twice.
 */
export async function consumeAdmission(
  transaction: Transaction,
  db: Firestore,
  buckets: AdmissionBucket[],
  nowMs: number,
): Promise<void> {
  try {
    if (!Number.isSafeInteger(nowMs) || nowMs < 0 || buckets.length === 0) throw unavailable();
    const unique = new Map<string, AdmissionBucket>();
    for (const bucket of buckets) {
      if (!/^[a-f0-9]{64}$/.test(bucket.key) || !Number.isSafeInteger(bucket.limit) || bucket.limit <= 0 ||
          !Number.isSafeInteger(bucket.windowStartMs) || !Number.isSafeInteger(bucket.windowEndMs) ||
          nowMs < bucket.windowStartMs || nowMs >= bucket.windowEndMs) throw unavailable();
      const prior = unique.get(bucket.key);
      if (prior && (prior.limit !== bucket.limit || prior.windowStartMs !== bucket.windowStartMs ||
          prior.windowEndMs !== bucket.windowEndMs)) throw unavailable();
      unique.set(bucket.key, bucket);
    }
    const distinct = [...unique.values()];
    const refs = distinct.map(bucket => db.collection('_abuseCounters').doc(bucket.key));
    const snapshots = await transaction.getAll(...refs);
    const nextCounts = snapshots.map((snapshot, index) => {
      if (!snapshot.exists) return 1;
      const data = snapshot.data()!;
      if (!Number.isSafeInteger(data.count) || data.count < 0 || !(data.windowEnd instanceof Timestamp)) throw unavailable();
      const end = data.windowEnd.toMillis();
      if (end <= nowMs) return 1;
      if (end !== distinct[index].windowEndMs) throw unavailable();
      return data.count + 1;
    });
    const exhausted = distinct.filter((bucket, index) => nextCounts[index] > bucket.limit);
    if (exhausted.length > 0) {
      const retryAfterSeconds = Math.min(86_400, Math.max(1,
        ...exhausted.map(bucket => Math.ceil((bucket.windowEndMs - nowMs) / 1000))));
      throw new HttpsError('resource-exhausted', 'Please wait before trying again.', {retryAfterSeconds});
    }
    // No writes are queued until every read and every admission decision passes.
    distinct.forEach((bucket, index) => transaction.set(refs[index], {
      count: nextCounts[index],
      windowEnd: Timestamp.fromMillis(bucket.windowEndMs),
      expiresAt: Timestamp.fromMillis(bucket.windowEndMs + counterRetentionMs),
    }));
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    throw unavailable();
  }
}
