---
feature_id: FEAT-041
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md]
---

# Scenario: VMS — Event Lock / Evidence Protection

Covers the fleet-operator-facing side of FEAT-041: locking/protecting priority-incident
recordings across a site from automatic retention deletion or overwrite.

## Scenario: Operator locks multiple incident recordings

**Scenario ID:** SCN-147
**Feature ID:** FEAT-041

**Persona:** Marcus is investigating an incident that spans clips from three cameras and wants
all of them protected from deletion while the investigation is open.

1. Marcus selects the relevant clips across the three cameras from the event log.
2. He applies "Lock" to all of them in one action.
3. The VMS confirms each clip's lock individually, marking all three as protected in the event
   log and in each camera's own timeline.
4. Marcus can later view a fleet-wide list of every currently locked recording, to confirm
   nothing was missed and nothing stayed locked longer than needed.

**What the user expects:** he can protect a whole set of related evidence in one action and
later audit everything currently under protection across the site.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall allow locking multiple recordings (potentially across different
  cameras) in a single action, confirming each lock individually.
- **[vms]** The VMS shall provide a fleet-wide view listing every currently locked recording
  across all cameras at a site.

## Scenario: Retention policy attempts to delete a locked recording

**Scenario ID:** SCN-148
**Feature ID:** FEAT-041

**Persona:** Priya's site retention policy (FEAT-037) reaches the age of a recording that was
locked earlier for an ongoing case.

1. As the retention process evaluates recordings for deletion, it detects the recording is
   locked and skips it.
2. The VMS's health/storage view accounts for locked recordings separately when estimating
   available/reclaimable storage, so Priya isn't surprised that storage didn't shrink as much
   as the retention policy alone would suggest.
3. If accumulated locked recordings begin materially reducing available storage for new
   recording, the VMS surfaces this as a distinct warning rather than only a generic
   low-storage alert.

**What the user expects:** locked evidence is never silently deleted by a routine policy change,
and the storage math accounts honestly for what's protected.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS retention engine shall skip any locked/protected recording during
  policy-driven deletion, regardless of age.
- **[vms]** The VMS shall account for storage consumed by locked recordings separately in its
  storage/health estimates, and shall warn distinctly when locked recordings are materially
  reducing available recording storage.
