---
feature_id: FEAT-123
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md]
---

# Scenario: Mobile App — Storage-Failure Alert Prioritization

Covers the mobile-app side of FEAT-123: a recording/storage failure must visually outrank
ordinary activity alerts in the notification/alert feed.

## Scenario: A storage failure alert stands out from routine motion alerts

**Scenario ID:** SCN-456
**Feature ID:** FEAT-123

**Persona:** Priya's camera's SD card fails while she also has several routine motion alerts
from the same day.

1. The storage-failure alert appears at the top of Priya's alert feed regardless of its
   timestamp relative to other alerts, with a visually distinct treatment (e.g. red banner
   styling, a dedicated icon) that ordinary motion/detection alerts don't use.
2. The push notification for the storage failure is delivered even if Priya has muted or
   scheduled quiet hours for ordinary activity notifications (per FEAT-120), since it's a
   health issue, not routine activity.

**What the user expects:** something is clearly, unmistakably wrong with her camera's ability
to keep recording — this can't blend into the normal stream of "someone walked by" alerts.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The alert feed shall render a storage/recording-failure alert with a
  visually distinct treatment separate from ordinary activity alerts, and shall pin it above
  routine alerts regardless of chronological order.
- **[mobile-app]** A storage/recording-failure push notification shall bypass the user's
  activity-notification schedule/quiet-hours preferences, since it represents a health issue
  rather than routine detected activity.
- **[camera-firmware]** The camera shall detect and report a storage/recording failure (e.g.
  SD card fault, write failure, disk full) as a distinct health event, separate from its normal
  AI-detection event stream.

## Scenario: A storage failure alert remains prominent until resolved

**Scenario ID:** SCN-457
**Feature ID:** FEAT-123

**Persona:** Priya sees the storage failure alert but doesn't act on it immediately.

1. The storage-failure alert stays pinned at the top of the feed across app sessions — it isn't
   pushed down by newer ordinary activity alerts arriving afterward.
2. Priya can dismiss/acknowledge it explicitly, but a routine swipe-to-clear gesture used for
   ordinary alerts doesn't silently clear it without confirmation.
3. Once the underlying issue is actually resolved (e.g. she replaces the SD card and the camera
   reports storage healthy again), the alert updates to a resolved state rather than lingering
   indefinitely.

**What the user expects:** an unresolved storage problem keeps demanding attention until either
she acts on it or the camera confirms it's fixed — it can't be accidentally swiped away like a
routine notification.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** A storage/recording-failure alert shall remain pinned above newer ordinary
  activity alerts until explicitly acknowledged or resolved, and shall require an explicit
  confirmation to dismiss rather than a routine swipe gesture.
- **[camera-firmware]** The camera shall report when a previously-failed storage condition has
  recovered, so the app can update the alert to a resolved state rather than leaving it open
  indefinitely.

## Scenario: Multiple simultaneous health issues are all prioritized, ranked by severity

**Scenario ID:** SCN-458
**Feature ID:** FEAT-123

**Persona:** Priya's camera reports both a storage failure and a separate tamper alert around
the same time.

1. Both health alerts appear above routine activity alerts, and are themselves ordered relative
   to each other by severity (e.g. tamper, being an active-threat signal, ranked above a
   storage capacity warning that isn't yet a hard failure).
2. Priya can distinguish the two health alerts from each other clearly, not just from the
   routine activity below them.

**What the user expects:** when several things need attention at once, the feed still gives her
a sensible priority order rather than an undifferentiated pile of "important" alerts.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The alert feed shall rank multiple concurrent health-category alerts (e.g.
  storage failure, tamper) among themselves by defined severity, in addition to ranking the
  whole health category above routine activity alerts.
