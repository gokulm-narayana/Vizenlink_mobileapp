---
feature_id: FEAT-165
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Installation Reference View Capture

Covers FEAT-165: as part of commissioning, capture and store a reference snapshot of the
camera's view, used later to detect unauthorized or accidental camera movement.

## Scenario: Installer captures a reference view as part of commissioning

**Scenario ID:** SCN-591
**Feature ID:** FEAT-165

**Persona:** Diego, finishing up an installation, now at the reference-capture step of the
checklist.

1. As part of the commissioning checklist, the app prompts Diego to confirm the current framing
   looks correct and capture it as the camera's official reference view.
2. Diego reviews the live image, confirms it's angled and framed as intended, and taps "Set as
   reference view."
3. The app stores this snapshot associated with the camera, to be used later to detect
   unauthorized or accidental movement.
4. Diego proceeds to complete the rest of the checklist.

**What the user expects:** establishing "what this camera should be looking at" is a
deliberate, one-time part of the installation, not something left implicit.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let the installer capture and store a reference snapshot of
  the camera's view as part of commissioning.
- **[camera-firmware]** The camera shall support capturing and persisting a designated
  reference-view snapshot associated with its configuration.

## Scenario: The homeowner intentionally re-aims the camera and needs a new reference view

**Scenario ID:** SCN-592
**Feature ID:** FEAT-165

**Persona:** Priya, deciding months later to angle her backyard camera slightly differently to
cover a new shed.

1. Priya adjusts the camera's physical aim herself.
2. Rather than the system repeatedly flagging the new (deliberate) framing as "possible
   tamper" indefinitely, the app offers her a way to review and re-confirm the current view as
   the new official reference.
3. She reviews the updated framing, confirms it's what she intends, and sets it as the new
   reference view, replacing the old one.
4. Future movement comparisons use this new reference rather than the original
   installation-time one.

**What the user expects:** a deliberate re-aim by the owner isn't treated as a permanent false
alarm — she can establish a new "normal" view when she means to change it.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall allow the account owner (not just the original installer) to
  review the current camera view and re-set it as the reference view after an intentional
  re-aim.
- **[camera-firmware]** The camera shall replace its stored reference-view snapshot when a new
  one is explicitly set, rather than keeping the original installation-time reference
  indefinitely.
</content>
