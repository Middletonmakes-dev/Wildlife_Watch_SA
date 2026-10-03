# Decision log

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
