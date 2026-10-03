# Project context

## Problem

Tortoises in and around Scarborough are being struck by vehicles. There is not enough structured local data to confidently identify where and when crossings and fatalities are concentrated.

## Goal

Create a low-friction citizen reporting tool that turns individual sightings into useful geospatial evidence while keeping exact wildlife locations protected.

## Umbrella identity

The user selected **Wildlife Watch SA** on 2026-10-03. **Scarborough Tortoise Watch** remains the first local programme. Use the umbrella name for the new Firebase project; retain the tortoise pilot's current user-facing scope while completing phone/backend testing.

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

One minor usability finding remains: corrected fields keep their old validation message until resubmission. The separately authorized live Android smoke is complete: exactly two labelled synthetic manual-location reports are private/pending, with one private JPEG attached to the second. Both submissions and the upload passed real Auth/App Check verification. The public collection and phone map remain empty; the photo has no download token and unauthenticated media access returns 401. A reviewed camera/gallery selector was deployed after 24 passing Flutter tests and a successful configured release build. The gallery path was tested through the already-registered `firebaseapp.com` alias after the user approved Chrome photos/media access. Actual GPS, camera capture, installed PWA behavior and iPhone compatibility remain unverified. No report was moderated, published or deleted. Demo reports/photos remain simulated in memory with fixed public fixtures; the HTTPS Firebase app uses actual cloud data.
