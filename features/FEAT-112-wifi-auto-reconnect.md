# FEAT-112 — WiFi Auto-Reconnect

**Origin:** Inferred — existing FR/code audit (not from a seed row). Surfaced during the §8.7
Offline operation and synchronization existing-code gap scan, while checking for uncovered
sync-adjacent capability.

**What it is:** After a router/WiFi outage, the camera automatically restores its WiFi station
connection and resumes normal operation — no manual reboot, no re-entering WiFi credentials,
no re-running WiFi provisioning. Implemented in firmware networking code (this path has a
multi-iteration fix history, i.e. it has already been hardened, not newly written).

**Why it's not an OFF-* row:** OFF-001 through OFF-013 describe durable local buffering/sync
of *events and evidence* during a WAN/cloud outage — they assume the camera stays network-
attached at the link layer and only the cloud path is down. This Feature is the layer below
that: recovering the WiFi link itself. Filed alongside `FEAT-096`/`FEAT-097` (§8.6 connectivity
health) rather than under §8.7, same reasoning as `FEAT-111`.

**Cross-check performed:** No existing `HLT-*` or `OFF-*` row describes link-layer WiFi
recovery explicitly; the closest is `FEAT-096` (RSSI indicator), which reports signal quality
but not recovery behavior after a full drop.

**Priority:** P1 — a reliability expectation, not itself a core P0 security capability.

**User-Facing:** yes — the user experiences the camera simply working again after a router
reboot/outage, without needing to touch the WiFi-provisioning flow again.

**FR Status:** Existing in code, no FR entry yet.

**Status:** confirmed (2026-07-21).
