---
feature_id: FEAT-075
status: draft
target_fr_docs: [FR-vms.md, FR-security-rules-engine.md, FR-camera-firmware.md]
---

# Scenario: VMS — Package Arrival/Removal Detection

Covers the fleet-operator side of FEAT-075: monitoring a shared community package area, and
handling a false-candidate detection.

## Scenario: Operator monitors a shared package room across a community building

**Scenario ID:** SCN-266
**Feature ID:** FEAT-075

**Persona:** Dana, managing a community building's shared package room where residents' parcels
sit until picked up.

1. Dana configures package arrival/removal detection on the package-room camera's shelf zone.
2. Throughout the day, arrivals and removals are logged as distinct events in the VMS's event
   list, each with a snapshot.
3. When a resident disputes whether their package was actually delivered, Dana searches the
   event list for arrivals in the relevant time window and finds the snapshot confirming (or
   disproving) the delivery.

**What the user expects:** she has a searchable, evidence-backed log of what came and went from
the shared area, useful for resolving exactly this kind of dispute.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall log package arrival and removal events with timestamps and linked
  snapshots in the site event list, searchable/filterable by camera and time range.

## Scenario: False candidate — a shadow is mistaken for a package

**Scenario ID:** SCN-267
**Feature ID:** FEAT-075

**Persona:** Dana, who notices the package room's event list has an "arrival" logged for a time
when no delivery actually happened — likely a shifting shadow or lighting change mistaken for a
new static object.

1. Dana reviews the flagged "arrival" event's snapshot and can see it's clearly not a package
   (a shadow, a lighting artifact).
2. Because this is presented as a candidate detection (per FEAT-075's own framing), Dana
   understands the system isn't claiming certainty — it's flagging a plausible new-static-object
   appearance for her to confirm or dismiss.
3. Dana can dismiss the false candidate in the VMS, and the dismissal doesn't require her to
   distrust the detection type going forward — occasional false candidates are an accepted
   trade-off of a "candidate," not "confirmed," detection.

**What the user expects:** the system is honest that this class of detection is a candidate,
not a certainty, and gives her an easy way to dismiss an obvious false one without friction.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall visually label package arrival/removal events as candidate detections
  (not confirmed facts), and shall let an operator dismiss a false candidate with a single
  action, distinct from deleting or disputing a confirmed event.
- **[camera-firmware]** The camera shall apply a stability check (the new/removed object
  persisting across multiple frames, not a single transient lighting change) before raising a
  package arrival/removal candidate event, to reduce — though not eliminate — false candidates
  from shadows or lighting shifts.
