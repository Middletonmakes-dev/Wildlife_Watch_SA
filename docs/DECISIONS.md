# Decision log

## 2026-10-04 — Fynbos Journal and a two-screen resident report

Decision: Adopt the selected Fynbos Journal identity: true-white surfaces, rust actions, bundled Source Serif 4 headings, nature imagery and ruled rows. Use two report screens: four incident choices, then explicit GPS or manual map pin plus optional direction on the same north-up map. A large arrow wheel supports drag, tap, keyboard and semantic adjustment; untouched/skipped direction remains null and roadkill has no direction question. Keep optional photo and note out of the required path, preserve the photo pipeline and anchor submission within reach.

Reason: Occasional residents need a readable, local interface and a quick path without typing, compass knowledge or a compulsory review screen. The five-action GPS path targets roughly twenty seconds, subject to permissions, GPS and network response; this is a design target without measured physical-device timing.

Consequences: Direction remains private in the existing nullable bearing field. Pin placement and direction interaction have separate modes; report maps cannot rotate. Public map data still uses the existing trusted allowlist projection. The current locally bundled tortoise image is explicitly labelled AI-generated illustrative artwork and can be replaced by a real photograph later. Source Serif 4 regular is distributed with its OFL license, avoiding runtime font downloads. This local demo redesign is not deployed and does not establish new Android/iPhone, GPS, camera, PWA or Firebase integration evidence.

## 2026-10-03 — Wildlife Watch SA umbrella identity

Decision: Use **Wildlife Watch SA** as the umbrella project name and **Scarborough Tortoise Watch** as its first local programme. The user approved this name before Firebase project creation.

Reason: The intended future coverage may extend across South Africa and include leopard toads, caracals and a live baboon activity/incursion map.

Consequences: Create the new Firebase project under the umbrella identity. Complete the existing tortoise pilot and phone/backend testing first. This naming decision does not implement other species, live tracking or a multi-tenant platform. Before those features, define species-appropriate location privacy and distinguish expiring activity reports from historical observations. Domain and trademark availability have not been established.

## 2026-10-03 — Johannesburg database for the South African pilot

Decision: Provision the new project's default Standard Firestore database in `africa-south1` (Johannesburg), initially denying all client reads and writes.

Reason: The initial and intended future users are in South Africa, and both Firestore and second-generation Functions support this region.

Consequences: The database location is fixed. Before deployment, explicitly configure the Functions server and Flutter client to use this region, and review colocated Storage. Creation does not deploy the application's rules or allow reporting yet. Billing activation remains a user handoff, with no billing account attached by the agent. See `FIREBASE_SETUP.md` for live setup evidence.

## 2026-10-03 — Enterprise App Check and colocated Functions

Decision: Use a score-based reCAPTCHA Enterprise web provider with automatic token refresh, registered only for the two Firebase Hosting domains. Enforce App Check for Firestore and Storage, and retain callable enforcement in code. Use `africa-south1` for all Functions clients, exports and emulator endpoints, colocated with the actual Firestore database and Storage bucket.

Reason: The live Firebase console disables deprecated Classic registration. The user approved Enterprise registration and its Cloud terms. A shared explicit region avoids clients calling the SDK's default US endpoint after a Johannesburg deployment.

Consequences: The production site key cannot be used on localhost. Local tests use the isolated emulator branch; real integration tests require the configured HTTPS Hosting build and separate deployment/write authority. Keep that build at `build/firebase-web` so the existing USB demo output is preserved. Authentication App Check remains unenforced while its console integration is in preview; anonymous authentication still accompanies each reporting callable.

## 2026-10-03 — Flutter Web/PWA first

Decision: Start with Flutter Web and a small PWA shell.

Reason: Residents can open a link quickly and the initial audience does not justify native store work.

Consequences: Browser permissions, tile policies and weak-network behaviour require explicit testing.

## 2026-10-03 — Firebase with callable trust boundary

Decision: Use Auth, Firestore, Storage, App Check and Functions, with `submitIncident` owning validation, server timestamps, idempotency and private/public separation.

Reason: Client Firestore writes cannot safely own a public projection or trust sensitive fields.

