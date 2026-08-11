---
feature_id: FEAT-009
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md, FR-access-control.md]
---

# Scenario: Mobile App — Privacy Masks

Covers the homeowner-facing side of FEAT-009 (Privacy Masks): drawing static masked regions over
part of the camera's view (e.g. a neighbor's window), restricted to an authorized administrator
of the household account.

## Scenario: Household admin adds a privacy mask over a neighbor's window

**Scenario ID:** SCN-025
**Feature ID:** FEAT-009

**Persona:** Priya, the household account admin, has a side-yard camera whose field of view
partly overlaps her neighbor's bedroom window, and wants to block that area out entirely.

1. Priya opens the camera's privacy mask editor in the app and sees the current live view as a
   reference image.
2. She draws a rectangular region over the window area.
3. She saves the mask, and the live view immediately shows that region permanently blacked out —
   not just blurred — in both live view and any new recordings.
4. The masked region stays blacked out consistently, including in the video the camera streams to
   other authorized viewers on the household account.

**What the user expects:** once she masks an area, it's reliably and consistently hidden for
everyone who can view this camera, not just for her own session.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall provide a privacy mask editor, restricted to the household's
  administrator role, allowing one or more rectangular regions to be drawn over the camera's live
  view and saved.
- **[camera-firmware]** The camera shall apply configured privacy mask regions by permanently
  obscuring (not merely overlaying in the app UI) that area of the video in both the live stream
  and recordings, so the masking is enforced at the source for every viewer.
- **[camera-firmware]** The camera shall persist privacy mask configuration across reboots and
  apply it immediately on stream start.

## Scenario: A non-admin household member cannot edit or remove a mask

**Scenario ID:** SCN-026
**Feature ID:** FEAT-009

**Persona:** Priya's teenage son has a viewer-only account on the same household's camera app and
notices the masked region while watching live view.

1. He opens the camera's settings looking for the privacy mask control.
2. The editor either doesn't appear for his account at all, or appears but is clearly read-only,
   with any attempt to change or remove the mask denied.
3. He can see that a mask exists (so he's not confused about the blacked-out area) but cannot
   alter it.

**What the user expects:** privacy masking decisions stay under the household admin's control —
a viewer-level account can't quietly remove a mask that was placed for someone's actual privacy.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall prevent any account below administrator role from creating,
  modifying, or removing a camera's privacy masks, whether via the UI or a direct request.
- **[camera-firmware]** The camera shall reject a privacy mask configuration change from any
  client that does not authenticate as the household administrator role.
