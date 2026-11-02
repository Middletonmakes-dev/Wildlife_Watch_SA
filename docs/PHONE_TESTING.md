# Physical phone testing

## Android live smoke — 2026-10-14

Physical Samsung SM-S901U, Android 12, Chrome 155.0.8059.39; foreground Chrome CustomTabActivity at `https://goodspotting.web.app/`. This was a custom tab, not standalone PWA mode. Latest documented deployment is the 2026-10-13 security release; this smoke did not independently match the phone's cached assets to release hashes.

PASS: home rendered; native ADB taps opened report categories and Crossing road's location step; map tiles finished loading; Back retained the category selection and returned home. Public map loaded approximate sightings; Alive removed the red marker while retaining green markers. A normal warm reload rendered the public map again, reset the filter to All, and reported a controlling service worker. The initially blank report map was transient, not established as a defect.

PENDING: missing-location submission validation (automatic approval review blocked the submit tap because a validation defect could create a production report); GPS, manual-pin/direction interaction, media cancellation, account flows, App Check issuance/refresh, console/CSP diagnostics, standalone relaunch, cross-version update, offline and iPhone checks. No release-wide security acceptance is implied. No report/photo submission, account change, permission change, deployment or source fix was performed.

App screenshots and the scoped diagnostic helper are in ignored `.local/phone-tests/security-20261014/`; see its `handoff.md`. The completed ADB chat confirms temporary forward `tcp:19224` was removed and the phone was left on the public map with All selected. No exact GPS was acquired. Resource CSP enforcement remains NOT READY as previously documented. The November 2 context reconciliation checked this saved handoff/final response; it did not reconnect the phone or establish its current state.

## Security resource-policy preparation — 2026-10-13

Task 8 adds desktop-browser evidence only. Historical phone results below do not certify the new security changes/CSP; no physical phone was tested in this task. Resource policy remains report-only, with unresolved stylesheet reports; enforcement is **NOT READY**. See `HOSTING_SECURITY.md` for exact artifact pairing and diagnostic limits.

| Flow | Local Chrome evidence | Android on selected release/policy | Physical iPhone Safari on selected release/policy |
|---|---|---|---|
| Cold home/CanvasKit | Configured and labelled demo home rendered; CDN/font requests observed. Style report remains. | Pending | Pending; device unavailable |
| Warm load/worker | Worker controlled reload; meaningful warm render/update not established. | Pending | Pending |
| GPS allow/deny/timeout/manual pin | No GPS acquired; report interaction unverified. | Pending | Pending |
| Camera/gallery/cancel | No media selected/uploaded. | Pending | Pending |
| Public map/filters/refresh | Direct-path fixture did not establish hash-routed map; no filter claim. | Pending | Pending |
| Firebase/App Check initial/refresh | SDK/reCAPTCHA GETs observed; APIs/provider POST blocked, valid token/refresh unverified. | Pending | Pending |
| Google redirect/anonymous link | No sign-in/link/account creation; alternate wrapper/auth-helper compatibility unverified. | Pending | Pending |
| Standalone PWA/relaunch/cross-version update | Local worker control is insufficient proof. | Pending | Pending |
| Weak network/offline | Not exercised. | Pending | Pending |
| Main website/SnapScan links | Source destinations retained; navigation/payment not exercised. | Pending | Pending |

The 412×915 desktop viewport and synthetic accessibility activation are fixture mechanisms, not device evidence. Future device checks identify exact artifact/header release, device/OS/browser, flow and result. Production writes, account/linking, permission/settings changes and publication require applicable explicit authority; synthetic demo checks remain distinct. Shared privacy terms stay deferred as requested.

## Chrome location feedback correction — 2026-10-04

The owner reported that Use my location did nothing in Chrome on the attached Samsung, although it worked on another phone. Root's site-permission inspection showed **Location blocked**, consistent with the denied state retained after earlier permission testing. After the owner explicitly authorized allowing location, a fresh inspection already showed **Location allowed**; root did not toggle an already-allowed permission or request a position. Evidence: `work/location-fix/location-permission-control.png` (earlier blocked control) and `work/location-fix/permission-current-panel.png` (allowed state).

The Hosting correction places pending/error feedback above the map beside the location controls and bounds the whole GPS/permission workflow to 15 seconds. The live thank-you message now explains moderation before public-map visibility. All 58 Flutter tests, analysis, format and the configured build passed; independent review found no issues, and the deployed bundle hash matched the prepared release (see `FIREBASE_SETUP.md`). Root opened the updated live home in Chrome for owner testing without acquiring GPS, selecting media or submitting data. Successful GPS acquisition on this release remains unverified until the owner tests it.

