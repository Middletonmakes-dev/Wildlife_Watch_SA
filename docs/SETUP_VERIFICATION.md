# Setup verification — 2026-10-03

The foundation section records local verification by the implementation agent on 2026-10-03. Those checks used no cloud project/account creation, production data, deployment or external Git mutation. Later sections distinguish phone evidence and subsequent user-authorized Firebase setup. Emulator-only authentication users and synthetic local documents were disposable. Root owns the separate final browser/review/Git evidence.

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

The photo flow was corrected after review found Firebase SDK uploads would create download tokens that bypass rules. The final implementation uses a bounded callable and token-free Admin GCS writes, with a Firestore image reservation plus storage preconditions. The Storage emulator does not faithfully enforce the GCS generation-zero condition, so the Firestore reservation independently protects replacement and is tested. At foundation verification the old non-generated options stub had been removed. The later authorized setup generated genuine ignored FlutterFire options; see `FIREBASE_SETUP.md`.

## Warnings and limits

- Build succeeded with only Flutter informational Wasm/font output and a deprecation notice for `--pwa-strategy=none`; revisit the option when upgrading. The custom worker caches only the static shell, without offline submission/runtime guarantees.
- `npm audit` reports 2 moderate upstream `gaxios`/`uuid` advisories; compatible `npm audit fix` did not resolve them. High advisories were removed by official SDK updates and a compatible patched gRPC override. Reassess dependencies before a pilot.
- App Check is intentionally bypassed only in explicit emulators. Real provider tokens/enforcement, real generated-option Firebase UI, production IAM/rules, mobile permission/camera/network behaviour and browser installability require separately authorized project/device checks.
- Public map is bounded to the latest 500 projections, with local filters. Admin provides trusted repository/CSV seams; a full sign-in/review/dashboard workflow is future work. CI was authored but has not run on GitHub.
- Concurrent different-photo uploads and a crash between object save and photoStored update were not separately scheduled as integration scenarios; transaction/hash/precondition handling exists, and focused review reported no actionable issue. No further production claim is made.

## What is included

The demo routes home, report, thank-you, public map, admin foundation and support placeholder. Models, service seams, three trusted callables, separate private/public collections, restrictive rules, indexes, isolated emulators, PWA manifest/PNG icons/shell worker, nondeploying CI and all requested context docs are present. `docs/DIRECTORY_TREE.txt` records the final project tree.

## Manual steps before a pilot

For current project setup and completed prerequisites, see `FIREBASE_SETUP.md`. Remaining public-pilot work includes trusted admin accounts/claims, private bucket IAM review, conservation wording approval, an appropriate tile provider, retention/deletion, cost alerts and support/legal decisions. Deploy only with separate explicit authority. See `DEVELOPMENT.md` and `DEPLOYMENT.md` for exact setup boundaries.


## Root review and browser evidence

Root inspected the preserved final format/analyze/Flutter/Node/emulator/build output. An independent GPT-6.1 Sol review identified four important privacy/data-integrity defects and one bearing issue; the implementation owner fixed them and the same reviewer gave a focused PASS with no remaining actionable finding. Review scope and the unforced photo failure schedules above remain explicit limitations.

The rebuilt demo was checked in the in-app browser at 390 x 844. Root dragged the manual pin, confirmed nonnumeric bearing `abc` was rejected, corrected it to `90`, submitted a clearly synthetic note, and reached the thank-you screen with the live-crossing safety guidance and explicit local-demo notice. The browser console returned no warnings or errors. Earlier checks also covered empty location rejection, injured confirmation, combined Alive filtering/date range, and desktop layout. No real location permission or real Firebase traffic was used. Temporary viewport settings were reset.

Screenshots: [demo home](screenshots/demo-home.jpg), [successful synthetic report](screenshots/demo-thanks.jpg). The local preview is served at http://127.0.0.1:18765 while the development server remains running. It uses the release build under ignored `build/web`.

The final branding-only correction routes MaterialApp.title through central AppConfig. Format (36 source/test files after removal of the unused stub), analysis, all 20 Flutter tests and the release build were rerun successfully; root reloaded and confirmed the home screen afterward. Final Git whitespace cleanup removed only trailing blank lines at EOF.

## Physical Android follow-up — 2026-10-03

Root tested the existing release on the user's already-authorized USB-connected SM-S901U (Android 12, Chrome 154.0.8037.92) via scoped ADB reverse port 18765. Core manual demo passed: missing classification/location validation, pin drag, bearing 360 rejection, corrected bearing 90 to thank-you, Alive filtering and October 1–3 date range selection. See `PHONE_TESTING.md` for screenshots, the stale-validation-message finding and exact untested capabilities. USB testing did not generate Firebase writes or real GPS collection. This follow-up changed documentation only, so the app/test/build results above are historical baseline evidence rather than reruns. Documentation diff and link checks are the proportionate verification for these edits.

## Firebase integration and release preparation — later on 2026-10-03

After the user's separate cloud-setup approval, root provisioned the project as recorded in `FIREBASE_SETUP.md`. A coder aligned all callable exports/clients/emulator URLs with Johannesburg, selected Enterprise App Check and enabled token refresh. Root reviewed the source diff and removed an unnecessary configuration wrapper and literal-only tests through a bounded coder correction. An independent read-only reviewer found no implementation blocker; deployment and live provider/device evidence remain separate gates.

