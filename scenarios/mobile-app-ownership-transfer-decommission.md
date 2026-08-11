---
feature_id: FEAT-125
status: draft
target_fr_docs: [FR-mobile-app.md, FR-access-control.md, FR-security-lifecycle.md]
---

# Scenario: Mobile App — Secure Ownership Transfer/Decommission Flow

Covers the mobile-app side of FEAT-125: a distinct, explicit flow for permanently transferring
a camera to a new owner or decommissioning it, clearing prior ownership/credentials.

## Scenario: Selling a camera and transferring ownership to the buyer

**Scenario ID:** SCN-467
**Feature ID:** FEAT-125

**Persona:** Priya is selling her old camera to a neighbor and wants to hand it over cleanly.

1. Priya opens a distinct "Transfer Ownership" flow in the app (separate from ordinary settings
   and clearly labeled as a permanent, hard-to-reverse action), and confirms she wants to
   release the camera.
2. The app requires an explicit confirmation step (e.g. re-entering her password, or a
   "type CONFIRM" style prompt) before proceeding, given the permanence of the action.
3. Once confirmed, the camera clears Priya's account credentials, cloud pairing, and all her
   configured zones/rules/preferences, and returns to an unprovisioned, ready-for-new-owner
   state.
4. Priya's app no longer shows the camera at all, and her prior recordings tied to it are
   handled per the platform's data-retention policy rather than silently transferring to the
   new owner along with the device.

**What the user expects:** handing off a physical device to someone else genuinely severs her
account's access and history, rather than leaving any residual link she'd have to trust the new
owner not to exploit.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide a distinct "Transfer Ownership" flow, separate from
  ordinary settings, requiring an explicit high-friction confirmation before executing.
- **[camera-firmware]** Completing ownership transfer shall clear the camera's account
  credentials, cloud pairing, and all owner-configured settings (zones, rules, preferences),
  returning it to an unprovisioned state ready for a new owner to set up.
- **[cloud-components]** The cloud account system shall unlink the camera from the prior
  owner's account as part of transfer, and shall not automatically link it to any other account
  without that new owner completing their own setup/pairing flow.
- **[security-lifecycle]** Recordings and metadata tied to the prior owner's use of the device
  shall be handled per the platform's data-retention/deletion policy at transfer time, rather
  than implicitly passing to the new owner.

## Scenario: Decommissioning a camera being retired/disposed of

**Scenario ID:** SCN-468
**Feature ID:** FEAT-125

**Persona:** Priya is retiring an old camera entirely (not giving it to anyone) and wants to
make sure no trace of her account remains on it before recycling it.

1. Priya opens a "Decommission Device" flow, distinct from Transfer Ownership, since there's no
   new owner to hand off to.
2. After confirmation, the camera is factory-reset: credentials, pairing, and configuration are
   wiped, and the device returns to its out-of-box unprovisioned state.
3. Priya's account no longer lists the device, and any cloud-side records tied to it are
   handled per the platform's retention policy.

**What the user expects:** a device she's discarding is left with nothing recoverable that
identifies her or her home once she's done.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide a "Decommission Device" flow, distinct from Transfer
  Ownership, for permanently retiring a camera with no new owner, requiring the same explicit
  confirmation.
- **[camera-firmware]** Decommissioning shall factory-reset the camera to its out-of-box
  unprovisioned state, clearing all credentials, pairing, and configuration.

## Scenario: Attempting to transfer a camera that's currently offline

**Scenario ID:** SCN-469
**Feature ID:** FEAT-125

**Persona:** Priya starts the Transfer Ownership flow for a camera that's currently unreachable
(e.g. already unplugged in preparation for handing it over).

1. The app detects the camera can't be reached to receive the transfer/reset command and tells
   Priya plainly, rather than silently marking the transfer complete on her account side only.
2. Priya is guided to reconnect the camera (e.g. plug it back in on the same network) before
   the transfer can actually complete, so the on-device reset genuinely happens.
3. The app does not remove the camera from Priya's account until the device confirms it
   received and applied the reset.

**What the user expects:** ownership transfer only ever completes once the physical device is
actually confirmed reset — it can't be "transferred" on the account side while the device
itself still holds her data and credentials.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall not mark an ownership transfer or decommission complete on the
  account side until the target camera confirms it has applied the credential/configuration
  wipe.
- **[cloud-components]** The cloud account system shall queue a pending transfer/decommission
  command for an unreachable camera and apply it once the camera reconnects, rather than
  completing the account-side change unilaterally.
