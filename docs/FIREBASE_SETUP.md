# Wildlife Watch SA Firebase setup

## Current release pointer — reconciled 2026-11-02

The Firebase project remains `wildlife-watch-sa`; the public Good Spotting site is `https://goodspotting.web.app/` and its `firebaseapp.com` alias. The separately approved October 13 security release deployed five Functions, Firestore rules and `build/security-task8-configured` through `firebase.security-release.local.json`. Source/options, rules, assets and baseline/report-only headers were read back successfully. Storage already matched and indexes were READY; the older `wildlife-watch-sa` Hosting site was unchanged. See [current handoff](NEXT_SESSION.md) and `.local/security-release-20261013/` for exact dated evidence.

This context refresh did not perform live checks or a deployment. Historical commands/builds below are not instructions to redeploy. Actual phone authentication/App Check and installed-PWA acceptance, strict resource-CSP enforcement, MFA/budget readiness and runtime least privilege remain separate gates. The October 14 Android smoke is documented in [PHONE_TESTING.md](PHONE_TESTING.md).

## GPS feedback and review clarification — 2026-10-04

After the owner reported an unresponsive GPS button and a missing public-map marker, device inspection found Chrome blocking this site's location permission. The existing feedback could fall below the map on a small phone. Feedback now appears immediately beside the location controls, and the complete permission/location workflow has a 15-second deadline with guards preventing late permission results from starting another request. Manual pin selection remains available. Successful live submissions explicitly explain that saved reports await review before an approved, location-obscured projection appears publicly.

Focused regression tests failed before the fixes and passed afterward. All 58 Flutter tests, format, analysis and the configured release build passed; independent review reported no findings. Root published only Hosting using `firebase deploy --only hosting --project wildlife-watch-sa --config firebase.json.local --non-interactive`. The live bundle returned HTTP 200 with `Cache-Control: no-cache`; SHA-256 `AA20F9B937C612056974F6ED50DD4037189EC6EFD5DA101972C71336CEB5E82C` exactly matched the prepared release. Evidence is under ignored `.local/gps-feedback-fix/` and local `work/location-fix/`.

Scoped production metadata confirmed the 08:58 SAST photo report has a stored private JPEG and remains pending review, without a public projection. No report was moderated or otherwise changed. Following the owner's explicit permission to allow location, root rechecked Chrome and found the site already displayed **Location allowed**, so no permission toggle was necessary. Root did not request GPS or submit a report, and opened the updated live app for the owner's next test. Actual GPS acquisition on this updated release remains an owner check.

## Firefox startup correction — 2026-10-04

The owner reported the generic Firebase setup error in a normal Firefox tab after the Fynbos release. The application queried `Firebase.apps` before initializing the web SDK. In the installed `firebase_core_web` 2.24.1, that getter tolerates only an uninitialized error containing the Chromium-specific text `of undefined`; Firefox can throw different wording before SDK scripts load. Bootstrap now calls `Firebase.initializeApp(options: options)` directly, allowing FlutterFire to load its SDK first and reuse a matching default app. Generated-options checks and App Check enforcement remain unchanged.

A regression test with a fresh-browser platform double reproduced the reported setup failure before the change, then passed with one initialization call and no premature app-list access. All 50 Flutter tests, analysis, format and the configured release build passed; independent focused review found no issues. Root published the correction through the same Hosting-only release workflow. The live main bundle returned HTTP 200 with `Cache-Control: no-cache` and SHA-256 `89E7092930457A39D3A968285F80850C13609DE7F70DE55069F60443FC976AAF`, matching the prepared artifact.

Root opened a fresh live navigation in the attached phone's normal Firefox browser (`org.mozilla.firefox`) and verified the Fynbos home screen without the setup error. Firefox privacy settings were not changed, browser storage was not cleared, and no GPS, photo or report submission was performed. Evidence is under ignored `.local/firefox-startup-fix/`; regression and verification logs are in `work/startup-fix/`. The phone remains on the live Firefox page. This verifies startup, not every Firefox reporting capability.

