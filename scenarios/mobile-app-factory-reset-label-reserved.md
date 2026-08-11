---
feature_id: FEAT-161
status: draft
target_fr_docs: [FR-mobile-app.md]
---

# Scenario: Mobile App — "Factory Reset" Label Reserved for Destructive Reset Only

Covers the mobile-app side of FEAT-161: the user-facing term "Factory Reset" is never applied
to a lesser action — only to the fully destructive, ownership-clearing reset.

## Scenario: The app clearly separates "Restart" from "Factory Reset"

**Scenario ID:** SCN-578
**Feature ID:** FEAT-161

**Persona:** Sam, troubleshooting a camera that's acting sluggish, looking for a way to restart
it.

1. Sam opens the camera's device settings and sees a "Restart camera" option, described as a
   quick reboot that doesn't change any settings.
2. Right next to it (or in a separate, clearly-marked section), there's a "Factory Reset"
   option, described distinctly as erasing all settings and clearing the camera's
   ownership/pairing entirely.
3. Sam picks "Restart," which reboots the camera without erasing anything, exactly as labeled.
4. He never has to guess whether "Restart" secretly wipes his configuration, because the two
   actions are worded and positioned to be unmistakably different.

**What the user expects:** the word "Factory Reset" is never used loosely — if he sees it, he
knows without doubt it means starting completely from scratch.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall label every lesser action (restart, reboot, network reset,
  clear cache) with wording distinct from "Factory Reset," never using that term for a
  non-destructive action.
- **[mobile-app]** The app shall reserve "Factory Reset" exclusively for the fully destructive,
  ownership-clearing reset action.

## Scenario: A genuine factory reset requires deliberate, multi-step confirmation

**Scenario ID:** SCN-579
**Feature ID:** FEAT-161

**Persona:** Sam, selling his camera to a friend and wanting to properly wipe it first.

1. Sam selects "Factory Reset" from device settings.
2. The app shows an explicit warning describing exactly what will happen: all settings erased,
   all recorded local data cleared, ownership/pairing removed, and that the camera will need to
   be re-provisioned from scratch afterward.
3. Sam has to confirm at least twice (e.g. an initial confirm plus typing the camera's name or a
   "Yes, factory reset" phrase) before the action proceeds — a single accidental tap can't
   trigger it.
4. Once confirmed, the reset proceeds and Sam's account no longer shows the camera as his.

**What the user expects:** an action this destructive is genuinely hard to trigger by
accident, and its consequences are spelled out plainly before it happens.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall require multi-step, explicit confirmation (not a single tap)
  before executing a Factory Reset, describing its full consequences (settings erased,
  ownership cleared, re-provisioning required) in that confirmation.
- **[camera-firmware]** The camera shall clear ownership/pairing state and all local
  configuration only for a genuine Factory Reset command, never for a restart/reboot/
  network-reset command.
</content>