Consequences: A real project needs generated options, claims, App Check and emulator/deployment setup.

## 2026-10-03 — Riverpod and go_router

Decision: Use Riverpod for small dependency seams and go_router for routes.

Reason: They keep the small app testable without an enterprise framework.

Consequences: Keep providers and route logic centralised.

## 2026-10-03 — Anonymous reporter, no visible registration

Decision: Use anonymous Auth behind the callable when Firebase is enabled.

Reason: Reporting should take seconds and collect no unnecessary identity fields.

Consequences: Anonymous-account churn and abuse controls need pilot monitoring.

## 2026-10-03 — Private/public coordinate separation

Decision: Public map reads a separate allowlist projection displaced 20–50 metres by server-side cryptographic randomness.

Reason: Hiding exact fields in a client response is not a privacy boundary.

Consequences: Projection radius, publication policy and retention require pilot review; projection reuse prevents averaging across moderation changes.

## 2026-10-03 — Mobile-first local design

Decision: Use warm sand, fynbos green, large controls and compact reporting.

Reason: The first users are residents on inexpensive phones and the project should feel credible and local.

Consequences: Visual polish remains intentionally restrained.

## 2026-10-03 — Donation provider deferred

Decision: Ship a disabled support placeholder only.

Reason: Legal, accounting and provider decisions are not part of the reporting MVP.

Consequences: No payment or tax claims can appear until separately approved.

## 2026-10-03 — Map provider abstracted

Decision: Use `MapProvider` and an OpenStreetMap starter URL with attribution.

Reason: Core reporting must not be locked to one commercial provider.

Consequences: Production must confirm tile acceptable-use, capacity, attribution and cost.

## 2026-10-03 — Scarborough and tortoises remain the MVP focus

Decision: Keep one local community and species focus; defer multi-tenancy and other wildlife platforms.

Reason: Reliable resident reporting and privacy are the first outcomes to prove.

Consequences: Keep clean models/export seams, without speculative tenant/account machinery.

## 2026-10-03 — Explicit Firebase entry point and local-only verification

Decision: The default `main.dart` imports no generated credentials. An ignored `main_firebase.dart`, copied from the example after FlutterFire configuration, explicitly passes generated options. Local emulator mode requires a `demo-` project and skips App Check only in the emulator.

Reason: Demo builds must compile without platform options, while an incomplete Firebase launch must fail closed.

Consequences: Production requires generated options and an App Check site key. Rules/callable integration uses isolated synthetic local data and ports 18080/19199/19099/15001.

## 2026-10-03 — Single reserved private photo slot

Decision: The server reserves `incidentPhotos/{incidentId}/photo.jpg` on each committed private report. Creation is owned by an Auth/App Check callable with bounded JPEG processing and token-free Admin GCS saves; direct client writes and all listings are denied. Trusted administrative reads remain private.

Reason: Photos can upload after a successful core report without granting client incident writes or sacrificing the report on upload failure.

Consequences: `photoReferences` denotes a reserved slot, which may not contain an object. Photo retry uses only the committed incident ID; same-image retries are idempotent and different-image replacement is denied by GCS generation preconditions/private hash. No download URL is created. Image content scanning remains later work. This server boundary avoids Firebase client uploads automatically minting bearer download tokens that bypass rules.

## 2026-10-03 — Android and iPhone browser coverage, staged phone testing

Decision: Treat Android browsers and iPhone Safari as intended MVP targets. Begin physical testing with the user's Android phone on the same Wi-Fi using the existing credential-free manual-location demo. Follow with HTTPS and configured-backend testing for GPS, PWA behavior and real submissions.

Reason: The web-first product is not restricted to Android. A simple LAN smoke test can expose touch/layout/photo-selection issues before cloud setup, without implying that simulated data or a desktop device profile proves real-device integration.

Consequences: LAN HTTP is suitable for the manual demo but does not provide the secure context required for browser geolocation and service workers. HTTPS alone does not enable GPS or storage in demo mode. Real GPS/backend testing requires an explicit configuration path; cloud setup, publication, public tunnels and production actions still need separate authority. Windows WebKit testing is supplementary; Apple Simulator requires macOS and final iPhone evidence must come from an appropriate device or Apple simulator environment.

