You are setting up a new software project from scratch.

Create the complete workspace, initial documentation, folder structure, configuration, architecture foundation, starter application, tests, and developer context required for this project.

Do not merely describe what should be created. Create the files and initialise the project.

# PROJECT

Working title:

**Scarborough Tortoise Watch**

The name is provisional. Keep branding/name configuration centralised so it can easily be renamed later.

The project is a community wildlife road-sighting web application initially focused on tortoises in Scarborough, Cape Town, South Africa.

The immediate purpose is to collect reliable location data showing where tortoises cross roads and where they are injured or killed by vehicles.

The long-term objective is to identify roadkill hotspots and produce defensible data that can be presented to conservation authorities, road authorities, researchers, community organisations, and potentially other communities.

This should start as a very small and simple community project, but the architecture should not prevent it later becoming a reusable wildlife incident-mapping platform.

Do NOT overengineer the MVP.

# PRIMARY USER EXPERIENCE

A resident should be able to open a link or scan a QR code on their phone and submit a sighting in roughly 20 seconds.

No visible registration or login should be required.

The initial reporting flow is:

1. Open website.
2. Choose/report location.
3. Device GPS should be offered automatically.
4. Show location on a map with a draggable pin.
5. Select incident type:
   - Alive / crossing road
   - Alive / near road
   - Injured
   - Dead / roadkill
6. Optionally take/upload a photo.
7. Optionally indicate direction of travel.
8. Optionally enter a short note.
9. Submit.
10. Show a thank-you screen with appropriate guidance.

For a live tortoise on or crossing a road, the guidance should explain that if it is safe to do so, the animal should be moved off the road in the same direction it was already travelling, rather than relocated elsewhere.

Keep conservation guidance in centrally managed content/configuration rather than burying it throughout UI code.

# PUBLIC MAP

Include a public sightings map.

The public map must NOT expose exact stored coordinates.

Exact coordinates are retained privately for analysis.

The public representation should use a configurable coordinate-obfuscation strategy such as approximately 20–50 metres of deterministic or controlled fuzzing.

Implement this as a separate service/function rather than modifying the raw source data.

Raw coordinates must never be returned to unauthorised public clients.

Allow filtering by:

- Alive
- Injured
- Roadkill
- Date range

Initial map markers can be simple.

The public map should eventually make hotspot patterns obvious.

# ADMIN FUNCTIONALITY

Create the architectural foundation for a protected admin dashboard.

The first admin features should eventually include:

- Exact incident locations
- Full uploaded photographs
- Report timestamp
- GPS accuracy if available
- Incident type
- Direction of travel
- Notes
- Record status
- Ability to mark obvious spam/duplicate reports
- Export reports to CSV
- Filter by date/status
- Basic counts

Do not build a huge administration system yet.

Create enough scaffolding that admin features can be added cleanly.

# TECHNOLOGY STACK

Use:

- Flutter
- Flutter Web first
- PWA support
- Firebase
- Firebase Authentication
- Firebase anonymous authentication for normal reporters where useful
- Firebase Authentication with authorised accounts/roles for administrators
- Cloud Firestore
- Firebase Storage
- Firebase App Check
- Firebase Hosting
- Firebase Functions only where server-side trust boundaries or processing are justified

Use a clean architecture suitable for a small application without introducing unnecessary abstraction layers.

State management:

Prefer Riverpod unless there is a strong technical reason not to.

Routing:

Use go_router.

Data modelling:

Use strongly typed Dart models.

Serialization:

Prefer json_serializable/freezed if appropriate, but avoid unnecessary generated-code complexity if plain immutable Dart models are sufficient.

Mapping:

Abstract the map provider behind a small interface.

For development, use a sensible Flutter-compatible map implementation.

Do not lock core business logic to a single commercial map provider.

Document production map/tile-provider considerations separately, including API cost and acceptable-use considerations.

Do not assume unrestricted production use of free public OpenStreetMap tile servers.

