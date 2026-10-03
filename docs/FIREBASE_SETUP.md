# Wildlife Watch SA Firebase setup

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

Evidence is preserved under ignored `.local/`: `firebase-deployment-commands.json`, deployment logs, exact rules/source readbacks, `firebase-callable-verification-logs.json`, `firebase-phone-summary.json` and phone screenshots. Full private test documents and generated settings remain outside tracked documentation. No test report was moderated, made public or deleted.

The selected database and Storage region is Johannesburg (`africa-south1`), supported by [Firestore](https://firebase.google.com/docs/firestore/locations) and [second-generation Functions](https://firebase.google.com/docs/functions/locations). Local integration changes explicitly align the three Functions, Flutter Functions clients and emulator endpoints with that region.

Any later deployment must retain the repository's narrow target and verification requirements. Do not weaken rules or bypass App Check to make phone testing work.

Billing handoff completed by the user, with Blaze verified afterward. Local screenshots of the original rules and billing handoffs are saved under ignored `.local/`.

The live App Check console marks reCAPTCHA Classic deprecated and disables its registration fields. The integration uses the supported Fraud Defense / reCAPTCHA Enterprise provider with automatic token refresh. The public site key and Firebase enablement flag are in ignored `.local/firebase-web-defines.json`; generated Firebase options remain ignored. FlutterFire added public project/app metadata to tracked `firebase.json`, without credentials.

The Firebase release must use `lib/main_firebase.dart`, the ignored define file and output directory `build/firebase-web`. Ignored `firebase.json.local` selects this output explicitly and the exact Hosting site. The existing USB demo at `build/web` is preserved. No deploy command may accidentally publish that demo output as the configured app.

The configured release build passed locally in 47.3 seconds, with 21 Flutter tests, 9 Node tests and 65 emulator assertions passing. Analysis and formatting are clean. Root inspected the diff and verification evidence; an independent read-only review found no implementation blocker. See `SETUP_VERIFICATION.md` for exact commands and evidence. The prepared release and its inputs are hashed in ignored `.local/firebase-release-manifest.json`; the proposed narrow deployment/phone-smoke sequence is in `.local/firebase-release-plan.md`.

Before authorization, a read-only Functions inventory returned HTTP 403 `SERVICE_DISABLED`. Root then enabled the approved infrastructure APIs and obtained a successful empty inventory before deploying. The CLI additionally enabled its required Extensions/Eventarc infrastructure and generated service identities. No other project was changed.
