---
feature_id: FEAT-040
status: draft
target_fr_docs: [FR-mobile-app.md, FR-camera-firmware.md]
---

# Scenario: Mobile App — Evidence Export with Integrity Manifest

Covers the homeowner-facing side of FEAT-040: exporting a clip with camera/site/time metadata
and a cryptographic integrity manifest proving it hasn't been tampered with, for cases like
sharing footage with police or insurance.

## Scenario: Homeowner exports a clip with metadata and manifest

**Scenario ID:** SCN-141
**Feature ID:** FEAT-040

**Persona:** Marcus wants to give a police officer a copy of the clip showing a package theft,
in a form that can be trusted as unaltered.

1. Marcus selects the relevant clip and taps "Export."
2. The app packages the clip along with metadata (camera identity, site/location, and the exact
   recording time range) and a cryptographic integrity manifest (hash) covering the exported
   content.
3. The app confirms the export completed and shows Marcus where the file was saved / how to
   share it.
4. The manifest is presented (or made available) in a form Marcus, or whoever receives the
   export, can use to verify the file's integrity independently.

**What the user expects:** what he hands over isn't just a video file — it comes with proof of
where it came from and that it hasn't been edited.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let a user export a clip bundled with camera identity,
  site/location, and recording time-range metadata, plus a cryptographic integrity manifest
  covering the exported content.
- **[mobile-app]** The app shall make the integrity manifest available to the user in a form
  that can be independently verified, not only embedded invisibly.
- **[camera-firmware]** The camera (or the service producing the export) shall compute the
  integrity manifest from the actual exported bytes at export time, so any later modification of
  the file would be detectable.

## Scenario: Verifying an exported clip hasn't been tampered with

**Scenario ID:** SCN-142
**Feature ID:** FEAT-040

**Persona:** Priya, months later, is asked by an insurance investigator to prove that a clip she
handed over earlier is the original, unaltered export.

1. Priya (or the investigator, using the manifest she provided) checks the exported file's
   current hash against the integrity manifest issued at export time.
2. If the file is unmodified, the check confirms a match.
3. If the file was altered in any way since export, the check clearly reports a mismatch rather
   than a false confirmation.

**What the user expects:** the integrity claim actually holds up under real scrutiny later, not
just at the moment of export.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app (or an accompanying verification tool/instructions) shall support
  checking an exported file's current hash against its original integrity manifest, reporting a
  clear match/mismatch result.
