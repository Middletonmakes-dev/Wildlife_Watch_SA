# Architecture

Flutter Web is the presentation shell. Riverpod supplies small dependencies and go_router owns routes. Feature folders contain presentation, domain models/controllers and data seams. Models are immutable Dart classes with explicit JSON conversion to keep the initial code understandable.

The report flow uses `IncidentRepository`, `LocationService` and `PhotoStorage` interfaces. Demo implementations make the starter usable without credentials. Firebase implementations use anonymous authentication, a callable `submitIncident` boundary and a separate `uploadIncidentPhoto` callable after the core incident commits. The server reserves one private slot and writes re-encoded JPEG bytes through the Admin GCS API without Firebase download tokens; direct client Storage writes are denied.

The callable validates numbers, enums, notes, request IDs and forged fields, applies a modest per-UID cooldown and creates an idempotent private record. `setIncidentModeration` is restricted to admin/analyst claims. On acceptance it creates an allowlisted `publicIncidents` projection with a cryptographically random 20–50 metre displacement. The private projection is retained so accept/reject/reaccept does not generate a new public point.

The map is behind `MapProvider`; the starter uses OpenStreetMap tile URLs and attribution. Production must select a provider with an acceptable-use policy, capacity and cost plan. Service-worker caching excludes map tiles, Firebase responses, photos and admin data.

The controller captures one immutable submission snapshot and protects it with an independent in-flight latch; delayed GPS or manual edits cannot reopen submission. A stable request ID plus server canonical payload hash makes same-payload retries idempotent and rejects changed details after ambiguous responses. Photo retries use the committed incident ID only. Server photo writes use generation-zero preconditions and a private processed-image hash; identical retry is allowed and replacement is denied.

Public reads fetch the latest 500 accepted projections by coarse date, then filter type/date locally; larger-volume pagination and server-side filtered queries are follow-up work. Admin repository reads at most 500 exact incidents only after trusted claims; CSV cells neutralize formula injection while retaining numeric coordinate columns. The UI provides a protected CSV text/export seam, not a complete dashboard or administrator sign-in flow.