# LOCATION MODEL

Design the location model carefully.

An incident should be capable of storing:

- latitude
- longitude
- GPS accuracy in metres if supplied
- location source:
  - device GPS
  - manually positioned pin
  - unknown
- timestamp
- optional direction/bearing

Direction can initially be nullable.

If direction is captured in the UI, storing a compass bearing in degrees is preferred over arbitrary text.

# INCIDENT DATA MODEL

Create a sensible typed model along these lines:

Incident
- id
- createdAt
- occurredAt if supplied separately
- latitude
- longitude
- locationAccuracyMetres
- locationSource
- incidentType
- directionBearing
- note
- photo references
- anonymousUserId / reporter UID where appropriate
- moderationStatus
- source/version metadata
- server timestamp
- public display coordinates or derived public representation where appropriate

Incident types should be represented as an enum.

Moderation status should allow at minimum:

- pending
- accepted
- rejected
- duplicate

Do not expose fields publicly merely because they exist in Firestore.

# PHOTO HANDLING

Photos are optional.

Design uploads so photographs are:

- compressed/resized client-side where sensible
- stored using non-guessable paths
- associated with an incident
- not publicly listable
- accessible according to security rules

Preserve enough resolution for later species/incident verification, but do not upload unnecessarily huge phone images.

Document sensible initial image limits.

Strip unnecessary image metadata where practical, especially metadata that could unintentionally expose location information independently of our location privacy controls.

# PRIVACY

Privacy must be part of the architecture from the beginning.

Principles:

- No public exact wildlife locations.
- No unnecessary collection of personally identifiable information.
- No visible account required to submit a report.
- Do not collect reporter names/emails unless a future feature genuinely requires it.
- Do not collect advertising/tracking data by default.
- Clearly distinguish operational telemetry from marketing analytics.
- Exact location data is only available to authorised administration/analysis roles.
- Photo access follows the same principle.

Create a preliminary PRIVACY.md explaining the intended data handling.

It is not a substitute for a future formal privacy policy.

# ABUSE / DATA QUALITY

The reporting endpoint must not be completely trusting merely because the app is community-focused.

Prepare for:

- spam
- duplicate reports
- automated abuse
- obviously invalid coordinates
- repeated submissions
- inappropriate photo uploads

Use Firebase security rules and App Check.

If server-side validation is warranted, establish the appropriate Functions boundary.

Do not create a complicated anti-fraud system for MVP.

Document future options such as rate limiting and duplicate detection.

# DONATIONS

The website will eventually have a simple:

**Support the project**

section/button.

The intention is to allow voluntary contributions toward:

- hosting
- mapping/API costs
- storage
- development
- conservation work associated with the project

Do NOT implement a payment processor yet.

Instead:

- Create a reusable donation/support UI component with a disabled/configurable placeholder action.
- Keep payment-provider integration behind a small abstraction/config.
- Add `docs/DONATIONS.md`.
- Document what needs to be decided before enabling payments.
- Never imply donations are tax deductible.
- Do not describe the project as a registered charity/PBO unless that later becomes true.

The donation functionality must never obstruct reporting a tortoise.

# ACCESSIBILITY AND PERFORMANCE

The public reporting interface must work well on inexpensive Android phones.

Prioritise:

- fast initial load
- touch-friendly controls
- readable text
- high contrast
- minimal network use
- graceful behaviour on weak mobile connections

Make the report flow usable with one hand.

Photo upload failure should not necessarily destroy the rest of a report.

Think mobile-first even though this is Flutter Web.

# OFFLINE / POOR SIGNAL

Do not build a complicated offline-first system initially.

However, structure the submission workflow so eventual queued/offline submissions are possible.

At minimum:

- preserve form state during transient errors where practical
- show useful network errors
- do not make the user re-enter everything unnecessarily

Document offline submission as a future enhancement.

# PROJECT STRUCTURE

Use a feature-oriented Flutter structure similar to:

