---
feature_id: FEAT-155
status: draft
target_fr_docs: [FR-vms.md, FR-access-control.md]
---

# Scenario: VMS — Last Access & Active Session Visibility

Covers the VMS side of FEAT-155: an admin can see last-access time and currently active
sessions across the organization, and end other sessions remotely.

## Scenario: Admin reviews active sessions across the organization

**Scenario ID:** SCN-565
**Feature ID:** FEAT-155

**Persona:** Farid, doing a periodic security check of who's currently logged into the VMS
across his sites.

1. Farid opens the VMS's session management screen and sees every currently active session
   across the organization, each showing the user, role, site, device/browser, and last-access
   time.
2. He notices a Security Operator's session has been open for several days without activity and
   ends it remotely.
3. That operator's next action in the VMS (if they return) requires a fresh login.

**What the user expects:** he has one place to see and control everyone's live sessions
across the whole org, not just his own.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall display last-access time and all currently active sessions across the
  organization, with user, role, site, and device information for each.
- **[vms]** The VMS shall let an authorized admin remotely terminate any listed active session.

## Scenario: A terminated user is clearly informed their session was ended

**Scenario ID:** SCN-566
**Feature ID:** FEAT-155

**Persona:** The Security Operator from the previous scenario, returning to a browser tab that
was still open with their old session.

1. The operator, unaware their idle session was remotely ended, clicks something in their
   still-open VMS tab.
2. Instead of a confusing generic error, the VMS tells them their session was ended (e.g. due
   to inactivity or an admin action) and prompts them to log in again.
3. Once logged back in, they resume normal work with a fresh session.

**What the user expects:** being logged out remotely isn't a mysterious dead end for the
affected user — it's communicated plainly, with an easy way back in if their access is still
valid.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall present a clear "session ended" message (rather than a generic error)
  to a user whose active session was remotely terminated, with a path to re-authenticate if
  their access is still valid.
</content>
