---
feature_id: FEAT-070
status: draft
target_fr_docs: [FR-mobile-app.md, FR-security-rules-engine.md]
---

# Scenario: Mobile App — Installer Rule Test Mode

Covers the homeowner-facing side of FEAT-070: running a new rule in test mode (events
generated, no notifications sent) before trusting it with live notifications.

## Scenario: Homeowner tests a new zone rule silently before enabling notifications

**Scenario ID:** SCN-247
**Feature ID:** FEAT-070

**Persona:** Raj, who just drew a new zone and built a rule on it, but isn't sure yet whether
the zone boundary is well-tuned to his yard.

1. When Raj finishes creating the rule, the app offers "Test mode" as the initial state rather
   than defaulting straight to live notifications.
2. While in test mode, the app shows a running log of events the rule would have triggered
   on, but Raj's phone receives no push notifications for any of them.
3. After watching the test log for a day and confirming the zone behaves as expected, Raj
   switches the rule to "Live" and notifications begin.

**What the user expects:** he can see exactly what a new rule would have alerted him about
without actually being interrupted by it, so he can be confident it's tuned right before it
starts buzzing his phone.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall offer a "Test mode" state for any rule, distinct from "Live,"
  in which triggered events are logged and viewable in the app but no push notification (or
  other live alert) is sent to the user.
- **[camera-firmware]** The camera shall evaluate a test-mode rule's trigger condition
  identically to a live rule and record matching events, while suppressing the outbound alert
  that would otherwise notify a connected client.

## Scenario: Forgetting to exit test mode

**Scenario ID:** SCN-248
**Feature ID:** FEAT-070

**Persona:** Raj, who tested a rule two weeks ago and forgot to switch it to Live, not realizing
he's had zero notifications from it since.

1. Raj opens his rules list and sees the rule still marked "Test mode," with a visible
   duration indicator (e.g. "In test mode for 14 days").
2. The app proactively surfaces a reminder that a rule has been in test mode for an unusually
   long time, prompting him to review and either go live or intentionally keep testing.
3. Raj reviews the test log, is satisfied, and switches the rule to Live.

**What the user expects:** the app doesn't let a forgotten test-mode rule silently provide zero
real protection indefinitely — it nudges him to notice and decide.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall visibly and persistently indicate that a rule is in test mode
  (not just at creation time) on its summary/list view, including how long it has been in that
  state, and shall proactively prompt the user to review a rule that has remained in test mode
  beyond a reasonable duration.