lib/
  app/
    app.dart
    router.dart
    theme/
    config/

  core/
    constants/
    errors/
    services/
    utilities/
    widgets/

  features/
    report/
      data/
      domain/
      presentation/

    map/
      data/
      domain/
      presentation/

    admin/
      data/
      domain/
      presentation/

    support/
      presentation/

  firebase_options.dart only when generated by the proper tooling

Do not manually fabricate real Firebase credentials.

Adjust the exact structure if necessary, but keep feature ownership clear.

# REPOSITORY DOCUMENTATION

Create these files:

README.md

AGENTS.md

docs/
  PROJECT_CONTEXT.md
  PRODUCT_REQUIREMENTS.md
  MVP_SCOPE.md
  ARCHITECTURE.md
  DATA_MODEL.md
  PRIVACY.md
  SECURITY.md
  CONSERVATION_GUIDANCE.md
  DONATIONS.md
  ROADMAP.md
  DECISIONS.md
  DEVELOPMENT.md
  DEPLOYMENT.md
  TESTING.md
  OPERATIONS.md

Create `.env.example` or equivalent configuration documentation where relevant.

Never place secrets in the repository.

# AGENTS.md

This file is particularly important because future Codex sessions will use this repository.

Write AGENTS.md as durable context for AI coding agents.

It should explain:

- what the project is
- why it exists
- current scope
- technology choices
- architectural principles
- privacy requirements
- exact-vs-public coordinate separation
- coding conventions
- what NOT to overengineer
- testing expectations
- security expectations
- documentation update requirements
- how architectural decisions should be recorded

Include a rule that meaningful architectural/product decisions must be appended to `docs/DECISIONS.md`.

Include a rule that agents must read:

- AGENTS.md
- docs/PROJECT_CONTEXT.md
- docs/MVP_SCOPE.md
- docs/DECISIONS.md

before making substantial changes.

# PROJECT_CONTEXT.md

Populate it with the following context.

Problem:

Tortoises in and around Scarborough are being struck by vehicles.

At present there is not enough structured local data to confidently identify where and when crossings and fatalities are concentrated.

Goal:

Create a low-friction citizen reporting tool that turns individual sightings into useful geospatial evidence.

Initial geographic focus:

Scarborough, Cape Town, South Africa.

Initial species focus:

Tortoises.

Potential future expansion:

The platform architecture could eventually support other wildlife/road incidents, other communities, conservation organisations, estates, reserves, environmental studies, or municipalities.

However, no generic multi-tenant platform should be built during the MVP.

The Scarborough use case comes first.

Success initially means:

- residents actually use it
- reports take seconds rather than minutes
- location data is useful
- exact wildlife locations remain protected
- meaningful crossing/roadkill hotspots can eventually be identified
- data can be exported for credible external analysis

# MVP_SCOPE.md

Clearly define IN SCOPE:

- mobile-first Flutter web application
- PWA
- anonymous reporting
- geolocation
- draggable map pin
- incident classification
- optional image
- optional note
- optional direction
- submission to Firebase
- confirmation/guidance page
- public privacy-protected map
- basic protected admin foundation
- CSV export architecture or basic implementation if straightforward
- support/donation placeholder
- tests
- security rules

Clearly define NOT IN MVP:

- native Play Store/App Store applications
- social network
- user profiles
- gamification
- push notifications
- AI species identification
- machine learning
- complicated offline synchronisation
- automated volunteer dispatch
- IoT wildlife sensors
- municipal integrations
- multi-tenant SaaS
- paid subscription plans
- advertising network
- sophisticated hotspot algorithms
- custom hardware

# ARCHITECTURE

Prefer boring, understandable engineering.

Create repository/service abstractions where they provide a real testability or trust-boundary benefit.

Avoid abstraction for abstraction's sake.

UI widgets must not directly contain Firestore queries throughout the codebase.

Separate:

presentation
domain/model
data access

without attempting to reproduce a huge enterprise clean-architecture framework.

