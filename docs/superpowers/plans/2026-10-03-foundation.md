# Scarborough Tortoise Watch implementation plan

> **For agentic workers:** Use the subagent-driven-development workflow adapted to the user's explicit one-coder ownership: one coder implements the complete local foundation, followed by independent read-only review. Do not spawn further agents.

**Goal:** Create the complete runnable local Flutter/Firebase foundation requested in the supplied specification.

**Architecture:** Feature-oriented Flutter with small testable service interfaces and a Firebase callable trust boundary. Private exact incidents and allowlisted public projections are separate collections; demo mode requires no credentials.

**Tech stack:** Flutter Web/PWA, Dart, Riverpod, go_router, flutter_map, Firebase Auth/Firestore/Storage/App Check/Hosting, Node 22 Functions.

**Spec:** `docs/superpowers/specs/2026-10-03-foundation-design.md`; full original request in `docs/INITIAL_REQUEST.md`.

## Global constraints

- Work only in `C:\Users\admin\Documents\Scarborough Tortoise watch` and ordinary task-local dependency caches.
- No deployment, production writes, external accounts/services, billable API enabling, payment implementation, remote Git publication, or fabricated Firebase credentials.
- User explicitly requests execution, not a plan-only response. Root retains Git commits and any approval boundary.
- All exact data/private photographs require authorised administrative access. Public schema is an allowlist, generated on the server. Draft coordinates in the reporter's own form are not public data.
- One coder owns all product code/docs/tests/config; root owns this plan/spec and local environment investigation. Preserve others' edits.
- Use plain immutable Dart models; no unnecessary generators or enterprise framework. A small functional starter is the goal, not speculative future systems.

## Review focus

1. Denied/late GPS must not block manual reports or overwrite selected pins.
2. Retrying after a lost response or failed photo must not duplicate the incident or lose draft fields.
3. Public reads, photos, projections, log/error output and service-worker caches must not leak exact private fields.
4. NaN/infinity/out-of-range values, forged enum/status/UID fields and duplicate request IDs must be handled at the server boundary.
5. Anonymous/unauthorised access to admin and CSV must fail closed; dates and CSV cells must export safely.

## Task 1 — Complete local foundation

**Ownership:** One coder owns `lib/`, `test/`, `web/`, `assets/`, `functions/`, `firebase/` or rule tests, `scripts/`, `.github/`, root app/config files, README/AGENTS and all requested docs except this plan/spec.

**Interfaces:**

- `IncidentRepository.submit(ReportDraft)` returns stable submission result; an existing request ID is reused across retries.
- `LocationService.currentLocation()` returns typed position/source/accuracy or an application error.
- `PhotoStorage` accepts a committed report and processed bytes; failure is independent from core submission.
- `MapProvider` supplies report/public map widgets without coupling domain coordinates to a vendor type.
- `PublicIncident` is a separate immutable model from private `Incident`.
- Names can be adjusted consistently for idiomatic APIs; required semantic boundaries cannot.

- [x] Read full user request and design. Locate usable Flutter SDK; if genuinely absent, create all source and document exact pending Flutter commands. Never fabricate successful output.
- [x] Scaffold Flutter Web and robust gitignore/config. Add central theme, branding/config/guidance, Riverpod and go_router. Default to visibly labelled demo mode. Generate real Flutter boilerplate with tooling when possible.
- [x] Write failing tests for models/enum/coordinate and form validation; implement immutable models and validation. Cover NaN/infinity/ranges and JSON round-trip.
- [x] Write repository/controller tests for errors, idempotent retry, preserved draft, low accuracy/manual fallback and photo partial failure; implement demo services and the reporting controller.
- [x] Implement home/report/thank-you/public-map/admin foundation/support routes. Build draggable/tappable pin selection and optional direction/note/photo. Include a report-flow widget test with fake services (no tile network needed in tests).
- [x] Implement Firebase setup using an explicit config path (no fabricated options), repositories, auth/App Check/emulators, callable submission/moderation and controlled server-side public projection. Test public projection field allowlist, distance bounds, stable reuse, auth/validation/idempotency and rejection/retraction.
- [x] Add restrictive Firestore/Storage rules and index definitions; emulator rule tests prove exact/private/photo access denied to unauthorised clients and no client-forged writes, while intended public reads/admin access work. Bind private upload permissions to incident ownership and limits.
- [x] Add a small admin authentication gate/data interface and CSV service with privacy guard plus injection/escaping tests. Admin UI may remain minimal with exact records, status/filter/count and export seams documented.
- [x] Add PWA app shell, manifest/icons and cache exclusions; configuration/docs must explain no offline queue or successful offline submission.
- [x] Create README, durable AGENTS, all 15 requested docs, sample synthetic data and config examples. Include date 2026-10-03 decisions, phase exit criteria, cost monitoring, tile policy, draft conservation review, setup/deployment boundaries and exact test commands. Include CI analyze/test/build and Node/rules checks as practical; no deploy workflow.
- [x] Run formatting, `flutter analyze`, `flutter test`, `flutter build web --release`, Functions tests/build, emulator rule tests. Fix errors; save concise evidence with exact command, exit result, test counts and limitations to `docs/SETUP_VERIFICATION.md`. Return root a completion report, not a commit.
- [x] Root reviews code/evidence, dispatches one independent reviewer, coordinates bounded fixes, verifies final state, and creates logical initial local commits if permitted. No remote.

