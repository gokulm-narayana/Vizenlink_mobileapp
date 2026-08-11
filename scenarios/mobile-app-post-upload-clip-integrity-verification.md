---
feature_id: FEAT-103
status: draft
target_fr_docs: [FR-mobile-app.md, FR-health-monitoring.md, FR-nuraeye-service.md]
---

# Scenario: Mobile App — Post-Upload Clip Integrity Verification

Covers the homeowner-facing side of FEAT-103: after a clip uploads, its integrity is verified
(e.g. checksum match) before it's marked sync-complete.

## Scenario: A clip passes integrity verification after upload

**Scenario ID:** SCN-379
**Feature ID:** FEAT-103

**Persona:** Priya, watching an event sync shortly after it's captured.

1. The clip finishes uploading and briefly shows "Verifying" rather than immediately jumping to
   "Verified," reflecting that a real integrity check happens after the transfer completes, not
   just an assumption that upload success means the file is intact.
2. A moment later it updates to "Verified," and only then does the app treat the clip as the
   authoritative, trustworthy copy (e.g. eligible to be shared or exported).
3. Priya isn't shown any of the checksum mechanics — just the simple state progression — but can
   trust that "Verified" means something concrete happened.

**What the user expects:** "uploaded" and "verified as intact" are treated as two different
things, and she's only told a clip is good once it's actually been checked, not just because the
transfer finished.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall show a distinct "Verifying" sync state between upload
  completion and final "Verified" status, and shall only allow export/sharing actions once an
  event reaches "Verified."
- **[cloud-components]** The cloud sync service shall perform an integrity check (e.g. checksum
  comparison) on each uploaded clip after transfer completes, and shall only mark the event
  "Verified" once that check passes.

## Scenario: A clip fails integrity verification after upload (corrupted in transit)

**Scenario ID:** SCN-380
**Feature ID:** FEAT-103

**Persona:** Priya has a clip that uploads successfully over a flaky connection, but ends up
corrupted, failing its post-upload integrity check.

1. Instead of silently marking the clip "Verified" just because the transfer completed, the app
   shows "Failed — integrity check did not match" and automatically triggers a re-upload attempt
   rather than leaving the corrupted copy as final.
2. Priya sees the event stay in a pending/retrying state rather than a false "Verified," so she
   never mistakenly trusts a corrupted clip as good evidence.
3. Once the re-upload succeeds and passes verification, the event updates to "Verified" as
   normal.

**What the user expects:** the app never lets a corrupted upload masquerade as a good one — it
catches the mismatch and fixes it automatically before telling her the clip is trustworthy.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall never display a clip as "Verified" if its post-upload integrity
  check failed, and shall reflect an automatic re-upload attempt in the visible sync state.
- **[cloud-components]** The cloud sync service shall automatically trigger a re-upload when a
  clip fails its post-upload integrity check, rather than accepting the corrupted copy as final.