## Firefox startup correction — 2026-10-04

The owner reported a setup error in a normal Firefox tab on the attached Samsung phone. A browser-specific pre-initialization Firebase app-list check was removed and regression-tested. After a Hosting-only correction, root opened a fresh live page in `org.mozilla.firefox` and verified the Fynbos home rendered successfully. No privacy/permission settings or browser data were changed, and no GPS, media or report submission was exercised. See `FIREBASE_SETUP.md` and ignored `.local/firefox-startup-fix/firefox-live-home.png`. The phone is left on this live Firefox page. Broader Firefox capability tests remain separate.

## Fynbos local-demo check — 2026-10-04

Following separate explicit approval, root published the prepared Hosting-only update and opened the live `https://wildlife-watch-sa.web.app/` home on the attached Samsung phone. The new Fynbos design and absence of the demo banner were verified; exact live-file hashes matched the release. The owner can now test the live flow. Root did not request GPS, change permissions, select media or submit another report during this publication check. See `FIREBASE_SETUP.md` for the release evidence; the local preparation details below remain historical.

Later refinements on the same date increased the report-map default to zoom 17 (public map remains 14) and removed the visible illustration caption and conservation draft notice. The refreshed USB preview is explicitly built with `DEMO_DEVICE_GPS=true`, enabling the resident to request actual GPS by tapping Use my location while report/photo storage remains local. Ordinary demo builds still disable GPS by default. Agent checks did not tap GPS, grant permissions or collect a device location; successful GPS-to-wheel behavior and retry/manual-race handling have automated coverage. The revised Flutter suite passes 49 tests, with clean analysis and successful demo and configured Firebase release builds. The configured release has been prepared locally, not deployed.

The attached physical Samsung SM-S901U (Android 12, Chrome 154.0.8037.92; 1080 × 2340 display, 360 × 649 CSS browser viewport) was tested through USB reverse on `http://127.0.0.1:18768/`. This used the credential-free `build/fynbos-preview` release and synthetic manual locations. It is separate from the older deployed UI and Firebase evidence below.

Home and incident choices rendered readably. Missing-location submission was blocked; confirming a manual point cleared that error and revealed the direction wheel. Skip direction displayed its skipped state, Back preserved the chosen incident, Roadkill retained the location while hiding direction, and local demo submission reached Thank you. The scoped runtime monitor recorded no warning, error or exception events.

The first native touch drags exposed a wheel/page-scroll conflict missed by desktop checks: the arrow kept its initial angle while the page scrolled. A regression test reproduced the failure. The wheel now owns gestures beginning within its bounds and tracks one pointer; cancellation releases it, while swipes outside still scroll. After rebuilding, native drags turned the arrow south and east with the map, pin and page position unchanged. Skip and demo submission were checked again. Format, analysis, all 41 Flutter tests and the release build passed; focused independent review found no blocking defect. An optional coverage gap remains for direct invocation of the unchanged semantic increase/decrease callbacks.

Local screenshots and logs are under `work/fynbos-phone/`, including `fixed-drag-south.png`, `fixed-drag-east.png`, `fixed-outside-scroll.png`, `fixed-skipped.png`, `fixed-thanks.png`, `drag-red.log`, `full-tests.log`, `analyze.log` and `build.log`. No real GPS, camera/gallery, production submission, deployment, commit or push was performed. Human completion time under twenty seconds, iPhone compatibility, landscape and changed-release PWA behavior remain unverified.

## Current status — 2026-10-03

Intended targets are Android browsers and iPhone Safari. After first selecting same-Wi-Fi testing, the user explicitly authorized testing the USB-connected Android phone. ADB already reported it as authorized. The initial local-demo test used USB port reversal. The later, separately approved Firebase deployment is available at <https://wildlife-watch-sa.web.app/> and can be opened without USB or the PC preview.

Device: Samsung SM-S901U; Android 12; Chrome 154.0.8037.92; physical screenshot resolution 1080 x 2340. These are the device-reported values, not a desktop viewport emulation. Core manual-demo checks and the separately approved live Firebase smoke passed: two synthetic manual-location reports, one with the prepared JPEG. A subsequent no-submission session also passed actual GPS acquisition, manual override, controlled camera capture/cancellation, PWA installation, standalone navigation and relaunch. Cross-version updates and iPhone remain unverified.

## Retained Android USB demo connection

With the PC-only preview on port 18765 running and the phone already authorized for Android debugging, use the selected device serial returned by `adb devices -l`:

