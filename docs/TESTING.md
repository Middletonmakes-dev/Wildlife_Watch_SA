# Testing

Flutter checks:

```powershell
& 'C:\Users\admin\Documents\Flutter\flutter\bin\cache\dart-sdk\bin\dart.exe' format --set-exit-if-changed lib test
& 'C:\Users\admin\Documents\Flutter\flutter\bin\flutter.bat' analyze
& 'C:\Users\admin\Documents\Flutter\flutter\bin\flutter.bat' test
```

The tests cover model JSON round trips, enum wire values, finite/ranged coordinate and form validation, privacy displacement/allowlisting, retry/idempotency and draft preservation, low-accuracy/manual location precedence, optional photo failure, and the report-flow widget. Functions checks use `npm test` and cover validation, forged fields, projection distance/allowlist, projection reuse and static rule invariants.

Build the demo with `flutter build web --release --pwa-strategy=none`. The custom shell worker is the only intended worker; Flutter's broad generated worker is disabled. The option is deprecated in Flutter 3.41.1, so revisit tooling when upgrading.

Node unit/build checks and real integration checks:

```powershell
npm ci --prefix functions
npm test --prefix functions
firebase emulators:exec --only auth,functions,firestore,storage --project demo-scarborough-tortoise-watch 'node functions/test/emulator-all.cjs'
```

The integration runner refuses nonlocal service hosts and uses only a demo project. Tests seed synthetic documents with rules disabled, then exercise actual rules through unauthenticated, reporter, admin and analyst client contexts. They cover private reads/listing, forbidden client writes, public reads, strict private-photo access and denied direct uploads. Callable tests verify Auth, null/array/forged input, concurrent same-request deduplication, changed-payload rejection, UID cooldown, admin moderation, coarse dates and stable projection after retraction/reacceptance.

Photo integration exercises valid server JPEG upload, type/size bounds, incident ownership, immutable storage, same-image retries, absence of download-token metadata, and denied unauthenticated media/token requests. The client never uploads with `putData` or obtains download URLs. Metadata is stripped again on the server.

App Check is enforced in production options and intentionally bypassed by emulators; production provider issuance/enforcement needs a separately authorized project smoke test. CI `.github/workflows/verify.yml` runs analyze/tests/build/Functions/emulators and has no deploy step. The workflow itself has not run on GitHub. See `docs/SETUP_VERIFICATION.md` for fresh local counts and command results.
