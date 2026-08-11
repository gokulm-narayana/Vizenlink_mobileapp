---
feature_id: FEAT-143
status: draft
target_fr_docs: [FR-vms.md, FR-camera-firmware.md]
---

# Scenario: VMS — NVR-Offline Fallback for Standalone-Capable Cameras

Covers FEAT-143: when the NVR goes offline but an individual camera is still online and
standalone-capable, remote viewing through the VMS falls back to a defined safe path instead
of failing silently.

## Scenario: NVR outage — the camera keeps serving remote view directly

**Scenario ID:** SCN-513
**Feature ID:** FEAT-143

**Persona:** Elena, a site manager for a small retail plaza, checks a store's camera remotely
through the VMS's web client from home, while the site's local NVR has gone offline (e.g. a
power blip in the back office).

1. Elena opens the VMS from her laptop and selects the parking-lot camera, as she does most
   evenings.
2. Normally the VMS fetches live view via the NVR, but the VMS detects the NVR is unreachable.
3. Because the parking-lot camera is a standalone-capable model still online on the local
   network, the VMS automatically falls back to viewing it directly, without Elena having to do
   anything different.
4. The VMS clearly marks this as a fallback (direct/standalone) view rather than the normal
   NVR-mediated view, so Elena understands the site's NVR needs attention.
5. Elena confirms nothing is actually wrong at the store despite the NVR outage.

**What the user expects:** an NVR outage degrades gracefully to whatever remote view is still
possible, rather than remote viewing failing entirely.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall detect NVR unreachability and automatically attempt a direct
  fallback connection to any standalone-capable camera at that site, rather than reporting the
  site as fully offline.
- **[vms]** The VMS shall visibly distinguish a fallback (direct-to-camera) view from the
  normal NVR-mediated view, so the operator knows the NVR itself needs attention.
- **[camera-firmware]** The camera shall remain reachable for direct remote/standalone viewing
  when it detects it has lost contact with its local NVR, rather than depending on the NVR to
  broker every remote session.

## Scenario: Both the NVR and the camera are unreachable

**Scenario ID:** SCN-514
**Feature ID:** FEAT-143

**Persona:** Elena, same site, but this time the whole site has lost internet/power, not just
the NVR.

1. Elena opens the VMS and tries the same camera.
2. The VMS attempts the normal NVR path, fails, then attempts the direct fallback path, and
   that also fails.
3. Rather than looping silently or showing the same generic error as a simple NVR hiccup, the
   VMS reports that the entire site appears offline (both NVR and camera unreachable), not just
   "NVR down."
4. Elena can see the last successful contact time for both the NVR and the camera, to judge how
   long the outage has lasted.

**What the user expects:** the VMS tells the difference between "just the NVR is down, but I
can still watch this camera" and "the whole site has gone dark" — so she doesn't waste time on
a fallback path that was never going to work.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall distinguish, in its status messaging, "NVR unreachable, camera
  fallback available" from "NVR and camera both unreachable," rather than one generic offline
  message.
- **[vms]** The VMS shall show last-known-contact time for both the NVR and the camera when
  both are currently unreachable.

## Scenario: NVR comes back online while a fallback session is active

**Scenario ID:** SCN-515
**Feature ID:** FEAT-143

**Persona:** Elena, still viewing the parking-lot camera via the direct fallback path from the
first scenario, when the site's NVR comes back up.

1. While Elena is still watching the fallback view, the site's NVR reconnects and comes back
   online.
2. The VMS detects the NVR is reachable again and transitions Elena's view back to the normal
   NVR-mediated path.
3. The transition happens without a jarring stream drop that Elena would perceive as a glitch —
   at most a brief, clearly-indicated reconnect.
4. The VMS's fallback indicator disappears, confirming normal operation has resumed.

**What the user expects:** recovery from the fallback path is automatic and clean, not
something she has to manually undo by closing and reopening the camera.

> **Review:** ⏳ Pending

### Derived Requirements

- **[vms]** The VMS shall detect NVR recovery while a direct-fallback session is active and
  transition the viewer back to the NVR-mediated path automatically, clearing the fallback
  indicator.
- **[vms]** The VMS shall avoid maintaining both a direct and an NVR-mediated session to the
  same camera simultaneously once the NVR is confirmed back online, to avoid doubling load on
  the camera.
</content>
