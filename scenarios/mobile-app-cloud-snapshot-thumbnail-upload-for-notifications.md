---
feature_id: FEAT-048
status: draft
target_fr_docs: [FR-mobile-app.md, FR-nuraeye-service.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Cloud Snapshot/Thumbnail Upload for Notifications

Covers FEAT-048: periodic/on-demand JPEG snapshots uploaded to the cloud to back
push-notification payloads and alert-history thumbnails — narrower-purposed than full
evidence-retention cloud backup (FEAT-043).

## Scenario: Push notification arrives with a thumbnail

**Scenario ID:** SCN-166
**Feature ID:** FEAT-048

**Persona:** Marcus gets a motion alert on his phone while away from home.

1. The camera detects motion and, alongside triggering the alert, uploads a snapshot image of
   the moment to the cloud.
2. Marcus's push notification arrives with that snapshot as a thumbnail, so he can see at a
   glance what triggered the alert before even opening the app.
3. Tapping the notification opens the full event in the app, where the same (or a higher-res)
   image/clip is available.

**What the user expects:** a notification tells him something useful about what happened, not
just that "something" happened.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall display an event-associated thumbnail image within the push
  notification itself, not only after opening the app.
- **[camera-firmware]** The camera shall capture and upload a snapshot image at the moment of a
  qualifying event, sized/optimized for notification-payload use.
- **[cloud-components]** The cloud service shall make an uploaded event snapshot available
  quickly enough to be embedded in the corresponding push notification without material delay.

## Scenario: Snapshot upload fails; notification arrives without a thumbnail

**Scenario ID:** SCN-167
**Feature ID:** FEAT-048

**Persona:** Priya's camera has a brief connectivity issue right as an event triggers, so the
snapshot upload fails.

1. The push notification still arrives (the alert itself doesn't depend on the snapshot),
   showing generic event text but no thumbnail image.
2. The app does not show a broken image or a stuck loading spinner where the thumbnail would be
   — it falls back to a clear "image unavailable" state.
3. If the snapshot upload later succeeds on retry, the alert-history entry updates to include
   the thumbnail once it's available.

**What the user expects:** a missing thumbnail never breaks the notification itself or leaves a
broken-looking gap in the app.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall not block or degrade delivery of the underlying alert on a
  failed snapshot upload, and shall show an explicit "image unavailable" state rather than a
  broken image or indefinite loading indicator.
- **[cloud-components]** The cloud service shall retry a failed snapshot upload and update the
  associated alert-history entry with the thumbnail once it succeeds.

## Scenario: Alert history shows thumbnails for past events

**Scenario ID:** SCN-168
**Feature ID:** FEAT-048

**Persona:** Marcus scrolls back through several days of alert history to find a specific past
event.

1. Marcus opens the alert-history list.
2. Each past alert shows its associated snapshot thumbnail (where one was successfully
   uploaded), letting him visually scan for the event he's looking for rather than reading
   timestamps one by one.
3. Older thumbnails remain viewable within the cloud snapshot service's own retention window,
   independent of the camera's local recording retention.

**What the user expects:** he can visually browse his alert history, not just read a list of
times and event types.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall display each past alert's snapshot thumbnail in the alert
  history list, where one exists.
- **[cloud-components]** The cloud snapshot service shall retain uploaded thumbnails for a
  defined retention window, independent of the camera's local recording retention.