## Progress

- 2026-10-03: Empty project folder verified; no Git repository existed. Git initialisation requested. Flutter not on PATH; SDK search ongoing. Node 22 and Java 21 available. Firebase CLI needs isolated config because its user config is inaccessible in the sandbox.
- 2026-10-03: SDK verified at `C:\Users\admin\Documents\Flutter\flutter\bin\flutter.bat`: Flutter 3.41.1, Dart 3.11.0. External SDK cache requires elevated tool execution; no global settings changed. Firebase CLI 15.7.0 runs with task-local XDG_CONFIG_HOME. Initial documentation commit: `21c578a`. One coder owns the complete implementation.
- Root interim review sent these integration checks to the coder: form callbacks must use the current draft; submitting state must render immediately and disallow overlap; thank-you must retain incident type and photo warning; rejected/duplicate moderation must preserve the private stored public offset for reacceptance; public date must use incident date; callable input must handle null/non-object payloads. Final review must confirm these are resolved, alongside map abstraction/dragging, private photo handling and configurable server privacy radius.
- Initial root `flutter build web --release` passed (37.9s, exit 0). Browser preview at `http://127.0.0.1:18765` loaded; synthetic demo report with live-crossing type, bearing 90 and a labelled test note reached thank-you. Mobile 442px and desktop 1280px home layouts were readable; initial browser console had no warnings/errors. This was an interim build; final verification must use the corrected source.
- Browser review found default latitude -34.126 was near Masiphumelele. Use central Scarborough latitude -34.197 / longitude 18.375 (GeoNames record); keep demo GPS source honest. Further checks sent: visible demo state on direct report/thanks routes, public map attribution/date filters/repository, actual admin role gate/repository/CSV interface, generated Firebase web options consumption and App Check/emulator wiring, real emulator rule tests, correct `dart format` command, service worker registration and installable icons, ignored generated dependency directories.
- At the user's explicit request, remaining implementation ownership transferred from the stopped `foundation` coder to GPT-6.1 Sol (`sol_implementation`). Existing work retained; root reviews and verifies. Handoff is in ignored `.local/sol-handoff.md`.
- Root verified isolated Firestore + Storage emulator startup and clean shutdown (exit 0) with a demo project and local caches. Default 8080 was occupied and left untouched; isolated test ports are 18080/19199 with hub 14400/logging 14500. Startup success is not a claim that access-control tests passed.
- Independent GPT-6.1 Sol review confirmed Firebase client uploads automatically create bearer download tokens and token downloads bypass read rules. Ruling: replace direct client photo upload with a bounded Auth/App Check callable using Admin GCS storage without token metadata; deny direct Storage client writes. This corrects the original upload design to satisfy private-photo requirements. Cost if wrong: extra Function invocation/encoding overhead; verify with real emulator metadata and unauthorised download assertions. No production actions authorised.
- Review fix wave 1 assigned to the existing Sol implementation owner: photo-token boundary above; independent submission lock/immutable snapshot against map/GPS changes; photo-only retry using committed incident ID; explicit changed-payload retry conflict; preserve bearing entered before GPS and reject nonnumeric nonempty bearing. Review report is in ignored `.local/review-result.md`; same reviewer will verify corrections. Browser confirmed 390x844 manual pin interaction, corrected map centre, demo notices, conditional injured guidance, combined Alive filter and applied 2026-10-01 to 2026-10-03 date range.

- Final verification: formatter 36 files/0 changes; analyzer no issues; Flutter 20/20; TypeScript build + Node 8/8; emulator 35 rules + 30 callable/photo assertions (65), exit 0; release web build 41.6 seconds, exit 0. Root inspected preserved logs. Focused Sol 6.1 re-review resolved I1-I4/M1 with no new actionable finding. Rebuilt 390x844 UI rejected nonnumeric bearing, accepted corrected synthetic report and showed conditional guidance; no browser warnings/errors. Final application-title configuration was centralized, reanalyzed and rebuilt successfully; the home page was reloaded and confirmed after that change. Local Git commit closes this work.
