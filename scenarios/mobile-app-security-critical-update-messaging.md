---
feature_id: FEAT-187
status: draft
target_fr_docs: [FR-mobile-app.md, FR-security-lifecycle.md]
---

# Scenario: Mobile App — Security-Critical Update Prioritization Messaging

Covers FEAT-187's mobile-app side: update notifications that clearly distinguish and prioritize
a security-critical OTA update from a routine feature update, so a homeowner is motivated to
install it promptly.

## Scenario: A security-critical update arrives

**Scenario ID:** SCN-619
**Feature ID:** FEAT-187

**Persona:** Priya has automatic updates disabled and checks for updates manually.

1. Priya opens the app and sees a banner on her camera's card: "Critical security update
   available" with a distinct visual treatment (icon + red/amber accent, not the same look as a
   routine update banner).
2. Tapping it shows a short, plain-language explanation of why it's urgent (e.g. "fixes a
   security issue — install as soon as possible") without requiring her to read a full changelog
   to understand the urgency.
3. Priya taps "Update now" and the update installs, same mechanism as any OTA update.

**What the user expects:** she can tell at a glance that this one actually matters and shouldn't
be put off the way she might put off a routine feature update.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall visually distinguish a security-critical update notification
  from a routine/feature update notification, using a distinct label and visual treatment
  rather than one generic "update available" style for both.
- **[mobile-app]** The app shall show a short, plain-language urgency explanation for a
  security-critical update without requiring the user to open a full release-notes/changelog
  view to understand why it matters.
- **[cloud-components]** The update-availability signal delivered to the app shall carry a
  distinct security-critical flag/severity, sourced from the same release metadata used to gate
  the rollout, rather than the app inferring urgency from the version string alone.

## Scenario: Priya defers a security-critical update

**Scenario ID:** SCN-620
**Feature ID:** FEAT-187

**Persona:** Priya, mid-way through something else, dismisses the critical-update banner
instead of installing right away.

1. Priya taps "Remind me later" instead of "Update now."
2. The banner reappears on a shorter interval than a routine update reminder would use, and
   continues to carry the same critical labeling — it doesn't get quietly downgraded to a
   routine reminder after being dismissed once.
3. If the camera is still unpatched after a defined grace period, the app escalates the
   messaging (e.g. a persistent, non-dismissible-until-acknowledged notice) rather than letting
   it fade into the background indefinitely.

**What the user expects:** dismissing it buys her a little time, not indefinite silence — the
app keeps reminding her that this one is different from a routine "what's new" nudge.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall re-surface a deferred security-critical update reminder on a
  shorter interval than a routine update reminder, retaining its critical labeling on every
  reappearance.
- **[mobile-app]** The app shall escalate a still-unpatched security-critical update's messaging
  after a defined grace period, rather than allowing repeated deferrals to silently reduce its
  visibility over time.

## Scenario: Update messaging for a routine feature release (contrast case)

**Scenario ID:** SCN-621
**Feature ID:** FEAT-187

**Persona:** Priya later receives a routine feature update (e.g. a new UI setting), unrelated to
any security fix.

1. The banner shows "Update available" with the standard, non-urgent visual treatment and no
   critical labeling.
2. Priya can dismiss it and it reappears on the normal, longer routine-update cadence, with no
   escalation behavior.

**What the user expects:** routine updates don't cry wolf — only genuinely security-critical
ones get the urgent treatment, so when she does see it, she takes it seriously.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall never apply the security-critical visual treatment or
  escalation cadence to a routine/feature-only update, preserving the distinction's meaning.