## 2026-10-03 — Prefer the authorized Android USB preview for the first device test

Decision: Use the existing authorized Android debugging connection and a scoped reverse mapping for port 18765 to exercise the built demo in physical-device Chrome. Stop the now-unneeded LAN-only server; retain the USB mapping and PC loopback preview for continued local testing.

Reason: The user explicitly offered the USB-connected phone for agent-operated testing. This avoids network/firewall changes and yields actual device evidence rather than desktop emulation.

Consequences: The PC must remain awake and USB connected. Phone loopback is a browser secure-context exception, so later GPS checks need not require public hosting; the present demo still deliberately disables GPS and simulates writes. Remove only this port mapping when finished. Record device-specific evidence and remaining limitations without claiming iPhone or Firebase integration coverage.

## 2026-10-03 — Wildlife Watch SA umbrella and Johannesburg backend

Decision: Use Wildlife Watch SA for the cloud project while retaining Scarborough Tortoise Watch as the first local programme. Align the Functions clients and all three callable deployments with Johannesburg (`africa-south1`), matching Firestore and Storage. Use registered reCAPTCHA Enterprise App Check with automatic refresh and enforcement.

Reason: The user intends possible future South African wildlife programmes, while the immediate pilot still concerns Scarborough tortoises. Regional consistency avoids an accidental default-US callable deployment. The live Firebase console supports Enterprise registration.

Consequences: No additional species, tenant model or live baboon map is implemented. Generated Firebase options and release defines remain ignored. Cloud publication and synthetic phone writes were separately approved and performed by root; subsequent cloud actions still require their own applicable authority.

## 2026-10-03 — Explicit photo source choice

Decision: Offer Take photo and Choose existing photo before invoking the existing photo pipeline. Cancelling either selection preserves the current report draft.

Reason: Physical Android testing exposed a camera-only implementation, while the original requirement permits taking or uploading a photo. Selecting a prepared synthetic image also permits testing the upload without using the device camera or personal photographs.

Consequences: JPEG processing, limits, private upload and retry behavior stay the same. The gallery path receives physical-device verification; camera capture and iPhone behavior remain separate checks.

## 2026-10-04 — Closer report map and explicit local-preview GPS

Decision: Start the report map at zoom 17 while retaining zoom 14 for the public map. A successful explicit GPS request recentres at the closer report zoom and shows the direction wheel for live observations; roadkill keeps only the pin. Bearing changes and manual adjustments preserve the resident's zoom.

The ordinary demo keeps device GPS disabled. `DEMO_DEVICE_GPS=true` explicitly enables the existing device location service for a local preview while report, photo and public-map repositories remain in demo mode. GPS is requested only after the resident taps Use my location; enabling this flag does not enable Firebase writes or imply permission to collect location during agent checks.

Remove the public image caption and conservation draft notice at the owner's request. Retain an honest illustration description for assistive technology and the existing road-safety guidance. Removing the notice does not establish conservation-authority approval.

## 2026-10-04 — Reporter withdrawal and owner receipts

Decision: Add `listOwnIncidents` and `withdrawIncident` callable boundaries. The list is authenticated by the server-side reporter UID, capped at the latest 500 records, and returns only incident ID, type, moderation status and creation time. Withdrawal is transactional, only the original reporter may request it, deletes the public projection, and retains the private incident as an explicitly labelled `withdrawn` audit record. Repeated withdrawal is idempotent and moderation rejects withdrawn records.

Reason: Residents need a way to correct mistaken submissions without exposing exact private records or adding a registration step. Existing anonymous Auth sessions remain the ownership boundary, so earlier reports work without a new browser receipt.

Consequences: Withdrawn records are excluded from active resident/admin views and may be selected only through an explicit audit view. Photo upload checks withdrawal before reserving or writing the private slot; an already-running private upload cannot publish or reactivate a report. The local demo uses a shared in-memory receipt store. This is a local implementation decision and does not authorize deployment or production writes.

## 2026-10-04 — Claim-gated live exact-location admin map