```powershell
adb -s DEVICE_SERIAL reverse tcp:18765 tcp:18765
```

Open `http://127.0.0.1:18765/` in Chrome on the connected phone. This explicit USB mapping forwards the phone's port to the PC preview, so Wi-Fi is not required. Keep USB connected and the PC/server awake. The temporary LAN server on port 18766 was stopped after USB testing; the loopback server and scoped USB mapping remain available for continued testing.

To remove only this mapping when finished:

```powershell
adb -s DEVICE_SERIAL reverse --remove tcp:18765
```

Never use `reverse --remove-all` or stop another project's ADB server. Do not record the phone serial in versioned documentation. If a future device says unauthorized, its owner must approve the normal device prompt; this session did not need a new approval.

### Observed core smoke results

- Home and report screens loaded with explicit demo notices; portrait scrolling and keyboard entry were usable.
- Submitting without classification showed Choose what happened. Selecting Alive / crossing road without touching the pin then showed Confirm the location.
- Dragging the pin updated the map and showed Manual location selected.
- Bearing `360` was rejected with the expected range message. Correcting it to `90` allowed a photo-free demo report to reach Thank you with same-direction safety guidance and the local-demo notice.
- Public map showed synthetic alive and roadkill markers. Alive filtering removed the roadkill marker. The horizontally scrolling filter row exposed the date control; selecting October 1–3, 2026 and saving applied the range.
- Evidence: [physical Android thank-you](screenshots/android-report-thanks.png), [physical Android filtered map](screenshots/android-map-filter.png). Other local screenshots remain under ignored `.local/phone-tests/`.

Minor finding: validation feedback is only refreshed on the next submit. After selecting a missing location or correcting an invalid bearing, its earlier red message remains visible temporarily. Submission succeeds with corrected data. A small future validation-feedback change should clear or revalidate stale field errors and include a regression test. No application code was changed during this initial demo test.


## Stage 1 — Same-Wi-Fi manual demo

This checks usability without creating cloud data. The current demo deliberately uses manual location rather than GPS. Core submissions are simulated in memory, optional photo upload is a no-op and public markers are fixed synthetic fixtures. Submitted demo reports do not appear on the public map. Reloading is not a persistence test.

On the PC, keep the existing release build and serve only its public output. Use the verified Wi-Fi IPv4 address in place of `LAN_IP`; do not bind to an unrelated VPN adapter or serve the repository root:

```powershell
python -m http.server 18766 --bind LAN_IP --directory 'C:\Users\admin\Documents\Scarborough Tortoise watch\build\web'
```

Keep that server running and the PC awake. On the phone, join the same Wi-Fi, open Chrome on Android or Safari on iPhone, and enter `http://LAN_IP:18766/`. Use the live address supplied in the chat, since DHCP addresses can change. The PC-only `http://127.0.0.1:18765/` link cannot reach this PC from the phone.

Walk through these checks with clearly synthetic content:

1. Confirm the home page and visible Demo mode notice load. Check text and buttons in portrait and landscape.
2. Open Report a tortoise. Select an incident type and attempt to submit before choosing a pin: it should ask you to confirm location.
3. Tap the map or drag the pin. Confirm Manual location selected appears; try scrolling the page without unintentionally moving the pin.
4. Select Alive / crossing road, enter optional bearing `90` and note `Synthetic phone test`. Submit without a photo. Expect a thank-you page and same-direction safety guidance, with the local-demo notice.
5. Start another report using Injured. Try invalid bearing `abc` or `360`: it must be rejected. Correct it or leave it empty and continue.
6. Optionally choose a non-sensitive test image. Check that selection/processing completes and that cancelling the picker leaves the form usable. Record any HEIC/HEIF or large-photo failure; do not assume every phone format is supported. This verifies local processing only, not server upload or camera capture support.
7. Open View sightings map. Try Alive, Injured, Roadkill and a date range. Markers are synthetic and the public view must never offer private notes/photos or exact source coordinates.

After the first successful load, report the phone model/OS/browser and any failure with the step number and message shown. Capture a screenshot only if useful and keep real people, personal photos and genuine wildlife locations out of test evidence.

### If the link does not open

Check the exact `http://` URL, current PC address, server process and same-Wi-Fi connection. Guest Wi-Fi/client isolation or a VPN may prevent device-to-device access. A successful HTTP response from the PC does not prove the phone can reach it.

