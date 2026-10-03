# Preliminary privacy notice

The project collects the incident location, timing, classification, optional accuracy, direction, note and optional photograph needed for conservation analysis. Reporter names, email addresses, advertising identifiers and marketing profiles are not collected by the MVP. Firebase anonymous authentication may provide an operational UID so submissions can be protected and deduplicated.

Exact coordinates, private notes, reporter identifiers and uploaded resized JPEG photographs are restricted to authorised administration/analysis roles. The source image is processed in memory; only a re-encoded image stripped of source EXIF/GPS metadata is uploaded. Public map records are generated server-side from an allowlist and displaced by a configurable random 20–50 metre radius. Public clients never receive source coordinates. This is approximate location protection, not a guarantee against outside knowledge or repeated observations.

Map tiles are requested from the configured provider. That provider receives the browser's network address and tile coordinates for the viewed area; the private reporting map itself is not the public projection. Provider terms, logging/retention and location confidentiality need review before the pilot. Firebase/Hosting infrastructure may retain operational request metadata needed for security and service delivery. No advertising analytics or marketing identifiers are installed.

The demo uses in-memory synthetic reports and fixtures, without Firebase. The app keeps drafts in memory and disables persistent Firestore caching. The service worker caches only a static shell allowlist; it excludes Firebase responses, tile images, private photos and administration data. This does not promise offline submission.

The notice is preliminary and is not a formal legal policy. Before public launch, confirm retention, deletion, data-subject requests, processor terms, cross-border hosting and conservation authority expectations.