## Fynbos Hosting update — 2026-10-04

The user explicitly approved publishing the prepared Fynbos version for testing. Root verified all 41 prepared artifact hashes and the exact Hosting site/output, then ran `firebase deploy --only hosting --project wildlife-watch-sa --config firebase.json.local --non-interactive`. Hosting published 40 files successfully (the hidden build marker is excluded). Functions, Firestore/Storage rules, indexes and cloud reports were not changed by this release. No commit or push accompanied it.

The configured release includes the two-screen report, optional direction wheel with the physical-touch fix, closer report zoom, automatic direction mode after successful GPS, and requested caption removals. All 49 Flutter tests, analysis and both demo/configured builds passed before release; focused review had no outstanding findings. Live HTTP 200 readbacks of the app bundle, bootstrap, index, worker, asset manifest, font and image matched the prepared SHA-256 hashes. App bundle, bootstrap, index and worker retained `Cache-Control: no-cache`. The deployed main bundle SHA-256 is `12921C31765DB8DE27E90298352639A32B8FDE7ED8ACFCAF8857EE68433CC6E6`.

Root opened `https://wildlife-watch-sa.web.app/` on the attached Samsung phone and verified the new Fynbos home without a demo banner or illustration caption. The phone remains on that live page for owner testing. This release check did not acquire GPS, change permissions, select media or submit a report; iPhone and changed-release installed-PWA checks remain unverified. Deployment log, prepared/published manifest, exact live readbacks and the phone screenshot are under ignored `.local/fynbos-launch/`. Earlier evidence below describes previous releases.

## Initial provisioning on 2026-10-03

The user authorized creating and configuring the Firebase project in their browser and selected the umbrella name **Wildlife Watch SA**.

- Project ID: `wildlife-watch-sa`.
- Console: <https://console.firebase.google.com/project/wildlife-watch-sa/overview>.
- Project creation completed and the project dashboard is accessible.
- Created on the no-cost Spark plan, with Google Analytics and Gemini integration toggled off in the creation wizard.
- Firebase Authentication initialized; the Anonymous sign-in provider shows **Enabled**. Automatic deletion of anonymous accounts was not enabled.
- Default Firestore database provisioned in Standard edition, location **`africa-south1` (Johannesburg)**. The data page shows an empty database and the confirmed location. The Rules page shows `allow read, write: if false;` for all documents. Scheduled backups were not enabled.
- Registered **Wildlife Watch SA Web**. The project overview confirms one Web App with that name. Registration reported a console polling error, so the existing app was verified after refreshing instead of repeating the registration.
- The user completed the billing-account link; Firebase now visibly reports **Blaze / Pay as you go**.
- Default Storage bucket `wildlife-watch-sa.firebasestorage.app` created in **AFRICA-SOUTH1**, Standard access frequency, with initial deny-all client rules. The bucket is empty and its Rules page confirms `allow read, write: if false;`.
- Official FlutterFire CLI generated ignored `lib/firebase_options.dart` for the existing registered web app; root copied the ignored `lib/main_firebase.dart` from the example. Project ID, app ID and Storage bucket match the live project. No credentials were fabricated.
- The user explicitly approved reCAPTCHA Enterprise activation and App Check registration under Google Cloud terms. Root enabled the Enterprise API, created the score-based **Wildlife Watch SA Web** key, and registered the web app with App Check. The console shows **Registered**; token TTL is 1 hour and the risk threshold is 0.5.
- The key permits only `wildlife-watch-sa.web.app` and `wildlife-watch-sa.firebaseapp.com`. Domain verification is enabled. Localhost, testing scores, challenge mode, AMP and WAF integration were not enabled.
- App Check **Enforced** is confirmed for both Firestore and Storage. The console warns propagation can take up to 15 minutes. Authentication App Check remains unenforced (preview); callable Functions require App Check in application code outside emulators.
- The existing default Hosting site was verified by the CLI as `https://wildlife-watch-sa.web.app`. No application was deployed there.

