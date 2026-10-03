# Data model

`Incident` stores an opaque ID, created/occurred timestamps, exact `GeoCoordinate`, source and accuracy, typed incident type, optional bearing/note/photo references, reporter UID, moderation status, request ID and source version. It is private.

`PublicIncident` stores only opaque public ID, incident type, displaced display latitude/longitude and coarse date. It is a different type and collection, not a view that relies on the client hiding fields.

Enums have stable wire values: `alive_crossing_road`, `alive_near_road`, `injured`, `dead_roadkill`; location sources are `device_gps`, `manual_pin`, `unknown`; moderation is `pending`, `accepted`, `rejected`, `duplicate`.

## Stored schema

| Collection/field | Meaning and units | Access |
|---|---|---|
| `incidents/{id}` | ID derived privately from authenticated UID + stable request ID | Trusted server writes; admin/analyst reads |
| `createdAt` | Authoritative Firestore server timestamp (UTC instant) | Private |
| `occurredAt` | Optional reported UTC instant; future timestamps beyond 5 minutes rejected | Private |
| `latitude`, `longitude` | Exact finite geographic degrees, [-90,90]/[-180,180] | Private |
| `locationAccuracyMetres` | Nullable finite GPS accuracy, 0–10000 metres | Private |
| `locationSource` | `device_gps`, `manual_pin`, `unknown` | Private |
| `incidentType` | Stable enum wire value | Private; classification allowlisted publicly |
| `directionBearing` | Nullable degrees in [0,360) | Private |
| `note` | Optional string up to 500 characters | Private |
| `reporterUid`, `requestId`, `submissionFingerprint` | Auth ownership and retry binding | Private |
| `moderationStatus` | pending/accepted/rejected/duplicate | Private |
| `moderatedAt`, `moderatedBy` | Server time and trusted moderator UID | Private |
| `sourceVersion` | Current schema/source marker `v1` | Private |
| `photoReferences`, `photoFingerprint`, `photoStored` | Reserved path, immutable image reservation/hash and existence flag | Private |
| `publicProjection` | Persisted displaced allowlist reused after moderation changes | Private copy |
| `publicIncidents/{id}` | `id`, `incidentType`, `displayLatitude`, `displayLongitude`, `date` only | Public read; trusted server writes |
| public `date` | UTC `YYYY-MM-DD` from occurredAt, otherwise createdAt | Public, deliberately coarse |
| `_submissionThrottle/{uid}` | `lastSubmittedAt` server timestamp for UID cooldown | Server only |

Photos use a single immutable private slot `incidentPhotos/{incidentId}/photo.jpg`. A reference initially reserves the slot and does not prove an object exists. The callable verifies reporter ownership, strict encoded/decoded limits (2 MiB decoded), actual JPEG decoding and an 8-megapixel decode cap, then re-encodes with longest edge 1600 and no source metadata. Private GCS custom metadata contains only the processed-image hash required for identical retry; no download token or public URL is created. Direct client creates/updates and all listings are denied; trusted admin/analyst `get` remains available.
