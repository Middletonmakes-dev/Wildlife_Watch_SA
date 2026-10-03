# Setup verification — 2026-10-03

This record describes fresh local verification by the implementation agent on 2026-10-03. No cloud project/account creation, production data, deployment or external Git mutation was used. Emulator-only authentication users and synthetic local documents were disposable. Root owns the separate final browser/review/Git evidence.

## Commands and results

| Exact final command (repository root unless noted) | Result |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test` | PASS exit 0; 36 files, 0 changed (unused ignored options stub removed) |
| `flutter analyze --no-pub` | PASS exit 0; no issues, 8.4 seconds |
| `flutter test --no-pub` | PASS exit 0; 20 tests, 0 failures |
| `npm test` in `functions/` | PASS exit 0; TypeScript build + 8 Node tests, 0 failures |
| `firebase emulators:exec --config firebase.json --only auth,functions,firestore,storage --project demo-scarborough-tortoise-watch 'node functions/test/emulator-all.cjs'` | PASS exit 0; 35 actual rules assertions + 30 callable/Auth/photo assertions = 65 |
| `flutter build web --release --no-pub --pwa-strategy=none` | PASS exit 0; final release built in 41.6 seconds, with no generated options file |

The real Windows SDK commands used `& 'C:\Users\admin\Documents\Flutter\flutter\bin\dart.bat'` / `flutter.bat`; Firebase used `firebase.cmd`, Node package tests used `npm.cmd`. Flutter 3.41.1, Dart 3.11.0, Node 22.23.1, Java 21 and Firebase CLI 15.7.0 were available. Dependency resolution via `flutter pub get` and official npm installs completed successfully.

Exact preserved output is in ignored `.local/final-format.log`, `final-analyze.log`, `final-flutter-tests.log`, `final-node-tests.log`, `final-emulators.log` and `final-build.log`. Tests use an in-memory tile provider, so widget verification makes no map network request. Rules denial logs in emulator output are expected assertions, not failures. Emulators shut down cleanly after the final run. No unrelated occupied service was stopped.

## Regression and privacy evidence

- Domain/model/enum validation and serialization; nonfinite/ranged coordinates; type/location requirements; optional note/bearing bounds; Firebase fail-closed startup without options; JPEG dimension and GPS EXIF removal.
- Controller draft preservation/idempotent retry, independent in-flight lock, mutation/GPS callback races, delayed GPS failure, manual precedence, optional photo failure, and photo-only recovery without resubmitting the core.
- Widget home→report→explicit pin drag→classification/bearing/note→thanks, with nonnumeric bearing entered before location rejected; synthetic mode and same-direction draft guidance stay visible.
- Real Firestore/Storage rules: private reads/listing/writes denied to anonymous/reporters, public projections readable, client public/private writes denied even to admins, admin/analyst exact/private-photo reads allowed, direct uploads/overwrites/listing denied.
- Actual Functions/Auth/Firestore/Storage integration: null/array/forged fields, missing Auth, UID cooldown, concurrent identical requests, changed-payload retry rejection, protected moderation, correct coarse occurrence date, stable reaccept projection, server JPEG/size/pixel validation, owner checks, token-free GCS metadata, no unauthenticated media/token read, EXIF removal and immutable/same-image photo retry.

The photo flow was corrected after review found Firebase SDK uploads would create download tokens that bypass rules. The final implementation uses a bounded callable and token-free Admin GCS writes, with a Firestore image reservation plus storage preconditions. The Storage emulator does not faithfully enforce the GCS generation-zero condition, so the Firestore reservation independently protects replacement and is tested. The existing ignored non-generated `firebase_options.dart` stub was moved to `.local/firebase_options.previous-stub.dart`; no generated options or fabricated credentials remain in `lib/`.

## Warnings and limits

- Build succeeded with only Flutter informational Wasm/font output and a deprecation notice for `--pwa-strategy=none`; revisit the option when upgrading. The custom worker caches only the static shell, without offline submission/runtime guarantees.
- `npm audit` reports 2 moderate upstream `gaxios`/`uuid` advisories; compatible `npm audit fix` did not resolve them. High advisories were removed by official SDK updates and a compatible patched gRPC override. Reassess dependencies before a pilot.
- App Check is intentionally bypassed only in explicit emulators. Real provider tokens/enforcement, real generated-option Firebase UI, production IAM/rules, mobile permission/camera/network behaviour and browser installability require separately authorized project/device checks.
- Public map is bounded to the latest 500 projections, with local filters. Admin provides trusted repository/CSV seams; a full sign-in/review/dashboard workflow is future work. CI was authored but has not run on GitHub.
- Concurrent different-photo uploads and a crash between object save and photoStored update were not separately scheduled as integration scenarios; transaction/hash/precondition handling exists, and focused review reported no actionable issue. No further production claim is made.

## What is included

The demo routes home, report, thank-you, public map, admin foundation and support placeholder. Models, service seams, three trusted callables, separate private/public collections, restrictive rules, indexes, isolated emulators, PWA manifest/PNG icons/shell worker, nondeploying CI and all requested context docs are present. `docs/DIRECTORY_TREE.txt` records the final project tree.

## Manual steps before a pilot

Generate real options with FlutterFire and create the ignored explicit entry point; enable anonymous Auth and App Check; provision trusted admin accounts/claims; review private bucket IAM and the default Functions bucket; obtain conservation wording approval; choose a production tile provider; establish retention/deletion, cost alerts and support/legal decisions; then deploy only with separate explicit authority. See `DEVELOPMENT.md` and `DEPLOYMENT.md` for exact setup boundaries.


## Root review and browser evidence

Root inspected the preserved final format/analyze/Flutter/Node/emulator/build output. An independent GPT-6.1 Sol review identified four important privacy/data-integrity defects and one bearing issue; the implementation owner fixed them and the same reviewer gave a focused PASS with no remaining actionable finding. Review scope and the unforced photo failure schedules above remain explicit limitations.

The rebuilt demo was checked in the in-app browser at 390 x 844. Root dragged the manual pin, confirmed nonnumeric bearing `abc` was rejected, corrected it to `90`, submitted a clearly synthetic note, and reached the thank-you screen with the live-crossing safety guidance and explicit local-demo notice. The browser console returned no warnings or errors. Earlier checks also covered empty location rejection, injured confirmation, combined Alive filtering/date range, and desktop layout. No real location permission or real Firebase traffic was used. Temporary viewport settings were reset.

Screenshots: [demo home](screenshots/demo-home.jpg), [successful synthetic report](screenshots/demo-thanks.jpg). The local preview is served at http://127.0.0.1:18765 while the development server remains running. It uses the release build under ignored `build/web`.

The final branding-only correction routes MaterialApp.title through central AppConfig. Format (36 source/test files after removal of the unused stub), analysis, all 20 Flutter tests and the release build were rerun successfully; root reloaded and confirmed the home screen afterward. Final Git whitespace cleanup removed only trailing blank lines at EOF.
