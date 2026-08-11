# FEAT-113 — Buffered-Event Timestamp Reconciliation After Reboot

**Origin:** Inferred — domain/industry-standard CCTV practice (not from a seed row or the
existing-FR/code audit). Raised during the §8.7 domain-knowledge gap scan for Offline
operation and synchronization.

**Why it's necessary/basic:** Grounded in this repo's actual firmware, not a guess. The
camera has no RTC battery — `ameba-rtos-pro2/project/nuraeye/src/main.c`'s `prvSntpSyncThread`
shows system time comes entirely from SNTP after boot. During a WAN/power outage where the
camera itself also reboots (not just loses network), there is a window after boot but before
SNTP re-syncs where the system clock is wrong or at a default epoch value. If OFF-002/OFF-003
(stable event ID + local buffering) start recording events in that window, those events would
be timestamped incorrectly and — without explicit reconciliation — that wrong timestamp would
persist permanently once synced to cloud, since nothing currently re-derives it after the
clock becomes accurate.

Correct timestamps on security events are basic table-stakes for any CCTV product — users and
any legal/incident review depend on "when did this happen" being right, and this repo's own
`APP-003` (§8.8) already commits to showing event "local time" in the app.

**Cross-check performed:** Re-read all 13 `OFF-*` rows — none mention clock/time accuracy
during buffering, only recording/AI continuity, ID assignment, buffering, sync state, upload
integrity, queue policy, eviction, dropped-event accounting, throttling, retention target,
diagnostics, and the ownership guardrail. None address the SNTP-dependency gap. Not listed in
§3.3 Non-goals or as a `Gated` seed ID either.

**Priority:** P1 — a correctness/trust issue, not itself a core P0 security capability.

**User-Facing:** no — the user directly perceives the (corrected) timestamp in the app/VMS
timeline, but has no dial to operate; same reasoning as `FEAT-030`/`FEAT-107`/`FEAT-110`.

**FR Status:** Not started — no FR entry addresses clock reconciliation for offline-buffered
events.

**Status:** confirmed (2026-07-21).
