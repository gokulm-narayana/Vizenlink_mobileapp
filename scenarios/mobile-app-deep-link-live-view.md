---
feature_id: FEAT-115
status: draft
target_fr_docs: [FR-mobile-app.md, FR-nuraeye-service.md]
---

# Scenario: Mobile App — Deep-Link to Live View from Notification/Card/Event

Covers the mobile-app side of FEAT-115: tapping a push notification, a dashboard camera card,
or an event's detail screen jumps straight into that camera's live view.

## Scenario: Tapping a push notification jumps straight to live view

**Scenario ID:** SCN-415
**Feature ID:** FEAT-115

**Persona:** Priya receives a motion-detected push notification for her front-door camera while
her phone is locked.

1. Priya taps the notification from her lock screen.
2. The app opens (launching if it wasn't running) and takes her directly into that camera's
   live view — not the home dashboard, not the notification list.
3. Live video begins streaming within a few seconds of the tap.

**What the user expects:** a notification tap is a shortcut straight to "show me that camera
right now," with no extra navigation in between.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** Tapping a push notification shall deep-link directly into the referenced
  camera's live view, cold-launching the app if necessary, without landing on an intermediate
  screen first.
- **[mobile-app]** The app shall begin streaming live video for the deep-linked camera
  automatically upon arrival at the live-view screen, without requiring an additional tap.
- **[cloud-components]** The push-notification payload shall carry enough camera-identifying
  information for the app to resolve and open the correct camera's live view without an extra
  round trip to look it up.

## Scenario: Tapping a dashboard card or an event's detail screen opens live view

**Scenario ID:** SCN-416
**Feature ID:** FEAT-115

**Persona:** Priya is browsing the dashboard and separately, later, reviewing an old event in
the timeline.

1. From the dashboard, Priya taps a camera's thumbnail card; the app opens straight into that
   camera's live view.
2. Later, while viewing a past event's detail screen, Priya taps a "View Live" control; the app
   again opens that same camera's live view, not the recorded clip a second time.
3. In both cases, returning (back gesture/button) takes her back to exactly where she was —
   the dashboard, or the event detail screen — not to some other screen.

**What the user expects:** any place a camera or its identity is shown gives her a one-tap path
to see what it's showing right now, and backing out returns her to where she started.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** Tapping a camera card on the dashboard shall deep-link into that camera's
  live view.
- **[mobile-app]** The event detail screen shall offer a "View Live" control that deep-links to
  the same camera's live view, distinct from replaying the event's own recorded clip.
- **[mobile-app]** Navigating into live view via any deep-link entry point (notification, card,
  event detail) shall preserve back-navigation to the originating screen.

## Scenario: Deep-linking to a camera that's currently unreachable

**Scenario ID:** SCN-417
**Feature ID:** FEAT-115

**Persona:** Priya taps a notification for a camera that has since gone offline (e.g. WiFi
outage at home) before she opens the app.

1. Priya taps the notification; the app navigates to that camera's live-view screen as usual.
2. Instead of a spinning loader forever, the screen clearly shows the camera is currently
   unreachable, with the same offline state the dashboard would show, rather than a blank or
   frozen video pane.
3. Priya can still see the event that triggered the notification (thumbnail/clip) even though
   live video isn't available right now.

**What the user expects:** a broken live connection is reported plainly, not left ambiguous or
mistaken for a loading delay.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The live-view screen reached via deep-link shall detect and display an
  explicit "camera unreachable" state, distinct from a loading state, when the target camera
  cannot be reached within a reasonable timeout.
- **[mobile-app]** When live video is unavailable, the deep-linked screen shall still surface
  the underlying event's snapshot/clip that prompted the notification, so the user isn't left
  with nothing.
- **[cloud-components]** The cloud relay shall report a clear failure/unreachable status back to
  the app when it cannot establish a live session with an offline camera, rather than leaving
  the request pending indefinitely.