If Windows Firewall blocks the connection, inspect the actual block before changing settings. Do not disable the firewall or add router port forwarding. Any necessary temporary inbound rule should be confined to this test port and the phone/local subnet, use the correct network profile, and be removed when no longer needed. Do not blindly change a Public network to Private.

Stop the temporary phone server with Ctrl+C in its terminal, or stop its recorded task session. Keep the separate loopback preview running if still useful. No public tunnel, deployment or external account is needed for this stage.

## Stage 2 — Secure context and actual device capabilities

LAN HTTP is not a secure context merely because the phone shares the PC's Wi-Fi. Browser geolocation and service workers require a secure context, normally HTTPS; the localhost exception applies on the device running the browser. See [MDN geolocation](https://developer.mozilla.org/en-US/docs/Web/API/Geolocation/getCurrentPosition) and [MDN service workers](https://developer.mozilla.org/en-US/docs/Web/API/Service_Worker_API/Using_Service_Workers).

For the current USB reverse setup, phone Chrome sees a loopback origin, which browsers treat as potentially trustworthy; this is the localhost exception, unlike LAN HTTP. This can support a later GPS capability check without public hosting, but the current demo still deliberately skips GPS.

For shared-network or remote testing, use a separately agreed HTTPS test environment with a normally trusted certificate. Do not bypass a certificate warning as the test setup. Keep development services and real data private. An HTTPS page also needs appropriately secured/accessible backend endpoints; pointing it at plain HTTP emulators can introduce mixed-content and local-network permission failures.

Changing transport to HTTPS does not change demo behavior. The current app selects device GPS only in configured Firebase mode. Follow `DEVELOPMENT.md` for genuine generated options and an explicit backend/emulator configuration; do not fabricate options. If a GPS-only demo is desired before Firebase, that is a separate small code change with a clear local-only privacy contract.

Then verify location allowed/denied/timeout/low-accuracy cases, manual fallback, real photo upload failure and retry, actual private record storage, accepted-only public projection, weak-network recovery and home-screen/PWA launch. Use disposable synthetic reports and an explicitly authorized test backend. No production writes or deployment are authorized by this guide.

## iPhone testing from Windows