Create interfaces for important external dependencies such as:

- incident repository
- location service
- photo storage
- map provider/public-coordinate representation where appropriate

# FIREBASE

Prepare:

- Firestore structure
- Storage structure
- security rules
- indexes if required
- local emulator configuration if practical
- deployment/config instructions

Do not require a real Firebase project to run static/unit tests.

Use emulator-friendly development patterns.

Create a documented setup path for later linking the repository to a real Firebase project.

# SECURITY RULES

Write initial Firestore and Storage rules with restrictive defaults.

Do not use blanket production rules such as:

allow read, write: if true;

Public users should only have permissions genuinely required to submit/view permitted data.

Exact incident records should not simply be directly public-readable.

If public map data requires a separate sanitised collection or server-generated representation, prefer that over relying on the client to hide secret fields.

Document the rationale.

# PUBLIC LOCATION PRIVACY DESIGN

This is important.

Evaluate the safest simple architecture for maintaining:

1. authoritative private exact incident data
2. sanitised public incident/map data

Prefer a server-side or rules-enforced separation.

Do not send exact coordinates to the public client and merely move the marker visually.

The public browser should never receive private exact coordinates unless authorised.

Record the selected implementation in `docs/DECISIONS.md`.

# DESIGN

Keep the visual identity understated and local.

General feel:

- conservation
- Cape coastal/fynbos environment
- clean
- credible
- community-driven
- not corporate
- not childish

Do not spend significant time on elaborate branding yet.

Build a clean basic design system:

- typography
- spacing
- buttons
- form fields
- status components
- card style

Use centralised theme tokens.

Do not hardcode styling everywhere.

# HOME PAGE

Create a simple home screen with clear primary actions:

**Report a tortoise**

**View sightings map**

Secondary content can briefly explain the purpose of the project.

A small **Support the project** option may appear lower on the page.

Reporting must be the dominant action.

# REPORT FLOW

Design it so that the minimum viable report requires as little interaction as possible.

Location should be obtained early.

Do not require a photo.

Do not require notes.

Do not require direction.

Do not require personal details.

Use sensible defaults and large touch targets.

# LOCATION PERMISSIONS

Handle these cases correctly:

- location permission accepted
- location permission denied
- location unavailable
- low GPS accuracy
- desktop device
- user wants to manually position the map pin

The system should remain usable if geolocation permission is denied.

# ERROR HANDLING

Use typed/structured application errors where sensible.

Users should receive understandable messages.

Do not display Firebase exception dumps.

Log sufficient development information without leaking sensitive data.

# TESTING FOUNDATION

Set up useful tests from the beginning.

At minimum include tests for:

- incident model serialization
- incident-type handling
- coordinate validation
- public coordinate sanitisation/obfuscation
- report form validation
- repository behaviour using mocks/fakes
- critical Firebase rules if emulator testing is configured

Include at least one widget test for the report flow.

Create `docs/TESTING.md` with exact commands.

# TOOLING

Configure:

- flutter_lints or an appropriate strict lint configuration
- formatting
- analysis
- test commands

If appropriate, add GitHub Actions for:

- flutter analyze
- flutter test

Do not create deployment automation that could publish accidentally.

# GIT

Initialise Git if this is not already a repository.

Create a robust `.gitignore`.

Never commit:

- Firebase service account keys
- local secrets
- generated credentials
- private environment files

Create logical initial commits if the environment allows it.

# DEVELOPER EXPERIENCE

The project should be easy for a new developer or future Codex session to understand.

The root README should contain:

- what this is
- screenshots section placeholder
- local prerequisites
- setup
- running locally
- testing
- Firebase emulator usage
- production configuration
- repository structure
- links into the detailed docs

Do not make README enormous if information belongs in `/docs`.

# DECISION LOG

Start `docs/DECISIONS.md` with dated entries for major initial choices, including:

