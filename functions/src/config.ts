export const FUNCTIONS_REGION = 'africa-south1';
export const PUBLICATION_DELAY_MS = 604_800_000;
export const PUBLIC_OFFSET_MINIMUM_METRES = 100;
export const PUBLIC_OFFSET_MAXIMUM_METRES = 250;

// Pilot admission allowances: fixed UTC minute/day windows. Capacity settings
// and endpoint integration are separate from these request/work counters.
export const ADMISSION_LIMITS = {
  submit: {uid: [6, 30], global: [30, 300]},
  listOwn: {uid: [6, 60], global: [30, 600]},
  withdraw: {uid: [12, 120], global: [60, 1200]},
  photoRequest: {uid: [12, 120], incident: [6, 30], global: [60, 1200]},
  photoDecode: {uid: [6, 30], incident: [3, 10], global: [20, 300]},
  moderate: {uid: [30, 500], global: [60, 1000]},
} as const;

// Capacity limits reduce simultaneous work; admission remains the request quota.
export const CALLABLE_RUNTIME = {
  submit: {minInstances: 0, maxInstances: 2, concurrency: 10, timeoutSeconds: 30},
  listOwn: {minInstances: 0, maxInstances: 2, concurrency: 10, timeoutSeconds: 30},
  withdraw: {minInstances: 0, maxInstances: 2, concurrency: 10, timeoutSeconds: 30},
  photo: {minInstances: 0, maxInstances: 2, concurrency: 2, timeoutSeconds: 60, memory: '256MiB'},
  moderate: {minInstances: 0, maxInstances: 2, concurrency: 5, timeoutSeconds: 30},
} as const;