Decision: Add a bounded Firestore snapshot stream for exact incident records behind existing `admin`, `role=admin`, or `role=analyst` custom claims. The admin UI defaults to pending reports, offers all active statuses and a separate withdrawn audit view, keeps the map viewport stable as snapshots arrive, and provides explicit fit, selection, moderation and CSV actions. Google sign-in links an anonymous current user when possible to preserve report ownership; credential conflicts are surfaced and never silently switched.

Reason: Protected reviewers need to see implausible exact points, including offshore coordinates, as new reports arrive without reloading. Authentication alone must not grant access, and public map documents remain the privacy-protected allowlist projection.

Consequences: Provider enablement, custom-claim grants and production verification remain separate root-owned release actions. The local demo/admin seams and emulator tests provide synthetic validation without bypassing production authorization. This decision does not claim physical-device, provider, or production evidence.

## 2026-10-04 — Truthful owner paging and claim-event revocation

Decision: Owner receipts read one extra ordered document and return a typed `hasMore` result; equal creation timestamps are ordered by document ID. Admin authorization checks observe both Auth state and ID-token events, while only an explicit sign-in or Check access action forces a token refresh. Private map subscriptions are dropped when a claim check is revoked, and stale asynchronous checks cannot restore them.

Reason: A fixed 500-document read cannot distinguish an exact page from a truncated result, and claim changes must revoke exact-location access without creating a refresh loop.

Consequences: The owner UI explains when older receipts are outside the current page. Admin stream and map-controller lifecycles are tied to the authorized widget, and synthetic tests cover cap ties, foreign isolation, claim revocation, logout cancellation, and concurrent moderation/withdrawal.

## 2026-10-04 — Same-origin Google redirect sign-in

Decision: Replace mobile Google popup authentication with Firebase redirect authentication, linking an existing anonymous user to preserve report ownership. Consume the redirect result once after Firebase initialization and before rendering the application; show recoverable authentication errors in the admin screen. The configured web build uses wildlife-watch-sa.web.app as authDomain and requires that domain's /__/auth/handler in the OAuth client's authorized redirect URIs.

Reason: The connected Android phone returned to a blank Firebase callback window with a window-close warning and no completed Google account link. A same-origin redirect follows Firebase's supported mobile flow.

Consequences: OAuth callback configuration and Hosting publication are pending exact user approval after automatic approval review rejected the callback save. Local tests and build do not establish successful physical-phone sign-in; that verification and the verified owner admin grant remain pending.

## 2026-10-05 — Tortoise condition map markers

Decision: Use the supplied assets/SVG/Tortoise.svg for public and admin sighting markers, tinted green for alive, yellow for injured and red for dead/roadkill, with a light circular backing. Admin selection retains an outline and larger marker; moderation status remains in accessible labels and report details.

Reason: Residents should recognise the species and sighting condition consistently across maps.

Consequences: The report location/direction picker and location privacy boundaries are unchanged. This local UI change does not authorize publication or deployment.

## 2026-10-05 — Real tortoise photograph on the home page

Decision: Use the supplied `assets/images/tortoise-real.jpeg` for the home-page hero image, with the truthful accessibility label “Tortoise walking on gravel.”

Reason: The owner requested this photograph in place of the illustrative placeholder, with an accurate description for assistive technology.

Consequences: The home page remains a local UI change and does not establish new conservation approval, device, backend or deployment evidence.

## 2026-10-07 — Good Spotting replaces Wildlife Watch SA as umbrella brand

Decision: The owner selected **Good Spotting** and the public address **https://goodspotting.web.app/**. Keep the existing `wildlife-watch-sa` Firebase project and data, and add a `goodspotting` Hosting site serving the current live app. Keep the previous address available. Scarborough Tortoise Watch remains the first programme. Full visible branding changes are separate from this requested address change.

Consequences: Future Hosting releases must target `goodspotting` explicitly. Existing installed PWAs and browser-local anonymous identities remain associated with their original origin; do not promise automatic migration of sessions or report ownership.

## 2026-10-13 — Good Spotting logo and external support links

