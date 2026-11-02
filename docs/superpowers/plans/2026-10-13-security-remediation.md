# Security remediation implementation plan

> **For agentic workers:** Use `superpowers:executing-plans` to implement this plan task by task after approval. The owner's routing overrides the skill's generic delegation recommendation: GPT-6.1 Sol, medium reasoning, owns the complete local implementation directly. Independent read-only review is required before a security release.

**Goal:** Reduce repeat-upload and service-abuse exposure, make the wildlife publication choice explicit, harden browser responses, and close the audit's verification gaps while retaining fast resident reporting.

**Architecture:** Keep Flutter/Riverpod repositories and the Firebase callable trust boundary. Add small, server-owned admission and photo-state modules, retain immutable private photo storage and stable public projections, and stage Hosting policy changes against the actual release build.

**Tech stack:** Flutter Web/PWA, Riverpod, go_router, Firebase Auth/App Check/Firestore/Storage, Node 22 TypeScript Functions, Sharp, Firebase Hosting.

**Spec:** This document contains the proposed security design and executable task breakdown. Read it with [project context](../../PROJECT_CONTEXT.md), [MVP scope](../../MVP_SCOPE.md), [decisions](../../DECISIONS.md), [phone testing](../../PHONE_TESTING.md), and root `AGENTS.md`.

**Status and authorship:** Original plan authored by GPT-6 Astra with medium reasoning on 2026-10-13. Proposed, not approved for execution. Numeric limits and the proposed map policy below are recommendations, not previously approved product decisions. The owner's deferral of the shared privacy terms/policy is already settled.

## Global constraints

- Preserve all unrelated dirty/untracked work and ignored real Firebase configuration. Reconcile the working tree before implementation; never reset it to a historical audit snapshot.
- Only local plan documents are authorized by this planning request. Implementation, release configuration, data migration and publication are not authorized by this document.
- Root retains all deployment, production-write, callable, external configuration, rollback, Git commit and push authority. Each external action needs applicable explicit authorization; no generic deploy or automatic rollback.
- Keep exact coordinates, reporter UID, notes, private photos, bearings and exact timestamps out of public responses. No download tokens, signed photo URLs or persistent private-data cache.
- Preserve metadata stripping, input bounds, reserved immutable photo slots, withdrawal semantics, fail-closed Firebase bootstrap, synthetic demo separation and `africa-south1`.
- Support Android browsers and iPhone Safari. Desktop emulation is not physical-iPhone evidence. Keep API compatibility with deployed clients wherever possible.
- No invasive analytics, fingerprinting, speculative multi-tenancy, second-app implementation or new compulsory interim privacy notice.
- Append approved architectural decisions to `docs/DECISIONS.md` during implementation; keep unapproved decisions here until then. Do not commit or publish merely to finish a task.

## Evidence and priorities

The 2026-10-13 audit found Important resource-abuse exposure in image processing and service admission, an owner decision about wildlife precision, and Medium missing browser headers. It did not demonstrate public access to exact records/photos or an exploitable dependency vulnerability. This was a bounded audit, not a penetration test or live abuse exercise.

Local evidence: `.local/security-audit-20261013/readback.json`, `emulator.log`, `flutter-tests.log`. Active Firestore/Storage rules match local; both services enforce App Check; bucket IAM is not public. Four Functions' compiled files/dependencies match; the older submit bundle differs overall, but its own handler matches. Hosting index/main/worker match `build/goodspotting-links-release`. Fresh checks reported 87 emulator assertions (35 rules, 52 callable), 12 backend tests and 25 targeted Flutter tests. These are baseline evidence, not tests of this proposed work.

The live upload/moderation readback reports `maxInstances=20`; submit/list/withdraw did not return an explicit maximum in the inspected field. Do not describe those as infinitely scalable. Admin MFA and billing alerts remain unverified. Physical iPhone compatibility is not established.

| Order | Deliverable | Dependency and gate |
|---|---|---|
| 1 | Admission primitives and safe photo retry state | Tasks 1–3; highest priority, review together |
| 2 | Callable quotas, bounded public reads and explicit runtime limits | Tasks 4–5; compatible initial public-map protection |
| 3 | Wildlife publication choice and optional implementation | Task 6; owner selects proposed policy before changing behavior |
| 4 | Hosting headers, observed CSP then enforcement | Tasks 7–8; separately authorized release stages |
| 5 | Dependencies, App Check assertions and access/operations checks | Tasks 9–10; can be reviewed independently |
| Later | Shared terms/privacy policy covering both apps | Task 11; triggered by second-app completion and website launch |

## Review focus

1. Two different JPEG byte streams produce the same normalized image: preserve the existing equality contract without an unlimited Sharp path (Tasks 2–3).
2. A save succeeds but the process dies, a lease expires, or withdrawal wins the race: recover only the same photo and never reactivate the report (Task 3).
3. Anonymous identities churn or residents share a mobile network: cap aggregate expensive work without treating an IP as a person (Tasks 1, 4–5).
4. An old client, cached public point or old privacy version survives release: explain compatibility and irreversible disclosure, never silently regenerate points (Tasks 5–6).
5. CSP appears correct on desktop but blocks Safari authentication, WASM, GPS or camera: require per-flow real-device evidence before broad enforcement (Tasks 7–8).

## 1. Repeat photo processing: immutable slot with bounded comparison

