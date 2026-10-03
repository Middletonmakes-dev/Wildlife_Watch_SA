# Physical phone testing

## Current status — 2026-10-03

Intended targets are Android browsers and iPhone Safari. After first selecting same-Wi-Fi testing, the user explicitly authorized testing the USB-connected Android phone. ADB already reported it as authorized. The initial local-demo test used USB port reversal. The later, separately approved Firebase deployment is available at <https://wildlife-watch-sa.web.app/> and can be opened without USB or the PC preview.

Device: Samsung SM-S901U; Android 12; Chrome 154.0.8037.92; physical screenshot resolution 1080 x 2340. These are the device-reported values, not a desktop viewport emulation. Core manual-demo checks and the separately approved live Firebase smoke passed: two synthetic manual-location reports, one with the prepared JPEG. The corrected camera/gallery chooser, real upload, App Check/Auth verification and private storage were exercised on the phone. Actual GPS, camera capture, installed PWA launch and iPhone remain unverified.

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
| SM-S901U / Android 12 / Chrome 154.0.8037.92 | Core flow and map filters passed via USB; landscape not tested | HTTPS location denied; manual fallback passed; actual GPS untested | PASS: two private pending reports, one private JPEG, valid Auth/App Check, empty public map | Pending |
| iPhone/Safari, model/version pending | Pending | Pending | Pending | Pending |
