---
feature_id: FEAT-005
status: decomposed
target_fr_docs: [FR-mobile-app.md, FR-nuraeye-service.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Day/Night Mode

Covers the homeowner-facing side of FEAT-005 (Day/Night Switching & IR Night Vision): the
automatic Auto/Day/Night behavior as experienced through the mobile app, plus the manual
Auto/Day/Night mode selector.

## Scenario: Automatic switch to night vision at dusk

**Scenario ID:** SCN-001
**Feature ID:** FEAT-005

**Persona:** Priya, a homeowner with the camera set to Auto mode, has the mobile app open on
live view as evening falls.

1. As ambient light drops below a usable threshold, the camera transitions itself from color
   day mode to infrared night mode without any action from Priya.
2. The moment it switches, the camera emits a mode-change event rather than waiting to be asked.
3. The app, already connected and listening, receives that event and updates the live view to
   the black-and-white infrared image, and the mode indicator, within a few seconds of the
   actual switch.
4. The app's mode indicator (wherever it's shown) updates from "Auto — Day" to "Auto — Night" to
   reflect the camera's current state, not just the configured mode.
5. Priya can still see a usable, adequately illuminated image of her porch despite it now being
   fully dark outside.

If Priya's app wasn't open/connected at the moment of the switch (e.g. backgrounded, or she was
disconnected over WAN), it still shows the correct "Auto — Night" state the next time she opens
live view or the app reconnects — by fetching current status at that point rather than relying
solely on having received the earlier event.

**What the user expects:** the camera "just knows" when it's dark enough to switch, and the app
always shows what the camera is actually doing right now — live, if she's watching, and
correctly caught up if she wasn't.

> **Review:** ✅ Accepted — 2026-07-23

### Derived Requirements

- **[mobile-app]** The app shall display the camera's current effective day/night state (e.g.
  "Auto — Night") distinctly from the configured mode (e.g. "Auto"), so a user in Auto mode can
  tell what the camera is doing right now.
- **[mobile-app]** The app shall update its mode indicator upon receiving a mode-change event
  from the camera while connected, without requiring the user to manually refresh.
- **[mobile-app]** The app shall fetch current day/night status on live-view open / app
  foreground / reconnect, so a mode change that happened while disconnected is reflected
  correctly rather than showing stale state.
- **[camera-firmware]** The camera shall autonomously switch between day (color) and night
  (infrared) capture based on ambient light when in Auto mode, without requiring any command
  from a connected client.
- **[camera-firmware]** The camera shall emit a mode-change event at the moment its effective
  day/night state changes (autonomous or manual), rather than only exposing it as a value a
  client must poll for.
- **[camera-firmware]** The camera shall also report its current effective day/night state on
  direct status query, so a client that reconnects after missing the event can still resync.
- **[cloud-components]** When the app is connected over WAN, the camera's mode-change event
  shall be relayed via the existing MQTT alert channel rather than requiring the app to poll
  over an open connection.

## Scenario: Manual override to Night mode during the day

**Scenario ID:** SCN-002
**Feature ID:** FEAT-005

**Persona:** Priya wants to check how her camera's night vision looks before dark, or has a
reason to force infrared capture despite daylight (e.g. testing, or a shaded area that stays
dim even at midday).

1. Priya opens the camera's video-mode setting in the app and selects "Night" instead of "Auto."
2. The camera switches to infrared capture within a few seconds, even though it's daytime.
3. The app confirms the change was applied and shows "Night" (not "Auto") as the current mode,
   making clear this is a manual override, not the automatic behavior.
4. The camera stays in Night mode continuously until Priya changes it again — it does not
   auto-revert to Day as ambient light changes.

**What the user expects:** she can force night vision on demand, and the app is clear that
she's now overriding the automatic behavior rather than merely observing it.

> **Review:** ✅ Accepted — 2026-07-23

### Derived Requirements

- **[mobile-app]** The app shall let an authorized user explicitly select Day, Night, or Auto
  mode from a dedicated video-mode control, distinct from the passive mode-state display.
