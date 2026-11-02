# Project context

> Git publication checkpoint (2026-11-02): the owner subsequently authorized review, commit and push. The dirty-tree/base-commit statements below describe the pre-publication context snapshot; verify current Git state. See [fresh verification](SETUP_VERIFICATION.md#git-publication-verification--2026-11-02).

## Current continuation — reconciled 2026-11-02

**Good Spotting** is the current umbrella brand; **Scarborough Tortoise Watch** is this programme. The primary app is <https://goodspotting.web.app/> (also `goodspotting.firebaseapp.com`); Firebase project ID remains `wildlife-watch-sa`. The older `wildlife-watch-sa` Hosting site was not updated by the security release. Anonymous browser identities are origin-specific; do not clear browser data or switch origins assuming report ownership will transfer.

The eleven-task security chain completed its authorized local scopes in separate GPT-6.1 Sol High sessions under GPT-6 Astra Medium oversight. The independent cumulative review reported no Critical/Important/Minor implementation findings. Recorded October 13 verification includes 44 Node tests, 168 emulator assertions, 92 Flutter tests, clean analysis, isolated builds and zero production dependency advisories at that time. These are dated results, not a new November test run or a guarantee of current advisory status. Evidence: `.local/security-chain-20261013/progress.md` and `cumulative-review.md`.

Following separate owner approval, the October 13 release deployed all five Functions, Firestore rules and the configured frontend. Exact source/options, rule and asset readbacks passed; Storage already matched and indexes were READY. The release uses `firebase.security-release.local.json` and `build/security-task8-configured`. Baseline browser security headers are enforced; resource CSP remains report-only. See [next session](NEXT_SESSION.md), [Firebase setup](FIREBASE_SETUP.md) and `.local/security-release-20261013/`. No live cloud readback was repeated during this context update.

Implemented protections include transactional UID/incident/aggregate admission, bounded photo decoding with immutable retries and withdrawal checks, explicit callable capacity, bounded public lists and memory-only public-page caching. Newly generated public projections use 100–250 m displacement and a seven-day publication eligibility delay; existing stored projections remain stable. Direct Firestore public reads still have no request-frequency limit. Withdrawal retains the private record/photo. Optional public gateway and analyst-role redesign were not implemented.

The October 14 Android smoke passed home/report navigation, map loading, Alive filtering and warm reload on Samsung SM-S901U / Android 12 / Chrome 155.0.8059.39 in a Chrome custom tab. It did not match the phone's cached assets to release hashes or prove installed-PWA, sign-in, token-refresh or iPhone behavior. The validation submit tap was blocked by automatic approval review because a defect could create a real report; do not bypass or repeat it without specific authorization. No report/photo was submitted. See [phone testing](PHONE_TESTING.md) and `.local/phone-tests/security-20261014/handoff.md`.

**Remaining acceptance:** selected-release identity on the phone; GPS/manual pin/direction/media checks; Google sign-in and App Check issuance/refresh; installed-PWA/relaunch/update and physical iPhone evidence; resource-CSP style/wrapper compatibility before enforcement; Google MFA/recovery and budget/recipient verification; separately scoped least-privilege review of the shared Functions runtime service account's recorded Editor role. Deployment is complete as documented, but community-launch clearance is not recorded. Exact remaining boundaries are in [security operations](SECURITY_OPERATIONS.md) and [Hosting security](HOSTING_SECURITY.md).

**Shared privacy policy remains deferred** to completion of the second app and its website launch, per the owner. [Preparation inventory](SHARED_PRIVACY_PREPARATION.md) is internal, not published terms. This update does not establish that the trigger has occurred or change either project's scope.

**Custody and routing:** local Git remains on `main` at `3d6a36c7458db980c331d42e638589d0187325a5`, with substantial preserved dirty/untracked work. No commit, push, deployment, device operation or production mutation was made by this context refresh. Under the owner's October 26 preference, all new implementation/design plans originate with **GPT-6 Astra Medium**, and implementation runs directly on **GPT-6.1 Sol High**. Earlier Medium/Luna/coder routing in historical notes is superseded. Use independent read-only review where required. New chats and external mutations still require their applicable user authority; the earlier security-chain permission is not blanket authority for new work.

Read this section and the current top of `NEXT_SESSION.md` first. The sections below preserve dated history; their old setup, not-deployed and model-routing statements are not current instructions.

## Historical continuation — 2026-10-04

Release update: after explicit user approval, owner withdrawal/Your reports/live-admin frontend and four backend Functions were deployed. Owner index READY; Functions ACTIVE; deployed source and Hosting asset hashes verified. Google provider remains unsaved pending consent-screen support-email choice; admin account sign-in and verified claim grant remain to complete. See the latest NEXT_SESSION.md entry. Older not-deployed wording below describes the pre-release checkpoint.

Read the current section at the top of `NEXT_SESSION.md` before older baseline/device notes below. The Fynbos UI and GPS feedback are already live. Owner withdrawal, Your reports and the protected live exact-location admin map are implemented, tested and independently reviewed locally, but not deployed. Current source is intentionally dirty on main at `3d6a36c7458db980c331d42e638589d0187325a5`; preserve all prior work and ignored Firebase configuration.

The user requested continuing the proposed release/admin setup in a new session after updating context, using Astra with low reasoning. The exact approval exchange and bounded release instructions are recorded in the ignored `.local/withdrawal-admin/session-handoff.md`. This does not authorize unrelated production writes, testing submissions, moderation, publication to Git, or cleanup. Local evidence: 70 Flutter tests, 12 Functions tests, 87 isolated emulator assertions reported by the implementer, successful release builds, and independent re-review with no Critical or unresolved Important findings. Consult the scoped manifest/checklist rather than rebuilding or repeating all tests without a change or evidence gap.

## Problem

Tortoises in and around Scarborough are being struck by vehicles. There is not enough structured local data to confidently identify where and when crossings and fatalities are concentrated.

## Goal

Create a low-friction citizen reporting tool that turns individual sightings into useful geospatial evidence while keeping exact wildlife locations protected.

## Umbrella identity

The owner selected **Good Spotting** on 2026-10-07, superseding the earlier Wildlife Watch SA brand. **Scarborough Tortoise Watch** remains the first local programme. Keep the existing Firebase project ID `wildlife-watch-sa`; do not provision or rename infrastructure merely to match the brand.

## Initial focus

- Geography: Scarborough, Cape Town, South Africa
- Species: tortoises
- Primary users: local residents and authorised conservation/data administrators

## Future possibility

The user intends possible expansion across South Africa, including leopard toads, caracals and a live map of baboon activity/incursions. These are future programmes, not implemented capabilities. The MVP remains Scarborough- and tortoise-specific; no generic multi-tenant platform is being built now. Future species and live-map work must define appropriate location visibility and freshness/expiry separately from historical conservation records.

## Initial success

Residents use it, reports take seconds, coordinates support useful analysis, exact locations stay private and clean exports can support credible external analysis.

## Supported devices and current handoff — 2026-10-03

Repository destination: <https://github.com/Middletonmakes-dev/Wildlife_Watch_SA.git>, branch `main`. The user authorized linking and pushing the reviewed project, then starting a new session for the remaining device tests. Read [NEXT_SESSION.md](NEXT_SESSION.md) for the exact continuation, existing evidence and limits. Reconcile live local/upstream state when the new session begins; do not repeat initial cloud provisioning or its completed test writes.

The intended audience includes Android browser users and iPhone Safari users. No App Store or Play Store installation is required for the website. Inexpensive Android phones are a performance priority, not a platform restriction. Core Android flows have physical-device evidence; iPhone remains untested.

The local foundation is recorded in commits `21c578a` and `520d617`. See `SETUP_VERIFICATION.md` for baseline and subsequent verification evidence. Following explicit user approval, the Firebase app is live at <https://wildlife-watch-sa.web.app/>. Project `wildlife-watch-sa` has anonymous Auth, Johannesburg Firestore/Storage, reviewed restrictive application rules, ready indexes, three active Johannesburg callable Functions and Enterprise App Check enforced for Firestore/Storage and required by the callables. The user completed the Blaze billing link. Genuine FlutterFire options and the explicit Firebase entry point are generated locally and ignored. Deployment and source readbacks are recorded in `FIREBASE_SETUP.md`; no commit or push accompanied deployment.

The user authorized testing their USB-connected Android phone after initially confirming same-Wi-Fi access. The phone was already authorized for ADB. Root connected Chrome through `adb reverse` to the PC's loopback preview and verified the core manual-demo flow on Samsung SM-S901U / Android 12 / Chrome 154.0.8037.92: required-field validation, draggable pin, invalid bearing rejection, corrected report to thank-you, Alive filtering and a date range. The temporary LAN server was stopped; loopback preview/USB mapping remain available while the cable and PC stay connected. See `PHONE_TESTING.md` and its physical-device screenshots.

One minor usability finding remains: corrected fields keep their old validation message until resubmission. The separately authorized live Android smoke is complete: exactly two labelled synthetic manual-location reports are private/pending, with one private JPEG attached to the second. Both submissions and the upload passed real Auth/App Check verification. The public collection and phone map remain empty; the photo has no download token and unauthenticated media access returns 401. A reviewed camera/gallery selector was deployed after 24 passing Flutter tests and a successful configured release build. The gallery path was tested through the already-registered `firebaseapp.com` alias after the user approved Chrome photos/media access. No report was moderated, published or deleted. Demo reports/photos remain simulated in memory with fixed public fixtures; the HTTPS Firebase app uses actual cloud data.

The subsequent testing session verified actual Android GPS (approximately 18 m reported accuracy), visible Location ready feedback and manual override, controlled camera capture plus cancellation preserving the selection, and PWA installation/standalone home-report-map navigation and relaunch. No additional report or photo was submitted. Site location and Chrome camera permissions were returned to denied afterward; the installed PWA remains on the phone. The denied camera path initially returned silently to the form, so permission-recovery guidance remains a usability follow-up. The active shell worker and unchanged-release update check were verified on the device, but cross-version updates, forced GPS timeout/low accuracy, weak-network behavior and iPhone compatibility remain unverified. See `PHONE_TESTING.md` for bounded evidence. Initial Git publication is complete at `3d6a36c`; this continuation leaves its documentation/evidence changes local for review.

## Current public address — 2026-10-07

The umbrella name is now **Good Spotting**, selected by the owner, and the new public address is **https://goodspotting.web.app/**. The Firebase project ID remains `wildlife-watch-sa`. Root copied the current live Hosting release to the new `goodspotting` site and retained the original URL. Future releases must explicitly target `goodspotting`; see `FIREBASE_SETUP.md` for domain configuration and origin-specific session limitations. This address change does not rebuild or publish unrelated local work.
