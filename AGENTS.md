# Agent context

Scarborough Tortoise Watch is a Flutter Web/PWA community wildlife reporting tool focused on tortoises in Scarborough, Cape Town. Its purpose is to turn quick resident observations into defensible evidence about crossings and roadkill while protecting exact wildlife locations.

## Current scope

The foundation provides a demo-mode home/report/thank-you flow, GPS or manual map selection, incident classification, optional JPEG processing and upload seam, privacy-protected public map, protected admin seam, typed models, callable Functions, restrictive Firestore/Storage rules, PWA shell and documentation. It is not a native app, social network, dispatch system or multi-tenant product.

## Architecture rules

- Keep the mobile-first flow fast, readable and usable on inexpensive Android phones.
- Keep presentation, typed domain models and data access separate. Widgets must not contain Firestore queries.
- Use Riverpod and go_router. Add abstractions only where they improve testing or protect a trust boundary.
- Exact `incidents` and private `incidentPhotos` are admin/analysis data. Public `publicIncidents` is an explicit allowlist projection created by trusted Functions.
- Never send exact coordinates, reporter UID, notes, private photos, bearings or exact timestamps to the public map.
- Use a cryptographically random server-side displacement and preserve the same projection across moderation changes.
- Firebase setup must fail closed when generated options are absent. Never fabricate credentials or commit `firebase_options.dart`.
- Demo fixtures are synthetic and must stay visibly separate from production data.
- Do not add invasive analytics, advertising, payment processing, complicated offline sync, AI identification or speculative multi-tenant machinery.

Before substantial changes, read `AGENTS.md`, `docs/PROJECT_CONTEXT.md`, `docs/MVP_SCOPE.md` and `docs/DECISIONS.md`. Meaningful architectural or product decisions must be appended to `docs/DECISIONS.md`.

## Verification

Use test-first development for behavior and security changes. Run `dart format`, `flutter analyze`, `flutter test`, `flutter build web --release --pwa-strategy=none`, Functions `npm test`, and the local emulator integration suite proportionately. Preserve unrelated dirty state. Deployment, publication, external account creation, production writes, commits and pushes require explicit user authority for that exact action, retained by the root; delegation alone grants none.
