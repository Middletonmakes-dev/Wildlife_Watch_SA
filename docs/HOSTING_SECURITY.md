# Hosting security preparation

The versioned root `firebase.*.local.json` files contain public Hosting deployment settings, despite their historical `.local` suffix. They contain no credentials. Generated artifacts and raw verification evidence remain ignored; use the release pair below when reconciling the deployed snapshot.

## Release status — reconciled 2026-11-02

The Task 7/8 preparation below was subsequently deployed under separate owner approval on October 13. The released pair is **`firebase.security-release.local.json` + `build/security-task8-configured`**, targeting `goodspotting`; do not use the older preparation artifact as the release default. Baseline security/framing headers are enforced and the resource policy is **report-only**. Nineteen-route checks on each Good Spotting alias passed, including reserved-helper exclusions. The older `wildlife-watch-sa` Hosting site was not changed. Evidence: `.local/security-release-20261013/` and [NEXT_SESSION.md](NEXT_SESSION.md).

Strict resource enforcement remains NOT READY: style/runtime-wrapper compatibility and actual auth/device flows are unresolved. The October 14 Android custom-tab smoke did not certify those flows or match cached assets to release hashes. No November live/browser checks were run for this context update. Below, “missing” live headers and references to `build/goodspotting-links-release` describe the pre-release preparation snapshot, not the later released state.

Prepared locally on 2026-10-13 under security remediation Task 7. Production deployment remains separately authorized. Current live headers, local configuration validation and browser fixture evidence are different kinds of evidence.

## Release source and route coverage

The maintained release configuration is `firebase.goodspotting-links.local.json`: project `wildlife-watch-sa`, Hosting site `goodspotting`, public directory `build/goodspotting-links-release`. `firebase.json` remains the foundation/demo configuration targeting `build/web`; it is not the current release header source. Other local release configurations and legacy Hosting site remain untouched. A new release must preserve the intended artifact and explicitly name its site. Publishing `goodspotting` does not publish `wildlife-watch-sa`.

Prepared application responses have these headers:

| Header | Value |
|---|---|
| Content-Security-Policy | `frame-ancestors 'none'; object-src 'none'; base-uri 'self'` |
| X-Frame-Options | `DENY` |
| X-Content-Type-Options | `nosniff` |
| Referrer-Policy | `strict-origin-when-cross-origin` |
| Permissions-Policy | `geolocation=(self), camera=(self), microphone=(), payment=(), usb=()` |

Firebase matches headers against the original request path before rewrites. The existing `**` rewrite can serve the app shell on unknown URLs. Astra approved two disjoint header sources: `/` and `/!(__){,/**}`. The extglob matches a nonempty first path segment other than exactly `__`, followed by either nothing or a slash and remaining path. It covers known application routes, unknown fallback routes, trailing slashes, assets and near-prefix paths such as `/__example`. The entire reserved `/__/` namespace (and `/__`) receives no application baseline headers. This prevents blanket `DENY`/`frame-ancestors 'none'` from being assigned to Firebase's embeddable auth helpers. No competing header-key override is used.

The framing headers also appear on static application assets; they do not restrict fetching scripts, WASM or images. Existing no-cache rules for `/`, `/index.html`, `/main.dart.js`, `/flutter_bootstrap.js` and `/service-worker.js` remain unchanged. There is no new HSTS value, COOP or COEP. Task 8 resource report-only preparation and compatibility gates are recorded below.

