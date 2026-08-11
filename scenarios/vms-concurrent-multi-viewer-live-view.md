---
feature_id: FEAT-142
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md]
---

# Scenario: VMS — Concurrent Multi-Viewer Live View with Limits

Covers the fleet-operator side of FEAT-142: multiple VMS operator seats can watch the same
camera's live feed at once, capped at a per-camera/site limit shared with any mobile-app
viewers of the same camera.

## Scenario: Two operator workstations monitor the same camera during a normal shift

**Scenario ID:** SCN-511
**Feature ID:** FEAT-142

**Persona:** Marcus, a security operator at a monitored office site, and a colleague on a
second workstation in the same control room.

1. Marcus opens the lobby camera's live tile on his workstation as part of his routine
   monitoring wall.
2. His colleague, on a separate login and a separate workstation, also opens the same lobby
   camera into their own live view.
3. Both tiles play the stream normally; the VMS shows a small viewer-count indicator on the
   tile (e.g. "2 viewing") so either operator can see the camera is being watched by more than
   just themselves.
4. Neither operator's stream stutters or drops because of the other's session.

**What the user expects:** normal shift-overlap monitoring — two operators covering the same
feed — just works, and each can see that the other is also watching.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall allow more than one operator session to open a live view of the same
  camera concurrently, and shall display a live viewer-count indicator on the camera tile.
- **[camera-firmware]** The camera shall support serving multiple concurrent live-view
  sessions of the same stream, up to a configured maximum, shared across VMS and mobile-app
  viewers of that camera.

## Scenario: Aggregate viewer cap is reached during an incident

**Scenario ID:** SCN-512
**Feature ID:** FEAT-142

**Persona:** Marcus, during a break-in alert, as several operators and an on-call manager all
try to pull up the same camera at once.

1. An alert fires, and within seconds several operators and an on-call manager all attempt to
   open live view of the alerted camera from their own consoles.
2. Once the camera's configured concurrent-viewer limit is reached, the VMS explicitly tells
   the next operator who tries that the limit has been hit, rather than showing a black tile or
   a generic timeout.
3. The VMS suggests an alternative — e.g. a shared/mirrored view of an existing session, or
   waiting for a slot to free up — instead of leaving the operator with no path forward.
4. As soon as one viewer closes their session, the next operator who tries can connect.

**What the user expects:** even during a high-attention incident, the system tells operators
plainly why they can't get another live tile, instead of behaving as if something is broken.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall present an explicit, distinguishable message when an operator's
  live-view request is rejected due to the camera's concurrent-viewer limit, and shall not
  silently drop or endlessly spin the tile.
- **[vms]** The VMS should offer a path forward (retry, or a shared/mirrored view of an
  existing session) when the limit is reached, rather than a dead end.
- **[camera-firmware]** The camera shall enforce the same concurrent-viewer limit consistently
  regardless of whether requesting clients are VMS operators or mobile-app users, since both
  draw from the same camera-side session pool.
</content>
