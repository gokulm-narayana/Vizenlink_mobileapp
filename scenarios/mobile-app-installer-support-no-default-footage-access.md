---
feature_id: FEAT-152
status: draft
target_fr_docs: [FR-mobile-app.md, FR-access-control.md]
---

# Scenario: Mobile App — No Default Footage Access for Installer/Support Roles

Covers the mobile-app side of FEAT-152: Installer and Support Technician roles default to
device/diagnostic access only — no live view, playback, or export — unless explicitly and
separately granted.

## Scenario: Installer is added with device-only access by default

**Scenario ID:** SCN-549
**Feature ID:** FEAT-152

**Persona:** Nadia, having a professional installer set up her new camera; the installer is
added as an "Installer" role on her account.

1. Nadia's installer app account is created with the Installer role during onboarding.
2. By default, the installer can see device status, run connectivity diagnostics, and adjust
   mounting/network settings — but there is no live view or playback available to them at all.
3. Nadia is not asked to separately "turn off" footage access — it's simply not part of what
   Installer grants by default.
4. If Nadia later wants the installer to see footage for a specific reason, she has to
   explicitly grant that separately.

**What the user expects:** a role whose whole job is setting up the device doesn't come
bundled with the ability to watch her home, unless she chooses to grant that herself.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall default the Installer and Support Technician roles to
  device/diagnostic access only, with no live view, playback, or export capability included.
- **[mobile-app]** The app shall require an explicit, separate grant action from an
  owner/admin before an Installer or Support Technician role gains any footage access.

## Scenario: Owner explicitly grants an installer temporary footage access, which then reverts

**Scenario ID:** SCN-550
**Feature ID:** FEAT-152

**Persona:** Nadia, wanting her installer to confirm a camera's field of view actually covers
the driveway as intended.

1. Nadia explicitly grants her installer temporary live-view access, separate from the default
   Installer role permissions.
2. The installer opens live view once, confirms the framing is correct, and Nadia lets the
   grant expire (or revokes it) once the check is done.
3. The installer's account reverts to its default device/diagnostic-only access — no
   lingering footage access remains.
4. The grant and its later expiry/revocation both appear in the household's access audit log.

**What the user expects:** extending temporary footage access to an installer is possible when
genuinely needed, but doesn't become a standing capability she has to remember to take back.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall allow an owner to grant an Installer/Support Technician role a
  separate, explicit footage-access permission distinct from their default device/diagnostic
  scope.
- **[mobile-app]** The app shall record both the grant and its expiry/revocation of installer
  footage access in the access audit log.
</content>
