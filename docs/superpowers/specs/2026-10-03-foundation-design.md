# Scarborough Tortoise Watch foundation design

The user supplied a comprehensive product specification and explicitly requested execution of the complete local setup. This design records implementation choices within that scope. No deployment, account creation, billable service activation, or payment processing is authorised.

## Outcome

A mobile-first Flutter Web/PWA starter lets a resident report a tortoise using GPS or a manually selected map pin, classify it, optionally attach a photo/note/bearing, and receive centrally maintained guidance. A separate public map displays sanitised accepted sightings. The local demo runs without Firebase credentials and labels all synthetic data and demo submissions visibly. The admin area establishes authorised data access and CSV export without a large management system.

## Architecture

Use Riverpod, go_router, immutable Dart models, feature-owned presentation/domain/data, and small interfaces for incident repositories, location, photo storage, and maps. Use flutter_map behind the map adapter. Central config owns provisional branding, Scarborough centre, zoom, tiles, photo limits, guidance, and support. The user asked for Firebase; alternatives considered were client-only Firestore writes with asynchronous projection, and callable submission with a server-managed projection. Choose the callable boundary because it validates input and owns idempotency, timestamps and public/private separation atomically where practical.

Private `incidents` contain exact coordinates, reporter UID, notes, accuracy, photo references and timestamps. Public `publicIncidents` contain an explicit allowlist only: opaque public ID, incident classification, coarse date, and stable displaced display coordinates. Public clients cannot read the private collection; administrators require a trusted custom claim. No public notes, photo URLs, reporter identifiers, bearings or exact timestamps. Only accepted incidents are published. Client mutations of private/public documents are denied; callable Functions validate reports and moderation. The public offset is generated server-side with cryptographic randomness once per report (20–50 metres by default), stored privately and reused across moderation so public refreshes cannot be averaged. Never use a publicly computable seed. This is approximate privacy, not a guarantee of anonymity against outside knowledge; the radius and publication policy require pilot review.

## Behaviour and trust boundary

- Start location on report-screen entry. Permission denied/unavailable/low accuracy remains recoverable with tap/drag/manual selection. Do not silently submit the default map centre. Late GPS cannot overwrite a manual pin.
- Require explicit incident classification and a confirmed location. Optional note max 500 characters; bearing finite in [0,360); coordinates finite within geographic bounds. Preserve the draft on failure and maintain a stable request ID for retry deduplication.
- Save the core incident first. Upload one optional resized/re-encoded JPEG afterward to a UUID-based private path. Strip metadata; initial 1600-pixel longest edge, 2 MiB upload cap and bounded source size. Retry or skip a failed photo without resubmitting the core incident. No public Storage listing or download-token URLs. Rules bind upload owner/path/type/size to a created incident; administrative reads only. Treat content type as a limit, not full content verification.
- Callable submission requires anonymous or authorised Firebase Auth and App Check outside emulators. Include server validation and a modest per-UID throttle; document anonymous-account churn limits and future broader abuse controls. Requests cannot specify moderation, UID, server time or public coordinates.
- Demo mode is the default. Production configuration fails closed when incomplete. Firebase options are only generated later by FlutterFire; no fabricated credentials or options file. Emulator configuration is explicitly local and uses a demo project ID.
- Admin uses authorised Firebase accounts/claims; unauthorised users never retrieve exact records. CSV should escape quotes/newlines and prevent spreadsheet formula injection.
- Guidance is draft pending appropriate authority verification. Include the requested same-direction safety guidance, without invented contacts or claims of authority.
- PWA manifest/icons and a minimal service worker cache only the app shell; never Firebase responses, map tiles, photos or admin data. No offline submission promise. Persist transient draft state in memory, not precise locations in browser storage.

## UI

Warm sand background, deep fynbos green, restrained coastal accent, consistent 8-point spacing and large touch targets. Home prioritises Report a tortoise, then View sightings map. Clear demo/config states. Reporting is one compact scrolling screen with location first and optional details secondary. Public map filters alive/injured/roadkill and dates. Support component is disabled/configurable and never blocks reporting. Branding is provisional, no elaborate asset work.

## Verification and deliverables

Create all requested docs, AGENTS.md, configuration examples, Git ignore, CI without deployment, rules/indexes/emulators, synthetic fixtures, and setup/operations guidance. Tests cover typed models, all incident types, invalid numbers, field validation, repository retries, photo partial success, public privacy projection, admin authorisation, and rule access boundaries. Run formatter, analyzer, Flutter tests and release web build when tooling permits; run Node Functions and emulator rule tests. Report exact commands and real results, including blockers. Finish with a directory tree, manual configuration steps and next three tasks.
