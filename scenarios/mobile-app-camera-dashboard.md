---
feature_id: FEAT-114
status: draft
target_fr_docs: [FR-mobile-app.md, FR-nuraeye-service.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Camera List/Grid Dashboard with Status Badges

Covers the mobile-app home-screen dashboard side of FEAT-114: a homeowner's single view of all
their cameras, each carrying at-a-glance status badges.

## Scenario: Opening the app shows every camera's status at a glance

**Scenario ID:** SCN-409
**Feature ID:** FEAT-114

**Persona:** Priya, a homeowner with four cameras (front door, driveway, backyard, garage),
opens the app after not checking it for a day.

1. The home screen loads a list or grid of all four cameras, each with a thumbnail.
2. Each card shows, without Priya tapping anything: whether the camera is online, whether it's
   currently recording, a health indicator (e.g. a warning icon if something needs attention),
   and a badge for unread/unreviewed events since she last looked.
3. Priya can tell in one glance which camera(s), if any, need her attention, without opening
   each one individually.
4. She can switch between list and grid layout, and her choice is remembered next time she
   opens the app.

**What the user expects:** the home screen alone answers "is everything okay?" without having
to dig into a single camera's detail view.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall render a home-screen list or grid view listing every camera
  associated with the user's account, each with a live or recent thumbnail.
- **[mobile-app]** Each camera card shall display, without further navigation: online/offline
  status, recording status, a health/attention indicator, and a count or badge of unread
  events since the user last viewed that camera.
- **[mobile-app]** The app shall let the user toggle between list and grid layout and persist
  that preference across sessions.
- **[cloud-components]** The app shall retrieve current per-camera status (online, recording,
  health) via the cloud relay for any camera not reachable directly on the local network, so
  the dashboard is accurate away from home.
- **[camera-firmware]** The camera shall expose its current online/recording/health state on
  status query so the dashboard badge reflects real-time state rather than a stale cached
  value.

## Scenario: One camera goes offline while the dashboard is open

**Scenario ID:** SCN-410
**Feature ID:** FEAT-114

**Persona:** Priya has the dashboard open when her garage camera loses power (tripped breaker).

1. Within a short time of the camera dropping off the network, its card updates from "Online"
   to "Offline" without Priya refreshing the screen.
2. The thumbnail for that camera either freezes on the last known frame or shows a clear
   "offline" placeholder — never a blank or broken-looking tile.
3. The offline badge is visually distinct enough (color, icon) that Priya notices it while
   scanning the grid, not buried among the other status text.

**What the user expects:** the dashboard reflects a camera going down in near-real time, and
makes that one card impossible to miss at a glance.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall update a camera's card to an "Offline" state within a short,
  bounded delay of the camera becoming unreachable, without requiring a manual refresh while
  the dashboard is in the foreground.
- **[mobile-app]** An offline camera's thumbnail shall show its last-known frame or an explicit
  offline placeholder, and its status badge shall be visually distinct from healthy-state
  badges (e.g. color-coded), so it isn't overlooked in a grid of many cameras.
- **[cloud-components]** The cloud relay shall propagate a camera's connectivity-loss event to
  subscribed mobile clients promptly, rather than only being discoverable on the next poll.

## Scenario: Dashboard with no unread events and a healthy fleet

**Scenario ID:** SCN-411
**Feature ID:** FEAT-114

**Persona:** Priya opens the app on an ordinary day when nothing has happened — all cameras
online, recording, healthy, and no new events.

1. Every card shows a calm, uniform "all good" state — no red/yellow badges anywhere, no
   unread-event counts.
2. The dashboard does not manufacture visual noise (e.g. a badge showing "0") just to have
   something to show — an empty/zero state is visually quiet, not alarming.

**What the user expects:** when nothing is wrong, the dashboard should look and feel calm, not
cluttered with zero-value indicators that could be mistaken for something needing attention.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall render a distinct "nothing to review" visual state (no badge,
  or a clearly neutral badge) for a camera with zero unread events, rather than showing a
  numeric "0" badge that could be misread as an alert.
- **[mobile-app]** The app shall use a consistent, low-attention visual treatment across all
  cards when the whole fleet is healthy, so a calm state doesn't compete visually with an
  actual attention-needed state.
