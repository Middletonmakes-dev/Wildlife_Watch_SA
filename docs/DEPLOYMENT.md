# Deployment boundaries

The configured Firebase release uses ignored `firebase.json.local`, with `Cache-Control: no-cache` for `/`, `/index.html`, `/main.dart.js`, `/flutter_bootstrap.js` and `/service-worker.js`. Preserve these revalidation headers when recreating that configuration. They avoid a new hour-long browser cache for the unversioned app bundle, but cannot evict an already-cached response or update the custom cache-first shell worker. Installed-PWA/update testing remains outstanding.

For the user-authorized `wildlife-watch-sa` project setup, first deployment and live readbacks, see [FIREBASE_SETUP.md](FIREBASE_SETUP.md). The configured HTTPS app is live with private reporting rules and App Check enforced.

The first deployment was explicitly approved and executed by root with narrow targets and immediate readbacks. Trusted admin/analyst claims, retention policy, operating costs and public-launch decisions remain separate from the initial phone smoke test. Artifact Registry cleanup is currently unset; decide retention explicitly rather than applying a force flag during deployment.

Follow `DEVELOPMENT.md` to generate real platform options and copy the ignored Firebase entry point. Build with:

```powershell
flutter build web --release --pwa-strategy=none -t lib/main_firebase.dart --output build/firebase-web --dart-define-from-file=.local/firebase-web-defines.json
```

The ignored define file must specify `USE_FIREBASE: true` and the public Enterprise App Check site key. Use only its allowed HTTPS domains for cloud testing; do not add localhost or disable enforcement to work around failures. Local development uses the isolated emulators described in `DEVELOPMENT.md`.

Before a separately authorized release, verify anonymous sign-in, App Check web provider/allowed domains, regional Firestore/Storage choice and billing alerts, trusted administrator account/claims, Functions default bucket and environment settings, tile-provider rights, approved conservation wording, privacy/retention policy, and representative Android/Chrome and iPhone/Safari permission/photo behaviour. Callable Functions are `submitIncident`, `uploadIncidentPhoto`, and `setIncidentModeration`; server exports, Flutter clients and emulator endpoints explicitly use `africa-south1`. The photo service uses token-free Admin GCS saves; public bucket/IAM access must remain disabled.

Review `build/firebase-web`, rules/indexes and Functions separately. Ignored `firebase.json.local` uses that build and the explicit `wildlife-watch-sa` Hosting site; the normal `firebase.json` still points to the separate demo output at `build/web`. Deploy each narrow target only with explicit user authority and `--project wildlife-watch-sa --config firebase.json.local`; no commands here should publish implicitly. Verify active rules and callable configuration after each authorized production change. CI verifies locally and contains no deployment action.

The Git-tracked Firebase config contains FlutterFire-generated public project/app metadata, but no credentials or default deployment alias. Generated options, the configured entry point and local release configuration remain ignored. Do not enable billing/APIs, create accounts, set production claims, deploy, or write production reports as part of routine local verification.
