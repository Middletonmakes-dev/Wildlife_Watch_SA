# Next session: remaining physical-device tests

## Goal and authority

The user requested a new session to perform the next tests after the successful Android Firebase photo smoke, and authorized linking/pushing this project to <https://github.com/Middletonmakes-dev/Wildlife_Watch_SA.git>. Continue the remaining device checks: actual GPS, camera capture, Android home-screen/PWA launch and update behavior, then iPhone Safari if a suitable device is available.

This is a testing handoff. Do not repeat project provisioning, the initial deployment or the two-report/one-photo cloud smoke. That cloud-write allowance has been used completely. Do not submit more reports, upload another cloud photo, moderate, publish a marker, delete cloud data, change billing/retention, or deploy a fix without applicable new authority. Never send actual GPS or personal photos to the reporting backend merely to test device capabilities.

Read `AGENTS.md`, `PROJECT_CONTEXT.md`, `MVP_SCOPE.md`, `DECISIONS.md`, `PHONE_TESTING.md`, `FIREBASE_SETUP.md` and `SETUP_VERIFICATION.md` before acting. Use the current checkout; first inspect Git status, branch, upstream and recent commits. Preserve unrelated changes. The current session owns initial Git publication; the new session must not repeat it automatically.

## Working environment

- Repository: `C:\Users\admin\Documents\Scarborough Tortoise watch`.
- Live primary URL: <https://wildlife-watch-sa.web.app/>. The same registered Hosting app is also at <https://wildlife-watch-sa.firebaseapp.com/>; the final phone photo test used this fresh origin.
- Local default build is a separate labelled demo at `http://127.0.0.1:18765/`. A scoped USB reverse mapping was retained. Recheck the server and mapping before relying on them; do not remove other mappings.
- Android test device: Samsung SM-S901U, Android 12, Chrome 154.0.8037.92, 1080 × 2340. Discover the currently attached authorized device with ADB; do not put its serial in tracked files.
- ADB: `C:\Users\admin\AppData\Local\Android\Sdk\platform-tools\adb.exe`.
- Flutter: `C:\Users\admin\Documents\Flutter\flutter\bin\flutter.bat`; Python: `C:\Python314\python.exe`.
- Firebase CLI: `C:\Users\admin\AppData\Roaming\npm\firebase.cmd`; Google Cloud CLI: `C:\Users\admin\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd`.
- Last observed device state: the live empty public map in Chrome. Location was denied on both Hosting origins, Chrome media permission was explicitly approved and granted, and camera permission was not granted. Recheck current state. Request owner unlock if required; do not change lock/security settings.

The saved Codex project list did not contain this checkout during handoff. A same-directory fork can retain its workspace and ignored local Firebase configuration. Keep the actual work in this repository, not a new empty directory.

## Proven baseline

- Exactly two labelled synthetic reports remain in the private `incidents` collection, both `pending` and `manual_pin`.
- The second owns one private JPEG of 17,423 bytes, with `photoStored: true`; no download token, no public bucket IAM members, and unauthenticated media access denied with 401.
- Exactly two submit requests and one photo upload logged valid Auth and App Check. Public projections are empty; the empty public map loaded on the physical Android.
- Firestore/Storage application rules match reviewed source; indexes are READY; three Node 22 callables are ACTIVE in Johannesburg (`africa-south1`). App Check is enforced. No emulator bypass is deployed.
- The photo-source selector now offers Take photo / Choose existing photo. Latest Flutter verification: 24 tests, clean format/analyze, successful configured release build. Backend baseline: 9 Node tests and 65 emulator assertions. Independent release/device review passed with no Critical/Important findings.
- Source and docs are intended for GitHub; generated Firebase options/entry point, release defines/config, builds, raw private readbacks and device identifiers stay ignored.

Local-only evidence: `.local/firebase-phone-final-check.json`, `.local/firebase-phone-summary.json`, `.local/firebase-phone-photo-privacy.json`, `.local/firebase-callable-verification-logs.json`, `.local/firebase-deployment-review.md`, and `.local/photo-choice-release-manifest.json`. These are available only in this checkout and must not be added to Git.

## Test order

1. Verify the current phone connection and app origin. Keep operations scoped to Wildlife Watch SA. When a UI dump fails, do not read an old snapshot: `.local/phone-tests/ui.py` now rejects failed dumps and supports `--wildlife-origin-only`. Do not publish unrelated account screens or personal media. ADB screenshot coordinates are native 1080 × 2340; scale coordinates if the tool resizes the displayed image.
2. Test GPS in the existing HTTPS app without submitting the resulting draft. Check the permission flow, successful location acquisition if available, accuracy feedback and manual fallback. Do not store exact device coordinates in Git, screenshots or logs. If a step would disclose live location to an external recipient beyond the authorized device test, explain that data flow and obtain the required specific permission first. Denied-location fallback has already passed and need not be repeatedly tested without a reason.
3. Test camera selection and cancellation locally using a harmless, controlled test target. Ask the owner to point the camera at that target if needed; do not capture personal surroundings. Do not upload a second cloud photo. Gallery selection/upload has already passed.
4. Test Android Add to Home screen/install and standalone launch, navigation, relaunch and the actual update behavior. Do not claim offline report submission: the app does not support it. Preserve the user's other tabs/apps and settings.
5. Test iPhone Safari only with an actual available iPhone or an explicitly selected suitable Apple environment. Windows viewport emulation/WebKit does not prove physical iPhone behavior. If no device is available, finish Android checks and record the exact iPhone blocker and a concise owner checklist.
6. Update `PHONE_TESTING.md`, `PROJECT_CONTEXT.md` and `SETUP_VERIFICATION.md` with observed results, limitations and app-only evidence. Delegate bounded local fixes to the configured `coder` and review proportionately if a source defect is found. Root retains all device/cloud/publication authority. Do not broaden into new species, rebranding, moderation UI or unrelated features.

## Known follow-ups

- Existing sessions can retain the old JavaScript through the earlier one-hour HTTP cache. Hosting now sends `Cache-Control: no-cache` for the app entry points, but this cannot evict existing responses. The custom worker caches allowlisted HTML/shell resources, not `main.dart.js`; its update behavior still needs testing.
- Validation errors can remain visible until resubmission after a field is corrected (minor, documented; do not silently broaden this test task to fix it).
- Artifact Registry cleanup is unset; this is a separate retention/cost decision, not a reason to rerun Functions deployment.
- Conservation wording, production tile-provider choice, admin access, data retention and broader public launch remain separate pilot-readiness work.