**Risk:** `uploadIncidentPhoto` currently executes `processPrivateJpeg` before looking at `photoFingerprint/photoStored`. One owned report permits repeated costly decoding, including images that will ultimately be rejected. The current fingerprint hashes the server-normalized JPEG, not the incoming bytes. A naive early `photoStored` success would incorrectly accept replacement images; rejecting every different incoming hash would also change the current normalized-equality contract.

**Recommendation:** Preserve normalized equality. Add a SHA-256 of the bounded incoming bytes for the common byte-identical fast path, serialize processing per slot, and charge all necessary decodes against incident/UID/global processing budgets before Sharp. A byte-different request must still normalize and compare under those limits. This is bounded comparison, not a claim that all different photos can be rejected without decoding.

The Flutter controller already retains `_committedPhoto` in memory and `retryPhoto()` resends those bytes without resubmitting the incident. Keep that behavior and the `{incidentId,jpegBase64}` request / `{photoStored:true}` success shape. No client-supplied hash is trusted and no private bytes are persisted in a browser cache.

### Task 1: Server admission primitives

**Files:** Create `functions/src/admission.ts`, `functions/test/admission.test.js`; modify `functions/src/config.ts`, `functions/test/emulator-callable.cjs`, `firestore.rules` only to make private counter denial explicit.

**Interfaces:** Export `type AdmissionOperation = 'submit' | 'listOwn' | 'withdraw' | 'photoRequest' | 'photoDecode' | 'moderate'`; `admissionBuckets(operation: AdmissionOperation, uid: string, incidentId: string | undefined, nowMs: number): AdmissionBucket[]`; `consumeAdmission(transaction: Transaction, db: Firestore, buckets: AdmissionBucket[], nowMs: number): Promise<void>`. `AdmissionBucket` contains opaque document key, integer limit, window start/end and counter scope. Use server time, never request timestamps. Callers first finish every incident/state read and collect the union of applicable buckets, including both `photoRequest` and `photoDecode` for a decoding request. Call `consumeAdmission` exactly once per transaction: it reads all distinct bucket documents, computes every decision, and only then queues writes. Never call it again to add a second operation after writes; no transaction read may follow a write. The caller may append incident/lease writes after admission succeeds.

- [ ] Write failing unit tests for first/last permitted admission, exact window rollover, malformed counter rejection, deterministic keys and concurrent transaction retries. Assert denial performs no expensive operation and no partial counter increments. A transaction spy must reject reads after any write, including a combined photo-request/decode admission, and verify duplicate bucket keys are charged only once.
- [ ] Run `npm test` in `functions`; confirm the new tests fail for missing behavior, not a harness error.
- [ ] Implement fixed UTC minute/day windows and a transactional all-or-nothing increment. Read the current clock on each transaction attempt; never reset a counter backwards when an older request resumes across a window boundary. Throw `resource-exhausted` with a generic message and bounded `retryAfterSeconds` detail; do not reveal global traffic or foreign incident existence. If counter storage fails, fail closed with `unavailable`.
- [ ] Use private `_abuseCounters/{opaqueKey}` documents with `count`, `windowEnd`, `expiresAt` (window end + 48 hours). Prefer a fixed document per scope/window class whose state resets, so storage per active UID/incident is bounded; verify window identity before counting. Do not retain request bodies, IPs, coordinates or image hashes in these documents. Server-owned incident photo state contains its own hashes.
- [ ] Add emulator tests for UID isolation, a shared global ceiling across different UIDs, simultaneous last-slot requests and denied client reads/writes. Run unit and emulator suites; preserve the existing `_submissionThrottle` during compatibility rollout.

Counter cleanup is operational follow-up: expiry fields alone do not delete documents. A Firestore TTL policy would require separately authorized root configuration and has asynchronous deletion/cost implications. Initial counters must work correctly without TTL. Review service cost of the limiter itself: denied calls still consume invocation and counter-read resources.

### Task 2: Photo admission and byte-identical fast path

**Files:** Create `functions/src/photo_upload.ts`, `functions/test/photo_upload.test.js`; modify `functions/src/index.ts`, `functions/src/photo.ts`, `functions/test/emulator-callable.cjs`; extend `test/report/report_controller_test.dart` only for retry compatibility.

**Interfaces:** Export `uploadPrivatePhoto(input: {uid: string; incidentId: string; bytes: Buffer}, dependencies: PhotoUploadDependencies): Promise<{photoStored: true}>`. Dependencies expose Firestore, a storage adapter, `processJpeg(bytes): Promise<Buffer>`, `nowMs(): number`, and `newLeaseId(): string`. Storage adapter offers `readMetadata(path)`, `saveIfAbsent(path, bytes, canonicalHash)` with generation-zero precondition. Use injected adapters for deterministic failure schedules; no production debug endpoint.

Proposed private fields: retain `photoFingerprint` as normalized SHA-256 and `photoStored`; add `photoInputFingerprint` only after successful equivalence, `photoProcessorVersion: 'jpeg-v1'`, and `photoLease: {id,inputFingerprint,expiresAt}`. The lease is temporary; the normalized fingerprint remains the immutable slot identity. Keep hashes private, never log or return them. Preserve the existing normalization settings (8,000,000 pixels; longest edge 1600; JPEG 82; decoded size at most 2 MiB).

