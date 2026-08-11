---
feature_id: FEAT-195
status: draft
target_fr_docs: [FR-mobile-app.md, FR-security-lifecycle.md]
---

# Scenario: Mobile App — Export Watermarking & Redaction Indicator

Covers FEAT-195's homeowner side: exported/shared footage carrying a watermark, and a visible
indicator whenever any part of what's been exported has been redacted/masked.

## Scenario: Sharing a clip shows a watermark on the exported file

**Scenario ID:** SCN-640
**Feature ID:** FEAT-195

**Persona:** Priya exports a short clip of a delivery to share with a neighbor.

1. Priya selects a clip and taps Export/Share.
2. The app shows a preview of the exported clip with a visible watermark overlay (e.g. camera
   ID/timestamp/"VizenLink" mark) burned into the video, not merely metadata a viewer could
   strip.
3. The exported file, once shared, plays back with that same watermark visible to whoever
   receives it.

**What the user expects:** anything she shares is traceably hers/from her camera, discouraging
someone from passing it off as unaltered footage from elsewhere.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall show a preview of an export's burned-in watermark before
  completing the export.
- **[cloud-components]** The export/encode pipeline shall burn a visible watermark into exported
  video, not merely attach removable metadata that a recipient could strip.

## Scenario: An exported clip includes a privacy-masked portion, and that's flagged

**Scenario ID:** SCN-641
**Feature ID:** FEAT-195

**Persona:** Priya's camera has a privacy zone configured (e.g. a neighbor's window is
masked/blurred in all footage); she exports a clip that includes that masked region.

1. When Priya exports a clip whose frame includes an active privacy mask, the export preview
   shows a visible "Redacted" indicator/badge on the clip, not just the mask itself blending in
   silently.
2. The exported file carries this indicator too (e.g. a visible on-screen badge, or an
   accompanying note if shared through the app's own share flow) so a recipient knows part of
   the footage isn't showing everything that was captured.

**What the user expects:** anyone viewing an export can tell if part of it was altered/redacted,
rather than mistaking a quietly-blurred region for an unaltered recording — this matters for
using footage as evidence.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall show a visible "Redacted" indicator on any export that includes
  a privacy-masked/blurred region, distinct from an export with no redaction.
- **[camera-firmware]** The export/encode pipeline shall preserve a machine-readable redaction
  flag alongside the burned-in visual indicator, so downstream tools can also detect that an
  export was redacted.

## Scenario: Exporting raw, unredacted footage for a legitimate investigation

**Scenario ID:** SCN-642
**Feature ID:** FEAT-195

**Persona:** Priya, following a break-in attempt, needs to hand police an unredacted export even
though a privacy zone would normally mask part of the frame.

1. Priya (or an authorized reviewer) selects an option to export without the privacy mask
   applied, available only where her permission level allows it.
2. The app requires an explicit confirmation step given the sensitivity of exporting normally-
   masked content, and the export is watermarked the same as any other export but does not carry
   a "Redacted" flag, since nothing was actually redacted this time.
3. This unredacted export action is itself audit-logged (per FEAT-192).

**What the user expects:** redaction protects privacy by default but doesn't block a genuine,
deliberate need to share the full picture when it matters — with the deliberate choice recorded,
not silent.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall require explicit confirmation to export footage with an
  otherwise-active privacy mask suppressed, gated to an authorized permission level.
- **[mobile-app]** An export with redaction suppressed shall be watermarked identically to any
  other export, and shall not carry the "Redacted" indicator since no masking was applied.
- **[cloud-components]** Suppressing redaction for an export shall be recorded as an audited
  sensitive-data-access event.