## Web Google redirect sign-in lifecycle

The configured Firebase entry point uses the FlutterFire web redirect flow. After Firebase setup completes, the app consumes the pending redirect result once before the widget tree can create an anonymous reporting account. An anonymous current user is linked with Google so the existing UID and report ownership remain intact; a credential conflict is shown in the admin screen and does not sign out or replace that user.

The generated web options must use the same-origin Hosting domain as `authDomain`, and the Google OAuth client must authorize the matching handler URI, including the required path: `https://wildlife-watch-sa.web.app/__/auth/handler`. The generated options and console/OAuth changes remain local release setup owned by the root agent.

## Authorized first deployment on 2026-10-03

The user explicitly approved publishing the prepared app, enabling required Functions infrastructure, deploying reviewed rules/indexes and all three named Functions, then submitting two synthetic Android reports and one synthetic JPEG. Root retained all cloud and device mutations. The public HTTPS site is now live at <https://wildlife-watch-sa.web.app/>. The separate USB loopback preview remains the original demo.

- All 56 prepared artifact/input hashes matched before release. Git remained on `main` at `520d617`, with the intentional local changes preserved and no commit or push.
- Firestore and Storage application rules were deployed separately. Authenticated REST readbacks confirmed exact source equality with the reviewed local files. Both Firestore indexes reached **READY**.
- App Check API readbacks confirm **ENFORCED** for Firestore and Storage.
- `submitIncident`, `uploadIncidentPhoto` and `setIncidentModeration` are **ACTIVE**, Node.js 22, in `africa-south1`. Every deployed source archive matched the five compiled JavaScript files and both dependency manifests. No runtime `FUNCTIONS_EMULATOR=true` bypass is configured.
- The initial Functions attempt hit a 409 creating its regional source bucket; only the photo Function was created. Root read the bucket, inventory and operations, confirmed no operation remained pending, then deployed only the two absent Functions. No working Function was redeployed during recovery.
- The second Functions command reported successful creates but exited 1 because optional Artifact Registry cleanup was not configured. Active-state/source readbacks establish deployment success independently. No force flag or image-deletion policy was applied; retained build images can incur storage charges.
- Hosting successfully published 38 files from `build/firebase-web` using the explicit `wildlife-watch-sa` site in ignored `firebase.json.local`.
- The attached Android phone loaded the HTTPS app without a demo notice. Its first synthetic manual-pin report reached thank-you and is stored privately with moderation status `pending`; public projections remain empty. The server verification log records `app: VALID` and `auth: VALID`.

The optional-photo test exposed a pre-existing camera-only picker. A reviewed correction now offers Take photo or Choose existing photo. Format and analysis passed, all 24 Flutter tests passed, and the configured release built successfully in 47.4 seconds. Root deployed only Hosting for this correction. The user then approved the photo test and Android's additional Chrome photos/media permission. Root selected only `wwsa-synthetic-test.jpg` from Downloads, submitted the second labelled manual-pin report once and reached thank-you. Final readback confirms exactly two private pending reports, one JPEG (17,423 bytes), the second report's `photoStored: true`, no download tokens, no public bucket IAM members and no public projection. An unauthenticated photo GET was denied with 401; both submit calls and the photo upload logged valid Auth and App Check. The phone's public map showed no markers. Real GPS and camera capture were not used; the location prompt was denied for this manual test. Installed PWA and iPhone testing remain outstanding.

The original Hosting response cached `main.dart.js` for one hour, so existing sessions retained the older picker. Root verified that the live JavaScript bytes exactly matched the new local artifact, then applied reviewed `Cache-Control: no-cache` headers to `/`, `/index.html`, `/main.dart.js`, `/flutter_bootstrap.js` and `/service-worker.js` through a Hosting-only configuration publish. The final header and exact artifact hash were read back. Existing HTTP caches cannot be evicted remotely, and the shell worker still caches its allowlisted HTML; this is not a claim of a complete PWA update strategy. The fresh, already-registered `https://wildlife-watch-sa.firebaseapp.com/` alias visibly shows the new chooser on the phone without clearing its browser data.