Owner approved the bounded design authored by GPT-6 Astra Medium. Use the main website's public/images/good-spotting-logo.svg in the shared app header, preserving its proportions and colours (inline SVG fills replace CSS for Flutter compatibility). Home links to https://good-spotting.netlify.app/ with “See more projects by Good Spotting”. The support page links to the owner-supplied https://pos.snapscan.io/qr/76M6XG6i with optional-contribution wording. This supersedes the deferred support placeholder: payments take place externally at SnapScan, with no payment processing or financial data collected in this app. Both links open new tabs and display failure feedback. Local implementation uses url_launcher and focused destination/error/layout tests. No backend changes or payment transaction is required.

## 2026-10-13 — Server-owned admission counters

The owner authorized local execution of the Astra-authored security remediation plan in sequential Sol 6.1 High sessions. Task 1 introduces transactional admission primitives with the plan's pilot UID, incident and aggregate allowances, using fixed UTC minute/day windows. Each opaque scope/window key resets its counter in place; all applicable counters are read and checked before any writes are queued. Combined operations pass one union of buckets, preventing Firestore reads after writes and partial admission. Malformed or unavailable counter state fails closed.

Counters contain count, window end and an expiry timestamp 48 hours later, with explicit denial for every client role. Expiry timestamps do not enable automatic deletion; any TTL policy requires a separate configuration decision. These primitives do not yet throttle endpoints: photo admission and callable integration follow in later tasks. No deployment or production configuration change accompanies this local decision.

## 2026-10-13 — Bounded private photo comparison and identical-byte retries

Task 2 of the approved local security plan adds photo request/decode admission before Sharp and a temporary server lease for each immutable photo slot. A byte-identical stored retry verifies private object metadata and skips decoding; a different byte stream must normalize under the decode allowance and match the existing canonical fingerprint. This retains compatibility with equivalent JPEG encodings and legacy normalized hashes. An active lease consumes only request admission before returning a retryable failure, and invalid input releases only its own lease without reserving a photo.

The accepted input fingerprint and fixed `jpeg-v1` processor version remain private. The canonical reservation is never overwritten, GCS still uses a generation-zero save without Firebase download tokens, and final stored state is committed only while ownership, withdrawal status and the worker's lease remain valid. Storage/transaction failures retain safe retry state. Local unit/emulator checks cover these boundaries; the next task adds exhaustive crash and concurrency proof. No deployment accompanies this change.

## 2026-10-13 — Photo retry state recheck after metadata access

Task 3 follows Astra's scoped remedial ruling: a stored identical-byte retry rereads private incident ownership, withdrawal status, stored state and canonical identity after asynchronous object-metadata verification. This rejects a report withdrawn or changed during the metadata request, without decoding again or consuming a second admission allowance. The final read is the retry's state-check boundary; Firestore and object storage are not claimed to form one atomic transaction.

Deterministic failure schedules cover reservation/save/finalization recovery, lease expiry and stale workers, matching/different/equivalent requests, generation-precondition metadata and withdrawal seams. An upload interrupted after saving can retain a private object; withdrawal never promises photo erasure or reactivates a record. No production mutation or deployment accompanies this local change.

## 2026-10-13 — Callable admission and pilot capacity

Task 4 integrates the approved minute/day UID and aggregate allowances with submission, owner listing, withdrawal and moderation. New submissions consume admission in the same transaction as creation, after the existing five-second cooldown; an identical saved request returns its receipt without spending a new-submission allowance. Owner-list admission commits before the bounded 501-document query. Withdrawal uses its own independent allowance and charges repeated successful withdrawals; ownership and moderation authorization checks precede operation-specific rate details. Transaction commit failures return generic temporary-unavailable errors.

All five callables now declare zero minimum and two maximum instances. Submission, listing and withdrawal use concurrency 10 and a 30-second timeout; moderation uses concurrency 5 and 30 seconds; private photo upload uses concurrency 2, a 60-second timeout and 256 MiB. Admission values remain centralised and retain fixed-window boundary bursts. These settings limit admitted work and simultaneous capacity, not total spending or invocation costs. Provider aggregate metrics remain the operational source; no identifying telemetry was added. Local test/emulator evidence does not authorize deployment or prove physical-device or production memory behavior.

## 2026-10-13 — Bounded public queries and explicit fresh-map reads

