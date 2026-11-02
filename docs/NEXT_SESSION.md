# Next session: remaining device and launch acceptance

> Git publication checkpoint (2026-11-02): the owner subsequently authorized review, commit and push. The dirty-tree/base-commit statements below describe the pre-publication context snapshot; verify current Git state. See [fresh verification](SETUP_VERIFICATION.md#git-publication-verification--2026-11-02).

## Start here — context reconciled 2026-11-02

The security implementation chain, independent review and separately authorized October 13 release are complete as recorded below. The subsequent October 14 phone session was a **limited Android smoke**, not complete release acceptance. This November refresh reconciled repository documents, saved evidence and the completed ADB/overseer chat handoffs; it did not rerun tests, access the phone or refresh live cloud state.

- Current app: `https://goodspotting.web.app/`; release config `firebase.security-release.local.json`, artifact `build/security-task8-configured`. Preserve historical build directories. The old `wildlife-watch-sa` Hosting site was not updated. Do not redeploy merely because historical notes say pending or the Functions CLI returned a post-success cleanup warning.
- Phone evidence: Samsung SM-S901U / Android 12 / Chrome 155.0.8059.39, Chrome custom tab. Home/report navigation, map tiles, Alive filtering and warm reload passed. Cached assets were not hash-matched; service-worker control is not standalone or cross-version PWA proof. Temporary ADB forward `tcp:19224` was removed; phone was left on the public map with All selected. Current connection/phone state must be rediscovered, not assumed.
- Missing-location Submit was rejected by automatic approval review because broken validation could create a production report. The command did not execute. Do not bypass the rejection; any retry needs explicit approval for the possible disposable production write, or a separately chosen local/demo check that is not presented as production evidence.
- Remaining device/auth evidence: selected-release identity, GPS/manual pin/direction, media cancellation, Google redirect/linking, App Check issuance/refresh, installed-PWA/relaunch/update, offline behavior and real iPhone checks. Finish independently authorized checks without treating unavailable-device work as passed.
- Resource CSP is report-only and strict enforcement is NOT READY. Baseline header and reserved-helper HTTP checks passed at release; they do not prove completed Google authentication. MFA/recovery, billing alerts/recipients and runtime Editor permission review remain open. No blind IAM revocation or billing/API enablement.
- Shared policy is deferred to the second-app/website trigger. No interim-policy requirement was added. Baboon-project planning and testing remain separate from this checkout; do not copy its notification or location policies here.
- Model routing now follows the October 26 owner instruction: new plans **Astra Medium**, implementation **Sol 6.1 High** directly. Preserve all dirty/untracked work on `main` at `3d6a36c`; do not use old `coder`/Medium instructions below. Commits, pushes, deployments, production writes and external configuration need exact applicable authority.

Evidence entry points: [project context](PROJECT_CONTEXT.md), [phone results](PHONE_TESTING.md), [verification record](SETUP_VERIFICATION.md), [Hosting security](HOSTING_SECURITY.md), [operations](SECURITY_OPERATIONS.md), ignored `.local/security-chain-20261013/`, `.local/security-release-20261013/` and `.local/phone-tests/security-20261014/`.

Completed chat references are retained in the local handoffs. Reuse recorded evidence; do not restart the eleven-task chain. Future action begins with current custody, relevant evidence and scope reconciliation.

## Latest release — 2026-10-13 security chain

The owner explicitly requested deployment after the eleven-task security chain and independent review. Root deployed all five reviewed Functions (`submitIncident`, `listOwnIncidents`, `withdrawIncident`, `uploadIncidentPhoto`, `setIncidentModeration`), the reviewed Firestore rules and the configured frontend to **https://goodspotting.web.app/** (also `goodspotting.firebaseapp.com`). Storage rules already matched; indexes were READY and neither needed redeployment. The older `wildlife-watch-sa` Hosting site was not changed.

Release configuration is `firebase.security-release.local.json`, with public directory `build/security-task8-configured`. This root-level copy of the Task 8 candidate preserves Firebase CLI relative-path resolution; do not deploy the historical `build/goodspotting-links-release` by accident. Baseline framing/security headers are enforced; resource CSP remains **report-only**, with known style/browser compatibility work pending.

Fresh readbacks confirm all five Functions ACTIVE with every compiled module and dependency manifest matching, maximum two instances and reviewed concurrency/timeouts, no emulator environment flag, exact Firestore/Storage rules, required indexes READY, Firestore/Storage App Check ENFORCED, and ten matching frontend asset comparisons across both Good Spotting aliases. Live header/MIME/cache checks passed for all nineteen paths on each alias, including reserved auth helpers. This establishes HTTP helper exclusions, not a successful Google sign-in flow. Backend tests passed44/44 immediately before release.

The Functions CLI returned a nonzero status only after reporting all five successful updates because Artifact Registry cleanup is unset. Readbacks verified success; deployment was not repeated and retention was not changed. Evidence is in `.local/security-release-20261013/`.

No production report/photo/moderation/withdrawal smoke, account/security/billing/IAM/TTL changes, legacy-location migration, Git publication or rollback occurred. Real-device/auth/PWA checks, resource-CSP enforcement, Google MFA/recovery, budget/recipient confirmation and scoped runtime-Editor review remain pending. Shared privacy terms remain deferred to the agreed second-app/website trigger. Earlier not-deployed entries below are historical.

## Historical handoff — 2026-10-04 Astra low

Latest release status: the user subsequently explicitly approved the reviewed index, four Functions, Hosting, Google sign-in and verified admin grant. Index deployment succeeded and the new owner index is READY. The four Functions are ACTIVE in africa-south1; deployed compiled source and dependency manifests match reviewed local files. submitIncident is unchanged. Hosting is deployed; all four main/bootstrap/index/worker hashes match build/withdrawal-release with no-cache headers. Google provider setup remains unsaved, awaiting the user's support-email choice (Google may display it on consent screens); the owner must then sign in before the verified admin claim grant. No report, photo, moderation or withdrawal test call was made. Detailed evidence is in `.local/withdrawal-admin/*readback.json`, deployed-source-verification.json and deployment logs.

Release approval checkpoint: automatic approval review rejected the attempted index deployment before execution because the user's session/model reply was considered ambiguous. No production mutation occurred. Live website and manifest hashes match the handoff; three existing Functions are ACTIVE, existing indexes READY, anonymous Auth/domains unchanged. Obtain explicit approval for the reviewed index/four-Function/Hosting release and Google/admin setup before retrying. Do not bypass the rejection through a different mechanism. Details: `.local/withdrawal-admin/release-preflight.json`.

The user asked to continue the proposed withdrawal/admin release in a new session after updating context, using Astra light (app setting: `gpt-6-astra`, reasoning `low`). Read `.local/withdrawal-admin/session-handoff.md` first for the exact user exchange, private account target, production scope, checked artifact and remaining steps. The older phone-testing sections below are historical context, not the immediate task.

Implementation and independent review are complete. The configured release is `build/withdrawal-release`, not the demo `build/web`; the current deployed artifact remains separately in `build/firebase-web`. Preserve this dirty checkout and ignored configuration. Root retains all deployment/Auth/claim operations. No production mutation for this feature has happened yet. Verify current custody and manifest hashes, then continue only the specific release/admin setup requested in the handoff. Do not restart implementation or rerun all passing checks without a material source change, failure or evidence gap.

## Goal and authority

The requested follow-up Android tests are complete: actual GPS, manual override, controlled camera capture/cancellation, PWA install, standalone navigation and relaunch passed. Initial publication to <https://github.com/Middletonmakes-dev/Wildlife_Watch_SA.git> completed at `3d6a36c7458db980c331d42e638589d0187325a5` on `main` tracking `origin/main`. The subsequent test documentation and screenshots remain local for review. Do not repeat the completed tests automatically. Remaining coverage is real iPhone Safari, a separately authorized cross-version PWA update, and optional device edge cases listed below.

This is a testing handoff. Do not repeat project provisioning, the initial deployment or the two-report/one-photo cloud smoke. That cloud-write allowance has been used completely. Do not submit more reports, upload another cloud photo, moderate, publish a marker, delete cloud data, change billing/retention, or deploy a fix without applicable new authority. Never send actual GPS or personal photos to the reporting backend merely to test device capabilities.

Read `AGENTS.md`, `PROJECT_CONTEXT.md`, `MVP_SCOPE.md`, `DECISIONS.md`, `PHONE_TESTING.md`, `FIREBASE_SETUP.md` and `SETUP_VERIFICATION.md` before acting. Use the current checkout; first inspect Git status, branch, upstream and recent commits. Preserve local test documentation and unrelated changes. Do not commit or push the continuation without applicable new authority.

## Working environment

- Repository: `C:\Users\admin\Documents\Scarborough Tortoise watch`.
- Live primary URL: <https://wildlife-watch-sa.web.app/>. The same registered Hosting app is also at <https://wildlife-watch-sa.firebaseapp.com/>; the final phone photo test used this fresh origin.
- Local default build is a separate labelled demo at `http://127.0.0.1:18765/`. A scoped USB reverse mapping was retained. Recheck the server and mapping before relying on them; do not remove other mappings.
- Android test device: Samsung SM-S901U, Android 12, Chrome 154.0.8037.92, 1080 × 2340. Discover the currently attached authorized device with ADB; do not put its serial in tracked files.
- ADB: `C:\Users\admin\AppData\Local\Android\Sdk\platform-tools\adb.exe`.
- Flutter: `C:\Users\admin\Documents\Flutter\flutter\bin\flutter.bat`; Python: `C:\Python314\python.exe`.
- Firebase CLI: `C:\Users\admin\AppData\Roaming\npm\firebase.cmd`; Google Cloud CLI: `C:\Users\admin\AppData\Local\Google\Cloud SDK\google-cloud-sdk\bin\gcloud.cmd`.
- Last observed device state: the installed PWA at home, launched from its installed launcher activity. Site location permission on `firebaseapp.com` and Chrome camera permission were returned to denied after the tests; `web.app` location remained denied. Chrome media permission from the prior approved gallery test was preserved. Recheck current state. Request owner unlock if required; do not change lock/security settings.

The saved Codex project list did not contain this checkout during handoff. A same-directory fork can retain its workspace and ignored local Firebase configuration. Keep the actual work in this repository, not a new empty directory.

## Proven baseline

- Exactly two labelled synthetic reports remain in the private `incidents` collection, both `pending` and `manual_pin`.
- The second owns one private JPEG of 17,423 bytes, with `photoStored: true`; no download token, no public bucket IAM members, and unauthenticated media access denied with 401.
- Exactly two submit requests and one photo upload logged valid Auth and App Check. Public projections are empty; the empty public map loaded on the physical Android.
- Firestore/Storage application rules match reviewed source; indexes are READY; three Node 22 callables are ACTIVE in Johannesburg (`africa-south1`). App Check is enforced. No emulator bypass is deployed.
- The photo-source selector now offers Take photo / Choose existing photo. Latest Flutter verification: 24 tests, clean format/analyze, successful configured release build. Backend baseline: 9 Node tests and 65 emulator assertions. Independent release/device review passed with no Critical/Important findings.
- Source and docs are intended for GitHub; generated Firebase options/entry point, release defines/config, builds, raw private readbacks and device identifiers stay ignored.
- The next session acquired real GPS at approximately 18 m reported accuracy, verified visible Location ready and manual override, and captured a harmless owner-prepared image locally. Camera cancellation preserved the selected image. No new report or photo was submitted. Only non-coordinate GPS metadata was retained; screenshots exclude the actual-location map.
- The installed PWA rendered home/report/empty public map in standalone mode and relaunched successfully. Its activated worker, five shell cache paths and unchanged-release update check were verified. The worker fetched on the device matched the local artifact and carried `no-cache`; this does not prove a changed-version update. No iPhone was available in the connected-device environment.

Local-only evidence: `.local/firebase-phone-final-check.json`, `.local/firebase-phone-summary.json`, `.local/firebase-phone-photo-privacy.json`, `.local/firebase-callable-verification-logs.json`, `.local/firebase-deployment-review.md`, `.local/photo-choice-release-manifest.json`, and `.local/phone-tests/next-*.json`. These are available only in this checkout and must not be added to Git. The capability test's temporary DevTools port 19222 was removed; the earlier USB demo reverse mapping remains.

## Remaining test order

1. Verify the current phone connection and app origin. Keep operations scoped to Wildlife Watch SA. When a UI dump fails, do not read an old snapshot: `.local/phone-tests/ui.py` now rejects failed dumps and supports `--wildlife-origin-only`. Do not publish unrelated account screens or personal media. ADB screenshot coordinates are native 1080 × 2340; scale coordinates if the tool resizes the displayed image.
2. Test iPhone Safari only with an actual available iPhone or an explicitly selected suitable Apple environment. Windows viewport emulation/WebKit does not prove physical iPhone behavior. Check location allow/deny and manual fallback without submission, controlled camera selection/cancellation, and Add to Home Screen/standalone relaunch. Record the actual model/iOS version. Do not record exact coordinates or personal media.
3. A cross-version PWA test requires a separately authorized changed release, with an already-installed client retained across that release. The unchanged-worker check has passed and must not be presented as cross-version proof. Do not deploy merely to clear this checklist. The existing worker lacks an explicit update/reload flow and serves its shell allowlist cache-first.
4. If requested, exercise GPS timeout/low-accuracy, landscape and weak-network behavior. Do not claim offline reporting: the app does not support it. Avoid changing broad device/network settings or capturing actual-location maps.
5. Update `PHONE_TESTING.md`, `PROJECT_CONTEXT.md` and `SETUP_VERIFICATION.md` with observed results, limitations and app-only evidence. Delegate bounded local fixes to the configured `coder` and review proportionately if a source defect is found. Root retains all device/cloud/publication authority. Do not broaden into new species, rebranding, moderation UI or unrelated features.

## Known follow-ups

- Existing sessions can retain the old JavaScript through the earlier one-hour HTTP cache. Hosting now sends `Cache-Control: no-cache` for the app entry points, but this cannot evict existing responses. The custom worker caches allowlisted HTML/shell resources, not `main.dart.js`; its update behavior still needs testing.
- Validation errors can remain visible until resubmission after a field is corrected (minor, documented; do not silently broaden this test task to fix it).
- A denied Chrome camera permission can silently return to the report form; capture worked after an explicit temporary permission. Permission-recovery guidance is a usability follow-up, not a failed camera pipeline.
- Artifact Registry cleanup is unset; this is a separate retention/cost decision, not a reason to rerun Functions deployment.
- Conservation wording, production tile-provider choice, admin access, data retention and broader public launch remain separate pilot-readiness work.

## 2026-10-04 — Withdrawal and live admin map ready locally

Owner withdrawal, Your reports, Google sign-in/account-linking and a claim-gated live exact-location admin map are implemented and independently reviewed locally. Withdrawal is terminal, deletes the public projection transactionally, and retains a private audit record. Public data remains privacy-protected. The admin view includes Pending, All active and Withdrawn audit filters, exact marker selection, Fit reports, moderation confirmations and CSV export.

Final root checks: 70 Flutter tests, clean format/analyze, 12 Functions tests, default/preview/configured release builds passed. The implementer completed 87 isolated emulator assertions. Root exercised synthetic withdrawal and live-map interactions, including an offshore fixture, and a 360x800 layout; this does not establish real-phone or production Google authentication compatibility. Independent re-review has no Critical or unresolved Important findings.

This feature is NOT DEPLOYED. The configured artifact is in build/withdrawal-release; evidence, review and scoped release preparation are in work/withdrawal-admin and ignored .local/withdrawal-admin. Live Google provider is not configured and the owner has no Firebase account yet. Next authorized release must deploy the required owner-list index, exactly listOwnIncidents/withdrawIncident/setIncidentModeration/uploadIncidentPhoto, and the configured Hosting build. Preserve submitIncident and existing rules/settings. Google provider setup, the owner's first Google sign-in, and a verified targeted admin claim grant are still required. Root retains production authority; ask for exact release/setup approval before any such mutation. Never use the demo build/web output for live Hosting.

Google provider is now enabled (management readback verified), with anonymous Auth and domains unchanged. User approved the support-email use. Remaining step: owner signs in at /#/admin, then root verifies the exact Google-linked account and grants admin:true while preserving existing claims. No admin claim has been granted yet.

Phone sign-in correction: anonymous Firebase users were wrongly displayed as Google-signed-in. Fixed and Hosting-only deployed after 71 passing Flutter tests and focused review. Live hash B07FDF858B32148E929F2474EB689DE7F513E3E5D07A9B40F85FA3C13C2CCE0D; browser now offers Sign in with Google. Owner should refresh the same phone page and sign in, preserving report ownership via linking. Target account lookup was empty before this fix; no admin grant has occurred.

### 2026-10-04 latest: phone Google callback repair ready, approval pending

The live popup sign-in returned a blank callback page on the attached Android phone. Local redirect correction links anonymous users, consumes redirect results before rendering, and surfaces errors in admin UI. Coder: 76 tests passed; independent reviewer: no Critical/Important findings. Root configured build and final analyze passed. New artifact build/admin-redirect-fix, SHA256 main.dart.js 7610CAE19489D3E271D2EEFF980BD16A7E268AF10387FAE2F298F6D8B3FAA02F. Scoped deployment config .local/withdrawal-admin/firebase.redirect-fix.json.

NOT deployed. Automatic approval review rejected saving the new Google OAuth authorized redirect URI because that exact security configuration change lacked approval. Ask approval to add only https://wildlife-watch-sa.web.app/__/auth/handler to the existing OAuth client and publish this Hosting correction. Existing firebaseapp.com handler stays. Console draft tab retained for handoff. Generated local options already have web.app authDomain, original backup ignored in .local/withdrawal-admin. Never bypass rejected save.

After exact approval, save/read back callback configuration, deploy Hosting only and verify asset hashes, then owner signs in on original phone/browser. Grant admin:true only after exact verified google.com-linked account [owner account recorded in private handoff] exists; preserve other claims. Current lookup has zero matching accounts; no claim granted. No report/test writes authorized. Local-only ADB forwarding tcp:19223 remains for read-only phone diagnostics; remove only that mapping when finished. Detailed evidence: .local/withdrawal-admin/release-result.md.

2026-10-04: User explicitly approved new web.app OAuth callback and corrected Hosting release. Saved existing OAuth client with both firebaseapp.com and web.app /__/auth/handler URLs; console confirmed OAuth client saved and reopened detail readback retained both. Other origins and secrets unchanged. Hosting-only deployment using firebase.redirect-fix.json succeeded exit0. Four live assets match configured build/admin-redirect-fix with Cache-Control:no-cache; main SHA256 7610CAE19489D3E271D2EEFF980BD16A7E268AF10387FAE2F298F6D8B3FAA02F. Evidence admin-redirect-deploy.log and admin-redirect-readback.json. Physical phone Google redirect retry and verified target account admin grant remain pending; no claim granted in this step. Google console notes settings may take 5 minutes to a few hours to propagate.

2026-10-04 admin grant completed: exact-email lookup found one enabled verified google.com-linked account. Applied admin:true preserving existing claims via accounts:update, then independent accounts:lookup confirmed emailVerified=true and admin=true. Evidence .local/withdrawal-admin/admin-grant-readback.json. User should press Check access again on phone to refresh token. No reports or moderation data changed.

Browser end-to-end sign-in verified: root in-app browser returned from Google redirect and rendered private admin map with 5 pending records. Phone claim refresh remains for user; admin grant and desktop browser access are confirmed.