A later no-submission device session passed GPS acquisition/manual override, controlled camera capture/cancellation, PWA installation, standalone navigation and relaunch against that alias. The device's current worker and unchanged-release update check passed; cross-version updates and iPhone remain unverified. See `PHONE_TESTING.md`. This follow-up made no deployment or cloud report/photo write.

Evidence is preserved under ignored `.local/`: `firebase-deployment-commands.json`, deployment logs, exact rules/source readbacks, `firebase-callable-verification-logs.json`, `firebase-phone-summary.json` and phone screenshots. Full private test documents and generated settings remain outside tracked documentation. No test report was moderated, made public or deleted.

The selected database and Storage region is Johannesburg (`africa-south1`), supported by [Firestore](https://firebase.google.com/docs/firestore/locations) and [second-generation Functions](https://firebase.google.com/docs/functions/locations). Local integration changes explicitly align the three Functions, Flutter Functions clients and emulator endpoints with that region.

Any later deployment must retain the repository's narrow target and verification requirements. Do not weaken rules or bypass App Check to make phone testing work.

Billing handoff completed by the user, with Blaze verified afterward. Local screenshots of the original rules and billing handoffs are saved under ignored `.local/`.

The live App Check console marks reCAPTCHA Classic deprecated and disables its registration fields. The integration uses the supported Fraud Defense / reCAPTCHA Enterprise provider with automatic token refresh. The public site key and Firebase enablement flag are in ignored `.local/firebase-web-defines.json`; generated Firebase options remain ignored. FlutterFire added public project/app metadata to tracked `firebase.json`, without credentials.

The Firebase release must use `lib/main_firebase.dart`, the ignored define file and output directory `build/firebase-web`. Ignored `firebase.json.local` selects this output explicitly and the exact Hosting site. The existing USB demo at `build/web` is preserved. No deploy command may accidentally publish that demo output as the configured app.

The configured release build passed locally in 47.3 seconds, with 21 Flutter tests, 9 Node tests and 65 emulator assertions passing. Analysis and formatting are clean. Root inspected the diff and verification evidence; an independent read-only review found no implementation blocker. See `SETUP_VERIFICATION.md` for exact commands and evidence. The prepared release and its inputs are hashed in ignored `.local/firebase-release-manifest.json`; the proposed narrow deployment/phone-smoke sequence is in `.local/firebase-release-plan.md`.

Before authorization, a read-only Functions inventory returned HTTP 403 `SERVICE_DISABLED`. Root then enabled the approved infrastructure APIs and obtained a successful empty inventory before deploying. The CLI additionally enabled its required Extensions/Eventarc infrastructure and generated service identities. No other project was changed.

## 2026-10-05 — Tortoise marker Hosting release

Following explicit owner deployment approval, root built the Firebase entry point with existing production defines into build/tortoise-markers-release and deployed Hosting only using firebase.markers.local.json to wildlife-watch-sa. Deployment exited 0. Live HTTP 200 readbacks of main.dart.js, bootstrap, index and the tortoise SVG matched the release SHA-256 hashes. Main bundle: 8857217D5439AF728B88E028BBDC21A4D2B19C73FF42EF2D9398A224D19D02AB. Evidence: work/tortoise-markers/firebase-build.log, deploy.log and live-readback.json. Local verification: 78 Flutter tests, clean analysis/format, successful demo and configured release builds. No Functions, rules, data, Auth settings or Git publication changed. Physical-device visual verification remains separate.

## 2026-10-05 — Home photograph and mission Hosting release

After explicit owner approval to deploy the non-payment changes, root built the configured Firebase entry point with the existing production defines into `build/home-content-release`. Hosting-only deployment used `firebase.home.local.json` and explicit project/site `wildlife-watch-sa`; it exited 0. The real tortoise photo, removed tagline and hotspot mission statement are live. Payments remain disabled; no Functions, rules, Auth settings, report data or Git publication changed.

Live HTTP 200 readbacks of main.dart.js, bootstrap, index, service worker and the new JPEG exactly matched the prepared release hashes. Main bundle SHA-256: `DFD96A75EDD0FB005EE6E5ED56B4819F7A6EA237823F6CAAB09B6D1107B57002`. Existing no-cache headers were retained. Evidence: `work/home-release/build.log`, `deploy.log`, and `live-readback.json`. The preceding local checks passed formatting, analysis, 78 Flutter tests and the demo release build; the configured production build also passed. This readback does not claim physical-device visual verification.

## 2026-10-07 — Good Spotting identity and address

The owner selected **Good Spotting** as the umbrella name and explicitly requested **https://goodspotting.web.app/**. The existing Firebase project remains `wildlife-watch-sa`; Scarborough Tortoise Watch remains the first programme. Root created the additional Hosting site `goodspotting`, added its `web.app` and `firebaseapp.com` domains to Firebase Auth and the existing reCAPTCHA Enterprise domain allowlists, and cloned `wildlife-watch-sa:live` to `goodspotting:live`. Existing domains and reCAPTCHA domain enforcement were preserved. The previous URL remains operational.

This is an address change using the existing live release, not a rebuild of the dirty checkout or a complete in-app rebrand. Future Hosting releases intended for the new public address must explicitly target site `goodspotting`; older local deployment configurations still target `wildlife-watch-sa`. Browser sessions, anonymous report ownership and installed PWAs are origin-specific and do not automatically transfer to the new address. No reports, photos, Functions or database rules were changed. Domain readback evidence is under ignored `.local/goodspotting/`.

## 2026-10-07 — Good Spotting visible header

At the owner's request, the shared JournalBrand header now reads Good Spotting (Good in ink, Spotting in rust), replacing Wildlife Watch / SA. Root built the configured Firebase entry point into `build/goodspotting-release` and deployed Hosting only to site `goodspotting` using `firebase.goodspotting.local.json`. Build and deploy exited successfully; the live browser visually displays the requested header. The old Hosting site was not republished. Evidence: `.local/goodspotting/header-live.png` and `header-readback.json`. No backend, rules, report or photo mutations were performed.

## 2026-10-13 — Prepared logo and external-link release (not deployed)

The approved Good Spotting logo/SnapScan/main-website change is implemented locally. Configured production build: `build/goodspotting-links-release`; Hosting-only configuration: `firebase.goodspotting-links.local.json`, explicitly targeting `goodspotting`. Verification: existing suite plus destination/failure tests passed (80 tests), four focused link/narrow-layout checks passed after SVG fill normalization, final analysis clean, configured release build passed. The 320px layout and enlarged-text tests are automated Flutter checks, not physical-phone evidence. No payment was made; no backend or production data was modified. Deployment awaits explicit owner approval for this release. The main website source remains unchanged.

## 2026-10-13 — Owner-authorized Good Spotting logo and links publication

After the owner explicitly said “publish”, root verified the prepared main bundle SHA-256 `75D041AD5E3E249EA712F610E9B50C1D88ED989C8CF1FBF07B8678A5B6840E93` and published only Hosting using `firebase.goodspotting-links.local.json` to site `goodspotting` in project `wildlife-watch-sa`. Firebase reported successful release and exit 0. This supersedes the preceding not-deployed checkpoint. No backend, security rules, payment transaction, main-website publication, commit or push was performed.
Live readback returned HTTP 200 for main.dart.js, bootstrap, index and logo; all four SHA-256 hashes exactly matched the prepared release. Evidence: `.local/goodspotting-links/live-readback.json`.