The official [Apple Simulator](https://developer.apple.com/documentation/safari-developer-tools/installing-xcode-and-simulators) is part of Xcode on macOS. [Playwright WebKit](https://playwright.dev/docs/browsers#webkit) and its device profiles can supplement Windows testing, but are not a complete iPhone/Safari environment. A physical iPhone or a separately chosen real-device service is needed for device-specific Safari, photo, keyboard and permission evidence. Do not label iPhone support as verified until its checks are recorded.

## Device result record

The `wildlife-watch-sa` backend and HTTPS application were deployed with separate explicit user approval; see `FIREBASE_SETUP.md`. The approved cloud smoke is complete with exactly two clearly labelled synthetic manual-location reports and one synthetic JPEG. Both reports are private/pending, with valid Auth/App Check and no public projection. Exact GPS collection, moderation/publication and deletion remained outside this test.

The live phone run denied location access and used synthetic manual map points. Both reports reached the real thank-you page. Final cloud readback confirms exactly two private pending manual-pin reports and one JPEG of 17,423 bytes owned by the second report, whose `photoStored` is true. The two submit calls and single upload log valid Auth and App Check. The photo carries no Firebase download token; an unauthenticated media GET returned 401, and bucket IAM has no `allUsers` or `allAuthenticatedUsers` member. The public collection is empty, and the phone map showed no test markers. Earlier desktop map checks showed no console warnings/errors.

The photo step exposed a camera-only picker. A small reviewed fix now offers Take photo / Choose existing photo; three new widget tests cover both source routes and cancellation, bringing the Flutter suite to 24. The configured build and Hosting-only publish passed. The existing `web.app` session retained the old bundle under its previous one-hour HTTP cache, so root used the already-registered `firebaseapp.com` alias without clearing browser data. Root then deployed and read back revalidation headers for future app-bundle fetches. This does not evict existing browser or shell-worker caches.

Android's gallery route requested Chrome access to photos/media. Root initially declined and asked separately; the user then replied `approved photo test`. Root accepted the permission and selected only `wwsa-synthetic-test.jpg` from Downloads. No personal file was selected or uploaded. Chrome media permission is now granted; camera permission was not granted, and location remained denied. The approved quota of two reports and one photo is exhausted: no additional report, moderation or deletion is implied by this result.

Screenshots: [photo report thank-you](screenshots/android-firebase-photo-thanks.png), [empty live phone map](screenshots/android-firebase-empty-map.png). Raw private documents, object metadata, verification logs and other device evidence remain ignored under `.local/`. The test helper was hardened to reject failed/stale UI dumps after one stale snapshot caused navigation confusion; only verified app screens are retained in this document.

| Device/browser | Manual demo | GPS/permissions in secure context | Real submission/photo | PWA launch |
|---|---|---|---|---|
| SM-S901U / Android 12 / Chrome 154.0.8037.92 | Core flow and map filters passed via USB; landscape not tested | Denied fallback passed; subsequent approved GPS acquired a fix at approximately 18 m accuracy; manual override passed | PASS: two private pending reports, one private JPEG, valid Auth/App Check, empty public map; subsequent camera capture/cancel passed without upload | Installed, standalone home/report/map navigation and launcher-entry relaunch passed; cross-version update pending |
| iPhone/Safari, model/version pending | Pending | Pending | Pending | Pending |

## Android capability continuation — 2026-10-03, after Git publication

Root began on clean `main` tracking `origin/main` at `3d6a36c7458db980c331d42e638589d0187325a5`. The user requested the new testing session and separately confirmed a harmless camera target and permission for the GPS test after being told that OpenStreetMap receives tile requests for the viewed area. The live `firebaseapp.com` origin was verified before device interaction. ADB drove the physical device; scoped Chrome DevTools readbacks supplemented screenshots. No viewport emulation was used.

| Check | Observed result |
|---|---|
| PWA installation | Chrome offered Install; the installed WebAPK's verified domain matched `wildlife-watch-sa.firebaseapp.com`. |
| Standalone routes and relaunch | Home, report and the empty public map rendered without Chrome's address bar. Android reported `SameTaskWebApkActivity`; runtime `display-mode: standalone` and secure context were true. Relaunch through the installed launcher activity returned to home. |
| Camera permission and capture | Initial attempts returned to the form while Chrome's camera permission was denied with `USER_FIXED`. Root changed the permission to Ask every time, accepted Only this time, opened the native camera, captured the owner-prepared harmless dark target and accepted it. After processing, the form showed Photo selected. |
| Camera cancellation | Opening Take photo again and pressing Android Back returned to the form with Photo selected preserved. The selected image was not submitted or uploaded. |
| GPS | Root temporarily allowed location for this origin through Chrome site controls. The app's real geolocation call succeeded once, reporting approximately 18 m accuracy. The rendered form showed Location ready. Tile-resource count increased from 16 to 34 after the fix; coordinates and tile URLs were not recorded. |
| Manual override | Tapping the report map after GPS changed the visible status to Manual location selected. The draft was left unsubmitted. |
| Worker/current update check | The device's worker was activated, with no waiting/installing worker before or after an explicit update check against the unchanged release. Its downloaded SHA-256 matched the local release worker, and the response carried `Cache-Control: no-cache`. Cache `tortoise-watch-shell-v2` contained only the five allowlisted shell paths. This does not prove a cross-version update. |
| Runtime inspection | Scoped DevTools inspections returned no warning/error log entries or runtime exceptions. This is a bounded observation, not a complete network/console trace of every preceding interaction. |

The initial denied camera path provided no visible recovery instruction; enabling the system permission resolved capture. Record this as a usability limitation rather than a camera-capture failure. No application source was changed in this session. GPS timeout and low-accuracy rendering were not forced, landscape/weak-network/offline scenarios were not exercised, and no iPhone was available in the connected-device test environment.

At completion, the site's location access and Chrome camera permission were returned to denied, the PWA remained installed and open at home, and the temporary DevTools forwarding port was removed. The earlier USB demo mapping was preserved. Relaunch cleared the unsent in-memory draft. No new report/photo callable, moderation, cloud-data deletion, deployment, commit or push was performed in this continuation.

Local-only evidence (excluded from Git): `docs/screenshots/android-gps-ready.png`, `docs/screenshots/android-camera-selected.png`, and `docs/screenshots/android-pwa-home.png`. Ignored evidence includes `.local/phone-tests/next-gps-evidence.json`, `next-pwa-runtime-evidence.json`, `next-pwa-relaunch-evidence.json`, `next-final-location-permission.json` and the manual-override screenshot. Exact coordinates, personal media and device serials are excluded from the published documentation.

Remaining owner/device checks: on an actual iPhone, open the live link in Safari, test location allow/deny and manual fallback without submitting, test a harmless camera image and cancellation, then Add to Home Screen and relaunch. Record the model/iOS version and observed result. Cross-version PWA updates need a separately authorized changed release and an existing installed client; an unchanged-worker check cannot substitute for that test.