- [ ] Add failing `sameInputSkipsSharp`, `differentInputNeverGetsUnconditionalSuccess`, `equivalentReencodingRemainsValid` and `legacyNormalizedHashStillWorks` tests. Count processor invocations, not elapsed time.
- [ ] Implement order: authenticate/App Check → bounded `photoInput` parsing → ownership/withdrawal/slot checks → incoming SHA-256 → transactional state decision and combined admission. In that transaction, read incident state first, decide whether the request needs decode, and pass the corresponding union of request/decode buckets to Task 1 once. The stored fast path consumes request admission only; the decode path consumes both atomically. Foreign/missing records must share the existing permission error before incident-specific rate details.
- [ ] If stored and incoming hash matches the recorded accepted input hash, check private object metadata matches the normalized fingerprint, then return success without Sharp. Missing/mismatched metadata is `failed-precondition` for operator investigation; do not silently recreate an object deleted administratively.
- [ ] Otherwise obtain one incident lease and consume the combined request/decode admission in the same transaction before invoking Sharp. An active lease consumes request admission only and returns a transaction outcome that becomes retryable `unavailable` after commit; throwing inside that transaction would wrongly roll back request accounting. It never grants success or permanently binds a different candidate. Use `timeoutSeconds:60`, lease length 120 seconds and a random server lease ID. Enforce lease ownership on subsequent transaction updates.
- [ ] After successful decode, atomically reserve the normalized hash if absent; otherwise require equality. Only then save or reconcile storage. Invalid JPEG frees only the caller's lease and never reserves the slot; a different normalized hash yields `already-exists` and cannot alter either stored or reserved identity. Decode attempts remain charged even on failure.
- [ ] Save accepted input hash only after equivalence is proved; a different equivalent encoding may replace this one-entry fast-path hash. Do not accumulate an unbounded list of input hashes. A caller alternating encodings uses the bounded decode path.
- [ ] Run Node tests and focused Flutter controller tests. Assert photo retry sends identical bytes and incident ID, never calls submit again, and throttling preserves the saved core report with a recoverable optional-photo failure.

Legacy records lacking `photoInputFingerprint` get one quota-controlled normalization, compare against their existing canonical fingerprint, verify storage, then gain the fast path. Never infer equivalence from `photoStored` alone. Keep normalization behavior pinned through this release; a future Sharp/normalization change must test old canonical hashes and plan version compatibility rather than silently permitting replacement.

### Task 3: Crash, lease, concurrency and withdrawal proof

**Files:** Extend `functions/src/photo_upload.ts`, `functions/test/photo_upload.test.js`, `functions/test/emulator-callable.cjs`; modify `functions/src/index.ts` withdrawal integration only if needed to clear leases safely.

**State rules:** Empty slot → leased candidate → immutable normalized reservation → private object saved → stored flag. A lease can expire; a normalized reservation cannot be overwritten or cleared to accept a different photo. Same normalized bytes can resume after expiry. A stale worker may not finalize another lease's state. Storage precondition and canonical metadata remain independent safety barriers.

- [ ] Write deterministic red tests for failure before decode, after decode but before reservation, after reservation but before save, after save but before finalization, and after successful finalization before response.
- [ ] Implement recovery: after matching canonical reservation, inspect object metadata first; if matching, finalize without another save; if absent and `photoStored` is false, save with `ifGenerationMatch:0`; if a 412 occurs, require matching `photoSha256`. Different/missing hash metadata fails closed. Other storage errors return `unavailable` and retain the immutable reservation.
- [ ] Make finalization transactional: reread ownership/status/reservation/lease; set stored/input/version only for this lease and fingerprint. Recheck withdrawal before save and at finalization. If withdrawal wins during the unavoidable cross-service gap, the object may remain private, but return `failed-precondition`, never change moderation/public state and never claim withdrawal deleted the photo.
- [ ] Test two same inputs (one decode while lease is live; loser retries safely), different images (one immutable winner), equivalent different encodings, expired-lease recovery, stale-worker save/finalization, malformed JPEG then valid retry, and withdrawal at every seam.
- [ ] Assert no EXIF/GPS, download token, signed URL, public object permission or additional storage path; assert tampered metadata cannot be trusted. Test generation-precondition behavior with the injected adapter because the Storage emulator does not faithfully model every GCS precondition.
- [ ] Run all backend/emulator tests. Reviewer must trace each state transition and classify Critical/Important/Minor findings before release preparation. A live crash/abuse test is not authorized or necessary for this gate.

## 2. Abuse and cost exposure: pilot admission with measured limits

