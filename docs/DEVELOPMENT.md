# Development

## Credential-free demo

From the repository root, run `flutter pub get`, then `flutter run -d chrome`. Demo is the default; no Firebase project, options file or cloud data is required. Reports remain in memory and all public fixtures are visibly synthetic. The map uses external starter tiles; configure a reviewed provider before public launch.

For a physical Android or iPhone on the same Wi-Fi, use the staged [phone testing guide](PHONE_TESTING.md). Serve only `build/web`, bound to the selected private LAN address. The existing `127.0.0.1` preview is reachable only on the PC. A phone's own `localhost` is the phone, not this PC, unless an explicit USB reverse mapping has been set up as described in that guide. The current Android test uses that USB mapping.

Verified tools: Flutter 3.41.1/Dart 3.11.0, Node 22, Java 21 and Firebase CLI 15.7.0. On this Windows workspace Flutter is at `C:\Users\admin\Documents\Flutter\flutter\bin\flutter.bat`; add its `bin` directory to your terminal PATH or use that absolute path. Standard commands below work on other systems with those tools on PATH.

## Generated Firebase integration (manual, after separate project setup)

Do not fabricate credentials. Select a properly owned Firebase project, install/use the official FlutterFire CLI and run:

```powershell
flutterfire configure --project YOUR_PROJECT_ID --platforms web --out lib/firebase_options.dart
Copy-Item lib/main_firebase.dart.example lib/main_firebase.dart
```

Both generated options and the configured entry point are ignored. The default `main.dart` deliberately cannot initialize production Firebase and displays a setup error if `USE_FIREBASE=true` is supplied without explicit options. The Firebase entry point consumes `DefaultFirebaseOptions.currentPlatform`; generating the file alone is insufficient. The cloud bootstrap requires `APP_CHECK_WEB_KEY` for a score-based reCAPTCHA Enterprise provider and enables token auto-refresh. Use the local emulator command below for localhost; the production key permits only the Hosting domains. See `FIREBASE_SETUP.md` for the authorized first deployment and live evidence, and `DEPLOYMENT.md` for the separate release build. Ordinary local verification remains emulator-only.

## Isolated emulators

Tests need no real Firebase project or generated Flutter options:

```powershell
npm ci --prefix functions
npm test --prefix functions
firebase emulators:exec --only auth,functions,firestore,storage --project demo-scarborough-tortoise-watch 'node functions/test/emulator-all.cjs'
```

Use exactly the `demo-` project ID. Default ports in `firebase.json`: Auth 19099, Functions 15001, Firestore 18080, Storage 19199, hub 14400 and logging 14500. UI is disabled. Existing services on other ports must not be stopped. First use downloads official emulator binaries; Java 21 is required.

For this restricted Windows environment, set task-local cache/config first:

```powershell
$env:XDG_CONFIG_HOME = Join-Path (Get-Location) '.local/config'
$env:FIREBASE_EMULATORS_PATH = Join-Path (Get-Location) '.local/emulators'
$env:CI = 'true'
```

After genuine options have been generated, the Firebase entry-point example can also run the UI against local emulators. Its explicit local branch retains tooling-generated identifiers and changes only the project/bucket to the demo namespace:

```powershell
firebase emulators:start --only auth,functions,firestore,storage --project demo-scarborough-tortoise-watch
# In a second terminal:
flutter run -d chrome -t lib/main_firebase.dart --dart-define=USE_FIREBASE=true --dart-define=USE_FIREBASE_EMULATORS=true
```

App Check is bypassed only in the Functions emulator and the explicit Flutter emulator branch. Production always requires it. Flutter Functions clients, all three callable exports and emulator test URLs use `africa-south1`. Use `FIREBASE_EMULATOR_HOST` for a device-accessible local hostname if testing on a phone; all services must remain local. No production Functions may be invoked by tests.

## Configuration and branding

`.env.example` documents settings; Flutter does not auto-load it. Pass values with `--dart-define` (or an ignored JSON file via `--dart-define-from-file`). Server privacy radii use Functions environment values, not Dart defines. Defaults are 20–50 metres; invalid/nonfinite/reversed radii fail validation. `AppConfig` owns centre/zoom and client photo limits. `MAP_TILE_URL` and `MAP_ATTRIBUTION` select the tile provider. `SUPPORT_URL` configures a future nonblocking support seam; no payments exist.

Edit `assets/config/branding.json` and run `python scripts/sync_branding.py` (Python/Pillow) to update the Flutter name, HTML title/description, manifest and 192/512 PNG icons together. Run `dart format lib/app/config/branding.dart` afterward. Safety/guidance text is centralized in `lib/app/config/guidance.dart`.

Use feature folders and immutable models. Put user-facing guidance in central config. For behavior or security changes, write a focused failing test first, observe the expected failure, implement the smallest change, then run the focused and full suites. Update the decision log when architecture or product scope changes.

The local demo deliberately stores reports in memory and keeps draft form state out of browser storage because precise locations should not be persisted casually. Offline queueing is future work.
