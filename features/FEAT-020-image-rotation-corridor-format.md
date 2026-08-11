# FEAT-020 — Image Rotation / Corridor Format

**Origin:** Inferred — domain/industry-standard CCTV practice (not from a seed row or the
earlier existing-FR/code audit). Raised as a "necessary for a basic CCTV camera" candidate
alongside mirror/flip; unlike mirror/flip, this one was confirmed **not yet implemented**.

**Why it's necessary/basic:** 90°/270° portrait-mode (9:16) streaming is a standard CCTV
feature for covering narrow, elongated scenes (corridors, aisles, stairwells) efficiently
without wasting frame area on a landscape aspect ratio. The seed doc's own SKU-D description
(§6) explicitly targets "long corridor" scenes, which is exactly the deployment case this
feature exists for — so while it has no seed ID, it's directly implied by the seed doc's own
SKU coverage.

**Investigation performed (against user pushback, each step verified in code rather than
assumed):**

1. Confirmed the ONVIF media capabilities layer hardcodes `rotation = false` — this repo does
   not currently advertise or expose ONVIF `Rotation`.
2. User asked whether the underlying hardware/ISP could support rotation at all. Verified the
   Realtek Ameba Pro 2 SDK's video encoder driver *does* define hardware rotation constants and
   carries a `rotation` field through its stream-open command construction — i.e. the
   capability exists at the encoder level, it's simply unexposed through this repo's BSP/ONVIF
   layer (the same situation mirror/flip was in before someone wired it up).
3. User asked whether rotation could change at runtime like bitrate. Verified it cannot the
   same way — bitrate/rate-control has a dedicated runtime setter, while rotation is only
   passed at video-channel-open time in the SDK, implying a channel close/reopen is needed to
   change it.
4. User asked whether the repo's existing stream-restart pattern (already used when changing
   other encoder parameters — stop stream, set params, reapply) would be sufficient to carry a
   rotation change too. Found that this repo's BSP already performs exactly that
   stop → set-params → apply sequence on the same parameter struct type that carries the
   rotation field, suggesting the existing restart mechanism is very likely reusable —
   **but this is based on static code reading, not a real-hardware test; verifying it actually
   rotates correctly end-to-end (including any downstream OSD/AI-path interaction) is
   unverified and should happen before this Feature reaches Design.**

**Priority:** P1 — a real differentiator tied to the seed doc's own corridor-scene SKU intent,
not a core P0 security capability.

**User-Facing:** yes — an installer/admin would select a rotation mode for narrow-scene
mounts.

**FR Status:** Not started — no FR entry exists, and the capability isn't wired up through the
BSP/ONVIF layer yet, only present as an unexposed encoder-level parameter.

**Status:** confirmed (2026-07-21). Carries a real-hardware-verification caveat into any
future Design stage for this Feature.