Task 5 retains direct public Firestore reads and the latest-500 map contract. Public lists require an explicit limit at most 500; single gets remain allowed and every client write remains denied. This bounds a query's size, not request frequency, and does not protect against repeated allowed reads.

The configured public repository coalesces ordinary in-flight loads and caches typed public projections in memory for 60 seconds. Filters reuse the page. Explicit refresh and successful marker withdrawal invalidate it and fetch from the server; superseded loads follow the newest result or error instead of restoring old markers or silently retrying. Failed reads have an explicit retry action. Demo fixtures and private-data access remain separate; no persistent cache, gateway, identifying telemetry or new production setting is added.

Operational guidance uses total database reads with scope-aware investigation thresholds, a proposed owner-reviewed budget and clear alert/TTL limitations. Final shared privacy terms remain deferred. These local changes require cumulative review and separately authorized release/readbacks.

## 2026-10-13 — Historical public sightings with stable privacy versions

Task 6 implements the chain's selected local policy: the first public projection is eligible only after exactly seven days from trusted server creation, and its cryptographically generated offset is 100–250 metres. The delay and radius values are central source configuration; previous radius environment overrides no longer silently weaken this policy. A supplied occurrence date cannot shorten the waiting period. No scheduler or automatic publication is added, and rejection, duplication and withdrawal remain available during the wait.

The public projection keeps its existing five-field allowlist. Private `publicProjectionVersion` is assigned `v2` when first projected under this policy; existing stored projections without a version are identified as `v1` when next moderated and reused unchanged. Records without any stored projection remain candidates for v2, even if stale private version metadata exists. Reject/reaccept never generates another coordinate sample. Legacy points retain their original 20–50 metre protection; information already viewed or copied cannot be recalled. No production migration is performed.

Admin publication-not-ready and withdrawn errors remain typed operation messages, with a validated UTC calendar eligibility date. They preserve the private view; genuine authentication/permission denial removes it and drops the private subscription. Public map copy describes approximate historical sightings rather than exact crossing locations. These changes are local and require reviewed release authority; shared privacy terms remain deferred.

## 2026-10-13 — Hosting framing with reserved-route exclusion

Task 7 prepares baseline response headers only in the maintained Good Spotting release configuration. Astra approved disjoint `/` and `/!(__){,/**}` sources because Firebase matches the initial URL before SPA rewrites: unknown application URLs need framing protection, while the entire reserved `/__/` namespace must avoid application `DENY`/`frame-ancestors 'none'`. The existing rewrite, release target, artifact, cache rules and platform HSTS are preserved. No COOP/COEP or resource CSP is introduced.

Configuration checks use the installed Firebase CLI matcher; served-header/browser evidence uses a clearly labelled private fixture adapting a Windows slash-normalization defect in the installed emulator. Live matching, managed auth helpers/redirects, camera/gallery and physical iPhone compatibility remain release gates. Current read-only checks show all four Firebase origins lack the prepared baseline; no custom domains are configured. No deployment or account configuration was performed. See `HOSTING_SECURITY.md` for evidence and verification commands; Task 8 extends resource CSP separately.

## 2026-10-13 — Resource CSP observation and enforcement gate

Task 8 adds resource report-only policy on the existing disjoint application sources, preserving enforced framing and reserved auth exclusions. Exact Firebase/reCAPTCHA/CanvasKit/font/tile hosts have observed versus inferred provenance. Fixed worker registration and six Firebase 11.9.1 runtime import wrappers use exact hashes; CanvasKit uses `wasm-unsafe-eval`. No universal HTTPS, broad eval, unsafe-inline or reporting collector is added. Current loader still selects CDN CanvasKit despite local copies; self-hosting is not changed or claimed.

A fresh configured artifact/private candidate and hashes are prepared; historical release remains intact. Cold local home rendered, but API/provider POST blocking prevents auth/App Check proof. Final stylesheet reports and the untested alternate wrapper branch leave enforcement NOT READY. Warm/report/map hash-routing fixture coverage and supported-device checks remain incomplete. Astra bounded automation repairs; no further browser run follows final observation. Root-owned report-only release/readbacks, reviewed style/wrapper remediation and actual device evidence precede enforcement. No deployment, production mutation or final shared policy accompanies this local preparation.