**Risk:** A five-second UID cooldown is bypassable by creating anonymous identities. `listOwnIncidents` can read 501 documents on every call. Public map clients read Firestore directly, outside every callable throttle. App Check raises the bar but does not prove unique humans or stop all valid-client abuse. Ordinary App Check tokens are reusable; replay protection requires separate limited-use-token consumption/client support and adds latency. Do not enable it casually or describe normal enforcement as one-use authorization ([Firebase App Check documentation](https://firebase.google.com/docs/app-check/cloud-functions)).

**Recommendation:** Add conservative per-UID and aggregate admission before expensive work, explicit Functions capacity limits, bounded public queries, useful aggregate operational signals and owner-controlled spending response. Keep IP collection out of the initial design. Shared mobile/carrier IPs are poor identity boundaries. This reduces expensive admitted work; it cannot guarantee a total spend ceiling.

### Task 4: Callable budgets and runtime capacity

**Files:** Modify `functions/src/config.ts`, `functions/src/index.ts`, `functions/src/admission.ts`, `functions/test/admission.test.js`, `functions/test/region.test.js`, `functions/test/emulator-callable.cjs`; optionally improve typed retry messages in `lib/features/report/data/incident_repository.dart`, `photo_storage.dart`, `owner_incident_repository.dart` with their existing tests.

**Proposed defaults:** Every applicable row must pass. UTC fixed windows permit boundary bursts; explicitly test and document up to twice the window limit across a boundary. These values are a pilot starting point, subject to owner acceptance and legitimate-usage evidence.

| Operation | Per UID | Per incident | Shared across UIDs | Runtime: max instances / concurrency / timeout |
|---|---|---|---|---|
| New submit | 5-second existing cooldown; 6/min, 30/day | Existing request fingerprint is immutable | 30/min, 300/day new incidents | 2 / 10 / 30s |
| listOwn | 6/min, 60/day | — | 30/min, 600/day queries | 2 / 10 / 30s |
| Photo request (all owned-slot attempts) | 12/min, 120/day | 6/min, 30/day | 60/min, 1,200/day | 2 / 2 / 60s; 256 MiB |
| Photo decode (subset of photo requests) | 6/min, 30/day | 3/min, 10/day | 20/min, 300/day decodes | Same upload runtime |
| Withdrawal | 12/min, 120/day | — | 60/min, 1,200/day | 2 / 10 / 30s |
| Moderation after role check | 30/min, 500/day | — | 60/min, 1,000/day | 2 / 5 / 30s |

At the proposed ceilings, owner listing can cause at most 600 × 501 = 300,600 returned document reads/day before limiter overhead/retries, and decoding permits 300 operations/day. These are workload bounds, not currency estimates or total read limits. Two upload instances at concurrency two limit simultaneous scheduled decode work to roughly four requests under normal platform operation; memory behavior still needs a bounded local test with four maximum-size synthetic images. Maximum instances constrain capacity, not request counts, and platform behavior is not a billing hard cap ([Functions runtime controls](https://firebase.google.com/docs/functions/manage-functions)).

- [ ] Write red tests for exact per-operation boundaries, 31st UID-churn submission in one minute, independent withdrawal capacity while submit is exhausted, query not issued after list denial, and decode budget charged before Sharp.
- [ ] Integrate admission transactionally with new submission creation; same request ID/payload returns its existing incident without consuming a new-submission allowance. Retain payload mismatch rejection. Retries still incur lightweight reads/invocations; do not promise zero cost. For list and moderation, consume admission before query/write work; permit idempotent withdrawal outcome while retaining an invocation budget.
- [ ] Keep the 500 receipt result / 501 query contract initially. Avoid silently reducing it and hiding previously accessible withdrawals. Add memory-only request coalescing if useful, invalidate on withdrawal/Auth change, and do not cache exact incident data. Rate feedback must not loop or resubmit the core report automatically.
- [ ] Configure explicit `minInstances:0` and the table's limits in source for all five callables; validate memory/CPU/concurrency options against the installed SDK. Do not assume a missing live maximum means no limit. Add endpoint-option tests and repeat a bounded local concurrency test, with no production load traffic.
- [ ] Log only operation, outcome category and latency bucket where existing logging can support this; do not add IP, UID, request payload or image identifiers. Use provider aggregate invocation/error/latency/billing metrics first. Run backend/emulator and affected Flutter tests.

Global ceilings can be deliberately exhausted to deny service. Preserve separate withdrawal capacity and show a temporary-unavailable message. Before expanding the pilot, review seven days of legitimate aggregate usage and rejection counts; propose a limit increase only after a cost model and owner acceptance. Never automatically raise caps on attack-driven traffic.

### Task 5: Public reads and operational response

**Files:** Modify `firestore.rules`, `functions/test/emulator-rules.cjs`, `lib/features/map/data/public_incident_repository.dart`, `lib/features/map/presentation/public_map_screen.dart`; create `test/domain/public_repository_test.dart`, `docs/SECURITY_OPERATIONS.md` during approved implementation.

**Initial compatible deliverable:** Keep the public Firestore collection and current 500 result bound. Change public rules to explicit `allow get: if true; allow list: if request.query.limit != null && request.query.limit <= 500; allow write: if false`. Verify this against the exact installed rules emulator. It caps query size, not requests; an App-Check-valid client can still repeat bounded lists and gets. Do not present this as full public-read abuse protection ([Firestore query rules](https://firebase.google.com/docs/firestore/security/rules-query)).

- [ ] Add red rules tests for no limit, 501 and 500 limits, allowed single public get, denied exact collections and counter access. Confirm the existing deployed query remains compatible.
- [ ] Implement the rule bound and coalesce public repository requests with a 60-second in-memory cache of public projections only. Type/date filtering should reuse that fetched page; show refresh/error states without tight retries. Keep the UI's 500-record limitation truthful. Browser cache is a usability optimization, not a security control.
- [ ] Test repeat filter/refresh operations, cache expiry, empty/error outcomes and a withdrawal disappearing after explicit fresh fetch. Do not promise removal from copies already downloaded. Run rules and relevant Flutter tests.
- [ ] Document an escalation trigger: provider-reported **total Firestore document reads** above 50,000/day for two days, unusual total-read bursts above five times the recent baseline, or the owner's cost alert merits review. Use the database's existing aggregate read metric and record its scope/time window; it may include admin, owner, counter and public traffic and must not be labeled a precise public-collection metric. Investigate with existing aggregate operation metrics and scoped evidence before attributing traffic; do not add a telemetry project. This is a conservative investigation trigger, not proof of attack or an automatic shutdown.
- [ ] Prepare a separate optional gateway change if direct-read risk is unacceptable: add `listPublicIncidents` callable with App Check, explicit allowlist serialization, a server 500-record bound, 60/min and 1,000/day aggregate cache-miss admission, 60-second process cache, `maxInstances:2`, concurrency 10. Require no anonymous account just to browse. All requests still incur invocation costs; process caches are not shared or a security ceiling.
- [ ] For that optional change, first deploy the endpoint, then a repository using it, then separately authorize denying direct public Firestore reads. Test bypass via SDK/REST against the new rules and two instances sharing cache-miss counters. Old cached clients will lose their direct map query after closure: explicitly approve the compatibility window and provide update/reload messaging. Keeping direct reads open leaves the bypass. No gateway rollout is part of the initial compatible task unless selected.

**Operations proposal:** Verify current billing account currency, alerts, recipients and service usage read-only. Propose a project-scoped monthly alert budget equivalent to ZAR 300, with 50/80/100% actual and 100% forecast alerts, then obtain owner acceptance of amount/currency/recipients before root configuration. If already configured, compare instead of duplicating. Budgets are alerts, not spending caps; notification delay exists ([Cloud Billing budgets](https://cloud.google.com/billing/docs/how-to/budgets)). No automatic billing disablement: it could impair withdrawal and all apps sharing the project.

If abuse persists after these controls, assess coarse network admission as a separate privacy decision. Only use a trusted platform-derived address after verifying proxy semantics; never trust arbitrary forwarded headers. A rotating keyed HMAC with at most 24-hour retention and loose network limits may reduce churn, but still risks carrier-NAT false positives and entails new personal-data handling. No raw-IP store, cross-app fingerprinting or Cloud Armor drop-in assumption. An edge/gateway redesign needs its own cost and compatibility plan.

## 3. Wildlife publication: choose useful precision consciously

**Current behavior:** Accepted points reveal exact incident type, a calendar date, and stable cryptographic displacement of 20–50 m. Pending reports are private. There is no automatic minimum publication delay. Stable projection reuse prevents averaging repeated moderation of one report, but independently jittered repeated reports can narrow the same sensitive area. Jitter alone cannot promise wildlife anonymity, especially when roads/habitat constrain plausible locations.

| Option | Benefit | Cost and remaining risk |
|---|---|---|
| Keep 20–50 m and manual acceptance | Best street-level community relevance; least code | Current inference risk remains; moderation timing is not a guaranteed delay |
| **Proposed pilot choice:** 100–250 m for newly projected reports; acceptance only after 7 days from server creation | Less immediate/precise targeting, small architecture change | Markers may be off-road; repeated observations still localize; historical dates/type remain visible |
| 500 m cells, calendar-week counts, suppress counts below 3 | Avoids public individual locations and improves privacy for sparse data | Loses event-level map utility; count differencing and adjacent periods still need review; separate aggregate model needed |
| No public point map; retain private analysis and broad summaries | Strongest simple reduction of location disclosure | Community feedback is less detailed |

**Owner decision:** Select whether to adopt the proposed pilot choice or retain the current policy. This does not block the other security tasks. If the goal requires stronger protection than larger jitter/delay can offer, select aggregation or no points and commission that bounded design before implementation. Do not generalize this tortoise setting to the unfinished second app or assume its species/features.

### Task 6: Proposed policy implementation and existing-data plan

**Files:** Modify `functions/src/projection.ts`, `functions/src/index.ts`, `functions/src/config.ts`, `functions/test/projection.test.js`, `functions/test/emulator-callable.cjs`, `lib/features/admin/data/admin_repository.dart`, `lib/features/admin/presentation/admin_screen.dart`, `lib/features/map/presentation/public_map_screen.dart`, `test/admin/admin_screen_test.dart`; create `test/admin/admin_repository_test.dart` for typed error mapping; extend relevant public-map tests. Approved decision later goes in `docs/DECISIONS.md`.

**Interfaces:** Add `publicationEligibility(createdAt: Date, now: Date): {eligible: boolean; eligibleAt: Date}` with seven days exactly (`604800000` ms) from trusted server creation. Extend private incident state with `publicProjectionVersion: 'v1' | 'v2'`; retain the public five-field allowlist. `createPublicProjection` keeps its explicit radius parameters; production always injects `secureRandom`. Premature-acceptance callable errors carry `details: {reason:'publication-not-ready', eligibleDate:'YYYY-MM-DD'}`; withdrawn errors carry `{reason:'incident-withdrawn'}`. The admin repository maps these to distinct typed `PublicationNotReadyException(eligibleDate)` and `IncidentWithdrawnException`, validating the date shape and using a generic operation error for malformed details. Only actual authentication/permission failures become `AdminAuthorisationException`; an unknown `failed-precondition` must not revoke access.

- [ ] Write red tests: creation + seven days − 1 ms denies acceptance; exact boundary allows; spoofed past `occurredAt` cannot shorten delay; invalid/missing server creation fails closed; reject/duplicate/withdraw remain available immediately.
- [ ] Implement eligibility in the same moderation transaction, checked before generating/writing a new public projection. Reject premature acceptance with the typed `failed-precondition` details above. Keep the report pending; no scheduler or automatic delayed publishing is introduced. Correct the repository's current mapping of every `failed-precondition` to an authorization exception; show the safe eligible date as an operation message while preserving the signed-in admin view and subscription.
- [ ] Add repository/widget red tests for publication-not-ready, withdrawn, malformed/unknown precondition and genuine permission denial. Assert the first three preserve authenticated admin access, premature acceptance displays the eligible date, withdrawal displays its own message, and only actual revoked authorization drops private access. Never parse arbitrary server message text as the discriminator.
- [ ] For first-time v2 projection use cryptographic radius 100–250 m and preserve exact type/calendar date as currently defined. Label public points as approximate historical reports, not navigation or exact crossing locations. Show eligible date to authorized admins; do not expose new exact timestamps publicly.
- [ ] Test radius bounds, invalid configuration, production secure randomness, identical projection after accept→reject→accept, transaction retries, and withdrawal races. Private version metadata must never enter the public projection.
- [ ] Choose existing-data treatment explicitly before release: recommended retain each existing v1 point and stored projection unchanged, mark its private version and accurately record that old points retain 20–50 m precision. The new policy must not claim every existing point has the wider radius. Never relabel v1 coordinates as v2.
- [ ] If the owner requires removing legacy points instead, prepare a separate dry-run migration manifest (IDs/version/counts, private location data kept local) and a reviewed resumable script. Suppress their public documents and record `publicSuppressedReason:'legacy-privacy-policy'`; moderation must respect suppression so reaccept cannot recreate them. No regeneration of multiple alternative points for the same report. Do not run a production migration under implementation authority.
- [ ] Migration tests must prove already-applied records are no-ops, a concurrent withdrawal cannot be undone, only still-accepted eligible records can be public, and partial failure resumes from recorded version/suppression state. Review old source rollback: it could ignore new suppression metadata, so such rollback is prohibited without a compatibility fix and explicit root authorization.

Already viewed, exported or cached public points cannot be recalled. Removing server documents only prevents future server retrieval after clients refresh. Neither a wider radius nor a new delay retroactively protects the old disclosure. Preserve stable versions and avoid re-jittering legacy records, which adds another location sample rather than erasing the first.

## 4. Hosting headers: harden without breaking the app

**Risk:** The audit observed HSTS but lacked framing CSP, `nosniff`, referrer and permissions headers. These reduce browser attack surface; they do not replace data authorization. The primary release target is `goodspotting`, while legacy origins remain relevant to installed PWAs and anonymous ownership.

### Task 7: Route inventory and baseline headers

**Files:** Modify `firebase.json` only if it is the maintained canonical header source; inspect and update the exact approved release configuration derived from `firebase.goodspotting-links.local.json`. Create `scripts/verify_hosting_headers.mjs`, `docs/HOSTING_SECURITY.md`; inspect `web/index.html`, `web/flutter_bootstrap.js` if present, and generated release assets. Do not overwrite unrelated Hosting targets or cache settings.

**Interfaces:** Verification script accepts `--base-url` and tests `/`, representative app routes, `/index.html`, JS/WASM/SVG/worker assets and reserved auth routes; returns nonzero on a required header/value/MIME mismatch and prints no credentials. Configuration test validates header coverage locally before release.

- [ ] Inventory `goodspotting.web.app`, `goodspotting.firebaseapp.com`, `wildlife-watch-sa.web.app`, `wildlife-watch-sa.firebaseapp.com` and any configured custom domains read-only; record actual routes, redirects, authDomain, OAuth callbacks and current cache headers. Do not assume primary-site deployment updates legacy sites.
- [ ] Write failing header-configuration assertions. For app documents propose enforced `Content-Security-Policy: frame-ancestors 'none'; object-src 'none'; base-uri 'self'` plus `X-Frame-Options:DENY`; add `X-Content-Type-Options:nosniff`, `Referrer-Policy:strict-origin-when-cross-origin`, `Permissions-Policy:geolocation=(self), camera=(self), microphone=(), payment=(), usb=()`.
- [ ] Keep Firebase-managed `/__/auth/*` routes out of blanket application framing restrictions where the same-origin auth helper must be embedded. Prefer positive matching of known app document routes and assets over assuming overlapping header rules override safely. Verify actual reserved-route behavior; use a different reviewed matching strategy if the Hosting emulator cannot prove it. Top-level Google redirects must still work ([Firebase redirect guidance](https://firebase.google.com/docs/auth/web/redirect-best-practices)).
- [ ] Preserve HSTS and existing revalidation headers. Do not add HSTS preload/includeSubDomains, COOP or COEP as incidental changes. Test camera/gallery behavior despite browser differences in Permissions Policy support; policy is not a substitute for user permission.
- [ ] Verify a hostile local iframe cannot embed an app document under enforced framing headers, while auth helpers and redirects remain usable. Report-only `frame-ancestors` does not block framing. Use the response header, not a meta tag ([CSP framing specification](https://w3c.github.io/webappsec-csp/#directive-frame-ancestors)).

### Task 8: Observe resource CSP, validate devices, then enforce

**Files:** Continue Task 7 files/configuration; extend `docs/PHONE_TESTING.md` with fresh evidence only. Do not add a remote CSP reporting endpoint or analytics without a separate scope decision.

- [ ] Capture a sanitized network/resource inventory from the exact configured release build across cold start, warm/PWA start, map tiles, Firebase initialization, Google redirect and App Check refresh. List exact hosts per directive; strip tokens/query credentials from evidence.
- [ ] Add a resource `Content-Security-Policy-Report-Only` candidate: `default-src 'self'; object-src 'none'; base-uri 'self';` then explicit `script-src`, `connect-src`, `img-src`, `style-src`, `font-src`, `worker-src`, `frame-src`, `manifest-src`. Populate from observed Firebase/reCAPTCHA Enterprise/Google/OSM and Flutter CanvasKit/WASM resources, not wildcard `https:`. Allow `data:`/`blob:` only for required resource types. Prefer self-hosted Flutter assets already in the build. Hash fixed inline bootstrap scripts where practical; test `'wasm-unsafe-eval'` before any broader eval exception.
- [ ] Exercise the candidate locally; record console violations and prove each proposed host/exception is needed. Flutter rendering may require a narrowly documented inline-style or script exception; do not silently add global `'unsafe-inline'`/`'unsafe-eval'` to make tests green. Keep baseline framing enforced separately while resource policy is report-only.
- [ ] Prepare a root-authorized report-only Hosting release to the explicitly named site(s); validate live response headers and exact asset hashes after release. Passive browser-console observation does not require a telemetry collector. Production report/photo/moderation writes still need a separate bounded smoke authorization.
- [ ] Verify Android and physical iPhone Safari: cold/warm load, CanvasKit/WASM, GPS success/denial, manual pin, camera/gallery/cancel, map/filters, Google redirect/anonymous link, App Check refresh, standalone PWA/relaunch/update, weak network, plus external main-website and SnapScan links. External top-level links are not an excuse to broaden `connect-src`; do not perform payment transactions.
- [ ] Require no unexplained blocking violations across these flows; keep iPhone marked unverified if no device evidence is available. Only then prepare a separately reviewed enforcement config and root release request. Lack of physical iPhone evidence leaves resource enforcement pending; baseline compatible headers can still be assessed separately.
- [ ] On breakage, preserve logs and prepare the smallest header relaxation or the previously verified header config for owner-approved rollback. Do not revert backend privacy rules or disable App Check to fix CSP. Read back exact headers at each origin/route; a valid JSON config alone is not proof of the deployed behavior.

## 5. Dependency and access assurance follow-ups

### Task 9: Compatible dependency review and direct App Check assertions

**Files:** Potentially modify `functions/package.json` and `functions/package-lock.json`; extend `functions/test/region.test.js`, add `functions/test/app_check.test.js`; use existing photo/emulator tests as upgrade regressions.

- [ ] Run `npm audit --omit=dev --json` and `npm explain uuid` / `npm explain gaxios` in `functions` at implementation time. Baseline: two Moderate package entries attributable to one advisory, no High/Critical; gaxios uses `uuid.v4()`, while [GHSA-w5hq-g745-h8pq](https://github.com/advisories/GHSA-w5hq-g745-h8pq) concerns buffer checks in other APIs. Record reachability; do not claim an exploit or that the entire tree is unaffected without checking it.
- [ ] Find the smallest compatible upstream parent update that removes the affected transitive version. Review Node 22/support/API/lockfile changes, run build/unit/emulator tests and compare photo canonical outputs. Avoid `npm audit fix --force` or a forced uuid major override. If no safe compatible update exists, document a time-bounded accepted residual advisory with recheck date proposed at 30 days; owner accepts any deferred remediation.
- [ ] Write an assertion over every exported callable rather than a manually maintained partial list. In fresh subprocesses, load compiled exports with `FUNCTIONS_EMULATOR` absent, `'false'` and `'true'`; assert callable App Check enforcement is true in the first two and false only in the emulator case. Check the SDK's actual callable options/metadata representation; do not rely on a source-string grep alone.
- [ ] Make the test fail for a deliberately unenforced test export. If SDK metadata cannot expose the option, extract a small tested `callableOptions` factory and assert every export uses it with a strict export/registration inventory. Keep missing-auth tests distinct; emulator bypass tests do not prove production rejection of invalid tokens.
- [ ] Run backend/emulator suites and review dependency diff. Root release readback must later confirm no emulator environment flag in production and enforcement in the released bundle; no live token/replay abuse traffic is proposed.

### Task 10: Least privilege, MFA and cost readiness

**Files:** Optional approved changes to `functions/src/index.ts`, `firestore.rules`, `storage.rules`, `lib/features/admin/data/auth_repository.dart`, `admin_repository.dart`, `presentation/admin_screen.dart`, relevant admin tests and `functions/test/emulator-rules.cjs`; checklist in `docs/SECURITY_OPERATIONS.md`.

The current `role=analyst` deliberately meets the admin predicate for moderation and Storage deletion. This is an existing broad-role policy, not evidence of an unauthorized bypass. Review it before granting analyst claims.

- [ ] Produce a read-only role matrix: anonymous/reporter, analyst, admin, service account; private reads/export, moderation, photo deletion and direct writes. Proposed least privilege: analyst reads/exports only, admin moderates/deletes, neither client role directly writes incidents/projections. Owner selects this optional change before implementation.
- [ ] If selected, add red rules/callable/UI tests for analyst read allowed and moderate/delete denied, admin allowed, forged client role denied, claim revocation dropping private subscriptions and controls. Split `canReadPrivate` and `canModerate` predicates instead of silently reusing one `isAdmin` everywhere. Review existing analyst workflows before release; do not grant/revoke any live claim under local implementation authority.
- [ ] Verify administrator sign-in method, privileged account MFA protection, recovery ownership and claim roster read-only with sensitive evidence kept local. Do not confuse MFA on an administrator's Google account with Firebase end-user MFA enrollment or claim authorization. Any account/security-setting change is separately root-authorized; no lockout experiment.
- [ ] Verify budget/alert recipients, Firebase/Google service quotas and operational contact/readiness. Record unknowns plainly. Prepare exact proposed settings, recipients and impact for owner review; do not silently create a budget, enable TTL or change billing.

## 6. Shared terms and privacy policy: explicitly deferred

### Task 11: Future shared-policy work package

**Trigger:** The second app is finished and goes live on the main website. The owner requested one shared policy covering both apps then. This is not a prerequisite for the local security improvements above, and this plan does not demand an interim policy or notice.

**Future files:** Decide the canonical website location when that website's repository/scope is supplied. Later add links from both apps' appropriate information/support surfaces. No second-app facts or implementation are assumed here.

- [ ] At the trigger, inventory each actual app separately: data collected, anonymous account identifiers, exact/approximate locations, optional notes/photos and stripped metadata, dates/times, administrators/analysis access, hosting/database region, browser storage, logs, third-party processors and transfers. Include differences explicitly in the shared document.
- [ ] Record map-tile third-party requests and what they disclose (network address and requested map area), Firebase/Google Auth/App Check processing, external website/SnapScan navigation, and whether the second app adds other services. Do not describe SnapScan payment data as collected by this app without evidence.
- [ ] Decide actual retention periods for private incidents, withdrawn incidents/photos, Auth identities, operational counters/logs and backups; design a separately approved deletion mechanism if the promises require one. Today withdrawal hides the public projection and active record but retains the exact private audit record and photo. It is not erasure.
- [ ] Establish the responsible contact, access/correction/deletion request process, limits of anonymous ownership recovery and the handling of already-public/cached copies. Review terminology/terms with an appropriate adviser if required; this plan makes no legal-compliance conclusion.
- [ ] Publish one accurate versioned shared policy with clear per-app differences, link both apps and the website, and test those links. Publication and implementation of any new retention/deletion behavior need their own authority. The current technical safeguards remain in force throughout the deferral.

## Verification, release boundaries and acceptance

Each implementation task starts with its named failing assertions, runs the focused tests to prove red, adds the smallest behavior/configuration change, then proves green. Keep synthetic fixtures and injected clocks/failure adapters; never spend production-write authority as a substitute for deterministic tests.

From the repository root, use the installed tools; adapt executable paths only, not test intent:

```powershell
dart format lib test
flutter analyze
flutter test
flutter build web --release --pwa-strategy=none
```

From `functions`: `npm test`. From root: `firebase emulators:exec --config firebase.json --only auth,functions,firestore,storage --project demo-scarborough-tortoise-watch "node functions/test/emulator-all.cjs"`. Preserve existing local emulator/session resources; do not kill unrelated processes. Configured release builds use the existing ignored Firebase entry point/defines and a new output directory, preserving `build/goodspotting-links-release` and phone previews. Do not fabricate generated options.

- [ ] Record changed files, focused red/green results, final relevant full suites, limitations and privacy invariants. Security behavior changes warrant backend/emulator verification; Flutter/header changes warrant analysis/tests/release build and the specified browser/device matrix. Do not repeatedly rerun unchanged baselines without an evidence gap.
- [ ] Obtain one independent read-only security review covering photo races/compatibility, quota transactions, public projection/version invariants, all-export App Check and Hosting/auth behavior. Root verifies evidence and coordinates bounded fixes; no unresolved Critical or Important finding goes to release.
- [ ] Prepare a release manifest with exact source/build hashes, named Functions/rules/Hosting targets, prior versions, backward compatibility and readback checks. Stop on material custody/live-state drift. Preserve root's sole authority; each production stage is a concrete separate request, not execution implied by plan approval.
- [ ] Stage compatible backend changes before dependent client changes; do not run old and new upload handlers concurrently as an intentional canary because old handlers do not honor new leases/admission. Account for old in-flight calls and a bounded drain period in a separately approved release runbook; generation-zero/canonical hash still guard the storage slot. Do not claim the new cost bound while old handlers remain active.
- [ ] Release headers report-only before resource enforcement; optionally close direct public reads only after gateway/client deployment; perform privacy migration only under separate data-write authority. Immediately read back each released configuration/hash/rule source without invoking mutation callables.
- [ ] Rollback is a prepared option requiring root approval, never automatic. Verify older code understands any new reservation/version/suppression state before proposing it. Prefer a narrow forward correction when rollback would reopen abuse or republish suppressed records.

**Complete means:** reviewed local implementation and evidence for the selected tasks, with production stages and unavailable device checks explicitly separated. It never requires a Git commit/push by default. The shared policy remains deferred as requested. Planning is complete when this document has been self-reviewed and handed back; it does not authorize starting the implementation.

## Plan self-review record

- All five audit points map to tasks: photo 1–3; abuse 4–5; wildlife privacy 6; headers 7–8; deferred shared policy 11. Dependency/App Check/access/operations follow-ups map to 9–10.
- Same-input fast path, equivalent-byte compatibility, legacy state, reservation/save crash recovery, withdrawal and concurrency all have explicit assertions; no unconditional stored-photo bypass is proposed.
- Direct Firestore reads remain explicitly outside callable quotas; the initial query-size control and optional gateway cutover are distinct. Counter cost, global-denial tradeoff and budget/instance limits are not hidden.
- Open owner choices: provisional quotas/capacity and budget amount, public wildlife policy and legacy treatment, optional gateway/analyst role split. Shared-policy deferral is settled and needs no reconfirmation.
- Only this new plan file was authored by this planning agent. No application code, approved decisions, configuration, cloud data or Git history was changed; no tests are claimed to verify unimplemented behavior.
