---
feature_id: FEAT-155
status: draft
target_fr_docs: [FR-mobile-app.md, FR-access-control.md]
---

# Scenario: Mobile App — Last Access & Active Session Visibility

Covers the mobile-app side of FEAT-155: an owner/admin can see last-access time and currently
active sessions for their account, and end other sessions remotely.

## Scenario: Owner checks last-access time and current active sessions

**Scenario ID:** SCN-563
**Feature ID:** FEAT-155

**Persona:** Nadia, checking her account's security page out of general good practice.

1. Nadia opens her account security settings and finds a "Last access" section, showing when
   her account was last used, from where (device type / rough location), and any currently
   active sessions.
2. She sees two active sessions: her own phone (currently open) and a tablet she used yesterday
   and forgot to close.
3. She ends the tablet session remotely from her phone; it logs out immediately.

**What the user expects:** she can see exactly what's currently logged into her account and
can clean up sessions she no longer needs, without having to physically have that device in
hand.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall display last-access time and a list of currently active
  sessions for the account, including device/platform information for each.
- **[mobile-app]** The app shall let the owner end any listed active session remotely,
  immediately terminating it.

## Scenario: Owner spots an unrecognized active session

**Scenario ID:** SCN-564
**Feature ID:** FEAT-155

**Persona:** Nadia, reviewing the same active-sessions list, finds a session she doesn't
recognize at all.

1. Nadia sees an active session from a device/platform she's never used and a location that
   doesn't match anywhere she's been.
2. She immediately ends that session from her own device.
3. The app also prompts her to change her password given the suspicious activity, since an
   unrecognized session could mean her credentials were compromised.

**What the user expects:** spotting something wrong gives her an immediate, effective way to
shut it down and take the next protective step, not just a "flag it and hope."

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall allow immediate remote termination of any active session,
  including one the owner doesn't recognize as their own.
- **[mobile-app]** The app shall prompt a password-change recommendation when a session is
  ended specifically because it was flagged/reported as unrecognized.
</content>