Fresh final verification for this integration:

| Check | Result and ignored evidence |
|---|---|
| `dart format --output=none --set-exit-if-changed lib test` | PASS, 39 files / 0 changes; `.local/firebase-format-final.log` |
| `flutter analyze --no-pub` | PASS, no issues; `.local/firebase-region-analyze.log` |
| `flutter test --no-pub` | PASS, 21 tests; `.local/firebase-region-flutter-tests.log` |
| `npm test --prefix functions` | PASS, 9 tests and TypeScript build; `.local/firebase-node-tests.log` |
| `firebase emulators:exec --config firebase.json --only auth,functions,firestore,storage --project demo-scarborough-tortoise-watch 'node functions/test/emulator-all.cjs'` | PASS, 35 rules + 30 callable assertions; all three local endpoints `africa-south1`; `.local/firebase-emulators.log` |
| `flutter build web --release --no-pub --pwa-strategy=none -t lib/main_firebase.dart --output build/firebase-web --dart-define-from-file=.local/firebase-web-defines.json` | PASS, 47.3 seconds; `.local/firebase-release-build.log` |
| `git diff --check` | PASS |

The configured Firebase bundle contains the expected project, Johannesburg region, Enterprise provider and public site key. Ignored `firebase.json.local` selects that build and the exact Hosting site; `.local/firebase-release-manifest.json` preserves SHA-256 values for 56 release artifacts/inputs. The original `build/web` USB demo was not overwritten. Generated options, the configured entry point, define file and deployment config remain ignored.

The release build reports the existing optional Wasm dry-run incompatibility in `firebase_storage_web` and deprecated PWA-strategy notice; the JavaScript release succeeded. The independent review is saved in `.local/firebase-release-review.md`. These local checks preceded the separately authorized deployment and do not themselves prove real App Check, device or cloud behavior.

## Authorized Firebase deployment and physical Android smoke — 2026-10-03

Root deployed the reviewed rules/indexes, three named Johannesburg Functions and configured Hosting build under explicit user approval. Active rules matched exact reviewed source; both indexes were READY; all Functions were ACTIVE with exact compiled/dependency-source matches and no emulator bypass. Firestore/Storage App Check enforcement was read back. The narrow recovery of two absent Functions after a regional source-bucket conflict and the optional Artifact Registry cleanup warning are documented in `FIREBASE_SETUP.md` and `.local/firebase-deployment-commands.json`. No force flag, image cleanup, Git commit or push was performed.

The physical Android loaded the configured HTTPS app and submitted one labelled synthetic manual-pin report. The thank-you screen appeared, the report is private/pending, no public projection exists and the callable log records `app: VALID` / `auth: VALID`. No real GPS or personal photo was used. [Phone success screenshot](screenshots/android-firebase-thanks.png).

The optional-photo step exposed a camera-only picker. A coder added a source selector with test-first evidence; root and an independent reviewer found no actionable issue. Fresh format and analysis passed, all **24 Flutter tests** passed, and the configured Firebase release build passed in **47.4 seconds**. Root deployed Hosting only. Evidence: `.local/photo-choice-{red,format,analyze,tests,release-build,deploy-hosting}.log`, `.local/photo-choice-report.md`, `.local/photo-choice-review.md` and `.local/photo-choice-release-manifest.json`.

An exact downloaded-artifact match confirmed the new bundle, while its original one-hour HTTP cache explained stale client sessions. Root published reviewed revalidation headers through Hosting only; the final `main.dart.js` hash still exactly matches the built artifact and its response now carries `Cache-Control: no-cache`. Evidence: `.local/cache-header-review.md`, `.local/cache-header-deploy-hosting.log`, `.local/cache-header-hosting-readback.json`. Existing shell caches are not evicted by these headers. The fresh authorized Firebase alias visibly showed the [updated phone chooser](screenshots/android-firebase-photo-choice.png).

After the user replied `approved photo test`, root accepted Chrome photos/media permission, selected only the synthetic JPEG from Downloads and submitted the second labelled manual report once. The physical phone reached [thank-you](screenshots/android-firebase-photo-thanks.png), and its [public map remained empty](screenshots/android-firebase-empty-map.png). Final readback confirms exactly two private pending manual-pin reports, one JPEG of 17,423 bytes attached to the second report, `photoStored: true`, no download tokens and no public bucket IAM member. The anonymous media request returned 401. All three real callable requests (two submissions and one upload) logged valid App Check and Auth. Evidence: `.local/firebase-phone-summary.json`, `.local/firebase-phone-photo-privacy.json`, `.local/firebase-callable-verification-logs.json` and `.local/firebase-phone-final-check.json`.

The approved two-report/one-photo Android smoke passed. This continuation changed documentation and local evidence helpers only; the previously reviewed 24-test application build stayed deployed. No extra reports, moderation, public projection or deletion occurred. Actual GPS, camera capture, installed PWA/update behavior and iPhone remain untested. Future pilot preparation still includes trusted admin access, conservation/tile-provider decisions, retention and cost controls.
