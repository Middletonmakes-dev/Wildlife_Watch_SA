# Decision log

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