- Flutter Web/PWA
- Firebase
- Riverpod
- no visible user registration
- public/private geolocation separation
- mobile-first design
- MVP remains Scarborough/tortoise-specific
- donation provider deferred
- map provider abstracted

Use a simple format:

## YYYY-MM-DD — Decision title

Decision:
...

Reason:
...

Consequences:
...

# ROADMAP

Create a practical staged roadmap.

Suggested phases:

Phase 0 — Repository/Foundation

Phase 1 — Functional reporting MVP

Phase 2 — Public map

Phase 3 — Admin/data-quality tooling

Phase 4 — Real Scarborough pilot

Phase 5 — Hotspot analysis/reporting

Phase 6 — Evaluate expansion beyond Scarborough

Include exit criteria for each phase.

Do not add artificial calendar deadlines.

# CONSERVATION GUIDANCE

Create `docs/CONSERVATION_GUIDANCE.md`.

Keep safety/conservation wording separate from application code.

Mark conservation guidance that still requires verification with the appropriate conservation authority before public launch.

Do not invent authoritative wildlife advice.

The application should make it easy to revise this content without restructuring the app.

# ANALYTICS

Do not install invasive analytics or advertising SDKs.

If product analytics becomes necessary, it should be consciously selected later.

Basic aggregate operational metrics may eventually be useful, for example:

- reports submitted
- successful submissions
- submission failures

But do not create unnecessary user tracking.

# COST CONTROL

This is intended to begin as a low-cost community project.

Document likely variable-cost components:

- Firebase reads/writes
- Firebase Storage
- Firebase Hosting
- Functions
- map/tile provider
- payment processor once enabled

Architect with sensible cost awareness but do not prematurely optimise insignificant usage.

Create `docs/OPERATIONS.md` with a section called:

**Cost monitoring**

# CONFIGURATION

Centralise things likely to change:

- application name
- geographic starting map position
- initial map zoom
- public coordinate privacy radius
- photo upload limits
- support/donation URL/provider
- contact links
- conservation guidance URLs/text where appropriate

Scarborough can be the default map centre, but it must not be scattered as hardcoded coordinates throughout the code.

# SAMPLE DATA

Provide a development-only sample dataset.

Clearly separate it from production.

Use obviously synthetic locations/data and do not make test fixtures look like genuine recorded wildlife incidents.

# FUTURE DATA ANALYSIS

Do not implement advanced hotspot detection now.

But structure exports/data cleanly enough that future analysis could examine:

- incidents per road segment
- density clusters
- fatalities vs live sightings
- time of day
- season/date
- recurring crossing locations

Document this in the roadmap.

# COMPLETION REQUIREMENTS

When finished, the workspace should:

1. Build successfully.
2. Pass `flutter analyze`.
3. Pass the test suite.
4. Have a functional starter UI.
5. Have the application routing in place.
6. Have the reporting feature skeleton or initial working implementation.
7. Have typed incident models.
8. Have Firebase interfaces/repositories structured.
9. Have security-rule foundations.
10. Have a public/private location privacy strategy explicitly implemented or clearly scaffolded.
11. Have comprehensive project context documentation.
12. Have AGENTS.md suitable for future Codex sessions.
13. Have no secrets.
14. Have clear instructions for connecting the real Firebase project later.

# IMPORTANT WORKING RULES

Do not stop after generating a plan.

Execute the setup.

Run the formatter, analyser and tests.

Fix errors you encounter.

If Flutter/Firebase tooling needed for a particular operation is unavailable, create everything that can reasonably be created without it and document the exact remaining command rather than fabricating generated configuration.

Do not create fake Firebase credentials.

Do not deploy anything.

Do not enable billable APIs.

Do not create external accounts or services.

Do not implement payment processing yet.

Do not overengineer speculative future features.

At the end:

1. Show the final directory tree.
2. Summarise what was created.
3. Report the exact results of analysis/tests.
4. Identify anything requiring my manual action.
5. Give me the next 3 most useful development tasks.