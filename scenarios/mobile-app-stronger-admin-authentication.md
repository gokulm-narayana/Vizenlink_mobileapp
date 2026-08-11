---
feature_id: FEAT-151
status: draft
target_fr_docs: [FR-mobile-app.md, FR-access-control.md]
---

# Scenario: Mobile App — Stronger Authentication for Admins/Remote Access

Covers the mobile-app side of FEAT-151: administrator accounts and any remote (WAN) access
session require a stronger authentication mechanism (e.g. MFA, shorter session lifetime) than
local Viewer-tier access.

## Scenario: Owner enables MFA and it's required for remote access

**Scenario ID:** SCN-544
**Feature ID:** FEAT-151

**Persona:** Nadia, the account owner, setting up her account security.

1. Nadia opens account security settings and enables multi-factor authentication (MFA), adding
   an authenticator app as her second factor.
2. From then on, whenever she logs in from a new device or over WAN (away from her home
   network), she's prompted for both her password and her MFA code.
3. When she's on her home WiFi, doing routine Viewer-tier things, she isn't re-prompted for MFA
   every single time — the stronger check specifically targets admin-level actions and remote
   sessions.
4. Family members with only Viewer-tier local access aren't required to set up MFA at all — the
   requirement targets the Owner/admin tier and remote access, not every account.

**What the user expects:** the extra security step shows up exactly where it matters (her own
privileged account, and remote sessions) without becoming a nuisance for basic local viewing.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall require MFA for any Owner/admin-tier account, and for any WAN
  (remote) access session regardless of tier, distinct from local Viewer-tier access which does
  not require it.
- **[mobile-app]** The app shall let the account owner set up and manage an MFA method (e.g.
  authenticator app) from account security settings.

## Scenario: A remote admin session expires sooner than a local one

**Scenario ID:** SCN-545
**Feature ID:** FEAT-151

**Persona:** Nadia, working remotely, leaving her app open over WAN for an extended period
without interacting with it.

1. Nadia opens the app remotely and authenticates with password + MFA.
2. After a shorter period of inactivity than would apply on her home network, the app requires
   her to re-authenticate before she can perform any admin-level action (e.g. changing another
   user's access).
3. Simple, already-open live view continues, but any privileged action prompts a fresh
   authentication check.
4. Once re-authenticated, she can proceed normally.

**What the user expects:** sensitive/administrative capability doesn't stay "unlocked"
indefinitely on a remote session the way it reasonably can on her own home network.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall apply a shorter session lifetime for admin-level actions
  performed over a remote (WAN) session compared to a local (LAN) session, prompting
  re-authentication when the shorter lifetime elapses.
</content>
