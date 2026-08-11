---
feature_id: FEAT-190
status: draft
target_fr_docs: [FR-vms.md, FR-security-lifecycle.md]
---

# Scenario: VMS — Configurable Retention with Verified Deletion

Covers FEAT-190's fleet-operator side: setting retention policy across many cameras at once, and
being able to audit that deletions are actually happening as configured, not just trusted.

## Scenario: Setting retention policy per site/camera group

**Scenario ID:** SCN-631
**Feature ID:** FEAT-190

**Persona:** Raj manages cameras across three community sites, each with a different legally
required retention period.

1. Raj opens VMS Storage & Retention settings and sets a retention period per site (not only
   globally per-camera), since different sites have different requirements.
2. Cameras at each site inherit that site's retention setting unless individually overridden.
3. VMS shows, per camera, the effective retention period actually in force, so Raj can spot a
   camera that's drifted from its site default.

**What the user expects:** he can manage retention at the scale he actually operates at (by
site), while still being able to see and override the effective setting per camera.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall support configuring retention policy at a site/group level, with
  per-camera override, and shall display each camera's currently effective retention period.

## Scenario: Auditing that scheduled deletions actually completed across the fleet

**Scenario ID:** SCN-632
**Feature ID:** FEAT-190

**Persona:** Raj needs to demonstrate, for a compliance review, that footage older than the
configured retention period is genuinely being deleted across all managed cameras.

1. Raj opens a fleet-wide Deletion Audit view in VMS.
2. It lists completed deletion batches per camera/site with counts and dates, and flags any
   camera where a scheduled deletion did not run or did not complete (e.g. camera was offline).
3. Raj can drill into a flagged camera to see the reason and trigger a retry.

**What the user expects:** a real audit trail he can present as evidence, and an active flag for
any camera where deletion silently failed to happen — not a dashboard that just assumes success.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall provide a fleet-wide deletion audit view showing completed deletion
  batches per camera with counts/dates, and shall flag any camera whose scheduled deletion did
  not run or complete.
- **[cloud-components]** A camera that misses a scheduled retention deletion (e.g. due to being
  offline) shall have that miss recorded and retried, rather than silently skipped with no
  record.

## Scenario: An operator manually purges a camera's entire history for an offboarded site

**Scenario ID:** SCN-633
**Feature ID:** FEAT-190

**Persona:** Raj's organization loses the contract for one community site and must fully purge
that site's footage per the data handling agreement.

1. Raj selects the site and initiates a full-history purge, distinct from routine retention
   deletion, requiring elevated confirmation (e.g. re-entering credentials) given its
   irreversibility and scope.
2. VMS reports back a verified completion (counts deleted, confirmation from the backend) rather
   than an immediate "done" the moment the request was submitted.
3. The deletion audit view (SCN-632) reflects this purge as a distinct, logged event.

**What the user expects:** a full, deliberate purge is treated with more friction and better
verification than routine day-to-day retention deletion, given the stakes of getting it wrong.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall require elevated confirmation for a full-history manual purge, distinct
  from routine retention-triggered deletion, and shall report verified completion rather than an
  immediate optimistic success.
- **[cloud-components]** A full-history purge shall be logged as a distinct audited event,
  separate from routine scheduled retention deletions.
