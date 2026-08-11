---
feature_id: FEAT-124
status: draft
target_fr_docs: [FR-mobile-app.md, FR-wifi-provisioning.md]
---

# Scenario: Mobile App — Network Recovery Without Data/Ownership Loss

Covers the mobile-app side of FEAT-124: the user-driven recovery flow for reconnecting a
camera after its network configuration changes, guaranteeing recordings and ownership survive.

## Scenario: Reconnecting a camera after replacing the home router

**Scenario ID:** SCN-461
**Feature ID:** FEAT-124

**Persona:** Priya replaces her home router with a new one (new WiFi name and password); her
camera can no longer reach the internet.

1. Priya opens the app and sees the camera reported as offline/unreachable.
2. The app offers a "Reconnect Camera" flow rather than a "Set Up New Camera" flow, making
   clear this is recovering an existing camera, not adding a new one.
3. Priya walks through re-entering the new WiFi credentials (via the WiFi-provisioning portal
   flow) and the camera reconnects.
4. Once reconnected, all of Priya's existing settings (zones, rules, notification
   preferences), her ownership/pairing of the camera, and every previously recorded local clip
   remain exactly as they were before the router change.

**What the user expects:** reconnecting after a network change is a distinct, low-risk "fix
the connection" action — never something that risks looking like starting over from scratch.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall offer a distinct "Reconnect Camera" recovery flow for an
  already-owned, currently-unreachable camera, separate from the new-camera setup flow.
- **[mobile-app]** Completing the reconnect flow shall preserve the camera's existing ownership/
  pairing, configured zones/rules/preferences, and all previously recorded local clips
  unchanged.
- **[wifi-provisioning]** The provisioning flow triggered from "Reconnect Camera" shall update
  only the camera's network credentials, without resetting or clearing any other on-device
  configuration or stored recordings.

## Scenario: Camera's WiFi password changed without a router replacement

**Scenario ID:** SCN-462
**Feature ID:** FEAT-124

**Persona:** Priya just changed her home WiFi password for security reasons; the router itself
and network name are unchanged.

1. The app detects the camera can no longer authenticate (distinct from being fully
   unreachable) and prompts Priya specifically to update the saved WiFi password.
2. Priya enters the new password once, through the same reconnect flow, and the camera resumes
   normal operation immediately.

**What the user expects:** a simple password change is recovered from with minimal steps —
she isn't forced through a full re-provisioning wizard for what's really a one-field update.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall distinguish an authentication failure (wrong/changed password,
  same network) from a fully unreachable camera, and shall offer a shortened credential-only
  update path for the former.

## Scenario: Reconnect flow is interrupted partway through

**Scenario ID:** SCN-463
**Feature ID:** FEAT-124

**Persona:** Priya starts the reconnect flow but closes the app (or loses her own phone's
connectivity) before it finishes.

1. The camera, having not yet received complete new credentials, remains on its prior
   configuration rather than ending up in a half-configured or bricked state.
2. Priya can safely restart the reconnect flow from the beginning; nothing about the partial
   attempt corrupts existing recordings or ownership state.

**What the user expects:** an interrupted recovery attempt is always safely retryable — it
never leaves the camera or her data in a worse state than before she started.

> **Review:** ⏳ Pending

### Derived Requirements

- **[wifi-provisioning]** The provisioning flow shall apply new network credentials atomically
  — a camera that doesn't receive a complete, valid credential update shall retain its prior
  working configuration rather than entering a partially-applied state.
- **[mobile-app]** The app shall allow safely restarting an interrupted reconnect flow from the
  beginning without any risk to the camera's existing ownership state or stored recordings.