Sources: [Firebase Hosting header matching and extglob](https://firebase.google.com/docs/hosting/full-config#headers), [Firebase redirect sign-in guidance](https://firebase.google.com/docs/auth/web/redirect-best-practices), [CSP frame-ancestors specification](https://w3c.github.io/webappsec-csp/#directive-frame-ancestors). Framing protection uses response headers; report-only policy or an HTML meta tag does not establish it.

## Observed pre-release live state — 2026-10-13

Read-only checks on 2026-10-13 covered ten routes on each origin below. Each returned HTTP 200 without changing sign-in state or submitting data.

| Origin | Role | Baseline currently deployed | Custom domains |
|---|---|---|---|
| `https://goodspotting.web.app` | Current public address | Missing | None returned by site API |
| `https://goodspotting.firebaseapp.com` | Same site, separate browser session | Missing | Same site |
| `https://wildlife-watch-sa.web.app` | Legacy address and configured authDomain | Missing | None returned by site API |
| `https://wildlife-watch-sa.firebaseapp.com` | Legacy alias | Missing | Same site |

All four origins currently return platform HSTS `max-age=31556926; includeSubDomains; preload`. That is observed existing platform behavior, not a new project policy. Root/index/JS/worker return `no-cache`; tested SPA paths return `max-age=3600`; `/__/auth/iframe` and `/__/auth/handler` return HTML with `max-age=1800`. Tested paths did not redirect to another origin. There are no custom domains to infer from a marketing link.

Fresh read-only Firebase Auth authorized-domain inventory includes the four origins plus localhost. Generated local web options still have `authDomain: wildlife-watch-sa.web.app`. Historical release evidence records Google OAuth authorized handler URIs at `https://wildlife-watch-sa.web.app/__/auth/handler` and `https://wildlife-watch-sa.firebaseapp.com/__/auth/handler`; current OAuth console callbacks were not independently re-read. Domain allowlisting alone does not prove that a new same-origin authDomain has a matching OAuth callback. Current helper HTTP responses do not prove a complete redirect flow after a new header release.

Sanitized evidence is local under `.local/security-chain-20261013/task-7/origin-inventory.json`; it contains no tokens, private reports or OAuth client secrets.

## Verification commands

From repository root, with Node and the existing Firebase CLI installed:

```powershell
node scripts/verify_hosting_headers.mjs
node scripts/verify_hosting_headers.mjs --base-url https://goodspotting.web.app
node scripts/verify_hosting_headers.mjs --base-url https://goodspotting.web.app --inventory
```

Local configuration checks use the installed Firebase CLI's `superstatic` matcher. Set `FIREBASE_TOOLS_DIR` or pass `--firebase-tools-dir <absolute CLI package directory>` if its location differs from the usual Windows global npm directory. `--config` selects another explicitly scoped single-site configuration. No dependencies are installed by this script.

Response verification checks twelve document URLs, JS/bootstrap/worker/WASM/SVG MIME types, header values, original no-cache paths, HTTPS HSTS and both reserved auth routes. It rejects redirects, wrong MIME and an auth URL incorrectly rewritten to the Flutter shell. It prints only paths and selected public response headers, never auth parameters or credentials. Any required mismatch exits nonzero. `--inventory` gathers public response metadata without a readiness verdict. `--app-only` excludes reserved helpers explicitly and reports them pending; it is insufficient for release acceptance.

Re-run default response verification separately on every approved origin after an authorized release. Keep live asset hash readback separate. Google redirect, anonymous-account linking and App Check remain browser/device checks, not things an HTTP header script can certify.

## Local tooling limits and remaining gates

The unmodified Windows Firebase Hosting server in this environment suppresses every configured response header, including preexisting Cache-Control. Installed `superstatic` 10.0.0 uses `glob-slasher`, which normalizes both requested paths and glob patterns through Windows `path.normalize`, producing backslashes that its matcher does not match. Direct matcher tests over configured URL paths pass; unmodified served-header tests fail. The server also rewrites `/__/auth/*` to the Flutter shell rather than emulating managed auth helpers. This is recorded as a tooling limitation, not a reason to relax the prepared security policy.

An Astra-approved private diagnostic normalized slashes only inside its own Node process and used the same installed superstatic strict stack/config. All twelve document and five asset responses passed header, MIME and relevant cache checks. In system Chrome155.0.8059.39, an external loopback-port parent successfully loaded a control iframe while the app root, `/admin` and an unknown nested fallback were blocked by enforced `frame-ancestors 'none'`. Screenshot and console evidence are in `iframe-proof.png` and `iframe-proof.json` in the local task evidence directory. Browser requests outside the two loopback ports were blocked, and service workers disabled; this was a framing check rather than an app-flow smoke. The Browser plugin was unavailable, so bundled Playwright drove Chrome.

This is adapted fixture evidence only. It cannot prove deployed Firebase matching, managed auth helper compatibility, platform HSTS or real-device behavior. No installed packages were changed. The first private diagnostic attempt contained a synchronous subprocess/event-loop deadlock; Astra authorized one asynchronous correction and the corrected run passed. Both owned fixture servers/browser and the earlier CLI server were stopped. No application assets were rebuilt or overwritten.

Pending release gates: authorized deployment to explicitly selected sites; exact live header/asset readbacks including unknown fallback paths and reserved auth paths; actual Google redirect and helper embedding; camera/gallery/GPS on Android and physical iPhone Safari; PWA behavior. Permissions Policy keeps camera/geolocation eligible for same-origin app use but neither grants user permission nor proves a browser picker works. Physical iPhone checks remain unverified. See `PHONE_TESTING.md` for the existing device record.

## Task 8 — resource report-only candidate, 2026-10-13

Resource enforcement is **NOT READY**. The maintained configuration now contains identical `Content-Security-Policy-Report-Only` values on the two application sources, while retaining enforced framing and reserved-route exclusions. There is no reporting endpoint, universal HTTPS source, script/style `unsafe-inline`, or broad `unsafe-eval`. This policy observes resource restrictions. Final local observations still report inline stylesheet insertion; do not promote it to enforced CSP or claim complete Firebase/device compatibility.

The maintained public directory remains historical `build/goodspotting-links-release`; its assets were preserved. A fresh configured build was created separately at `build/security-task8-configured`, using existing ignored Firebase options/entry point and `.local/firebase-web-defines.json`. Private candidate `.local/security-chain-20261013/task-8/firebase.security-report-only.json` pairs identical headers with that fresh directory and explicitly targets `goodspotting`. Neither configuration was deployed. Root must review/select the exact pair, rather than inadvertently publish the historical directory. Backend/rule release gates remain separate.

Build command: `flutter build web --release --no-pub --pwa-strategy=none -t lib/main_firebase.dart --output build/security-task8-configured --dart-define-from-file=.local/firebase-web-defines.json` passed in 31.8 seconds after scoped SDK-cache access. SHA-256 inventories of index, main, bootstrap, worker, manifest and both CanvasKit variants are in `task-8/artifact-hashes.json`. Fresh and historical index content matches; main-bundle equivalence is not implied. The existing Task 6 demo supplied distinct synthetic UI observations. No prior build was overwritten.

### Resource inventory and provenance

Evidence used Task 7's process-only adapted superstatic fixture and Chrome 155.0.8059.39 at 412×915. The Browser plugin was unavailable; existing Playwright drove the check. Only local resources and approved public SDK/font/tile GETs were allowed. Remote API/non-GET requests were blocked intentionally, including a reCAPTCHA POST. Requests were reduced to host/type/method/allowance. Tokens, query parameters, tile paths/coordinates, personal media and private/provider bodies were excluded.

| Resource/source | Candidate directive | Evidence and limits |
|---|---|---|
| Same-origin assets, manifest, custom worker, bundled fonts | Relevant directives use `'self'` | Local fetches/source inventory. Worker controlled a reload, without verified warm render/update. |
| `https://www.gstatic.com/firebasejs/` | `script-src` | Observed module loads; source pins Firebase JS 11.9.1. Inline import wrappers require hashes below. |
| `https://www.gstatic.com/flutter-canvaskit/` | `script-src`, `connect-src` | Observed script/WASM GETs. Current loader selects CDN assets despite local copies existing; self-hosting is not claimed or changed here. |
| `https://fonts.gstatic.com/s/` | `connect-src` | Observed fallback-font byte fetch and initial connect report. `font-src` remains `'self'`; other glyph/browser paths unverified. |
| `https://www.google.com/recaptcha/`, `https://www.gstatic.com/recaptcha/` | `script-src`; Google path also `connect-src`/`frame-src` | Script/frame/provider stylesheet GETs observed. Provider POST blocked; no assessment/App Check refresh proof. |
| `https://recaptcha.google.com/recaptcha/` | `frame-src` | Official provider requirement; not observed in bounded capture. |
| `https://firestore.googleapis.com`, `https://firebaseappcheck.googleapis.com`, `https://identitytoolkit.googleapis.com`, `https://securetoken.googleapis.com` | `connect-src` | SDK/service requirements inferred from selected integrations; successful requests/token refresh not exercised. |
| `https://africa-south1-wildlife-watch-sa.cloudfunctions.net` | `connect-src` | Client regional callable construction; no callable invoked. No speculative hosting-provider domains. |
| `https://tile.openstreetmap.org` | `connect-src`, `img-src` | Exact configured tile provider. Map interaction did not establish fresh network coverage; exact tile paths omitted. |
| `https://wildlife-watch-sa.web.app/__/auth/` | `frame-src` | Generated authDomain/design; no successful redirect/link. `frame-src` grants no permission to embed the main app; enforced `frame-ancestors` remains. |
| `data:`/`blob:` | `img-src` only | Renderer/selected-photo seams inferred; not exercised photo evidence. No script/connect scheme allowance. `worker-src` remains `'self'`. |
| Main website/SnapScan | No additional resource host | Top-level links do not justify broader connects. Navigation/payment not exercised. |

References: [reCAPTCHA CSP guidance](https://docs.cloud.google.com/recaptcha/docs/faq), [Flutter loader configuration](https://docs.flutter.dev/platform-integration/web/initialization), [App Check API endpoint](https://firebase.google.com/docs/reference/appcheck/rest). Inferred requirements are distinguished from observed requests above. Prefer a separately reviewed loader change to existing self-hosted CanvasKit assets before enforcement; simply finding them in the build is insufficient.

### Hashes and scoped exceptions

`script-src` uses the narrower `'wasm-unsafe-eval'` for CanvasKit compilation. No WASM CSP report appeared in this report-only Chrome capture; this is not enforced-policy or Safari proof. Fixed HTML script hashing normalizes CRLF/CR to LF as the HTML parser does.

| SHA-256/base64 hash | Provenance |
|---|---|
| lxybZtu/9pEo9t2cXF8OdVCueZV6paBpNEQpBgqbYWA= | Firebase app runtime import wrapper |
| JAe3kXNkLbcxHg2ubdnFd1ozxf8byMAcYA7B4I7gV5I= | Firebase auth runtime import wrapper |
| Kd6jrSJ+A8S4mbnMXfLL0WXdMJ02uYTrwrdvhPTpDug= | Firebase firestore runtime import wrapper |
| NgGZv0N7ml5Cnqo6sP6SR+wvDZmu359jxvlmnBvBdx8= | Firebase functions runtime import wrapper |
| 5LqYaNspg9CFrAptOVe5769ZJbQQLi/9/zqrBNhPepc= | Firebase storage runtime import wrapper |
| wtfUX3o+VhYEVP+bzIDF4V/mircbtP9PtlVEYPDTvb0= | Firebase app-check runtime import wrapper |
| K0APflN/rM59EMvpheEdCkRR3UN0TaBIT3epwlgTFgU= | fixed custom worker registration in index.html |
| 2hxujCU6WzSO6ycZznxFKlHE++BDsDuMYXT/O0zl8rM= | Observed final Flutter engine stylesheet |

The six wrappers match installed `firebase_core_web` 2.24.1 source's TrustedTypes branch, Firebase SDK 11.9.1 and exact public module URLs. They were observed across captured cold/warm pages, but are runtime-generated SDK/version/whitespace-sensitive hashes, not a durable third-party guarantee. The non-TrustedTypes branch has different text and was not exercised. Re-inventory after Flutter/FlutterFire/SDK/bootstrap/HTML changes and on supported browsers. The stylesheet hash is final DOM text only; incremental insertion still reports and other engines/routes remain unverified. Exact source derivation/stability is in `task-8/hash-provenance.json`; no credential-bearing script body was published.

### Observed results and remaining gates

Fresh configured and labelled synthetic demo home rendered with expected title/content and no framework overlay; screenshots were inspected. Initial candidate reports concerned inline scripts, fallback-font connection and inline stylesheet. A bounded correction added six observed wrapper hashes, corrected the parser-normalized worker hash, added the observed stylesheet hash and allowed only the font `/s/` path. One final run removed script/connect reports; `style-src-elem` inline reports remain. Report-only does not block resources, so rendered home success is not an enforcement pass. No broad script/style exception was added.

The configured browser raised a generic runtime error while the fixture deliberately blocked reCAPTCHA POSTs. This is separate from the style report and does not demonstrate a valid App Check token/refresh. No account/sign-in/link/API/callable/report/photo/moderation operation was performed.

Warm reload became worker-controlled but its render was not established. Direct `/report` and `/map` requests failed to establish the intended Flutter flow: this build uses hash routing, and fixture timing/activation did not prove controls or filters. The final map screenshot displayed home, so no filter interaction is claimed. No further automation repair was pursued. GPS/photo/auth/PWA/weak-network/external-link and physical Android/iPhone coverage remains pending in `PHONE_TESTING.md`.

### Verification and release preparation

`node scripts/verify_hosting_headers.mjs --resource-policy` verifies directive coverage, narrow exceptions, reserved exclusions and the selected artifact's fixed inline hash. Add `--config .local/security-chain-20261013/task-8/firebase.security-report-only.json` to check the fresh artifact pair. Expected missing-policy RED was followed by GREEN. Negative variants for missing policy, universal HTTPS, broad eval and stale hash were rejected; baseline/cache rules stayed intact. No backend/Flutter full suites were repeated for this config/doc-only boundary; one fresh build and focused checks were used.

After separately authorized report-only publication, root runs `node scripts/verify_hosting_headers.mjs --resource-policy --config <exact-reviewed-config> --base-url <approved-origin>` on every selected alias, with exact asset-hash readbacks. Resource mode compares the returned report-only value to the selected configuration and checks baseline/auth-helper exclusions. Default mode still supports baseline-only verification; `--inventory` makes no readiness claim. Adapted local evidence does not establish deployed matching or managed helper redirects.

No enforcement configuration is prepared. Remaining stylesheet/alternate-wrapper issues require reviewed remediation and actual supported-device/flow evidence with no unexplained blocking violations before enforcement. On breakage preserve logs/header/hash evidence and prepare a minimal correction or the Task 7 baseline for separately approved rollback; no rollback is executed here and backend privacy/App Check remain intact. Shared privacy terms remain deferred until the second app and website launch.
