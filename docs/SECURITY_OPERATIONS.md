# Security operations for the Scarborough pilot

## Status and ownership

This runbook accompanies the 2026-10-13 security plan, implemented and independently reviewed locally, then deployed under separate owner approval. The November 2 context refresh reconciled saved evidence only. The original root retains deployment, configuration, billing, claim and rollback authority. Task 10's dated metadata inventory below reconciles accessible operational settings; unresolved settings remain unknown.

The initial audit is recorded in ignored `.local/security-audit-20261013/readback.json`; it preceded the new quota/public-query changes. Subsequent release readbacks under `.local/security-release-20261013/` verify the new rules, all five Functions' source/options, App Check and Hosting assets/headers. See [NEXT_SESSION.md](NEXT_SESSION.md) for the released artifact and remaining acceptance gates. Neither snapshot is a fresh November cloud inspection. Never submit reports or upload photos merely to check configuration.

## Public-map reads

The compatible public API remains Firestore `publicIncidents`: individual gets are allowed, while lists require an explicit limit at most 500. The app orders by descending calendar date and requests 500 records. Type/date filters operate on that page; they do not search every historical record. The trusted public projection allowlist remains the wildlife privacy boundary. Firestore query constraints can be enforced by [Security Rules](https://firebase.google.com/docs/firestore/security/rules-query).

The Firebase public repository coalesces overlapping ordinary loads and retains only typed public projections in memory for 60 seconds after a successful load. Filters reuse the page. Explicit refresh and successful map-marker withdrawal bypass this cache, fetch from the server, and prevent older in-flight results from restoring stale markers. A failed fresh fetch displays an error with an explicit retry; it does not silently fall back to the old page or loop requests. Demo fixtures remain synthetic. No exact incident, private photo, receipt record or new persistent browser cache is added by this feature.

These controls bound results per query and reduce ordinary app reads. They do **not** rate-limit a caller who repeats allowed Firestore queries or document gets. The in-memory cache is a client optimization, not an abuse boundary. App Check is an additional control; valid-client misuse remains possible. Previously viewed, cached or exported public points cannot be recalled, and other viewers may retain a page until refreshing or reloading. Withdrawal does not erase the retained private audit record/photo.

The optional public callable gateway from the plan is not implemented or selected for this baseline. If direct-read exposure becomes unacceptable, commission that separate change with endpoint/client rollout and an explicit compatibility decision before closing direct reads. Do not claim callable quotas protect this direct Firestore path.

## Callable workload and capacity

The local `functions/src/config.ts` is the source of truth for fixed UTC minute/day admission limits. Each applicable UID, incident and aggregate allowance must pass before admitted work; counters commit transactionally. Windows permit boundary bursts. Submission retains its five-second cooldown; same saved request/payload retries do not consume another new-report allowance. Withdrawal has its own allowance, separate from submission. Photo decoding is admitted before Sharp; byte-identical stored retries verify metadata and consume only request allowance.

| Operation | UID minute/day | Incident minute/day | Aggregate minute/day |
|---|---|---|---|
| New submission | 6 / 30 | — | 30 / 300 |
| Owner listing | 6 / 60 | — | 30 / 600 |
| Photo request | 12 / 120 | 6 / 30 | 60 / 1,200 |
| Photo decode | 6 / 30 | 3 / 10 | 20 / 300 |
| Withdrawal | 12 / 120 | — | 60 / 1,200 |
| Moderation | 30 / 500 | — | 60 / 1,000 |

Local runtime configuration uses zero minimum/two maximum instances for each callable, with request concurrency 10 for submit/list/withdraw, 5 for moderation and 2 for uploads. Timeout is 30 seconds except uploads at 60; upload memory is 256 MiB. These settings constrain capacity, not total requests or currency spent. The limited local image-memory observation is not a production memory guarantee. Confirm exact options after any authorized release and watch errors/latency/memory.

Denied calls, counter reads, authentication, invalid input and idempotent retries can still incur costs. Global allowances can be deliberately exhausted to deny service; do not label their existence proof of availability. Do not automatically raise limits in response to attack-driven traffic. Review seven days of legitimate aggregate usage/rejections before proposing changes, with an owner-approved cost assessment.

## Monitoring and investigation

Use existing provider metrics before creating new instrumentation: total Firestore document reads, writes and storage; Functions invocations/errors/latency/memory; Storage operations/bytes; Hosting transfer; App Check verification results and billing reports. Record the resource, time window, aggregation and observed baseline. Do not publish raw logs, tokens, coordinates, reporter UIDs or photos in evidence.

Investigate when **total database Firestore document reads** exceed 50,000/day on two consecutive days, total-read bursts exceed five times the recent comparable baseline, or the owner's budget alert arrives. Total reads include public, owner/admin and admission-counter traffic; this is not a precise `publicIncidents` metric. Correlate existing operation/error metrics and scoped evidence before attribution. These are conservative investigation triggers, not proof of attack or an automatic shutdown rule.

1. Record the UTC window, aggregate observations and recent release/task changes in private incident-response evidence.
2. Compare legitimate community activity, expected reads per view and counter/query costs with changes in invocations, rejections and App Check results. Avoid scanning private report data as the default diagnostic.
3. Check current rules and released options/source read-only. Do not disable App Check or broaden rules to diagnose traffic.
4. Have the overseer prepare the smallest response: a reviewed capacity/allowance adjustment, a client-loop fix, or separately scoped public-gateway work. Preserve withdrawal access and account for shared-project applications.
5. Obtain original-root approval for any live configuration, deployment or rollback. Immediately read back the exact changed state. Keep unresolved attribution/measurement limits explicit.

No IP collection, fingerprinting, remote telemetry collector, automatic billing disablement or automatic rollback is introduced. Carrier/mobile networks can share addresses, so an IP must not be treated as a person. Any future network admission requires a separate privacy and proxy-trust design.

## Budget proposal — not enabled by this task

Verify the existing billing account currency, project scope, current budgets, notification recipients and alert delivery/readiness read-only before changing anything. Task 10's 2026-10-13 project billing-link request returned HTTP 403 with `SERVICE_DISABLED` for the Cloud Billing API. Currency, current budgets and recipients therefore remain **unknown**, rather than absent. The earlier owner-completed Blaze link is historical evidence; this failed API request does not show billing is disabled. No API was enabled and no alternative console access was attempted. Do not duplicate an existing budget.

The plan proposes a project-scoped monthly alert budget equivalent to **ZAR 300**, with actual-spend thresholds at **50%, 80%, 100%**, and a **100% forecast** threshold. If the billing currency differs, prepare a reviewed amount in that currency; do not invent an exchange rate or silently save a converted value. The owner must accept the amount, scope, recipients and any configuration action.

[Cloud Billing budgets](https://docs.cloud.google.com/billing/docs/how-to/budgets) provide alerts, not hard spending caps. Data/notification delay can allow costs to pass a threshold before anyone responds. An alert needs an identified operator and response procedure; it must not automatically disable billing and impair reporting, withdrawal or another application sharing the project.

## Private admission counters and cleanup

`_abuseCounters` is server-only, including for admin/analyst clients. Counter keys are opaque; records contain only a count, window end and `expiresAt`. Window documents reset in place. `expiresAt` is window end plus 48 hours, but that field alone does not delete documents. No TTL policy was enabled by this chain.

If cleanup is selected, prepare an exact separately authorized TTL configuration for this collection group/field. [Firestore TTL](https://firebase.google.com/docs/firestore/ttl) deletion is asynchronous and has cost implications; admission must function correctly while expired records remain or disappear. Do not delete private incidents/photos, alter their retention or add a scheduler as incidental counter cleanup.

## Dependency and callable App Check evidence — 2026-10-13

Task 9 refreshed only the Storage dependency within Firebase Admin's existing `@google-cloud/storage:^8.1.0` range. The lockfile now selects Storage 8.4.0 instead of 8.2.0; direct dependencies, Node 22 requirement, Sharp and existing overrides are unchanged. Its supported upstream dependencies use gaxios 7 and google-auth-library 11, removing uuid 9 and obsolete/deduplicated HTTP dependencies. No forced major override or `audit fix --force` was used. See the [upstream Storage changelog](https://github.com/googleapis/google-cloud-node/blob/main/handwritten/storage/CHANGELOG.md) for the dependency correction and subsequent compatible release changes.

The fresh production audit changed from two Moderate package entries for one [uuid advisory](https://github.com/advisories/GHSA-w5hq-g745-h8pq) to zero reported vulnerabilities. Before the update, the installed gaxios 6 multipart path called `uuid.v4()` without a supplied buffer; the advisory concerns bounds checks in the v3/v5/v6 APIs. That path did not demonstrate an app exploit. Removal of the affected package resolves the reported dependency finding; a clean audit is not proof that all possible vulnerabilities are absent. Private before/after audit, dependency inventory, lock diff and canonical JPEG comparison evidence is under `.local/security-chain-20261013/task-9/`.

`functions/test/app_check.test.js` inspects every actual compiled callable export in fresh processes with `FUNCTIONS_EMULATOR` absent, `false` and `true`. SDK 7.4.0 leaves App Check out of `__endpoint`/`__trigger` deployment metadata. The test therefore captures the explicit options passed to the real SDK constructor, maps each returned callable by identity, and refuses to skip an export or unmatched registration. Enforcement must be `true` in the first two cases and `false` only for exact emulator `true`. The same checker rejects an additional deliberately unenforced real-SDK callable. No production factory or test instrumentation was added.

This proves callable constructor configuration, not live invalid-token rejection. Existing missing-auth tests remain separate from this evidence, and the emulator intentionally bypasses App Check. After an authorized Functions release, root must verify the exact released source/dependencies and that no production `FUNCTIONS_EMULATOR` flag is present. No live token/replay traffic or account mutation was used for these checks.

## Outstanding release/readiness work

- Cumulative independent security review and root approval for concrete release artifacts.
- Live rules/source/options readback following an approved release; local tests are not live evidence.
- Owner verification of Google-account MFA/recovery, billing currency/budgets/recipients and nominated operational contacts; review the broad runtime IAM role below.
- Real device/header/CSP checks from Tasks 7–8, with physical iPhone evidence kept separate.
- Shared terms/privacy policy remains deferred to second-app completion and website launch, as the owner requested. Technical safeguards remain in force; [the preparation inventory](SHARED_PRIVACY_PREPARATION.md) records tortoise data flows and future owner decisions.

## Role matrix — inspected 2026-10-13

This matrix describes current local rules, callable predicates and client access. The pre-chain 2026-10-13 live rules used the same privileged predicate; the new admission/public-query controls still require release. A privileged Firebase token has `admin:true`, `role:'admin'` or `role:'analyst'`. A client-provided role field, email verification or Google sign-in alone grants no role.

| Identity | Exact incident reads and CSV export | Private photos | Moderation | Direct incident/projection writes |
|---|---|---|---|---|
| Signed out, no Firebase UID | Denied | Get/list/upload/delete denied | Denied | Denied |
| Anonymous or Google-linked reporter without privileged claim | No direct exact reads or admin CSV; owner callable returns only own ID/type/status/createdAt receipts | Owner callable uploads to own active incident; direct get/list/create/update/delete denied | Denied; owner callable can withdraw own report | Denied |
| Analyst claim | All exact incident documents readable; admin UI/CSV available | `photo.jpg` get/delete allowed; list/create/update denied | Callable allows accepted/rejected/duplicate, subject to state/publication/admission checks | Denied |
| Admin claim | Same as analyst | Same as analyst | Same as analyst | Denied |
| Functions runtime or other service account using server APIs | Depends on IAM; application routines read private records | GCS access depends on IAM; upload routine validates ownership and creates immutable token-free objects | Server routines validate callers; independent IAM-authorized writes can bypass these routines | IAM controls server access; Firebase client-rule denial does not constrain it |

Public gets and lists are available without a Firebase user claim, subject to service App Check enforcement; local lists require an explicit limit at most 500. Public documents remain the allowlist projection. Neither reporter ownership nor a privileged claim permits clients to read `_abuseCounters` or `_submissionThrottle`. Privileged incident read permission includes all stored fields and withdrawn audit records, even though the current CSV contains only ID, createdAt, exact coordinates, type, status and note. UI subscription/CSV filtering is not a field-level security boundary, and downloaded exports cannot be recalled.

There is currently no photo-deletion button in the admin UI, but the Storage rule grants the underlying delete operation to analysts and admins. Deletion does not automatically remove the incident or update its photo bookkeeping. Treat it as a separately authorized operational action. Withdrawal removes the public projection and active status but retains the private exact audit record/photo.

The broad analyst policy is deliberate and unchanged. **Optional least privilege is not selected:** a future owner-approved change could let analysts read/export while only admins moderate/delete. It would need coordinated callable/rule/client tests and a claim/workflow rollout; do not grant an analyst claim believing it already means read-only. Existing UI drops private views on sign-out, refreshed claim loss or actual permission denial; this does not make remote claim removal instantaneous for previously issued tokens or erase downloaded information.

## Privileged identity and IAM readback — 2026-10-13

At **15:01 UTC / 17:01 SAST**, bounded management reads reviewed all four current Firebase accounts and found **one privileged account**, enabled and email-verified, linked to `google.com`, with `admin:true` and no `role` claim. No analyst claim was found. The Google provider is enabled. The selected metadata shows zero Firebase MFA enrollments for that admin; it does **not** expose Google-account 2-Step Verification. Google MFA, recovery ownership and successful sign-in on the newly prepared build remain **unknown**. No login, claim grant/revocation, account change or lockout test occurred.

Sensitive roster details remain outside project documentation. Private evidence stores only an opaque account reference and selected privilege/provider flags, with no raw UID, email, token, password hash or MFA contact. The [account metadata API](https://docs.cloud.google.com/identity-platform/docs/reference/rest/v1/projects.accounts/batchGet) supports this bounded readback; it is not a Google-account security audit.

All five deployed Functions currently share one runtime service account with a direct project **`roles/editor`** binding. The project has three service-account Editor members in total and one user Owner member. This is a broad server-side trust boundary to review before community release; no evidence of compromise was found by this metadata inventory. [Server Firestore clients use IAM rather than client rules](https://firebase.google.com/docs/firestore/security/overview), and [basic IAM roles grant broad access](https://docs.cloud.google.com/iam/docs/choose-role-type). Application role restrictions cannot contain a compromised IAM-authorized runtime identity.

The inventory covers direct project bindings and runtime identity mapping, not complete inherited/resource-level access, service-account keys or impersonation paths. The earlier bucket inventory found no public IAM member; it does not establish least privilege for every principal. Any runtime-IAM remediation needs its own root-approved dependency/permission inventory and staged verification. Do not remove Editor blindly or replace it with guessed grants: deployment agents, runtime and Auth/Storage operations have different requirements.

## Observed provider quotas and measurement limits

The same read-only snapshot obtained complete returned pages of quota metrics for Firestore, Identity Toolkit, Cloud Functions and GCS. Selected values are recorded below; full compact metadata is private. These are provider limits, not the local callable allowance table, traffic usage, alerts or spending caps. Omitted effective limits remain unverified rather than interpreted as zero/unlimited.

| Provider metric | Observed effective limit | Meaning/limit of evidence |
|---|---|---|
| Firestore free daily reads/writes/deletes, default database | 50,000 / 20,000 / 20,000 per project/day | Free allowance figures; paid usage can exceed these. Not a bill cap or public-map rate limit. |
| Firestore composite indexes | 1,000 per database | Schema capacity; not report/read capacity. |
| Identity Toolkit default requests | 180,000 per project/min; 30,000 per project/user/min | Returned service dimensions; not a per-person anonymous-signup rule or callable limit. |
| Cloud Functions v2 management reads/writes, africa-south1 | 1,200 / 60 per project/region/min | Management API limits; not invocation throughput. |
| GCS internet egress bandwidth, africa-south1 | 200 Gbps (200,000,000,000 bits/s) | Returned service quota, not observed traffic, private-photo admission or an egress cost cap. |

See [Firestore free quotas](https://firebase.google.com/docs/firestore/quotas), [Functions quota categories](https://docs.cloud.google.com/functions/quotas), [GCS bandwidth units](https://docs.cloud.google.com/storage/quotas) and the [quota inventory API](https://docs.cloud.google.com/service-usage/docs/reference/rest/v1beta1/services.consumerQuotaMetrics/list). This snapshot did not measure recent usage, remaining regional Cloud Run CPU/memory, per-IP Auth anti-abuse limits, reCAPTCHA assessment allowance, Hosting transfer or alert delivery. Confirm those relevant limits/usage in their service consoles before changing capacity. No quota override, API enablement or monitoring rule was created.

## Owner readiness decisions — prepared, not applied

| Item | Current evidence | Concrete next owner/root action |
|---|---|---|
| Privileged roster | One verified Google-linked admin; no analyst | Privately confirm intended ownership of the opaque roster entry; record the approver and review date. Before any new grant, verify exact account/provider and existing claims. |
| Google MFA/recovery | Unknown; zero Firebase MFA enrollment proves neither Google protection nor its absence | Owner reviews Google Account Security for 2-Step Verification/passkey/security-key readiness and controlled recovery email/phone; confirm backup-code custody without sharing codes. Record protection status/date and a safe recovery custodian. Settings changes need explicit authority; no lockout exercise. |
| Runtime IAM | Shared runtime has Editor | Root commissions a scoped least-privilege permission review; approve a concrete tested replacement before any IAM change. Preserve required application paths and deployment agents. |
| Budget | Currency, existing amount/scope and recipients unknown; Billing API unavailable | Owner reviews the linked billing account's currency, existing project/account budgets and recipient rules in Billing Console. Select the ZAR 300 proposal or an explicitly approved native-currency amount; retain monthly project scope and 50/80/100% actual, 100% forecast thresholds. Verify existing coverage before creating/updating. |
| Alert operators | Primary/backup operator, contact channels and delivery unverified | Nominate a primary and backup, confirm each can see metrics/billing and accepts the investigation procedure. Privately record recipients, escalation channel and acknowledgement target. Proposed target: check alert within one working day; owner decides whether adequate. No test email/message was sent. |
| Abuse/cost readiness | Local allowances/runtime caps prepared; no recent usage baseline collected | Root verifies released limits and captures aggregate baseline after release. Review App Check results, Auth growth, Firestore reads, Functions errors/memory and Storage/Hosting transfer. Budget alerts are delayed signals, never an automatic shutdown instruction. |
| Counter cleanup | `expiresAt` prepared; TTL not enabled by chain | Owner decides whether to authorize exact `_abuseCounters`/`expiresAt` TTL after reviewing asynchronous deletion/cost. This is separate from incident/photo retention. |
| Community release | Cumulative review and release/readbacks pending | Use exact reviewed artifacts; read back rules/options/dependencies/headers per origin. Task 8 resource enforcement remains NOT READY; fresh auth/device/PWA checks and dynamic-style remediation are outstanding. Shared policy stays deferred to the agreed trigger. |

Google account recovery guidance is available in [Google's 2-Step Verification help](https://support.google.com/accounts/answer/185834). [Budget API results can omit console-only fields](https://docs.cloud.google.com/billing/docs/reference/budget/rest/v1/billingAccounts.budgets/list), so even a later successful API inventory cannot by itself certify every recipient or alert delivery. These decisions are prepared for review; no operational setting was saved by Task 10.