- **[mobile-app]** The app shall visually distinguish a manually-set mode (Day/Night) from Auto
  mode in its mode indicator, so the user can tell a manual override is active.
- **[camera-firmware]** The camera shall accept an explicit Day/Night/Auto mode command from an
  authorized client and apply it, overriding automatic light-based switching until a new mode
  command is received.
- **[cloud-components]** When the mobile app issues a mode-change command while connected over
  WAN, the command shall be relayed to the camera via the AWS IoT Core / MQTT command channel
  rather than requiring a LAN connection.

## Scenario: Returning to Auto after a manual override

**Scenario ID:** SCN-003
**Feature ID:** FEAT-005

**Persona:** Priya, having manually forced Night mode earlier (Scenario SCN-002), now wants the
camera to resume deciding for itself.

1. Priya reopens the video-mode control and selects "Auto."
2. The camera immediately re-evaluates ambient light and switches to whichever of Day/Night
   actually matches current conditions — it does not require the previous manual mode to
   "expire" first.
3. The app's indicator updates to reflect the resumed automatic behavior (e.g. "Auto — Day" if
   it's currently light out).

**What the user expects:** switching back to Auto is a single, immediate action with no
transition delay or leftover state from the manual override.

> **Review:** ✅ Accepted — 2026-07-23

### Derived Requirements

- **[mobile-app]** The app shall let a user revert from a manually-set mode back to Auto using
  the same control used to set the manual override.
- **[camera-firmware]** The camera shall immediately resume automatic light-based day/night
  switching upon receiving an Auto mode command, evaluating current ambient light rather than
  waiting for the next scheduled check.

## Scenario: Borderline dusk/dawn light doesn't cause flicker

**Scenario ID:** SCN-004
**Feature ID:** FEAT-005

**Persona:** Priya's camera faces a west-facing yard where light levels hover right around the
day/night switching threshold for extended periods at dusk.

1. As light fades through the borderline range, the camera does not rapidly flip back and forth
   between Day and Night capture.
2. Once the camera does switch to Night, it doesn't immediately flip back to Day if light
   briefly ticks back up (e.g. a passing headlight, a porch light triggering).
3. Priya's live view stays visually stable through this transition period — no repeated,
   distracting mode flicker.

**What the user expects:** the automatic switch feels like a single, deliberate transition each
evening and morning, never a rapid back-and-forth.

> **Review:** ✅ Accepted — 2026-07-23

### Derived Requirements

- **[camera-firmware]** The camera shall apply hysteresis/debounce to automatic day/night
  switching so that transient light-level fluctuations near the switching threshold do not
  cause repeated mode flapping.
- **[mobile-app]** The app's mode-state indicator shall update only on a confirmed, stable
  mode change from the camera, not on transient intermediate reports, so the UI itself doesn't
  visibly flicker even if backend state briefly does.

## Scenario: Mode-change request fails because the camera is unreachable

**Scenario ID:** SCN-005
**Feature ID:** FEAT-005

**Persona:** Priya tries to switch her camera to Night mode manually while away from home, but
the camera has lost its connection (e.g. WiFi outage at the house).

1. Priya selects "Night" in the app's video-mode control.
2. The app attempts to send the command and, after a reasonable timeout, reports that the
   change could not be confirmed — it does not silently show "Night" as if the change succeeded.
3. The mode indicator continues to show the last known mode/state rather than the
   requested-but-unconfirmed one.
4. Priya can retry once connectivity is restored.

**What the user expects:** the app never claims a setting change took effect when it can't
actually confirm the camera received it.

> **Review:** ✅ Accepted — 2026-07-23

### Derived Requirements

- **[mobile-app]** The app shall not update its displayed mode/state until the camera has
  acknowledged the mode-change command; on failure or timeout, it shall show an explicit error
  rather than an optimistic success state.
- **[cloud-components]** The MQTT command relay shall surface a delivery failure/timeout back to
  the mobile app when a mode-change command cannot reach an unreachable camera, rather than
  reporting silent success.
