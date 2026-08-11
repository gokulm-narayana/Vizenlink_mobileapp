---
feature_id: FEAT-151
status: draft
target_fr_docs: [FR-vms.md, FR-access-control.md]
---

# Scenario: VMS — Stronger Authentication for Admins/Remote Access

Covers the VMS side of FEAT-151: administrator accounts and remote (WAN) access sessions
require a stronger authentication mechanism than local Viewer-tier access.

## Scenario: Organization admin account requires MFA at login

**Scenario ID:** SCN-546
**Feature ID:** FEAT-151

**Persona:** Farid, Site Owner, logging into the VMS web console.

1. Farid enters his username and password on the VMS login page.
2. Because his account is an admin-tier role (Site Owner), the VMS requires a second factor
   before granting access, even though he's logging in from the office network.
3. He completes the MFA challenge and reaches his dashboard.
4. A Resident/Tenant Viewer-tier account logging in from the same network is not required to
   complete MFA, since the stronger requirement targets admin tiers specifically.

**What the user expects:** the accounts with the most power are the ones held to the higher
bar, not every login regardless of privilege.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall require MFA for any admin-tier account (e.g. Site Owner, Security
  Supervisor) logging in, regardless of network location.
- **[vms]** The VMS shall not require MFA for lower-privilege, view-only tier accounts as a
  blanket rule, keeping the stronger requirement targeted at admin/remote access.

## Scenario: Admin loses their MFA device and needs recovery

**Scenario ID:** SCN-547
**Feature ID:** FEAT-151

**Persona:** Farid, having lost his phone (and with it, his authenticator app), unable to
complete his usual MFA challenge.

1. Farid attempts to log in and reaches the MFA prompt, but has no way to produce a valid code.
2. He uses a pre-established recovery path (e.g. backup codes generated at MFA setup, or a
   verified support-assisted reset) rather than being permanently locked out.
3. The recovery path itself requires meaningful proof of identity — it isn't a "skip MFA"
   bypass — and the recovery event is logged in the audit trail.
4. Once recovered, Farid is prompted to set up a new MFA method.

**What the user expects:** losing a second factor is a recoverable situation, not a lockout,
but recovery isn't a shortcut around the security requirement either.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide an MFA recovery path (e.g. backup codes or verified
  support-assisted reset) for an admin who has lost their second factor, without weakening the
  underlying requirement.
- **[vms]** The VMS shall log an MFA recovery/reset event in the audit trail, attributed and
  timestamped, given its security sensitivity.

## Scenario: A remote (WAN) admin session gets a shorter lifetime than a local console session

**Scenario ID:** SCN-548
**Feature ID:** FEAT-151

**Persona:** Farid, accessing the VMS remotely from home in the evening rather than from the
office console.

1. Farid logs into the VMS from home over the internet, completing MFA.
2. His session is configured with a shorter idle/absolute timeout than would apply if he were
   on the office's local network console.
3. After that shorter period, the VMS requires him to re-authenticate before continuing any
   admin action, even though he hasn't explicitly logged out.
4. His office colleague, logged in locally at the same time, keeps a longer-lived session under
   the same idle conditions.

**What the user expects:** the extra caution around remote admin access naturally includes a
tighter session lifetime, not just the login-time MFA check.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall apply a shorter session lifetime to admin-tier sessions authenticated
  over remote/WAN access compared to local/LAN console sessions.
</content>
