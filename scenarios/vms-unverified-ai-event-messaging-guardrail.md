---
feature_id: FEAT-131
status: draft
target_fr_docs: [FR-vms.md]
---

# Scenario: VMS — Unverified-AI-Event Messaging Guardrail

Covers the VMS side of FEAT-131: the same wording guardrail applied consistently across the
operator dashboard, alert feed, and case-management surfaces.

## Scenario: The alert feed and dashboard use hedged wording for unverified events

**Scenario ID:** SCN-497
**Feature ID:** FEAT-131

**Persona:** Marcus scans the fleet alert feed, which includes several just-generated,
unreviewed events.

1. Every unverified event in the feed and on the dashboard uses the same hedged, neutral
   wording convention as the mobile app (e.g. "Possible activity" rather than "Intruder"), with
   no VMS-specific wording that's more alarming than the mobile app's equivalent.
2. Once any operator confirms an event (per FEAT-117), its wording updates fleet-wide for every
   operator viewing it — consistent with the real-time status sync in FEAT-133 — rather than
   staying in unverified language for operators who haven't personally reviewed it.

**What the user expects:** the wording guardrail isn't a mobile-app-only nicety — it applies
uniformly across every surface operators use.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** All UI copy in the alert feed and dashboard for an unverified AI detection shall use
  the same hedged, neutral wording convention as the mobile app, never alarming or accusatory
  terms, prior to human verification.
- **[vms]** An event's wording shall upgrade to confirmed/firmer language for all operators
  once any authorized operator confirms it, consistent with real-time cross-user status sync.

## Scenario: An operator's own case note must not overstate an unverified detection

**Scenario ID:** SCN-498
**Feature ID:** FEAT-131

**Persona:** Marcus is drafting an incident note (FEAT-126) on an event that hasn't yet been
formally confirmed.

1. The incident-status/notes UI itself doesn't pre-fill or suggest language that overstates
   certainty (e.g. it doesn't default a status label to "Confirmed Intruder" just because
   Marcus opened a case on it) — opening a case and confirming an event's authenticity remain
   two distinct actions.
2. If Marcus's own free-text note asserts something the system hasn't verified, that's his own
   editorial judgment as a human reviewer — the guardrail's job is to ensure the *system's own*
   default labels and prompts never lead him toward overstating it, not to censor his notes.

**What the user expects:** the system's own default language nudges toward caution, without
his own genuine human assessment being blocked or put in the same bucket as an unverified
AI claim.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** Incident case-management default statuses/prompts shall not imply a confirmed
  determination merely from a case being opened; confirming an event's authenticity remains a
  distinct action from creating or annotating an incident case.
- **[vms]** The guardrail shall govern system-generated default wording and labels only — an
  operator's own free-text notes are their own human judgment and are not constrained in
  content, only distinguished visually from system-generated status labels.
