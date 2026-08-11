---
feature_id: FEAT-131
status: draft
target_fr_docs: [FR-mobile-app.md]
---

# Scenario: Mobile App — Unverified-AI-Event Messaging Guardrail

Covers the mobile-app side of FEAT-131: UI wording must never imply an unverified AI detection
is a confirmed crime or identity until a human verifies it.

## Scenario: A fresh, unverified detection uses hedged language throughout

**Scenario ID:** SCN-494
**Feature ID:** FEAT-131

**Persona:** Priya receives a push notification and opens an event the moment it's generated,
before anyone has reviewed it.

1. The push notification wording is hedged (e.g. "Possible activity detected at Front Door")
   rather than declarative/alarming (never "Intruder detected" or "Break-in in progress").
2. The event detail screen uses the same cautious framing (e.g. "Person detected — unverified")
   consistently in its title, not just the notification.
3. Nowhere in the unverified state does the UI use loaded words like "intruder," "suspect," or
   "crime" — only neutral, descriptive terms about what the AI actually detected.

**What the user expects:** nothing about the wording she sees implies more certainty, or a
worse situation, than an unreviewed AI detection actually warrants.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** All UI copy (push notifications, event titles, badges) for an unverified AI
  detection shall use hedged, neutral wording (e.g. "possible," "detected") and shall never use
  alarming or accusatory terms (e.g. "intruder," "suspect," "break-in") prior to human
  verification.
- **[mobile-app]** The hedged wording shall be applied consistently across every surface
  showing the event (notification, detail screen, list view badge), not varied inconsistently
  between them.

## Scenario: Wording upgrades only after a human confirms the event

**Scenario ID:** SCN-495
**Feature ID:** FEAT-131

**Persona:** Priya reviews the event from SCN-494 and taps "Confirm" because she genuinely
recognizes it as concerning activity.

1. Only after Priya's explicit Confirm action does the event's label change to firmer wording
   (e.g. "Confirmed — Person at Front Door"), and only within her own account's context of what
   she confirmed — the system doesn't unilaterally decide something is "confirmed" from AI
   confidence alone.
2. If Priya instead marks it "False Alert," the wording reflects that outcome (e.g. clearly
   marked as dismissed/false), never staying in an ambiguous unverified-but-scary state
   indefinitely.

**What the user expects:** the language a human sees always accurately reflects whether a
human has actually verified the situation, not just how confident the AI happened to be.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** An event's displayed wording/label shall only upgrade to confirmed/firmer
  language after an explicit human Confirm action, never automatically from AI confidence score
  alone.
- **[mobile-app]** An event marked False Alert by a user shall be labeled accordingly, and shall
  not continue to display hedged-but-alarming unverified wording after that determination.

## Scenario: Guardrail applies even to a high-confidence, named-identity-adjacent detection

**Scenario ID:** SCN-496
**Feature ID:** FEAT-131

**Persona:** Priya's camera flags a person whose appearance closely resembles someone in a
previously-tagged household member/visitor list, at high AI confidence.

1. Even at high confidence, the unverified event's wording avoids naming a specific person
   (e.g. "Possible known visitor detected" rather than asserting the name outright) until Priya
   confirms the identification herself.
2. Once Priya confirms it actually was that person, the event may then reflect that
   confirmed identity in her own event history.

**What the user expects:** the guardrail against overstated certainty applies to claimed
identity just as much as to claimed criminality — a high AI confidence score is never presented
as if it were a human-verified fact.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** UI wording shall not assert a specific person's identity from AI-only
  face/appearance matching, regardless of confidence score, until a human explicitly confirms
  that identification.
- **[camera-firmware]** The camera shall report identity-match confidence as a candidate
  suggestion distinct from a confirmed identity field, so the client can enforce the wording
  guardrail correctly.
