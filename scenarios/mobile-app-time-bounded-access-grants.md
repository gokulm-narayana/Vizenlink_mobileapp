---
feature_id: FEAT-153
status: draft
target_fr_docs: [FR-mobile-app.md, FR-access-control.md]
---

# Scenario: Mobile App — Time-Bounded Access Grants

Covers the mobile-app side of FEAT-153: an access grant (for contractors, temporary guards,
guests, or support sessions) automatically expires after a set duration, rather than requiring
manual revocation.

## Scenario: Homeowner grants a house-sitter access for the weekend only

**Scenario ID:** SCN-553
**Feature ID:** FEAT-153

**Persona:** Priya, going away for the weekend, granting her house-sitter temporary access to
her home cameras.

1. Priya invites her house-sitter and, instead of leaving the grant open-ended, sets an
   explicit expiration — this Saturday through Sunday night.
2. The house-sitter uses the app normally over the weekend, watching live view as needed.
3. Once the set time passes, the house-sitter's access automatically ends — Priya doesn't have
   to remember to revoke it herself.
4. The house-sitter's app clearly shows their access is no longer valid if they try to open it
   after the expiration.

**What the user expects:** a temporary grant genuinely stays temporary — it isn't something she
has to remember to clean up manually.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall let an owner set an explicit expiration duration/date when
  granting access to a guest, contractor, or other temporary user.
- **[mobile-app]** The app shall automatically expire a time-bounded grant at its set time
  without requiring any manual revocation action.

## Scenario: A guest tries to use expired access

**Scenario ID:** SCN-554
**Feature ID:** FEAT-153

**Persona:** The same house-sitter, opening the app on Monday morning after the weekend grant
expired Sunday night.

1. The house-sitter opens the app and taps into what was previously the live-view camera.
2. Instead of connecting, the app tells them plainly that their access has expired, rather than
   showing a generic error or letting the request silently fail.
3. Priya isn't required to take any action for this to happen — the expiration was already set
   in advance.

**What the user expects:** an expired grant is enforced automatically and communicated clearly
to the (former) guest, not left ambiguous.

> **Review:** ⏳ Pending

### Derived Requirements

- **[mobile-app]** The app shall reject any access attempt from a grant that has passed its
  expiration, and shall show the affected user a clear "access expired" message rather than a
  generic connection error.
</content>
