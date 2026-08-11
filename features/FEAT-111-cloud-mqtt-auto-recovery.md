# FEAT-111 — Cloud/MQTT Connection Auto-Recovery

**Origin:** Inferred — existing FR/code audit (not from a seed row). Surfaced during the §8.7
Offline operation and synchronization existing-code gap scan, while checking for uncovered
sync-adjacent capability.

**What it is:** The camera's MQTT connection to AWS IoT Core auto-reconnects after a network
blip, so mobile push alerts and remote live-view/control are restored without any user action
(no manual re-pair, no app restart). Backed by `FR-NE-050` (MQTT Connection to AWS IoT Core),
status `Implemented`.

**Why it's not an OFF-* row:** OFF-001 through OFF-013 all describe *durable local
buffering/sync of events and evidence* during a WAN outage. This is connection-layer
resilience for the live alert/command channel — closer in flavor to `FEAT-096`
(WiFi Signal Strength Indicator) and `FEAT-097` (Active Network Interface Indicator) from
§8.6 Camera tamper and health intelligence, both of which are also "network health is
directly relevant to the user" Features. Filed alongside them rather than under §8.7.

**Cross-check performed:** Confirmed FR-HLT-001 (§2.1, "cloud unreachable" state) measures
exactly this connection, but FR-HLT-001 detects/reports the *state*, it doesn't itself
describe the *auto-recovery behavior* — this Feature is the recovery behavior, not the
detection of its absence.

**Priority:** P1 — a reliability expectation, not itself a core P0 security capability.

**User-Facing:** yes — the direct, perceivable benefit is that push alerts and remote control
"just work again" after a blip, without the user having to do anything.

**FR Status:** Existing → FR-NE-050 (Implemented).

**Status:** confirmed (2026-07-21).
