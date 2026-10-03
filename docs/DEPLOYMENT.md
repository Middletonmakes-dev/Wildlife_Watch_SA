# Deployment boundaries

No deployment is configured or performed by the foundation. A future operator should create/select the intended Firebase project, generate platform options with FlutterFire, configure Auth anonymous sign-in and App Check, set admin/analyst claims, review rules/indexes, set Functions environment values for public radius, and choose an acceptable map provider before hosting.

Follow `DEVELOPMENT.md` to generate real platform options and copy the ignored Firebase entry point. Build with:

```powershell
flutter build web --release --pwa-strategy=none -t lib/main_firebase.dart --dart-define=USE_FIREBASE=true --dart-define=APP_CHECK_WEB_KEY=YOUR_RECAPTCHA_V3_SITE_KEY
```

Before a separately authorized release, verify anonymous sign-in, App Check web provider/allowed domains, regional Firestore/Storage choice and billing alerts, trusted administrator account/claims, Functions default bucket and environment settings, tile-provider rights, approved conservation wording, privacy/retention policy, and representative Android permission/photo behaviour. Callable Functions are `submitIncident`, `uploadIncidentPhoto`, and `setIncidentModeration`; default region is `us-central1` until consciously changed in both client and server. The photo service uses token-free Admin GCS saves; public bucket/IAM access must remain disabled.

Review `build/web`, rules/indexes and Functions separately. Deploy each narrow target only with explicit user authority; no commands here should publish implicitly. Verify active rules and callable configuration after each authorized production change. CI verifies locally and contains no deployment action.

The Git-tracked Firebase config has no project binding or credentials. Do not enable billing/APIs, create accounts, set production claims, deploy, or write production reports as part of routine local verification.
